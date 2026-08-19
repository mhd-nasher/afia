import { useState, type ReactNode } from 'react'
import type { Practitioner } from '@afia/core'
import { TAB_OF, type Go, type Screen, type TabName } from './nav'
import { DEVICE, IDENTITY_KEY, inProgressFor, store, useStoreSnapshot } from './store'
import { IdentityPicker } from './screens/IdentityPicker'
import { WardList } from './screens/WardList'
import { PatientDetail } from './screens/PatientDetail'
import { RecordingScreen } from './screens/Recording'
import { DraftReview } from './screens/DraftReview'
import { ReceivedList } from './screens/Received'
import { ReceivedDetail } from './screens/ReceivedDetail'
import { ShiftBoard } from './screens/ShiftBoard'
import { AccountScreen } from './screens/Account'
import { TemplateView } from './screens/TemplateView'

const TABS: Array<{ tab: TabName; label: string; root: Screen }> = [
  { tab: 'patients', label: 'Patients', root: { name: 'ward' } },
  { tab: 'received', label: 'Received', root: { name: 'received' } },
  { tab: 'shift', label: 'Shift', root: { name: 'shift' } },
  { tab: 'account', label: 'Account', root: { name: 'account' } },
]

/**
 * F-033 reopen rule: after identity, if the current practitioner has a
 * handover in `recording` or `draft_ready`, land DIRECTLY on that draft —
 * never on a home screen.
 */
function landingScreen(practitionerId: string): Screen {
  const open = inProgressFor(practitionerId)
  if (open !== undefined) {
    return open.status === 'recording'
      ? { name: 'recording', handoverId: open.id }
      : { name: 'draft', handoverId: open.id }
  }
  return { name: 'ward' }
}

function savedIdentity(): string | null {
  const saved = window.localStorage.getItem(IDENTITY_KEY)
  return saved !== null && store.practitioner(saved) !== undefined ? saved : null
}

function TabBar({ active, go }: { active: TabName; go: Go }): ReactNode {
  return (
    <nav className="tabbar" aria-label="Main navigation">
      {TABS.map((t) => (
        <button
          key={t.tab}
          type="button"
          className={active === t.tab ? 'tabbar__tab tabbar__tab--active' : 'tabbar__tab'}
          onClick={() => go(t.root)}
        >
          {t.label}
        </button>
      ))}
    </nav>
  )
}

export function App(): ReactNode {
  useStoreSnapshot()

  const [practitionerId, setPractitionerId] = useState<string | null>(savedIdentity)
  const [screen, setScreen] = useState<Screen>(() => {
    const id = savedIdentity()
    return id !== null ? landingScreen(id) : { name: 'ward' }
  })

  const practitioner: Practitioner | undefined =
    practitionerId !== null ? store.practitioner(practitionerId) : undefined

  const go: Go = (next) => setScreen(next)

  const pickIdentity = (id: string): void => {
    store.recordSignIn(id, 'sign_in', DEVICE)
    window.localStorage.setItem(IDENTITY_KEY, id)
    setPractitionerId(id)
    setScreen(landingScreen(id))
  }

  const signOut = (): void => {
    if (practitionerId !== null) store.recordSignIn(practitionerId, 'sign_out', DEVICE)
    window.localStorage.removeItem(IDENTITY_KEY)
    setPractitionerId(null)
    setScreen({ name: 'ward' })
  }

  if (practitioner === undefined) {
    return (
      <div className="app">
        <IdentityPicker onPick={pickIdentity} />
      </div>
    )
  }

  const hideTabs = screen.name === 'recording'

  let body: ReactNode
  switch (screen.name) {
    case 'ward':
      body = <WardList practitioner={practitioner} go={go} />
      break
    case 'patient':
      body = <PatientDetail patientId={screen.patientId} practitioner={practitioner} go={go} />
      break
    case 'recording':
      body = <RecordingScreen handoverId={screen.handoverId} practitioner={practitioner} go={go} />
      break
    case 'draft':
      body = <DraftReview handoverId={screen.handoverId} practitioner={practitioner} go={go} />
      break
    case 'received':
      body = <ReceivedList practitioner={practitioner} go={go} />
      break
    case 'receivedDetail':
      body = <ReceivedDetail handoverId={screen.handoverId} practitioner={practitioner} go={go} />
      break
    case 'shift':
      body = <ShiftBoard practitioner={practitioner} go={go} />
      break
    case 'account':
      body = <AccountScreen practitioner={practitioner} go={go} onSignOut={signOut} />
      break
    case 'template':
      body = <TemplateView go={go} />
      break
  }

  return (
    <div className="app">
      <main className={hideTabs ? 'content content--no-tabs' : 'content'}>{body}</main>
      {!hideTabs && <TabBar active={TAB_OF[screen.name]} go={go} />}
    </div>
  )
}
