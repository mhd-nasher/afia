import { useState, type ReactNode } from 'react'
import {
  MissingFlagReasonError,
  UnconfirmedChipsError,
  type Practitioner,
} from '@afia/core'
import { HoldButton } from '@afia/ui'
import { store } from '../store'
import { clock } from '../lib'
import { LockIcon } from '../bits'

/** One-tap reasons for signing with open omission flags (§2.4 — never blocking). */
const OPEN_FLAG_REASONS = [
  'End of shift — passed to next team',
  'Information is with the day team',
  'Patient asleep — will complete later',
] as const

const ACK_DELAY_MS = 1500
/** The demo's designed failure path: pat-6 never gets a positive acknowledgement. */
const FAILING_PATIENT_ID = 'pat-6'

/**
 * Screen 7 — sign sheet. Hold-to-sign; disabled ONLY while unconfirmed chips
 * exist. Open flags never block — they take a one-tap recorded reason.
 * Export fires automatically on signature (F-036); confirmed_in_system is
 * reached only on positive acknowledgement, simulated after ~1.5 s.
 */
export function SignSheet({
  handoverId,
  practitioner,
  onClose,
  onDone,
}: {
  handoverId: string
  practitioner: Practitioner
  onClose: () => void
  onDone: () => void
}): ReactNode {
  const [reason, setReason] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const handover = store.handover(handoverId)
  if (handover === undefined) return null

  const unconfirmed = handover.chips.filter((c) => c.confirmedAt === null)
  const openFlags = handover.flags.filter((f) => f.state === 'open')
  const signed = handover.signature !== null

  const doSign = (): void => {
    try {
      const queued = store.signHandover(
        handoverId,
        practitioner.id,
        reason !== null ? { openFlagReason: reason } : {},
      )
      setError(null)
      // Export fired automatically on signature. Simulated receiving system
      // acknowledges after ~1.5 s — positively, except for the failure demo.
      window.setTimeout(() => {
        store.acknowledgeExport(
          handoverId,
          queued.patientId === FAILING_PATIENT_ID
            ? { ok: false, error: 'Receiving system did not acknowledge (demo)' }
            : { ok: true },
        )
      }, ACK_DELAY_MS)
    } catch (e) {
      if (e instanceof UnconfirmedChipsError || e instanceof MissingFlagReasonError) {
        setError(e.message)
      } else if (e instanceof Error) {
        setError(e.message)
      } else {
        throw e
      }
    }
  }

  return (
    <div className="sheet-backdrop" role="dialog" aria-label="Sign handover">
      <div className="sheet">
        <div className="sheet__grab" />
        <h1 className="sheet__title">{signed ? 'Signed' : 'Sign this handover'}</h1>

        <div className="sig-identity">
          <LockIcon />
          <div>
            <div className="sig-identity__value">{practitioner.signatureIdentity}</div>
            <div className="sig-identity__note">Signature identity — set at invitation, read-only</div>
          </div>
        </div>

        {!signed && openFlags.length > 0 && (
          <section className="sheet__section">
            <h2>Open omission flags — signing proceeds with a recorded reason</h2>
            <ul className="flag-list">
              {openFlags.map((f) => (
                <li key={f.id}>{f.message}</li>
              ))}
            </ul>
            <div className="reason-chips">
              {OPEN_FLAG_REASONS.map((r) => (
                <button
                  key={r}
                  type="button"
                  className={reason === r ? 'reason-chip reason-chip--on' : 'reason-chip'}
                  onClick={() => setReason(r)}
                >
                  {r}
                </button>
              ))}
            </div>
          </section>
        )}

        {!signed && (
          <>
            {unconfirmed.length > 0 && (
              <p className="sheet__why">
                {unconfirmed.length} chip{unconfirmed.length === 1 ? '' : 's'} unconfirmed
              </p>
            )}
            {error !== null && <p className="sheet__error">{error}</p>}
            <HoldButton
              label="Hold to sign"
              onComplete={doSign}
              disabled={unconfirmed.length > 0}
            />
          </>
        )}

        {signed && handover.signature !== null && (
          <section className="sheet__section">
            <p className="sig-done">
              Signed as {handover.signature.signatureIdentity} at {clock(handover.signature.signedAt)}
            </p>
            {handover.signature.openFlagReason !== null && (
              <p className="sig-reason">Open-flag reason: {handover.signature.openFlagReason}</p>
            )}
            {handover.status === 'queued' && (
              <p className="export-state export-state--queued">Export queued…</p>
            )}
            {handover.status === 'confirmed_in_system' && (
              <p className="export-state export-state--ok">
                Confirmed in system
                {handover.acknowledgedAt !== null ? ` · ${clock(handover.acknowledgedAt)}` : ''}
              </p>
            )}
            {handover.status === 'export_failed' && (
              <div className="export-state export-state--failed">
                <p>{handover.exportError ?? 'Export failed.'}</p>
                <p>Retry from the Shift board.</p>
              </div>
            )}
            <button type="button" className="btn btn--primary" onClick={onDone}>
              Done
            </button>
          </section>
        )}

        {!signed && (
          <button type="button" className="btn btn--ghost sheet__close" onClick={onClose}>
            Back to draft
          </button>
        )}
      </div>
    </div>
  )
}
