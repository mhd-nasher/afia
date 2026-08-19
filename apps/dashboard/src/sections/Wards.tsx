import { useState, type ReactNode } from 'react'
import type { Patient, Ward } from '@afia/core'
import type { FormularyEntry } from '@afia/rules'
import { fmtDateTime } from '../lib'
import { store } from '../store'
import { useManager } from '../session'
import { admitPatient, updatePatient, updateWardCommitment } from '../firebaseAdmin'

/**
 * Wards — the committed review time per ward with a named owner (the value the
 * Live breach panel measures against), patient admissions (the clinician app
 * has no admission UI by design), the formulary with sound-alike clusters, and
 * aggregate-only staff wellbeing (suppressed below five responses, §2.9).
 *
 * Patients are never deleted — discharge is a flag on the record.
 */

type PatientRow = Patient & { discharged?: boolean }

// ── review-time commitment (persisted) ─────────────────────────────────────

function CommitmentEditor({ ward }: { ward: Ward }): ReactNode {
  const manager = useManager()
  const [committed, setCommitted] = useState(String(ward.committedReviewMinutes))
  const [owner, setOwner] = useState(ward.reviewOwner)
  const [msg, setMsg] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const minutes = Number.parseInt(committed, 10)
  const dirty =
    (Number.isFinite(minutes) && minutes !== ward.committedReviewMinutes) ||
    owner.trim() !== ward.reviewOwner
  const valid = Number.isFinite(minutes) && minutes >= 1 && owner.trim() !== ''

  const save = async (): Promise<void> => {
    if (!valid) return
    setBusy(true)
    setMsg(null)
    try {
      await updateWardCommitment(ward.id, minutes, owner.trim(), manager.name, {
        committedReviewMinutes: ward.committedReviewMinutes,
        reviewOwner: ward.reviewOwner,
      })
      setMsg('Saved — the Live breach panel now measures against this value.')
    } catch (e) {
      setMsg(e instanceof Error ? `Save failed: ${e.message}` : 'Save failed.')
    }
    setBusy(false)
  }

  return (
    <>
      <div className="commit-row">
        <span>
          <span className="field-label">Committed review time (min)</span>
          <input
            className="input input-sm input-narrow input-mono"
            type="number"
            min={1}
            value={committed}
            onChange={(e) => setCommitted(e.target.value)}
          />
        </span>
        <span style={{ minWidth: 220 }}>
          <span className="field-label">Named owner</span>
          <input
            className="input input-sm"
            value={owner}
            onChange={(e) => setOwner(e.target.value)}
          />
        </span>
        <button
          className="btn btn-primary btn-sm"
          onClick={() => void save()}
          disabled={!dirty || !valid || busy}
        >
          {busy ? 'Saving…' : 'Save commitment'}
        </button>
      </div>
      {msg !== null && (
        <p className={msg.startsWith('Saved') ? 'form-ok' : 'form-error'} style={{ marginTop: 8 }}>
          {msg}
        </p>
      )}
    </>
  )
}

// ── patients (admit / edit / discharge — never delete) ─────────────────────

function PatientEditor({
  patient,
  onClose,
}: {
  patient: PatientRow
  onClose: () => void
}): ReactNode {
  const manager = useManager()
  const [name, setName] = useState(patient.name)
  const [dob, setDob] = useState(patient.dateOfBirth)
  const [bed, setBed] = useState(patient.bed)
  const [discharged, setDischarged] = useState(patient.discharged === true)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const save = async (): Promise<void> => {
    if (name.trim() === '' || bed.trim() === '') {
      setError('Name and bed are required.')
      return
    }
    setBusy(true)
    setError(null)
    try {
      await updatePatient(
        patient.id,
        { name: name.trim(), dateOfBirth: dob, bed: bed.trim(), discharged },
        manager.name,
        { name: patient.name, dateOfBirth: patient.dateOfBirth, bed: patient.bed, discharged: patient.discharged === true },
      )
      onClose()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Update failed.')
      setBusy(false)
    }
  }

  return (
    <tr>
      <td colSpan={5}>
        <div className="invite-form" style={{ marginTop: 0, maxWidth: 'none' }}>
          <div className="invite-grid">
            <span>
              <span className="field-label">Name</span>
              <input className="input input-sm" value={name} onChange={(e) => setName(e.target.value)} />
            </span>
            <span>
              <span className="field-label">Date of birth</span>
              <input
                className="input input-sm input-mono"
                type="date"
                value={dob}
                onChange={(e) => setDob(e.target.value)}
              />
            </span>
          </div>
          <div className="invite-grid">
            <span>
              <span className="field-label">Bed</span>
              <input className="input input-sm input-mono" value={bed} onChange={(e) => setBed(e.target.value)} />
            </span>
            <label className="field-required" style={{ alignSelf: 'end', paddingBottom: 6 }}>
              <input
                type="checkbox"
                checked={discharged}
                onChange={(e) => setDischarged(e.target.checked)}
              />
              discharged — record is kept; nothing is ever deleted
            </label>
          </div>
          {error !== null && <div className="form-error">{error}</div>}
          <div style={{ display: 'flex', gap: 10 }}>
            <button className="btn btn-primary btn-sm" onClick={() => void save()} disabled={busy}>
              {busy ? 'Saving…' : 'Save changes'}
            </button>
            <button className="btn btn-sm" onClick={onClose}>
              Cancel
            </button>
          </div>
        </div>
      </td>
    </tr>
  )
}

