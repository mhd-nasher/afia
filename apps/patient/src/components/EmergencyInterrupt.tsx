import { EMERGENCY_NUMBERS } from '@afia/rules'

/**
 * Full-screen emergency interrupt (HANDOFF §6 / F-052). Shown the moment a
 * red-flag answer is YES — evaluated locally, offline, instantly (§2.7).
 * Calm but unmissable. Going back un-does nothing: the answer stays recorded,
 * and once a case exists its priority stays escalated — there is no
 * downgrade path anywhere in this system.
 */
export function EmergencyInterrupt({ onBack }: { onBack: () => void }) {
  return (
    <div
      className="interrupt"
      role="alertdialog"
      aria-label={`Emergency — call ${EMERGENCY_NUMBERS.emergency} now`}
    >
      <header className="interrupt-header">
        <h1>Call {EMERGENCY_NUMBERS.emergency} now</h1>
      </header>
      <div className="interrupt-body">
        <p className="interrupt-lead">
          Based on your answer, call {EMERGENCY_NUMBERS.emergency} now or ask someone near
          you to call.
        </p>
        <a className="interrupt-999" href={`tel:${EMERGENCY_NUMBERS.emergency}`}>
          Call {EMERGENCY_NUMBERS.emergency}
        </a>
        <a className="interrupt-111" href={`tel:${EMERGENCY_NUMBERS.urgentAdvice}`}>
          If you cannot call {EMERGENCY_NUMBERS.emergency}, call {EMERGENCY_NUMBERS.urgentAdvice}
        </a>
        <p className="interrupt-note">
          If you tapped Yes by mistake you can go back — your answer stays recorded.
        </p>
        <button type="button" className="btn-ghost" onClick={onBack}>
          Go back
        </button>
      </div>
    </div>
  )
}
