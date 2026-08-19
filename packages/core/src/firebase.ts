import { getApp, getApps, initializeApp } from 'firebase/app'
import { getAuth, signInAnonymously } from 'firebase/auth'
import {
  collection,
  doc,
  getDoc,
  getFirestore,
  initializeFirestore,
  onSnapshot,
  persistentLocalCache,
  persistentMultipleTabManager,
  setDoc,
  writeBatch,
  type Firestore,
} from 'firebase/firestore'
import type { AuditEvent } from './audit'
import { AuditLog } from './audit'
import { emptySeed, makeSeed } from './seed'
import { LocalStore, type SeedData, type StorageLike } from './store'

/**
 * Firebase seam (architecture R-003), now implemented. FirestoreStore extends
 * LocalStore, so EVERY §2 constraint lives in exactly one place — the
 * inherited state machines and pure functions. Only the persistence layer is
 * swapped: mutations diff-sync up to Firestore, snapshots merge down.
 *
 * The firestore.rules file enforces the sharpest constraints a second time at
 * the database boundary (no priority downgrade, immutable signatures,
 * append-only audit) — a client that bypasses this code still cannot break them.
 *
 * Data residency: me-central2 (Saudi Arabia), chosen deliberately (HANDOFF §8).
 */

/** Public web SDK config for project "Afia" (afia-12f38). Not a secret. */
export const FIREBASE_CONFIG = {
  projectId: 'afia-12f38',
  appId: '1:899977237335:web:a013b17104970466816412',
  apiKey: 'AIzaSyD5c4UUAZKG7ezYy_nx8msSs8wJ19zjYEA',
  authDomain: 'afia-12f38.firebaseapp.com',
  storageBucket: 'afia-12f38.firebasestorage.app',
  messagingSenderId: '899977237335',
} as const

/** Firestore rejects documents over ~1MB; long audio stays on-device (needs Storage/Blaze). */
const MAX_SYNCED_DOC_BYTES = 900_000

type EntityRow = { id: string } & Record<string, unknown>

/**
 * Canonical JSON (recursively sorted keys) so change detection compares
 * CONTENT, not key order — Firestore returns keys in its own order, and a
 * spurious "change" would re-write immutable documents (audit events), which
 * the security rules rightly deny.
 */