function AdmitForm({ wardId, onDone }: { wardId: string; onDone: () => void }): ReactNode {
  const manager = useManager()
  const [name, setName] = useState('')
  const [dob, setDob] = useState('')
  const [bed, setBed] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const submit = async (): Promise<void> => {
    if (name.trim() === '' || dob === '' || bed.trim() === '') {
      setError('Name, date of birth, and bed are all required.')
      return
    }
    setBusy(true)
    setError(null)
    try {
      await admitPatient(
        { name: name.trim(), dateOfBirth: dob, wardId, bed: bed.trim() },
        manager.name,
      )
      onDone()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not admit the patient.')
      setBusy(false)
    }
  }

  return (
    <div className="invite-form">
      <div className="invite-grid">
        <span>
          <span className="field-label">Name</span>
          <input
            className="input input-sm"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Full name"
          />
        </span>
        <span>
          <span className="field-label">Date of birth</span>
          <input
            className="input input-sm input-mono"
            type="date"
            value={dob}
            onChange={(e) => setDob(e.target.value)}
          />
        </span>
      </div>
      <div className="invite-grid">
        <span>
          <span className="field-label">Bed</span>
          <input
            className="input input-sm input-mono"
            value={bed}
            onChange={(e) => setBed(e.target.value)}
            placeholder="A13"
          />
        </span>
        <span />
      </div>
      {error !== null && <div className="form-error">{error}</div>}
      <div style={{ display: 'flex', gap: 10 }}>
        <button className="btn btn-primary btn-sm" onClick={() => void submit()} disabled={busy}>
          {busy ? 'Admitting…' : 'Admit patient'}
        </button>
      </div>
    </div>
  )
}

function WardPanel({ ward }: { ward: Ward }): ReactNode {
  const [admitting, setAdmitting] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [showDischarged, setShowDischarged] = useState(false)

  const allPatients = (store.patients() as readonly PatientRow[])
    .filter((p) => p.wardId === ward.id)
    .sort((a, b) => a.bed.localeCompare(b.bed, undefined, { numeric: true }))
  const active = allPatients.filter((p) => p.discharged !== true)
  const shown = showDischarged ? allPatients : active
  const wellbeing = store.wellbeing(ward.id)

  return (
    <section className="panel">
      <h2>{ward.name}</h2>
      <p className="panel-caption">
        The committed review time is the value the Live breach panel measures against.
      </p>

      <CommitmentEditor key={`${ward.committedReviewMinutes}·${ward.reviewOwner}`} ward={ward} />

      <h2 style={{ marginTop: 22 }}>
        Patients — <span className="num">{active.length}</span> in beds
      </h2>
      <p className="panel-caption">
        Admissions are made here — the clinician app deliberately has no admission
        UI. Records are never deleted; discharge keeps the record.
      </p>
      <div style={{ display: 'flex', gap: 10, marginBottom: 10 }}>
        <button className="btn btn-sm" onClick={() => setAdmitting((v) => !v)}>
          {admitting ? 'Close admission form' : 'Admit patient'}
        </button>
        <label className="field-required">
          <input
            type="checkbox"
            checked={showDischarged}
            onChange={(e) => setShowDischarged(e.target.checked)}
          />
          show discharged
        </label>
      </div>
      {admitting && <AdmitForm wardId={ward.id} onDone={() => setAdmitting(false)} />}
      {shown.length === 0 ? (
        <p className="empty-note">No patients on this ward.</p>
      ) : (
        <table className="data">
          <thead>
            <tr>
              <th>Bed</th>
              <th>Name</th>
              <th>Date of birth</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {shown.map((p) =>
              editingId === p.id ? (
                <PatientEditor key={p.id} patient={p} onClose={() => setEditingId(null)} />
              ) : (
                <tr key={p.id}>
                  <td className="num">{p.bed}</td>
                  <td>{p.name}</td>
                  <td className="num">{p.dateOfBirth}</td>
                  <td>
                    {p.discharged === true ? (
                      <span className="status-neutral">Discharged</span>
                    ) : (
                      <span className="status-neutral">In bed</span>
                    )}
                  </td>
                  <td>
                    <button className="btn btn-sm" onClick={() => setEditingId(p.id)}>
                      Edit
                    </button>
                  </td>
                </tr>
              ),
            )}
          </tbody>
        </table>
      )}

      <h2 style={{ marginTop: 22 }}>Staff wellbeing</h2>
      <p className="panel-caption">
        Aggregate and anonymous only — suppressed below five responses (§2.9).
      </p>
      {wellbeing.suppressed ? (
        <p className="wellbeing-suppressed">{wellbeing.reason}</p>
      ) : (
        <p style={{ margin: 0 }}>
          <span className="wellbeing-value">{wellbeing.mean}</span>{' '}
          <span className="cell-sub">
            mean of <span className="num">{wellbeing.count}</span> responses
          </span>
        </p>
      )}
    </section>
  )
}

