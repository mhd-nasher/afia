import { useEffect, useState, type ReactNode } from 'react'
import type { Practitioner } from '@afia/core'
import { StatusPill } from '@afia/ui'
import type { Go } from '../nav'
import { newestHandoverFor, store, SHIFT_COMPLETE_KEY } from '../store'
import { clock } from '../lib'
import { ShiftComplete } from './ShiftComplete'

const ACK_DELAY_MS = 1500

/**
 * Screen 10 — shift board: signature + export state for all 12 patients.
 * `signed` and `confirmed_in_system` are distinct pills (F-032) — a nurse must
 * see whether the hospital system actually received it. Export failures get a
 * retry. When all 12 are confirmed_in_system, the shift-complete screen shows
 * once (F-039). No metrics, no streaks (§11).
 */
export function ShiftBoard({
  practitioner,
  go: _go,
}: {
  practitioner: Practitioner
  go: Go
}): ReactNode {
  const [retrying, setRetrying] = useState<ReadonlySet<string>>(new Set())
  const [celebrate, setCelebrate] = useState(false)

  const patients = store.patients()
  const rows = patients.map((p) => ({ patient: p, handover: newestHandoverFor(p.id) }))
  const allConfirmed =
    rows.length === 12 && rows.every((r) => r.handover?.status === 'confirmed_in_system')

  useEffect(() => {
    if (allConfirmed && window.localStorage.getItem(SHIFT_COMPLETE_KEY) === null) {
      window.localStorage.setItem(SHIFT_COMPLETE_KEY, String(Date.now()))
      setCelebrate(true)
    }
  }, [allConfirmed])

  const retry = (handoverId: string): void => {
    store.retryExport(handoverId, practitioner.id)
    setRetrying((prev) => new Set(prev).add(handoverId))
    window.setTimeout(() => {
      store.acknowledgeExport(handoverId, { ok: true })
      setRetrying((prev) => {
        const next = new Set(prev)
        next.delete(handoverId)
        return next
      })
    }, ACK_DELAY_MS)
  }

  return (
    <div className="screen">
      <header className="patient-head">
        <h1>Shift board</h1>
        <p className="patient-head__meta">
          Signature and export state for every patient. Signed is not the same as confirmed in
          system.
        </p>
      </header>

      <div className="list">
        {rows.map(({ patient, handover }) => (
          <div key={patient.id} className="board__row">
            <div className="board__main">
              <span className="board__bed">{patient.bed}</span>
              <span className="board__name">{patient.name}</span>
              <StatusPill status={handover?.status ?? 'not_started'} />
            </div>
            {handover?.signature != null && (
              <p className="board__sub">
                Signed · {handover.signature.signatureIdentity} ·{' '}
                {clock(handover.signature.signedAt)}
                {handover.status === 'confirmed_in_system' && handover.acknowledgedAt !== null
                  ? ` · confirmed ${clock(handover.acknowledgedAt)}`
                  : ''}
              </p>
            )}
            {handover?.status === 'export_failed' && (
              <div className="board__failed">
                <p className="board__error">{handover.exportError ?? 'Export failed.'}</p>
                <button
                  type="button"
                  className="btn btn--ghost btn--retry"
                  onClick={() => retry(handover.id)}
                  disabled={retrying.has(handover.id)}
                >
                  {retrying.has(handover.id) ? 'Retrying…' : 'Retry export'}
                </button>
              </div>
            )}
            {handover?.status === 'queued' && retrying.has(handover.id) && (
              <p className="board__sub">Waiting for acknowledgement…</p>
            )}
          </div>
        ))}
      </div>

      {celebrate && <ShiftComplete onClose={() => setCelebrate(false)} />}
    </div>
  )
}
