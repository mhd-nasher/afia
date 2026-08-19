import type { ReactNode } from 'react'
import type { Practitioner } from '@afia/core'
import type { Go } from '../nav'
import { DEVICE, SHIFT_COMPLETE_KEY, STORE_KEY, store } from '../store'
import { clock, roleLabel } from '../lib'
import { LockIcon } from '../bits'

/**
 * Screen 12 — account. Sign out is PROMINENT and first: ward devices are
 * shared. Signature identity is read-only with the lock note (§2.5).
 * Template view (screen 13) is role-gated to charge_nurse / manager.
 */
export function AccountScreen({
  practitioner,
  go,
  onSignOut,
}: {
  practitioner: Practitioner
  go: Go
  onSignOut: () => void
}): ReactNode {
  const log = store
    .signInLog()
    .filter((e) => e.device === DEVICE)
    .slice()
    .sort((a, b) => b.at - a.at)

  const canSeeTemplate =
    practitioner.role === 'charge_nurse' || practitioner.role === 'manager'

  const resetDemo = (): void => {
    store.resetDemo()
    // Belt and braces: resetDemo leaves an empty-string sentinel the core
    // constructor cannot parse — drop the key and the once-only flag too.
    window.localStorage.removeItem(STORE_KEY)
    window.localStorage.removeItem(SHIFT_COMPLETE_KEY)
    window.location.reload()
  }

  return (
    <div className="screen">
      <button type="button" className="btn btn--signout" onClick={onSignOut}>
        Sign out — shared ward device
      </button>

      <section className="card">
        <h2>Signed in as</h2>
        <p className="account__name">{practitioner.name}</p>
        <p className="account__role">{roleLabel(practitioner.role)}</p>
        <div className="sig-identity">
          <LockIcon />
          <div>
            <div className="sig-identity__value">{practitioner.signatureIdentity}</div>
            <div className="sig-identity__note">Set at invitation — cannot be edited</div>
          </div>
        </div>
      </section>

      {canSeeTemplate && (
        <button
          type="button"
          className="btn btn--ghost"
          onClick={() => go({ name: 'template' })}
        >
          Handover template (read-only)
        </button>
      )}

      <section className="card">
        <h2>Sign-in log — {DEVICE}</h2>
        {log.length === 0 ? (
          <p className="empty">No sign-ins recorded on this device.</p>
        ) : (
          <ul className="signin-log">
            {log.map((e) => (
              <li key={e.id}>
                <span className="signin-log__who">
                  {store.practitioner(e.practitionerId)?.name ?? e.practitionerId}
                </span>
                <span className="signin-log__what">
                  {e.kind === 'sign_in' ? 'Signed in' : 'Signed out'} · {clock(e.at)}
                </span>
              </li>
            ))}
          </ul>
        )}
      </section>

      <button type="button" className="btn-reset" onClick={resetDemo}>
        Reset demo data
      </button>
    </div>
  )
}
