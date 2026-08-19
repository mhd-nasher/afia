/**
 * Confirmation after a "my condition has changed" update (F-056). The copy is
 * EXPLICIT that the update joined the existing case — same case id, never a
 * new case, never a reset.
 */
export function UpdateConfirmScreen({
  refCode,
  onDone,
}: {
  refCode: string
  onDone: () => void
}) {
  return (
    <div className="stack">
      <h1>Update added</h1>
      <p className="confirm-copy">
        Your update was added to your existing case. You have not lost your place, and you
        do not need to start again.
      </p>
      <p>
        Your case reference is still <strong>{refCode}</strong>.
      </p>
      <button type="button" className="btn-primary" onClick={onDone}>
        Back to your case
      </button>
    </div>
  )
}
