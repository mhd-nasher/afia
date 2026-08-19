import { collection, getDocs, getFirestore } from 'firebase/firestore'
import { describe, expect, it } from 'vitest'
import { FirestoreStore } from './firebase'
import { makeSeed } from './seed'

/**
 * LIVE integration check against project afia-12f38 (me-central2).
 * Exercises the exact production path the apps use: FirestoreStore inherits
 * every constraint from LocalStore; commit() diff-syncs to Firestore.
 * Requires network; excluded from the offline unit suite.
 */
describe('FirestoreStore against the live database', () => {
  it('creates a case through the real store and finds it on the server', async () => {
    const store = new FirestoreStore(makeSeed())

    // Wait for anonymous auth + initial sync.
    await waitFor(() => store.syncStatus === 'online', 30_000)
    expect(store.syncStatus).toBe('online')

    const created = store.createCase('Salem A. (sync check)', 'self', null)
    store.appendCaseUpdate(created.id, {
      id: `${created.id}-u1`,
      at: Date.now(),
      kind: 'initial',
      transcript: 'Live sync verification from the integration test.',
      audio: null,
      redFlagAnswers: [{ questionId: 'rf-chest-pain', answer: 'NO' }],
      redFlags: { triggered: false, triggeredBy: [], unanswered: [] },
      functionalAnswers: [{ questionId: 'fn-eating', value: 'UNKNOWN' }],
      syncState: 'sent',
    })

    // flush() resolves only on SERVER acknowledgement — not local echo.
    // (First version of this test read its own pending write and passed
    // while the server had nothing. getDocs on the writing client is echo.)
    await store.flush()

    const snap = await getDocs(collection(getFirestore(), 'cases'))
    const doc = snap.docs.find((d) => d.id === created.id)?.data()
    expect(doc).toBeDefined()
    expect(doc?.['patientName']).toBe('Salem A. (sync check)')
    expect(doc?.['status']).toBe('submitted')
    // UNKNOWN survived the round trip untouched (§2.2).
    expect(doc?.['updates']?.[0]?.functionalAnswers?.[0]?.value).toBe('UNKNOWN')

    store.stop()
  })
})

async function waitFor(
  cond: () => boolean | Promise<boolean>,
  timeoutMs: number,
): Promise<void> {
  const start = Date.now()
  while (Date.now() - start < timeoutMs) {
    if (await cond()) return
    await new Promise((r) => setTimeout(r, 500))
  }
  throw new Error('waitFor timed out')
}
