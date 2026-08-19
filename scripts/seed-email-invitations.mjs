// D-012: invitations are keyed by LOWERCASE EMAIL. Seeds the owner's invitations
// so they can sign into the clinician app with email+password.
// Run: node scripts/seed-email-invitations.mjs
import { initializeApp } from 'firebase/app'
import { getAuth, signInAnonymously } from 'firebase/auth'
import { doc, getDoc, getFirestore, setDoc } from 'firebase/firestore'

const app = initializeApp({
  projectId: 'afia-12f38',
  appId: '1:899977237335:web:a013b17104970466816412',
  apiKey: 'AIzaSyD5c4UUAZKG7ezYy_nx8msSs8wJ19zjYEA',
  authDomain: 'afia-12f38.firebaseapp.com',
})
await signInAnonymously(getAuth(app))
const db = getFirestore(app)

const invitations = [
  {
    email: 'nasgo.uk@gmail.com',
    name: 'Mohammed Nasher',
    role: 'charge_nurse',
    signatureIdentity: 'RN 88-0001 · Mohammed Nasher',
  },
  {
    email: 'mngnm17@gmail.com',
    name: 'Mohammed Nasher',
    role: 'charge_nurse',
    signatureIdentity: 'RN 88-0002 · Mohammed Nasher',
  },
]

for (const inv of invitations) {
  const id = inv.email.toLowerCase()
  const ref = doc(db, 'invitations', id)
  const existing = await getDoc(ref)
  if (existing.exists()) {
    console.log(`exists: invitations/${id} (claimedBy: ${existing.data().claimedBy})`)
    continue
  }
  await setDoc(ref, {
    ...inv,
    wardId: 'ward-a',
    invitedBy: 'Owner bootstrap',
    createdAt: Date.now(),
    claimedBy: null,
  })
  console.log(`created: invitations/${id}`)
}
console.log('done')
process.exit(0)
