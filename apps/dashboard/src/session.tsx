import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react'
import type { User } from 'firebase/auth'
import { watchManager, watchManagerAccount, type ManagerProfile } from './firebaseAdmin'

/**
 * Manager session context. Every section is gated behind this: the app shell
 * renders the auth screens until a manager is signed in, and the sections read
 * the signed-in manager's name for attribution (invitations, template edits,
 * audit events).
 */

interface Session {
  status: 'loading' | 'signed_out' | 'signed_in'
  manager: ManagerProfile | null
}

const SessionContext = createContext<Session>({ status: 'loading', manager: null })

export function SessionProvider({ children }: { children: ReactNode }): ReactNode {
  const [session, setSession] = useState<Session>({ status: 'loading', manager: null })

  useEffect(() => {
    let unwatchAccount: (() => void) | null = null
    const unwatchAuth = watchManager((user: User | null) => {
      unwatchAccount?.()
      unwatchAccount = null
      if (user === null) {
        setSession({ status: 'signed_out', manager: null })
        return
      }
      const fromAuth: ManagerProfile = {
        uid: user.uid,
        name: user.displayName ?? user.email ?? 'Manager',
        email: user.email ?? '',
      }
      setSession({ status: 'signed_in', manager: fromAuth })
      // The profile document is the source of truth for the display name —
      // during registration it lands moments after the auth event.
      unwatchAccount = watchManagerAccount(user.uid, (data) => {
        if (data?.name !== undefined && data.name !== '') {
          setSession({
            status: 'signed_in',
            manager: { ...fromAuth, name: data.name },
          })
        }
      })
    })
    return () => {
      unwatchAccount?.()
      unwatchAuth()
    }
  }, [])

  return <SessionContext.Provider value={session}>{children}</SessionContext.Provider>
}

export function useSession(): Session {
  return useContext(SessionContext)
}

/** The signed-in manager. Only callable from inside the auth gate. */
export function useManager(): ManagerProfile {
  const s = useContext(SessionContext)
  if (s.manager === null) throw new Error('useManager called outside the auth gate')
  return s.manager
}
