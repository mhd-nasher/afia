import { useState, type ReactNode } from 'react'
import type { ConfirmableChip, Practitioner } from '@afia/core'
import type { Go } from '../nav'
import { store } from '../store'
import { BackButton, MissingRecord } from '../bits'
import { CorrectionPicker } from './CorrectionPicker'
import { SignSheet } from './SignSheet'

function confidenceOf(chip: ConfirmableChip): 'high' | 'low' | 'none' | null {
  if (chip.kind !== 'drug') return null
  return chip.match?.confidence ?? 'none'
}

/**
 * Screen 4 + 5 — draft review with the confirmation layer. Unverified text is
 * periwinkle; after signing it renders indigo (F-034). Every drug and number
 * chip is confirmed INDIVIDUALLY (§2.3) — one store call per chip, and the
 * store API has no bulk variant. Omission flags are informational plain text,
 * never blocking, with no dismiss control (§2.4).
 */
export function DraftReview({
  handoverId,
  practitioner,
  go,
}: {
  handoverId: string
  practitioner: Practitioner
  go: Go
}): ReactNode {
  const [expandedChip, setExpandedChip] = useState<string | null>(null)
  const [pickerChip, setPickerChip] = useState<string | null>(null)
  const [showSign, setShowSign] = useState(false)

  const handover = store.handover(handoverId)
  if (handover === undefined) return <MissingRecord go={go} />

  const patient = store.patient(handover.patientId)
  const template = store.template()
  const signedLook = handover.signature !== null
  const confirmedCount = handover.chips.filter((c) => c.confirmedAt !== null).length
  const totalChips = handover.chips.length

  const confirmAsHeard = (chipId: string): void => {
    store.confirmChip(handoverId, chipId, practitioner.id)
    setExpandedChip(null)
  }

  return (
    <div className="screen screen--pad-bottom">
      <BackButton
        go={go}
        to={{ name: 'patient', patientId: handover.patientId }}
        label={patient?.name ?? 'Patient'}
      />

      <header className="patient-head">
        <h1>Draft handover</h1>
        <p className="patient-head__meta">
          {patient?.name ?? 'Patient'} · bed {patient?.bed ?? '—'} · v{handover.version}
        </p>
      </header>

      <section className="card">
        <h2>Structured note</h2>
        {template.map((field) => {
          const text = handover.fields.find((f) => f.fieldId === field.id)?.text.trim() ?? ''
          if (text === '') return null
          return (
            <div className="field" key={field.id}>
              <div className="field__label">{field.label}</div>
              <div className={signedLook ? 'field__text field__text--signed' : 'field__text field__text--unverified'}>
                {text}
              </div>
            </div>
          )
        })}
        {handover.fields.every((f) => f.text.trim() === '') && (
          <p className="empty">Nothing structured yet — the transcript was empty.</p>
        )}
      </section>

      <section className="card">
        <h2>Verify each drug &amp; dose</h2>
        {totalChips === 0 ? (
          <p className="empty">No drug names or numeric values detected.</p>
        ) : (
          <>
            <p className="chip-progress">
              {confirmedCount} of {totalChips} confirmed
            </p>
            {handover.chips.map((chip) => {
              const conf = confidenceOf(chip)
              const done = chip.confirmedAt !== null
              const expanded = expandedChip === chip.id
              const cls = done
                ? 'chip chip--confirmed'
                : conf === 'low'
                  ? 'chip chip--low'
                  : conf === 'none'
                    ? 'chip chip--none'
                    : 'chip chip--high'
              return (
                <div key={chip.id}>
                  <button
                    type="button"
                    className={cls}
                    onClick={() => setExpandedChip(expanded ? null : chip.id)}
                  >
                    <span className="chip__text">{chip.text}</span>
                    <span className="chip__kind">{chip.kind}</span>
                    <span className="chip__badge">
                      {done
                        ? chip.correctedTo !== null
                          ? `corrected to ${chip.correctedTo}`
                          : 'confirmed'
                        : conf === 'low'
                          ? 'check this'
                          : conf === 'none'
                            ? 'no formulary match'
                            : conf === 'high'
                              ? 'formulary match'
                              : 'confirm'}
                    </span>
                  </button>
                  {expanded && !done && (
                    <div className="chip-actions">
                      {chip.kind === 'number' ? (
                        <button
                          type="button"
                          className="btn btn--primary"
                          onClick={() => confirmAsHeard(chip.id)}
                        >
                          Confirm
                        </button>
                      ) : (
                        <>
                          <button
                            type="button"
                            className="btn btn--primary"
                            onClick={() => confirmAsHeard(chip.id)}
                          >
                            Confirm as heard
                          </button>
                          <button
                            type="button"
                            className="btn btn--ghost"
                            onClick={() => {
                              setPickerChip(chip.id)
                              setExpandedChip(null)
                            }}
                          >
                            Pick correct drug
                          </button>
                        </>
                      )}
                    </div>
                  )}
                </div>
              )
            })}
          </>
        )}
      </section>

      {handover.flags.length > 0 && (
        <section className="card">
          <h2>Omissions — informational, never blocking</h2>
          {/* §2.4 — plain text only. Never blocks signing, no dismiss control. */}
          <ul className="flag-list">
            {handover.flags.map((f) => (
              <li key={f.id}>{f.message}</li>
            ))}
          </ul>
        </section>
      )}

      {!signedLook && (
        <>
          <p className="chip-progress chip-progress--footer">
            {confirmedCount} of {totalChips} confirmed
          </p>
          <button type="button" className="btn btn--primary" onClick={() => setShowSign(true)}>
            Sign &amp; send
          </button>
        </>
      )}
      {signedLook && (
        <button type="button" className="btn btn--ghost" onClick={() => setShowSign(true)}>
          View signature &amp; export status
        </button>
      )}

      {pickerChip !== null && (
        <CorrectionPicker
          handoverId={handoverId}
          chipId={pickerChip}
          practitioner={practitioner}
          onClose={() => setPickerChip(null)}
        />
      )}

      {showSign && (
        <SignSheet
          handoverId={handoverId}
          practitioner={practitioner}
          onClose={() => setShowSign(false)}
          onDone={() => {
            setShowSign(false)
            go({ name: 'ward' })
          }}
        />
      )}
    </div>
  )
}
