import type { ReactNode } from 'react'
import { store } from '../store'
import { roleLabel } from '../lib'

const DEMO_IDENTITIES = ['prac-amara', 'prac-jonas']

/**
 * §5 — no login screen exists in the clinician app (§11). This overlay stands
 * in for SSO: pick a demo identity, no password field anywhere.
 */
export function IdentityPicker({ onPick }: { onPick: (id: string) => void }): ReactNode {
  const choices = store
    .practitioners()
    .filter((p) => DEMO_IDENTITIES.includes(p.id))

  return (
    <div className="identity">
      <div className="identity__card">
        <h1 className="identity__title">Afia Clinician</h1>
        <p className="identity__sso">
          Demo identity · SSO in production; accounts are invitation-only
        </p>
        {choices.map((p) => (
          <button
            key={p.id}
            type="button"
            className="identity__choice"
            onClick={() => onPick(p.id)}
          >
            <span className="identity__name">{p.name}</span>
            <span className="identity__meta">
              {roleLabel(p.role)} · {p.signatureIdentity}
            </span>
          </button>
        ))}
        <p className="identity__note">Ward A tablet 1 — shared device</p>
      </div>
    </div>
  )
}
