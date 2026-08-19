import type { ReactNode } from 'react'

/**
 * Screen 11 — shift complete. Warm palette, appears once per shift.
 * Deliberately empty of numbers: no metrics, no streaks, no points (§11).
 */
export function ShiftComplete({ onClose }: { onClose: () => void }): ReactNode {
  return (
    <div className="shift-complete" role="dialog" aria-label="Shift complete">
      <h1>Shift handed over. Rest well.</h1>
      <p>Every patient&rsquo;s handover is confirmed in the receiving system.</p>
      <button type="button" className="shift-complete__close" onClick={onClose}>
        Close
      </button>
    </div>
  )
}
