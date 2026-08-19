import type { ReactNode } from 'react'
import type { SyncStatus } from '@afia/core/src/firebase'
import { orderQueue, QUEUE_SORT_STATEMENT } from '@afia/rules'
import {
  caseCompleteness,
  caseReceivedAt,
  fmtMinutes,
  fmtTime,
  minutesSince,
  pct,
  wardName,
  useNow,
} from '../lib'
import { lastDataUpdateAt, store } from '../store'
import { useManager } from '../session'

/**
 * Live — the landing screen (HANDOFF §7).
 *
 * Deliberately absent, per §2.10: no severity or priority column, no urgency
 * color-coding, no risk sort. Cases carry a priority in the data model, but
 * the queue neither displays nor uses it — ordering by risk would be triage
 * performed by software.
 *
 * System failure is never clinical red: export failures and connection
 * outages render as full-width inverted banners (design brief).
 */

/** Cases carry no ward yet — intake goes to the acute medical ward. */
const INTAKE_WARD_ID = 'ward-a'

export function Live(): ReactNode {
  const now = useNow()
  const manager = useManager()
  const cases = store.cases()
  const handovers = store.handovers()
  const intakeWard = store.ward(INTAKE_WARD_ID)
  const committedMin = intakeWard?.committedReviewMinutes ?? 30
  const owner = intakeWard?.reviewOwner ?? '—'

  const submitted = cases.filter((c) => c.status === 'submitted')
  const waits = submitted.map((c) => minutesSince(caseReceivedAt(c), now))
  const longestWait = waits.length > 0 ? Math.max(...waits) : 0
  const signedUnconfirmed = handovers.filter(
    (h) => h.status === 'signed' || h.status === 'queued',
  )
  const failures = handovers.filter((h) => h.status === 'export_failed')

  const breaches = submitted.filter(
    (c) => minutesSince(caseReceivedAt(c), now) > committedMin,
  )

  const queue = orderQueue(
    submitted.map((c) => ({
      id: c.id,
      receivedAt: caseReceivedAt(c),
      completeness: caseCompleteness(c).completeness,
      patientName: c.patientName,
      completedBy: c.completedBy,
    })),
  )

  const retry = (id: string): void => {
    // Re-queues the export. Confirmation happens only on positive
    // acknowledgement from the receiving system — never on send-completion.
    store.retryExport(id, manager.name)
  }

  const syncStatus = (store as { syncStatus?: SyncStatus }).syncStatus
  const syncError = (store as { syncError?: string | null }).syncError ?? null

  return (
    <>
      <h1 className="page-title">Live</h1>
      <p className="page-caption">
        Current state of incoming patient files and outgoing handovers. Observation
        only — nothing on this screen sits between a patient file and the nursing team.
      </p>

      {syncStatus === 'error' && (
        <div className="invert-strip" role="alert">
          <span className="invert-icon" aria-hidden>▲</span>
          <span>
            Data connection failed — the numbers below may be stale.{' '}
            {syncError !== null && <span className="mono">{syncError}</span>}
          </span>
        </div>
      )}

      {failures.length > 0 && (
        <div className="invert-strip" role="alert">
          <span className="invert-icon" aria-hidden>▲</span>
          <span>
            Export integration: <span className="num">{failures.length}</span>{' '}
            signed {failures.length === 1 ? 'handover was' : 'handovers were'} not
            acknowledged by the receiving system. Retry from the failures table below.
          </span>
        </div>
      )}

      <div className="tiles">
        <div className="tile">
          <div className="tile-label">Awaiting review</div>
          <div className="tile-value">{submitted.length}</div>
          <div className="tile-sub">submitted patient files</div>
        </div>
        <div className="tile">
          <div className="tile-label">Longest wait</div>
          <div className="tile-value">
            {longestWait}<span className="tile-unit"> min</span>
          </div>
          <div className="tile-sub">since oldest file arrived</div>
        </div>
        <div className="tile">
          <div className="tile-label">Signed, unconfirmed</div>
          <div className="tile-value">{signedUnconfirmed.length}</div>
          <div className="tile-sub">awaiting acknowledgement from the hospital system</div>
        </div>
        <div className="tile">
          <div className="tile-label">Export failures</div>
          <div className="tile-value">{failures.length}</div>
          <div className="tile-sub">need retry below</div>
        </div>
      </div>

      <section className="invert" aria-label="Files past the committed review time">
        <h2>Past the committed review time</h2>
        <p className="panel-caption">
          Measured against each ward&apos;s committed review time (set in Wards).
        </p>
        {breaches.length === 0 ? (
          <p className="invert-empty">
            No files past the committed review time right now. This panel stays on
            screen even when empty — absence must be distinguishable from a broken
            query.
          </p>
        ) : (
          breaches.map((c) => {
            const wait = minutesSince(caseReceivedAt(c), now)
            return (
              <div className="breach-row" key={c.id}>
                <span className="breach-name">{c.patientName}</span>
                <span className="breach-ward">{wardName(INTAKE_WARD_ID)}</span>
                <span className="breach-over">
                  waiting <span className="num">{fmtMinutes(wait)}</span> ·{' '}
                  <span className="num">{fmtMinutes(wait - committedMin)}</span> past
                </span>
                <span className="breach-commit">
                  commitment <span className="num">{committedMin} min</span> — owner {owner}
                </span>
              </div>
            )
          })
        )}
      </section>

      <section className="panel">
        <h2>Incoming queue</h2>
        <p className="panel-caption">Patient files awaiting nursing review.</p>
        <div className="sort-statement">{QUEUE_SORT_STATEMENT}</div>
        {queue.length === 0 ? (
          <p className="empty-note">No files in the queue.</p>
        ) : (
          <table className="data">
            <thead>
              <tr>
                <th>Received</th>
                <th>Patient</th>
                <th>Ward</th>
                <th>Source</th>
                <th>Completeness</th>
                <th>Wait</th>
                <th>Review state</th>
              </tr>
            </thead>
            <tbody>
              {queue.map((entry) => (
                <tr key={entry.id}>
                  <td className="num">{fmtTime(entry.receivedAt)}</td>
                  <td>{entry.patientName}</td>
                  <td>{wardName(INTAKE_WARD_ID)}</td>
                  <td>{entry.completedBy === 'self' ? 'Patient' : 'Caregiver'}</td>
                  <td className="num">{pct(entry.completeness)}</td>
                  <td className="num">
                    {fmtMinutes(minutesSince(entry.receivedAt, now))}
                  </td>
                  <td className="status-neutral">Awaiting review</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="panel">
        <h2>Export failures</h2>
        <p className="panel-caption">
          Signed handovers the receiving system did not acknowledge.
        </p>
        {failures.length === 0 ? (
          <p className="empty-note">No export failures right now.</p>
        ) : (
          <table className="data">
            <thead>
              <tr>
                <th>Handover</th>
                <th>Ward</th>
                <th>Signed at</th>
                <th>Failure reason</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {failures.map((h) => {
                const patient = store.patient(h.patientId)
                return (
                  <tr key={h.id}>
                    <td>
                      {patient?.name ?? h.patientId}
                      <div className="cell-sub mono">{h.id}</div>
                    </td>
                    <td>{patient !== undefined ? wardName(patient.wardId) : '—'}</td>
                    <td className="num">
                      {h.signature !== null ? fmtTime(h.signature.signedAt) : '—'}
                    </td>
                    <td>{h.exportError ?? 'Unknown error'}</td>
                    <td>
                      <button className="btn btn-sm" onClick={() => retry(h.id)}>
                        Retry export
                      </button>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
        <p className="chart-note">
          Retry re-queues the export. A handover is confirmed only on positive
          acknowledgement from the receiving system — never on local send-completion.
        </p>
      </section>

      <section className="panel">
        <h2>System state</h2>
        <p className="panel-caption">Each component of the pipeline, with its last-known state.</p>
        <dl className="kv">
          <dt>Transcription service</dt>
          <dd>
            On-device browser transcription · checked <span className="num">{fmtTime(now)}</span>
          </dd>
          <dt>Export integration</dt>
          <dd>
            FHIR-ready — no hospital write path is connected yet; exports queue until
            a receiving system acknowledges them
          </dd>
          <dt>Last successful sync</dt>
          <dd>
            <span className="num">{fmtTime(lastDataUpdateAt())}</span>
            {syncStatus !== undefined && (
              <>
                {' '}· connection{' '}
                <span className="mono">{syncStatus === 'online' ? 'online' : syncStatus}</span>
              </>
            )}
          </dd>
        </dl>
      </section>
    </>
  )
}
