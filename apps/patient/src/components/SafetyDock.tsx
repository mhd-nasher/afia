import { createPortal } from 'react-dom'
import { EMERGENCY_NUMBERS } from '@afia/rules'

/**
 * The safety dock (HANDOFF §2.7 / F-051). Rendered via a portal to
 * document.body — OUTSIDE the step view hierarchy — position:fixed at the
 * bottom with a z-index above every step, overlay, and loading state, so no
 * keyboard or interrupt can occlude it. It exists on EVERY screen, including
 * the emergency interrupt itself. Numbers are bundled constants (§2.7) —
 * nothing here touches the network.
 */
export function SafetyDock({
  showConditionChanged,
  onConditionChanged,
}: {
  showConditionChanged: boolean
  onConditionChanged: () => void
}) {
  return createPortal(
    <div className="dock" role="region" aria-label="Emergency help — always available">
      <a className="dock-999" href={`tel:${EMERGENCY_NUMBERS.emergency}`}>
        <span aria-hidden="true">🚨</span> Emergency — call {EMERGENCY_NUMBERS.emergency}
      </a>
      <div className="dock-row">
        <a className="dock-111" href={`tel:${EMERGENCY_NUMBERS.urgentAdvice}`}>
          Urgent advice — call {EMERGENCY_NUMBERS.urgentAdvice}
        </a>
        {showConditionChanged ? (
          <button type="button" className="dock-changed" onClick={onConditionChanged}>
            My condition has changed
          </button>
        ) : null}
      </div>
    </div>,
    document.body,
  )
}
