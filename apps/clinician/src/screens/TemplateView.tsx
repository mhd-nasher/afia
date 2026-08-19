import type { ReactNode } from 'react'
import type { Go } from '../nav'
import { store } from '../store'
import { BackButton } from '../bits'

/**
 * Screen 13 — template, read-only. Reached from Account, role-gated to
 * charge_nurse / manager. Editing lives in the admin dashboard.
 */
export function TemplateView({ go }: { go: Go }): ReactNode {
  const template = store.template()

  return (
    <div className="screen">
      <BackButton go={go} to={{ name: 'account' }} label="Account" />

      <header className="patient-head">
        <h1>Handover template</h1>
        <p className="patient-head__meta">Edited in the admin dashboard (role-gated)</p>
      </header>

      <div className="card">
        <ul className="template-list">
          {template.map((f) => (
            <li key={f.id} className="template-list__row">
              <span className="template-list__label">{f.label}</span>
              <span
                className={
                  f.required
                    ? 'template-badge template-badge--required'
                    : 'template-badge'
                }
              >
                {f.required ? 'Required' : 'Optional'}
              </span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  )
}