// ── formulary (shared across wards) ────────────────────────────────────────

interface FormularyCluster {
  group: string | null
  entries: FormularyEntry[]
}

function clusterFormulary(formulary: readonly FormularyEntry[]): FormularyCluster[] {
  const clusters: FormularyCluster[] = []
  const seen = new Set<string>()
  for (const entry of formulary) {
    if (entry.soundAlikeGroup === null) {
      clusters.push({ group: null, entries: [entry] })
      continue
    }
    if (seen.has(entry.soundAlikeGroup)) continue
    seen.add(entry.soundAlikeGroup)
    clusters.push({
      group: entry.soundAlikeGroup,
      entries: formulary.filter((e) => e.soundAlikeGroup === entry.soundAlikeGroup),
    })
  }
  return clusters
}

function Formulary(): ReactNode {
  const [query, setQuery] = useState('')
  const q = query.trim().toLowerCase()
  const formulary = store.formulary()
  const matches = (e: FormularyEntry): boolean => q === '' || e.name.toLowerCase().includes(q)
  // A sound-alike cluster stays together whenever any member matches — the
  // pair is the safety feature, so it is never split by a search.
  const clusters = clusterFormulary(formulary).filter((c) => c.entries.some(matches))

  return (
    <section className="panel">
      <h2>Formulary</h2>
      <p className="panel-caption">
        Sound-alike pairs are grouped — they are always displayed together, in the
        clinician correction picker and here. A search never splits a pair.
      </p>
      <div style={{ maxWidth: 280, marginBottom: 8 }}>
        <input
          className="input input-sm"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search drug names"
          aria-label="Search formulary"
        />
      </div>
      {clusters.length === 0 ? (
        <p className="empty-note">No formulary entries match.</p>
      ) : (
        clusters.map((cluster) =>
          cluster.group === null ? (
            cluster.entries.map((e) => (
              <div className="drug-row solo" key={e.id}>
                <span className="mono">{e.name}</span>
              </div>
            ))
          ) : (
            <div className="formulary-cluster" key={cluster.group}>
              {cluster.entries.map((e, i) => (
                <div className="drug-row" key={e.id}>
                  <span className="mono">{e.name}</span>
                  {i === 0 && (
                    <span className="cluster-tag">sound-alike group · {cluster.group}</span>
                  )}
                </div>
              ))}
            </div>
          ),
        )
      )}
    </section>
  )
}

// ── section ────────────────────────────────────────────────────────────────

export function Wards(): ReactNode {
  const wards = store.wards()
  const latestTemplate = store.templateVersions()[store.templateVersions().length - 1]

  return (
    <>
      <h1 className="page-title">Wards</h1>
      <p className="page-caption">
        Per-ward configuration: the review-time commitment with its named owner,
        patient admissions, the drug formulary, and aggregate staff wellbeing.
      </p>

      <section className="panel">
        <h2>Overview</h2>
        <table className="data">
          <thead>
            <tr>
              <th>Ward</th>
              <th>Patients in beds</th>
              <th>Active template</th>
              <th>Committed review time</th>
              <th>Commitment owner</th>
            </tr>
          </thead>
          <tbody>
            {wards.map((w) => {
              const count = (store.patients() as readonly PatientRow[]).filter(
                (p) => p.wardId === w.id && p.discharged !== true,
              ).length
              return (
                <tr key={w.id}>
                  <td>{w.name}</td>
                  <td className="num">{count}</td>
                  <td>
                    {latestTemplate !== undefined ? (
                      <>
                        <span className="num">v{latestTemplate.version}</span> ·{' '}
                        <span className="num">{fmtDateTime(latestTemplate.at)}</span>
                      </>
                    ) : (
                      '—'
                    )}
                  </td>
                  <td className="num">{w.committedReviewMinutes} min</td>
                  <td>{w.reviewOwner}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </section>

      <div className="two-col">
        {wards.map((w) => (
          <WardPanel key={w.id} ward={w} />
        ))}
      </div>

      <div style={{ marginTop: 18 }}>
        <Formulary />
      </div>
    </>
  )
}
