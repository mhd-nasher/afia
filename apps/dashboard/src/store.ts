import { createStore, type StoreBackend } from '@afia/core/src/firebase'
import { useSyncExternalStore } from 'react'

/**
 * Module singleton over the shared data seam (HANDOFF §8 / architecture R-003).
 * The dashboard OBSERVES AND CONFIGURES — it is not in the clinical path, so
 * everything it renders is a read of the same store the clinical surfaces use.
 *
 * Default backend is Firebase — one live database (afia-12f38, me-central2)
 * shared by all three surfaces. Set VITE_AFIA_BACKEND=local for offline dev.
 *
 * Manager authentication is separate (see firebaseAdmin.ts): the store's data
 * sync uses the default Firebase app; manager sessions live on a named app.
 */

const STORAGE_KEY = 'afia-dashboard'

const backend = (import.meta.env.VITE_AFIA_BACKEND as StoreBackend | undefined) ?? 'firebase'

export const store = createStore({
  backend,
  key: STORAGE_KEY,
  storage: window.localStorage,
})

/** Epoch ms of the most recent store commit — the "last sync" the Live strip shows. */
let lastStoreUpdate = Date.now()
store.subscribe(() => {
  lastStoreUpdate = Date.now()
})
export function lastDataUpdateAt(): number {
  return lastStoreUpdate
}

/** Subscribe the React tree to store commits (call once, at the App root). */
export function useStoreSnapshot(): ReturnType<typeof store.getSnapshot> {
  return useSyncExternalStore(store.subscribe, store.getSnapshot)
}

// Dev-only HMR hygiene: without this, each hot swap of this module creates a
// fresh store while the old one's Firestore listeners keep firing (zombies).
if (import.meta.hot) {
  import.meta.hot.dispose(() => {
    ;(store as { stop?: () => void }).stop?.()
  })
}
