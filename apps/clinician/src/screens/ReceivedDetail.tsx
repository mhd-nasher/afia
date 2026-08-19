import { useState, type ReactNode } from 'react'
import type { Handover, Patient, Practitioner } from '@afia/core'
import { diffHandovers, tenSecondSummary } from '@afia/ai'
import { ClipboardExporter, FhirExporter, Hl7v2Exporter } from '@afia/export'
import { StatusPill } from '@afia/ui'
import type { Go } from '../nav'
import { earlierSignedFor, store } from '../store'
import { clock } from '../lib'
import { BackButton, MissingRecord } from '../bits'

const DIFF_KIND_LABEL: Record<string, string> = {
  added: 'Added',
  changed: 'Changed',
  'now-empty': 'No longer mentioned',
}

const clipboardExporter = new ClipboardExporter()
const fhirExporter = new FhirExporter()
const hl7v2Exporter = new Hl7v2Exporter()

type ExportTab = 'clipboard' | 'fhir' | 'hl7v2'

function ExportPreview({ handover, patient }: { handover: Handover; patient: Patient }): ReactNode {
  const [tab, setTab] = useState<ExportTab>('clipboard')
  const [copied, setCopied] = useState(false)

  const exporter =
    tab === 'clipboard' ? clipboardExporter : tab === 'fhir' ? fhirExporter : hl7v2Exporter
  const result = exporter.export({ handover, patient })

  const copy = (): void => {
    if (result.payload === null) return
    void navigator.clipboard.writeText(result.payload).then(() => {
      setCopied(true)
      window.setTimeout(() => setCopied(false), 1500)
    })
  }

  return (
    <section className="card">
      <h2>Export preview</h2>
      <div className="export-tabs">
        {(['clipboard', 'fhir', 'hl7v2'] as const).map((t) => (
          <button
            key={t}
            type="button"
            className={tab === t ? 'export-tab export-tab--on' : 'export-tab'}
            onClick={() => setTab(t)}
          >
            {t === 'clipboard' ? 'Clipboard' : t === 'fhir' ? 'FHIR' : 'HL7v2'}
          </button>
        ))}
      </div>

      {tab === 'fhir' && (
        <p className="export-note">FHIR-ready — generated locally, sent nowhere</p>
      )}

      {result.payload !== null ? (
        <pre className="export-pre">{result.payload}</pre>
      ) : (
        <p className="export-stub">{result.error ?? 'Nothing to show.'}</p>
      )}

      {tab === 'clipboard' && result.payload !== null && (
        <button type="button" className="btn btn--ghost" onClick={copy}>
          {copied ? 'Copied' : 'Copy'}
        </button>
      )}
    </section>
  )
}

/**
 * Screen 9 — received handover. Summary card, playable original audio (§2.6),
 * flags INLINE near the top (never behind an expand, F-037), all fields,
 * diff vs the patient's earlier handover, visible chip corrections, and the
 * export preview. No manual export button exists anywhere (§11).
 */
export function ReceivedDetail({
  handoverId,
  practitioner: _practitioner,
  go,
}: {
  handoverId: string
  practitioner: Practitioner
  go: Go
}): ReactNode {
  const handover = store.handover(handoverId)
  if (handover === undefined) return <MissingRecord go={go} />
  const patient = store.patient(handover.patientId)
  if (patient === undefined) return <MissingRecord go={go} />

  const template = store.template()
  const author = store.practitioner(handover.authorId)
  const earlier = earlierSignedFor(handover.patientId, handover.createdAt)
  const diff =
    earlier !== undefined
      ? diffHandovers(earlier.fields, handover.fields, template).filter(
          (d) => d.kind !== 'unchanged',
        )
      : []
  const corrections = handover.chips.filter((c) => c.correctedTo !== null)

  return (
    <div className="screen">
      <BackButton go={go} to={{ name: 'received' }} label="Received" />

      <header className="patient-head">
        <h1>{patient.name}</h1>
        <p className="patient-head__meta">
          Bed {patient.bed} · from {author?.name ?? handover.authorId} ·{' '}
          {handover.signature !== null
            ? `signed ${clock(handover.signature.signedAt)} as ${handover.signature.signatureIdentity}`
            : 'unsigned'}
        </p>
        <StatusPill status={handover.status} />
      </header>

      <section className="card card--summary">
        <h2>10-second summary</h2>
        <p className="summary-text">{tenSecondSummary(handover.fields, template)}</p>
      </section>

      <section className="card">
        <h2>Original recording</h2>
        {handover.audio !== null ? (
          <audio controls src={handover.audio.url} className="received-audio" />
        ) : (
          <p className="empty">No audio attached (typed handover).</p>
        )}
      </section>

      {handover.flags.length > 0 && (
        <section className="card card--flags">
          {/* Flags inline near the top — never behind an expand (F-037). */}
          <h2>Documented omissions</h2>
          <ul className="flag-list">
            {handover.flags.map((f) => (
              <li key={f.id}>
                {f.message}
                {f.signingNote !== null && (
                  <span className="flag-note"> — note: {f.signingNote}</span>
                )}
              </li>
            ))}
          </ul>
        </section>
      )}

      {diff.length > 0 && (
        <section className="card">
          <h2>What changed since the previous handover</h2>
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

      <section className="card">
        <h2>All fields</h2>
        {template.map((field) => {
          const text = handover.fields.find((f) => f.fieldId === field.id)?.text.trim() ?? ''
          return (
            <div className="field" key={field.id}>
              <div className="field__label">{field.label}</div>
              <div className={text === '' ? 'field__text field__text--blank' : 'field__text field__text--signed'}>
                {text === '' ? '—' : text}
              </div>
            </div>
          )
        })}
      </section>

      <section className="card">
        <h2>Verified chips</h2>
        {handover.chips.length === 0 ? (
          <p className="empty">No drug or number chips in this handover.</p>
        ) : (
          <ul className="chip-summary">
            {handover.chips.map((c) => (
              <li key={c.id}>
                <strong>{c.text}</strong> ({c.kind})
                {c.correctedTo !== null ? (
                  <span className="chip-summary__corrected"> — corrected to {c.correctedTo}</span>
                ) : c.confirmedAt !== null ? (
                  <span className="chip-summary__ok"> — confirmed as heard</span>
                ) : (
                  <span> — unconfirmed</span>
                )}
              </li>
            ))}
          </ul>
        )}
        {corrections.length > 0 && (
          <p className="card__foot">
            {corrections.length} correction{corrections.length === 1 ? '' : 's'} made via the
            formulary picker.
          </p>
        )}
      </section>

      <ExportPreview handover={handover} patient={patient} />
    </div>
  )
}
