import type { PatientCase } from '@afia/core'
import { shortRef } from '../episode'

/**
 * Status — the persistent safety surface (HANDOFF §6). Sync copy is HONEST:
 * a queued update says plainly that the nursing team has NOT seen it, and
 * nothing here ever implies a nurse is watching. The mandatory copy (F-058)
 * renders prominently and verbatim.
 */

function formatTime(at: number): string {
  return new Date(at).toLocaleString(undefined, {
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  })
}

export function StatusScreen({ patientCase }: { patientCase: PatientCase }) {
  return (
    <div className="stack">
      <h1>What you have sent</h1>
      <p className="case-ref">
        Your case reference: <strong>{shortRef(patientCase.id)}</strong>
      </p>

      {patientCase.updates.map((u) => (
        <div className="update-row" key={u.id}>
          <div className="update-kind">
            {u.kind === 'initial' ? 'Your answers and description' : 'Condition update'}
          </div>
          <div className="update-time">{formatTime(u.at)}</div>
          <div className={u.syncState === 'sent' ? 'sync sync--sent' : 'sync sync--queued'}>
            {u.syncState === 'sent'
              ? 'Sent to the nursing team'
              : "Saved on this phone. NOT yet sent — it will send when you're back online. The nursing team has NOT seen it."}
          </div>
        </div>
      ))}

      <div className="mandatory" role="note">
        No one is watching your condition continuously. If things get worse, use the button
        below, call the nurse line, or call emergency services.
      </div>

      <p>
        If anything changes, tap “My condition has changed” below. Your update joins this
        same case — you never start again.
      </p>
    </div>
  )
}
