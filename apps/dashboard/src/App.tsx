import { useState, type ReactNode } from 'react'
import { useStoreSnapshot } from './store'
import { useManager, useSession, SessionProvider } from './session'
import { signOutManager } from './firebaseAdmin'
import { AuthScreen } from './AuthScreen'
import { Live } from './sections/Live'
import { Templates } from './sections/Templates'
import { Questions } from './sections/Questions'
import { Users } from './sections/Users'
import { Wards } from './sections/Wards'
import { Quality } from './sections/Quality'

/**
 * Admin dashboard — desktop web. Six sections switched by a state enum.
 * Every section sits behind the manager auth gate. The dashboard observes and
 * configures; it is never in the clinical path between a patient file and the
 * nursing team.
 */

const SECTIONS = [
  { id: 'live', label: 'Live' },
  { id: 'templates', label: 'Templates' },
  { id: 'questions', label: 'Questions' },
  { id: 'users', label: 'Users' },
  { id: 'wards', label: 'Wards' },
  { id: 'quality', label: 'Quality' },
] as const

type SectionId = (typeof SECTIONS)[number]['id']

function Shell(): ReactNode {
  useStoreSnapshot() // subscribe the whole tree to store commits
  const manager = useManager()
  const [section, setSection] = useState<SectionId>('live')

  return (
    <>
      <aside className="sidebar">
        <div className="brand">
          <span className="brand-word">Afia</span>
          <span className="brand-product">Admin dashboard</span>
        </div>

        <nav className="nav" aria-label="Dashboard sections">
          {SECTIONS.map((s) => (
            <button
              key={s.id}
              className={section === s.id ? 'nav-item active' : 'nav-item'}
              onClick={() => setSection(s.id)}
              aria-current={section === s.id ? 'page' : undefined}
            >
              {s.label}
            </button>
          ))}
        </nav>

        <div className="sidebar-foot">
          <div>
            <div className="identity-name">{manager.name}</div>
            <div className="identity-role">Manager · signed in</div>
            <div className="identity-email">{manager.email}</div>
          </div>
          <button className="signout-btn" onClick={() => void signOutManager()}>
            Sign out
          </button>
        </div>
      </aside>

      <main className="content">
        {section === 'live' && <Live />}
        {section === 'templates' && <Templates />}
        {section === 'questions' && <Questions />}
        {section === 'users' && <Users />}
        {section === 'wards' && <Wards />}
        {section === 'quality' && <Quality />}

        <footer className="foot-note">
          This dashboard is not in the clinical path — patient files go directly to
          the nursing team.
        </footer>
      </main>
    </>
  )
}

function Gate(): ReactNode {
  const session = useSession()
  if (session.status === 'loading') {
    return <div className="auth-loading">Checking session…</div>
  }
  if (session.status === 'signed_out') {
    return <AuthScreen />
  }
  return <Shell />
}

export function App(): ReactNode {
  return (
    <SessionProvider>
      <Gate />
    </SessionProvider>
  )
}
