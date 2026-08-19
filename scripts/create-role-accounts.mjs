// Creates the ready-made role accounts requested by the owner (A1.3):
//   1. Dashboard manager (email+password)
//   2. Patient app account (email+password)
// Clinician accounts are invitation+OTP only — use the console test phone
// numbers with the seeded invitations instead.
// Run: node scripts/create-role-accounts.mjs
import { initializeApp } from 'firebase/app'
import {
  createUserWithEmailAndPassword,
  getAuth,
  signInWithEmailAndPassword,
} from 'firebase/auth'
import { doc, getFirestore, setDoc } from 'firebase/firestore'

const app = initializeApp({
  projectId: 'afia-12f38',
  appId: '1:899977237335:web:a013b17104970466816412',
  apiKey: 'AIzaSyD5c4UUAZKG7ezYy_nx8msSs8wJ19zjYEA',
  authDomain: 'afia-12f38.firebaseapp.com',
})
const auth = getAuth(app)
const db = getFirestore(app)

async function ensureAccount(email, password, collection, profile) {
  let cred
  try {
    cred = await createUserWithEmailAndPassword(auth, email, password)
    console.log(`created ${email} (uid ${cred.user.uid})`)
  } catch (e) {
    if (e.code === 'auth/email-already-in-use') {
      cred = await signInWithEmailAndPassword(auth, email, password)
      console.log(`exists ${email} (uid ${cred.user.uid})`)
    } else {
      throw e
    }
  }
  await setDoc(doc(db, collection, cred.user.uid), {
    ...profile,
    email,
    createdAt: Date.now(),
  })
  console.log(`profile written: ${collection}/${cred.user.uid}`)
  return cred.user.uid
}

// Credentials come from the environment — never hardcode passwords in the repo.
//   AFIA_ADMIN_EMAIL / AFIA_ADMIN_PASSWORD
//   AFIA_PATIENT_EMAIL / AFIA_PATIENT_PASSWORD
const need = (k) => {
  const v = process.env[k]
  if (!v) {
    console.error(`Missing env var ${k} — aborting (no credentials are stored in this repo).`)
    process.exit(1)
  }
  return v
}
await ensureAccount(
  need('AFIA_ADMIN_EMAIL'),
  need('AFIA_ADMIN_PASSWORD'),
  'managerAccounts',
  { name: 'Afia Admin' },
)
await ensureAccount(
  need('AFIA_PATIENT_EMAIL'),
  need('AFIA_PATIENT_PASSWORD'),
  'patientAccounts',
  { name: 'Test Patient', locale: 'en', externalIdentifier: null },
)
console.log('All role accounts ready.')
process.exit(0)