function stableStringify(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(',')}]`
  if (value !== null && typeof value === 'object') {
    const entries = Object.entries(value as Record<string, unknown>)
      .filter(([, v]) => v !== undefined)
      .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
    return `{${entries.map(([k, v]) => `${JSON.stringify(k)}:${stableStringify(v)}`).join(',')}}`
  }
  return JSON.stringify(value)
}

export type SyncStatus = 'starting' | 'online' | 'error'

export class FirestoreStore extends LocalStore {
  private db: Firestore
  private lastSynced = new Map<string, string>()
  private unsubscribers: Array<() => void> = []
  private started = false
  private syncChain: Promise<void> = Promise.resolve()
  private resolveOnline!: () => void
  private onlineOnce = new Promise<void>((resolve) => {
    this.resolveOnline = resolve
  })
  syncStatus: SyncStatus = 'starting'
  syncError: string | null = null

  constructor(seed: SeedData) {
    // No localStorage — Firestore's IndexedDB cache is the offline persistence.
    super(seed, {})
    const app = getApps().length > 0 ? getApp() : initializeApp(FIREBASE_CONFIG)
    let db: Firestore
    try {
      db = initializeFirestore(app, {
        localCache: persistentLocalCache({ tabManager: persistentMultipleTabManager() }),
      })
    } catch {
      db = getFirestore(app) // already initialized elsewhere
    }
    this.db = db
    void this.start()
  }

  private async start(): Promise<void> {
    try {
      await signInAnonymously(getAuth())
      await this.seedIfEmpty()
      this.listen()
      // syncStatus flips to 'online' only once EVERY collection has delivered
      // its first snapshot — before that, a diff against the fresh local seed
      // would try to rewrite server documents (and §2 rules would rightly
      // reject e.g. re-timestamped signatures, failing the whole batch).
    } catch (e) {
      this.syncStatus = 'error'
      this.syncError = e instanceof Error ? e.message : String(e)
      this.notify()
    }
  }

  // ── collection mapping ───────────────────────────────────────────────────

  private collectionRows(): Record<string, EntityRow[]> {
    const s = this.state
    return {
      patients: s.patients as unknown as EntityRow[],
      practitioners: s.practitioners as unknown as EntityRow[],
      wards: s.wards as unknown as EntityRow[],
      handovers: s.handovers.map((h) => this.fitForSync(h as unknown as EntityRow)),
      cases: s.cases as unknown as EntityRow[],
      consents: s.consents as unknown as EntityRow[],
      formulary: s.formulary as unknown as EntityRow[],
      templateVersions: s.templateVersions.map((v) => ({ ...v, id: `v${v.version}` })),
      redFlagQuestions: s.redFlagQuestions as unknown as EntityRow[],
      functionalQuestions: s.functionalQuestions as unknown as EntityRow[],
      signInLog: s.signInLog as unknown as EntityRow[],
      wellbeing: Object.entries(s.wellbeingScores).map(([wardId, scores]) => ({
        id: wardId,
        scores,
      })),
      audit: this.audit.read() as unknown as EntityRow[],
    }
  }

  /** Keep documents under Firestore's size limit: oversized audio stays on-device. */
  private fitForSync(row: EntityRow): EntityRow {
    const json = JSON.stringify(row)
    if (json.length <= MAX_SYNCED_DOC_BYTES) return row
    const audio = row['audio'] as { url?: string } | null
    if (audio && typeof audio.url === 'string' && audio.url.length > 100_000) {
      return {
        ...row,
        audio: {
          ...audio,
          url: '',
          urlOmittedReason:
            'Recording exceeds the Firestore document limit — kept on the recording device. Enable Firebase Storage (Blaze plan) to sync audio.',
        },
      }
    }
    return row
  }

  // ── seeding ──────────────────────────────────────────────────────────────

  private async seedIfEmpty(): Promise<void> {
    const marker = await getDoc(doc(this.db, 'meta', 'seeded'))
    if (marker.exists()) return
    await this.pushAll()
    await setDoc(doc(this.db, 'meta', 'config'), this.state.config)
    await setDoc(doc(this.db, 'meta', 'seeded'), { at: Date.now(), by: 'first-client' })
  }

  private async pushAll(): Promise<void> {
    const rows = this.collectionRows()
    // Firestore batches cap at 500 writes; the demo dataset is far smaller,
    // but chunk anyway so a grown dataset cannot break seeding.
    const writes: Array<{ col: string; row: EntityRow }> = []
    for (const [col, list] of Object.entries(rows)) {
      for (const row of list) writes.push({ col, row })
    }
    for (let i = 0; i < writes.length; i += 400) {
      const batch = writeBatch(this.db)
      const chunk = writes.slice(i, i + 400)
      for (const w of chunk) batch.set(doc(this.db, w.col, w.row.id), w.row)
      await batch.commit()
      // Mark as synced only AFTER the server accepted the batch.
      for (const w of chunk) this.lastSynced.set(`${w.col}/${w.row.id}`, stableStringify(w.row))
    }
  }

  // ── up-sync: every store mutation diffs and writes what changed ──────────

  protected override commit(): void {
    super.commit()
    // Before initial sync completes, mutations stay local; the union-merge in
    // apply() preserves them, and the post-initial syncUp pushes them.
    if (this.syncStatus === 'online') {
      this.syncChain = this.syncChain.then(() => this.syncUp())
    }
  }

  /**
   * Resolves when every batched write so far has been ACKNOWLEDGED BY THE
   * SERVER (Firestore batch commits resolve on server ack, not local echo).
   * This is what lets the patient app say "sent" honestly. Never resolves
   * while the store cannot reach the server — "queued on this device" stays
   * on screen, which is the truthful state.
   */
  override async flush(): Promise<void> {
    await this.onlineOnce
    await this.syncChain
  }

  private async syncUp(): Promise<void> {
    try {
      const rows = this.collectionRows()
      const batch = writeBatch(this.db)
      const pending: Array<{ key: string; json: string }> = []
      for (const [col, list] of Object.entries(rows)) {
        for (const row of list) {
          const key = `${col}/${row.id}`
          const json = stableStringify(row)
          if (this.lastSynced.get(key) !== json) {
            batch.set(doc(this.db, col, row.id), row)
            pending.push({ key, json })
          }
        }
      }
      if (pending.length > 0) {
        await batch.commit()
        // Mark as synced only AFTER the server accepted the batch — a failed
        // batch must stay "dirty" so the next syncUp retries it.
        for (const p of pending) this.lastSynced.set(p.key, p.json)
      }
    } catch (e) {
      // Writes that violate firestore.rules (or fail offline) surface here;
      // the local state keeps the app usable and honest logging records it.
      console.warn('[afia] Firestore sync-up failed:', e)
    }
  }

  // ── down-sync: server snapshots replace local collections ────────────────

  private listen(): void {
    const pendingInitial = new Set([
      'patients', 'practitioners', 'wards', 'handovers', 'cases', 'consents',
      'formulary', 'templateVersions', 'redFlagQuestions', 'functionalQuestions',
      'signInLog', 'wellbeing', 'audit',
    ])

    const initialDelivered = (col: string): void => {
      if (!pendingInitial.has(col)) return
      pendingInitial.delete(col)
      if (pendingInitial.size === 0) {
        this.syncStatus = 'online'
        // Push anything mutated locally while waiting for the initial sync.
        this.syncChain = this.syncChain.then(() => this.syncUp())
        this.resolveOnline()
        this.notify()
      }
    }

    // This system has no deletes anywhere (§3.4), so a union merge is sound:
    // the server version wins for shared ids; local-only documents (created
    // before the initial sync completed) survive and are pushed afterwards.
    const unionById = <T extends { id: string }>(local: readonly T[], server: T[]): T[] => {
      const serverIds = new Set(server.map((d) => d.id))
      return [...server, ...local.filter((d) => !serverIds.has(d.id))]
    }

    const apply = (col: string, serverDocs: EntityRow[]): void => {
      for (const row of serverDocs) this.lastSynced.set(`${col}/${row.id}`, stableStringify(row))
      const byCreated = (rows: EntityRow[]): EntityRow[] =>
        [...rows].sort(
          (a, b) => ((a['createdAt'] as number) ?? 0) - ((b['createdAt'] as number) ?? 0),
        )
      const merge = (local: readonly unknown[]): EntityRow[] =>
        byCreated(unionById(local as EntityRow[], serverDocs))
      const docs = serverDocs
      const sorted = merge(this.stateSlice(col))
      switch (col) {
        case 'patients': this.state.patients = sorted as never; break
        case 'practitioners': this.state.practitioners = sorted as never; break
        case 'wards': this.state.wards = sorted as never; break
        case 'handovers': {
          // §2.6 — audio omitted from an oversized synced doc stays available
          // locally on the device that recorded it.
          const existing = new Map(this.state.handovers.map((h) => [h.id, h]))
          this.state.handovers = sorted.map((row) => {
            const incoming = row as never as (typeof this.state.handovers)[number]
            const local = existing.get(incoming.id)
            if (incoming.audio && incoming.audio.url === '' && local?.audio?.url) {
              return { ...incoming, audio: local.audio }
            }
            return incoming
          })
          break
        }
        case 'cases': this.state.cases = sorted as never; break
        case 'consents': this.state.consents = sorted as never; break
        case 'formulary': this.state.formulary = docs as never; break
        case 'templateVersions':
          this.state.templateVersions = [...docs]
            .sort((a, b) => (a['version'] as number) - (b['version'] as number))
            .map((d) => {
              const { id: _id, ...rest } = d
              return rest as never
            }) as never
          break
        case 'redFlagQuestions': this.state.redFlagQuestions = docs as never; break
        case 'functionalQuestions': this.state.functionalQuestions = docs as never; break
        case 'signInLog':
          this.state.signInLog = [...sorted].sort(
            (a, b) => (a['at'] as number) - (b['at'] as number),
          ) as never
          break
        case 'wellbeing': {
          const scores: Record<string, number[]> = {}
          for (const row of docs) scores[row.id] = row['scores'] as number[]
          this.state.wellbeingScores = scores
          break
        }
        case 'audit': {
          const events = unionById(
            this.audit.read() as unknown as EntityRow[],
            serverDocs,
          ).sort((a, b) => (a['at'] as number) - (b['at'] as number)) as unknown as AuditEvent[]
          this.audit = AuditLog.from(events)
          break
        }
      }
      initialDelivered(col)
      this.notify()
    }

    const collections = [
      'patients', 'practitioners', 'wards', 'handovers', 'cases', 'consents',
      'formulary', 'templateVersions', 'redFlagQuestions', 'functionalQuestions',
      'signInLog', 'wellbeing', 'audit',
    ]
    for (const col of collections) {
      this.unsubscribers.push(
        onSnapshot(
          collection(this.db, col),
          (snap) => apply(col, snap.docs.map((d) => d.data() as EntityRow)),
          (err) => console.warn(`[afia] snapshot error on ${col}:`, err.message),
        ),
      )
    }
    this.unsubscribers.push(
      onSnapshot(doc(this.db, 'meta', 'config'), (snap) => {
        if (snap.exists()) {
          this.state.config = snap.data() as never
          this.notify()
        }
      }),
    )
    this.started = true
  }

  /** The local array backing one synced collection (for union merges). */
  private stateSlice(col: string): readonly unknown[] {
    switch (col) {
      case 'patients': return this.state.patients
      case 'practitioners': return this.state.practitioners
      case 'wards': return this.state.wards
      case 'handovers': return this.state.handovers
      case 'cases': return this.state.cases
      case 'consents': return this.state.consents
      case 'signInLog': return this.state.signInLog
      default: return []
    }
  }

  stop(): void {
    for (const u of this.unsubscribers) u()
    this.unsubscribers = []
  }

  /**
   * Amendment A1.1 — real-use posture: the shared cloud database holds real
   * records, so "demo reset" must never reintroduce synthetic data. No-op.
   */
  override resetDemo(): void {
    console.warn('[afia] resetDemo is disabled in real-use posture (A1.1) — no synthetic data will be written.')
  }
}

/** Map raw seed data to Firestore collection rows (used by demo reset). */
function seedRows(seed: SeedData): Record<string, EntityRow[]> {
  return {
    patients: seed.patients as unknown as EntityRow[],
    practitioners: seed.practitioners as unknown as EntityRow[],
    wards: seed.wards as unknown as EntityRow[],
    handovers: seed.handovers as unknown as EntityRow[],
    cases: seed.cases as unknown as EntityRow[],
    consents: seed.consents as unknown as EntityRow[],
    formulary: seed.formulary as unknown as EntityRow[],
    templateVersions: seed.templateVersions.map((v) => ({ ...v, id: `v${v.version}` })),
    redFlagQuestions: seed.redFlagQuestions as unknown as EntityRow[],
    functionalQuestions: seed.functionalQuestions as unknown as EntityRow[],
    signInLog: seed.signInLog as unknown as EntityRow[],
    wellbeing: Object.entries(seed.wellbeingScores).map(([wardId, scores]) => ({ id: wardId, scores })),
    audit: seed.auditEvents as unknown as EntityRow[],
  }
}

// ── factory ────────────────────────────────────────────────────────────────

export type StoreBackend = 'local' | 'firebase'

/**
 * The one line each app calls. `backend: 'firebase'` shares one live database
 * across all three surfaces (the real demo); `'local'` keeps everything
 * on-device with localStorage (works with no network and no Firebase project).
 */
export function createStore(opts: {
  backend?: StoreBackend
  key: string
  storage?: StorageLike
}): LocalStore {
  const backend = opts.backend ?? 'firebase'
  if (backend === 'firebase') {
    try {
      return new FirestoreStore(emptySeed())
    } catch (e) {
      console.warn('[afia] Firebase unavailable — falling back to local store.', e)
    }
  }
  return new LocalStore(makeSeed(), { storage: opts.storage, key: opts.key })
}
