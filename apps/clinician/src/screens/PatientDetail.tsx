import type { ReactNode } from 'react'
import type { Practitioner } from '@afia/core'
import { diffHandovers, tenSecondSummary } from '@afia/ai'
import type { Go } from '../nav'
import { inProgressFor, signedFor, store } from '../store'
import { ageFrom, clock, timeAgo, vitalRows } from '../lib'
import { BackButton, MissingRecord } from '../bits'

const DIFF_KIND_LABEL: Record<string, string> = {
  added: 'Added',
  changed: 'Changed',
  'now-empty': 'No longer mentioned',
}

/**
 * Screen 2 — patient detail: info, latest vitals in tabular mono, previous
 * handover summary + what changed, and the big Record button.
 */
export function PatientDetail({
  patientId,
  practitioner,
  go,
}: {
  patientId: string
  practitioner: Practitioner
  go: Go
}): ReactNode {
  const patient = store.patient(patientId)
  if (patient === undefined) return <MissingRecord go={go} />

  const template = store.template()
  const ward = store.ward(patient.wardId)

  // Latest vitals text from the newest handover (any author) that carries one.
  const withVitals = store
    .handovers()
    .filter(
      (h) =>
        h.patientId === patientId &&
        h.fields.some((f) => f.fieldId === 'vitals' && f.text.trim() !== ''),
    )
    .sort((a, b) => b.createdAt - a.createdAt)[0]
  const vitalsText = withVitals?.fields.find((f) => f.fieldId === 'vitals')?.text ?? null

  const signed = signedFor(patientId)
  const latestSigned = signed[0]
  const priorSigned = signed[1]
  const diff =
    latestSigned !== undefined && priorSigned !== undefined
      ? diffHandovers(priorSigned.fields, latestSigned.fields, template).filter(
          (d) => d.kind !== 'unchanged',
        )
      : []

  const inProgress = inProgressFor(practitioner.id, patientId)

  const onRecord = (): void => {
    if (inProgress !== undefined) {
      go(
        inProgress.status === 'recording'
          ? { name: 'recording', handoverId: inProgress.id }
          : { name: 'draft', handoverId: inProgress.id },
      )
      return
    }
    const h = store.createHandover(patientId, practitioner.id)
    go({ name: 'recording', handoverId: h.id })
  }

  return (
    <div className="screen">
      <BackButton go={go} to={{ name: 'ward' }} label="Ward list" />

      <header className="patient-head">
        <h1>
          {patient.name} <span className="patient-head__age">{ageFrom(patient.dateOfBirth)}</span>
        </h1>
        <p className="patient-head__meta">
          Bed {patient.bed} · DOB {patient.dateOfBirth} · {ward?.name ?? 'Ward'}
        </p>
      </header>

      <section className="card">
        <h2>Latest vitals</h2>
        {vitalsText !== null ? (
          <>
            <table className="vitals">
              <tbody>
                {vitalRows(vitalsText).map((row, i) => (
                  <tr key={i}>
                    <td>{row.label}</td>
                    <td>{row.value}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {withVitals !== undefined && (
              <p className="card__foot">From handover {timeAgo(withVitals.createdAt)}</p>
            )}
          </>
        ) : (
          <p className="empty">No vitals recorded yet.</p>
        )}
      </section>

      {latestSigned !== undefined && (
        <section className="card card--summary">
          <h2>Previous handover — 10-second summary</h2>
          <p className="summary-text">{tenSecondSummary(latestSigned.fields, template)}</p>
          <p className="card__foot">
            {store.practitioner(latestSigned.authorId)?.name ?? latestSigned.authorId} ·{' '}
            {clock(latestSigned.signature?.signedAt ?? latestSigned.createdAt)}
          </p>
        </section>
      )}

      {diff.length > 0 && (
        <section className="card">
          <h2>What changed since the one before</h2>
          <ul className="diff-list">
            {diff.map((d) => (
              <li key={d.fieldId}>
                <span className={`diff-kind diff-kind--${d.kind}`}>
                  {DIFF_KIND_LABEL[d.kind] ?? d.kind}
                </span>{' '}
                <strong>{d.label}:</strong> {d.text === '' ? '—' : d.text}
              </li>
            ))}
          </ul>
        </section>
      )}

      <button type="button" className="btn btn--record" onClick={onRecord}>
        {inProgress !== undefined
          ? inProgress.status === 'recording'
            ? 'Resume recording'
            : 'Resume draft'
          : 'Record handover'}
      </button>
    </div>
  )
}
