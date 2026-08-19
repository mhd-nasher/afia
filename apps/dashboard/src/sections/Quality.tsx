import { useMemo, useState, type ReactNode } from 'react'
import {
  actorName,
  caseReceivedAt,
  fmtDateTime,
  fmtTime,
  minutesSince,
  pct,
  useNow,
} from '../lib'
import { store } from '../store'
import { BarList, LineChart } from '../charts'

/**
 * Quality — all aggregate, ward-level at the finest grain (§2.9). No metric on
 * this screen can be traced to an individual clinician, and the audit log is
 * read-only: no delete, no edit, append-only by construction.
 *
 * Charts are lines and bars only; every series is an indigo tint. The clinical
 * trio never appears as a chart colour.
 */

const ACTION = '#2d4a8a'
const ACCENT = '#7b6fd4'

function dayKey(t: number): number {
  const d = new Date(t)
  d.setHours(0, 0, 0, 0)
  return d.getTime()
}

function formatPrev(v: unknown): string {
  if (v === null || v === undefined) return '—'
  return typeof v === 'string' ? v : JSON.stringify(v)
}

function toCsvCell(v: string): string {
  return /[",\n]/.test(v) ? `"${v.replaceAll('"', '""')}"` : v
}

export function Quality(): ReactNode {
  const now = useNow()
  const handovers = store.handovers()
  const cases = store.cases()
  const wardA = store.ward('ward-a')
  const committedMin = wardA?.committedReviewMinutes ?? 30

  // Most frequently missing fields — aggregate handover flags by label.
  const missing = useMemo(() => {
    const counts = new Map<string, number>()
    for (const h of handovers) {
      for (const f of h.flags) counts.set(f.label, (counts.get(f.label) ?? 0) + 1)
    }
    return [...counts.entries()]
      .sort((a, b) => b[1] - a[1])
      .map(([label, value]) => ({ label: `Not mentioned: ${label}`, value }))
  }, [handovers])

  // Drug correction rate over time — corrected drug chips ÷ all drug chips, per day.
  const allDrugChips = handovers.flatMap((h) =>
    h.chips.filter((c) => c.kind === 'drug').map((c) => ({ at: h.createdAt, chip: c })),
  )
  const correctionSeries = useMemo(() => {
    const byDay = new Map<number, { total: number; corrected: number }>()
    for (const { at, chip } of allDrugChips) {
      const k = dayKey(at)
      const acc = byDay.get(k) ?? { total: 0, corrected: 0 }
      acc.total += 1
      if (chip.correctedTo !== null) acc.corrected += 1
      byDay.set(k, acc)
    }
    return [...byDay.entries()]
      .sort((a, b) => a[0] - b[0])
      .map(([x, v]) => ({ x, y: (v.corrected / Math.max(1, v.total)) * 100 }))
  }, [handovers])
  const correctedCount = allDrugChips.filter((c) => c.chip.correctedTo !== null).length
  const correctionRate =
    allDrugChips.length === 0 ? 0 : correctedCount / allDrugChips.length

  // Committed vs actual review time — the single most important chart.
  const submitted = cases.filter((c) => c.status === 'submitted')
  const actualPoints = submitted
    .map((c) => ({ x: caseReceivedAt(c), y: minutesSince(caseReceivedAt(c), now) }))
    .sort((a, b) => a.x - b.x)
  const commitPoints =
    actualPoints.length > 0
      ? [
          { x: actualPoints[0]?.x ?? now, y: committedMin },
          { x: actualPoints[actualPoints.length - 1]?.x ?? now, y: committedMin },
        ]
      : []

  // Export success rate over time — cumulative, from the audit trail.
  const exportSeries = useMemo(() => {
    const events = store
      .auditTrail()
      .filter((e) => e.action === 'confirmed' || e.action === 'export_failed')
      .slice()
      .sort((a, b) => a.at - b.at)
    let ok = 0
    let total = 0
    return events.map((e) => {
      total += 1
      if (e.action === 'confirmed') ok += 1
      return { x: e.at, y: (ok / total) * 100 }
    })
  }, [handovers.length])

  const confirmed = handovers.filter((h) => h.status === 'confirmed_in_system').length
  const failed = handovers.filter((h) => h.status === 'export_failed').length
  const queued = handovers.filter((h) => h.status === 'queued').length
  const signedOnly = handovers.filter((h) => h.status === 'signed').length
  const exportDenominator = confirmed + failed + queued + signedOnly
  const exportRate = exportDenominator === 0 ? 0 : confirmed / exportDenominator

  // Audit log — searchable, filterable, exportable. Append-only underneath.
  const [query, setQuery] = useState('')
  const [actionFilter, setActionFilter] = useState('')
  const audit = [...store.auditTrail()].reverse()
  const actions = [...new Set(store.auditTrail().map((e) => e.action as string))].sort()
  const q = query.trim().toLowerCase()
  const filtered = audit.filter((e) => {
    if (actionFilter !== '' && e.action !== actionFilter) return false
    if (q === '') return true
    return [actorName(e.actor), e.action, e.entityId, e.detail ?? '', formatPrev(e.previousValue)]
      .join(' ')
      .toLowerCase()
      .includes(q)
  })

  const exportCsv = (): void => {
    const header = 'time,actor,action,entity,detail,previous_value'
    const rows = filtered.map((e) =>
      [
        new Date(e.at).toISOString(),
        actorName(e.actor),
        e.action,
        e.entityId,
        e.detail ?? '',
        formatPrev(e.previousValue),
      ]
        .map(toCsvCell)
        .join(','),
    )
    const blob = new Blob([[header, ...rows].join('\n')], { type: 'text/csv' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `afia-audit-${new Date().toISOString().slice(0, 10)}.csv`
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <>
      <h1 className="page-title">Quality</h1>
      <p className="page-caption">
        Aggregate quality signals, ward-level at the finest grain. Nothing here
        measures an individual clinician&apos;s speed, volume, or ranking (§2.9).
      </p>

      <div className="chart-grid">
        <section className="panel">
          <h2>Most frequently missing information</h2>
          <p className="panel-caption">
            Aggregated omission flags across all handovers — neutral counts, not
            importance rankings. Feeds template revision.
          </p>
          <BarList rows={missing} />
        </section>

        <section className="panel">
          <h2>Drug correction rate over time</h2>
          <p className="panel-caption">
            Drug chips corrected through the formulary picker ÷ all drug chips, per
            day. A rising line means transcription is degrading.
          </p>
          <LineChart
            series={[{ label: 'correction rate', color: ACTION, points: correctionSeries }]}
            yFormat={(y) => `${Math.round(y)}%`}
            xFormat={(x) => new Date(x).toLocaleDateString([], { day: '2-digit', month: 'short' })}
            yMax={100}
          />
          <p className="chart-note">
            All time: <span className="num">{correctedCount}</span> of{' '}
            <span className="num">{allDrugChips.length}</span> drug chips corrected (
            <span className="num">{pct(correctionRate)}</span>)
          </p>
        </section>

        <section className="panel">
          <h2>Committed vs actual review time</h2>
          <p className="panel-caption">
            Wait per submitted file against the ward&apos;s committed review time.
          </p>
          <LineChart
            series={[
              { label: 'actual wait (min)', color: ACTION, points: actualPoints },
              { label: `committed (${committedMin} min)`, color: ACCENT, points: commitPoints },
            ]}
            yFormat={(y) => `${Math.round(y)}`}
            xFormat={(x) => fmtTime(x)}
          />
          <p className="honesty">
            actual = current wait per open file — review completion is not yet
            instrumented (HANDOFF §9.4)
          </p>
        </section>

        <section className="panel">
          <h2>Export success rate</h2>
          <p className="panel-caption">
            Cumulative share of signed handovers positively acknowledged by the
            receiving system.
          </p>
          <LineChart
            series={[{ label: 'success rate', color: ACTION, points: exportSeries }]}
            yFormat={(y) => `${Math.round(y)}%`}
            xFormat={(x) => fmtTime(x)}
            yMax={100}
          />
          <p className="chart-note">
            Now: <span className="num">{confirmed}</span> confirmed ·{' '}
            <span className="num">{signedOnly}</span> signed ·{' '}
            <span className="num">{queued}</span> queued ·{' '}
            <span className="num">{failed}</span> failed —{' '}
            <span className="num">{pct(exportRate)}</span> confirmed overall
          </p>
        </section>
      </div>

      <section className="panel">
        <h2>Full audit log</h2>
        <p className="panel-caption">
          Append-only, newest first. No delete or edit control exists — not in this
          UI, not in the store beneath it, and not past the database rules.
        </p>
        <div className="audit-tools">
          <input
            className="input input-sm"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search actor, action, entity, detail"
            aria-label="Search audit log"
          />
          <select
            className="input input-sm"
            value={actionFilter}
            onChange={(e) => setActionFilter(e.target.value)}
            aria-label="Filter by action"
          >
            <option value="">All actions</option>
            {actions.map((a) => (
              <option key={a} value={a}>
                {a}
              </option>
            ))}
          </select>
          <button className="btn btn-sm" onClick={exportCsv}>
            Export CSV
          </button>
          <span className="cell-sub">
            <span className="num">{filtered.length}</span> of{' '}
            <span className="num">{audit.length}</span> events
          </span>
        </div>
        <div className="audit-wrap">
          <table className="data">
            <thead>
              <tr>
                <th>Time</th>
                <th>Actor</th>
                <th>Action</th>
                <th>Entity</th>
                <th>Detail</th>
                <th>Previous value</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((e) => (
                <tr key={e.id}>
                  <td className="num" style={{ whiteSpace: 'nowrap' }}>
                    {fmtDateTime(e.at)}
                  </td>
                  <td>{actorName(e.actor)}</td>
                  <td className="mono">{e.action}</td>
                  <td className="mono">{e.entityId}</td>
                  <td>{e.detail ?? '—'}</td>
                  <td>{formatPrev(e.previousValue)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </>
  )
}
