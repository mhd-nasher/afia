import { useSyncExternalStore } from 'react'
import { createStore, type StoreBackend } from '@afia/core/src/firebase'

/**
 * Module singleton (one store per tab), over the shared data seam
 * (architecture R-003). Default backend is Firebase — one live database
 * (afia-12f38, me-central2) shared by all three surfaces. Set
 * VITE_AFIA_BACKEND=local to run fully on-device with localStorage.
 */
const backend = (import.meta.env.VITE_AFIA_BACKEND as StoreBackend | undefined) ?? 'firebase'

export const store = createStore({
  backend,
  key: 'afia-patient',
  storage: window.localStorage,
})

export function useStoreSnapshot() {
  return useSyncExternalStore(store.subscribe, store.getSnapshot)
}

// Dev-only HMR hygiene: without this, each hot swap of this module creates a
// fresh store while the old one's Firestore listeners keep firing (zombies).
if (import.meta.hot) {
  import.meta.hot.dispose(() => {
    ;(store as { stop?: () => void }).stop?.()
  })
}
