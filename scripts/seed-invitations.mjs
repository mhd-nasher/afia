// Seed invitations for the clinician app's phone-OTP sign-in (§5).
// invitations/{phoneE164} — the dashboard normally creates these; this
// script stands in for it so test numbers can claim accounts.
// Uses the public web SDK with anonymous auth (rules require any auth).
// Run: node scripts/seed-invitations.mjs
// SYNTHETIC DEMO DATA — every identity below is invented.

import { initializeApp } from 'firebase/app'
import { getAuth, signInAnonymously } from 'firebase/auth'
import { doc, getDoc, getFirestore, setDoc } from 'firebase/firestore'

// Same public config as packages/core/src/firebase.ts (not a secret).
const FIREBASE_CONFIG = {
  projectId: 'afia-12f38',
  appId: '1:899977237335:web:a013b17104970466816412',
  apiKey: 'AIzaSyD5c4UUAZKG7ezYy_nx8msSs8wJ19zjYEA',
  authDomain: 'afia-12f38.firebaseapp.com',
  storageBucket: 'afia-12f38.firebasestorage.app',
  messagingSenderId: '899977237335',
}

const INVITATIONS = [
  {
    phone: '+966555000001',
    name: 'Amara Okafor',
    role: 'charge_nurse',
    signatureIdentity: 'RN 88-1042 · Amara Okafor',
    invitedBy: 'Omar Sy',
    claimedBy: null,
  },
  {
    phone: '+966555000002',
    name: 'Jonas Berg',
    role: 'nurse',
    signatureIdentity: 'RN 88-2210 · Jonas Berg',
    invitedBy: 'Omar Sy',
    claimedBy: null,
  },
  {
    phone: '+97333000001',
    name: 'Noor AlSayed',
    role: 'nurse',
    signatureIdentity: 'RN 88-3301 · Noor AlSayed',
    invitedBy: 'Omar Sy',
    claimedBy: null,
  },
]

async function main() {
  const app = initializeApp(FIREBASE_CONFIG)
  const auth = getAuth(app)
  try {
    await signInAnonymously(auth)
  } catch (e) {
    console.error(
      `✗ Anonymous auth failed (${e.code ?? e.message}). ` +
        'Enable Anonymous auth in the Firebase console, then re-run.',
    )
    process.exit(1)
  }

  const db = getFirestore(app)
  for (const invitation of INVITATIONS) {
    const ref = doc(db, 'invitations', invitation.phone)
    const existing = await getDoc(ref)
    if (existing.exists()) {
      const data = existing.data()
      if (data.claimedBy) {
        // The rules only allow claimedBy to be filled once; a claimed
        // invitation's identity fields are immutable. Leave it alone.
        console.log(`• ${invitation.phone} already claimed by ${data.claimedBy} — left untouched`)
        continue
      }
      console.log(`• ${invitation.phone} exists, unclaimed — re-asserting`)
    }
    await setDoc(ref, invitation)
    const check = await getDoc(ref)
    if (!check.exists()) throw new Error(`write did not land for ${invitation.phone}`)
    console.log(`✓ invitations/${invitation.phone} → ${invitation.name} (${invitation.role})`)
  }
  console.log('Done.')
  process.exit(0)
}

main().catch((e) => {
  console.error('✗ Seeding failed:', e.message ?? e)
  process.exit(1)
})
