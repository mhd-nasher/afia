/**
 * Entry — what this is, in plain words. Two SEPARATE toggles (HANDOFF §3.3):
 * terms acceptance and sharing consent are different records. The small
 * "Reset demo" link lives only here, in the footer.
 */
export function Entry({
  name,
  terms,
  consent,
  onName,
  onTerms,
  onConsent,
  onContinue,
  onReset,
}: {
  name: string
  terms: boolean
  consent: boolean
  onName: (v: string) => void
  onTerms: (v: boolean) => void
  onConsent: (v: boolean) => void
  onContinue: () => void
  onReset: () => void
}) {
  const ready = terms && consent
  return (
    <div className="stack">
      <h1>Tell the nursing team how you are</h1>
      <p>
        You answer a few questions and describe how you feel, in your own words. What you
        send goes to the nursing team for a nurse to read.
      </p>
      <p>It takes a few minutes. You can stop at any point — nothing you enter is lost.</p>

      <div>
        <label className="field-label" htmlFor="entry-name">
          Your first name (first name is enough)
        </label>
        <input
          id="entry-name"
          type="text"
          value={name}
          autoComplete="given-name"
          onChange={(e) => onName(e.target.value)}
        />
      </div>

      <Toggle checked={terms} onChange={onTerms} label="I agree to the terms of this demo" />
      <Toggle
        checked={consent}
        onChange={onConsent}
        label="I agree that my answers are shared with the nursing team"
      />

      <button type="button" className="btn-primary" disabled={!ready} onClick={onContinue}>
        Continue
      </button>
      {!ready ? <p className="hint">To continue, please agree to both statements above.</p> : null}

      <footer className="entry-footer">
        <button type="button" className="reset-link" onClick={onReset}>
          Reset demo
        </button>
      </footer>
    </div>
  )
}

function Toggle({
  checked,
  onChange,
  label,
}: {
  checked: boolean
  onChange: (v: boolean) => void
  label: string
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      className="toggle-row"
      onClick={() => onChange(!checked)}
    >
      <span className="toggle-box" aria-hidden="true">
        {checked ? '✓' : ''}
      </span>
      <span>{label}</span>
    </button>
  )
}
