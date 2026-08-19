// Live RTDB rules smoke: own-node presence write OK, foreign write DENIED,
// presence read OK, request create OK. Run from repo root (firebase dep).
import { initializeApp } from 'firebase/app'
import { getAuth, signInAnonymously } from 'firebase/auth'
import { getDatabase, ref, set, get, push, remove } from 'firebase/database'

const app = initializeApp({
  projectId: 'afia-12f38',
  appId: '1:899977237335:web:a013b17104970466816412',
  apiKey: 'AIzaSyD5c4UUAZKG7ezYy_nx8msSs8wJ19zjYEA',
  authDomain: 'afia-12f38.firebaseapp.com',
  databaseURL: 'https://afia-12f38-default-rtdb.europe-west1.firebasedatabase.app',
})
const { user } = await signInAnonymously(getAuth(app))
const db = getDatabase(app)
const results = []

// 1. Own presence write — must SUCCEED
try {
  await set(ref(db, `presence/${user.uid}`), {
    name: 'Smoke Test', role: 'nurse', wardId: 'ward-a', lastSeen: Date.now(), state: 'online',
  })
  results.push('own presence write: OK ✅')
} catch (e) { results.push(`own presence write: FAILED ❌ ${e.code || e.message}`) }

// 2. Foreign presence write — must be DENIED
try {
  await set(ref(db, 'presence/someone-else'), {
    name: 'Evil', role: 'nurse', wardId: 'ward-a', lastSeen: Date.now(),
  })
  results.push('foreign presence write: ALLOWED ❌ (rules broken!)')
} catch { results.push('foreign presence write: DENIED ✅') }

// 3. Presence read — must SUCCEED
try {
  const snap = await get(ref(db, 'presence'))
  results.push(`presence read: OK ✅ (${Object.keys(snap.val() ?? {}).length} node(s))`)
} catch (e) { results.push(`presence read: FAILED ❌ ${e.code || e.message}`) }

// 4. Request create (rules-shaped) — must SUCCEED
try {
  const r = push(ref(db, 'requests/ward-a'))
  await set(r, {
    from: { uid: user.uid, name: 'Smoke Test' },
    to: { uid: 'colleague-1', name: 'Colleague' },
    kind: 'med_witness', bed: 'A3', createdAt: Date.now(), status: 'pending',
  })
  results.push('request create: OK ✅')
  await set(ref(db, `requests/ward-a/${r.key}/status`), 'accepted').then(
    () => results.push('sender status update: OK ✅ (sender is a permitted writer)'),
    () => results.push('sender status update: DENIED (also acceptable)'),
  )
} catch (e) { results.push(`request create: FAILED ❌ ${e.code || e.message}`) }

// 5. Root read — must be DENIED (default deny)
try {
  await get(ref(db, '/'))
  results.push('root read: ALLOWED ❌ (should be denied)')
} catch { results.push('root read: DENIED ✅') }

// cleanup own presence
await remove(ref(db, `presence/${user.uid}`)).catch(() => {})
console.log(results.join('\n'))
process.exit(0)
