import { useSyncExternalStore } from 'react'
import { type Handover, type LocalStore } from '@afia/core'
import { createStore, type StoreBackend } from '@afia/core/src/firebase'

/**
 * Module singleton over the shared data seam (architecture R-003). Default
 * backend is Firebase — one live database (afia-12f38, me-central2) shared by
 * all three surfaces. Set VITE_AFIA_BACKEND=local for on-device demo.
 * All mutations go through store methods; every commit produces a new
 * snapshot object, so useSyncExternalStore re-renders subscribers.
 */

export const STORE_KEY = 'afia-clinician'
export const IDENTITY_KEY = 'afia-clinician-identity'
export const SHIFT_COMPLETE_KEY = 'afia-clinician-shift-complete-shown'
export const DEVICE = 'Ward A tablet 1'

if (window.localStorage.getItem(STORE_KEY) === '') {
  window.localStorage.removeItem(STORE_KEY)
}

const backend = (import.meta.env.VITE_AFIA_BACKEND as StoreBackend | undefined) ?? 'firebase'

export const store: LocalStore = createStore({
  backend,
  key: STORE_KEY,
  storage: window.localStorage,
})

/** Subscribe this component tree to store commits. */
export function useStoreSnapshot(): void {
  useSyncExternalStore(store.subscribe, store.getSnapshot)
}

// ── derived reads (pure lookups over the snapshot) ─────────────────────────

/** Newest handover for a patient, optionally restricted to one author. */
export function newestHandoverFor(
  patientId: string,
  authorId?: string,
): Handover | undefined {
  let best: Handover | undefined
  for (const h of store.handovers()) {
    if (h.patientId !== patientId) continue
    if (authorId !== undefined && h.authorId !== authorId) continue
    if (best === undefined || h.createdAt > best.createdAt) best = h
  }
  return best
}

/** Newest in-progress (recording / draft_ready) handover by this author. */
export function inProgressFor(
  authorId: string,
  patientId?: string,
): Handover | undefined {
  let best: Handover | undefined
  for (const h of store.handovers()) {
    if (h.authorId !== authorId) continue
    if (patientId !== undefined && h.patientId !== patientId) continue
    if (h.status !== 'recording' && h.status !== 'draft_ready') continue
    if (best === undefined || h.createdAt > best.createdAt) best = h
  }
  return best
}

/** Signed handovers authored by someone else — the Received list. Newest first. */
export function receivedHandovers(viewerId: string): Handover[] {
  return store
    .handovers()
    .filter((h) => h.authorId !== viewerId && h.signature !== null)
    .sort((a, b) => b.createdAt - a.createdAt)
}

/** All signed handovers for a patient, newest first. */
export function signedFor(patientId: string): Handover[] {
  return store
    .handovers()
    .filter((h) => h.patientId === patientId && h.signature !== null)
    .sort((a, b) => b.createdAt - a.createdAt)
}

/** The newest signed handover for the patient created before `before`. */
export function earlierSignedFor(
  patientId: string,
  before: number,
): Handover | undefined {
  return signedFor(patientId).find((h) => h.createdAt < before)
}

// Dev-only HMR hygiene: without this, each hot swap of this module creates a
// fresh store while the old one's Firestore listeners keep firing (zombies).
if (import.meta.hot) {
  import.meta.hot.dispose(() => {
    ;(store as { stop?: () => void }).stop?.()
  })
}
