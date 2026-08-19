import { getApps, initializeApp, type FirebaseApp } from 'firebase/app'
import {
  createUserWithEmailAndPassword,
  getAuth,
  onAuthStateChanged,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  signOut,
  updateProfile,
  type Auth,
  type User,
} from 'firebase/auth'
import {
  collection,
  doc,
  getDoc,
  getFirestore,
  onSnapshot,
  setDoc,
  updateDoc,
  type Firestore,
} from 'firebase/firestore'
import { FIREBASE_CONFIG } from '@afia/core/src/firebase'

/**
 * Manager identity and admin writes for the dashboard.
 *
 * A SECOND named Firebase app is used deliberately: the shared FirestoreStore
 * (packages/core) signs the DEFAULT app in anonymously for data sync, exactly
 * as the mobile surfaces do. Manager email/password sessions live on this
 * separate app so neither sign-in can clobber the other. Writes that must be
 * attributed to the manager's uid (managerAccounts/{uid}) go through this
 * app's Firestore client, which carries the manager's auth token.
 */

const APP_NAME = 'afia-manager'

function managerApp(): FirebaseApp {
  const existing = getApps().find((a) => a.name === APP_NAME)
  return existing ?? initializeApp(FIREBASE_CONFIG, APP_NAME)
}

export const managerAuth: Auth = getAuth(managerApp())
const db: Firestore = getFirestore(managerApp())

// ── auth ───────────────────────────────────────────────────────────────────

export interface ManagerProfile {
  uid: string
  name: string
  email: string
}

export function watchManager(cb: (user: User | null) => void): () => void {
  return onAuthStateChanged(managerAuth, cb)
}

/**
 * The manager's profile document. The auth listener can fire before
 * updateProfile/setDoc complete during registration, so the display name is
 * read reactively from managerAccounts/{uid} rather than from the auth token.
 */
export function watchManagerAccount(
  uid: string,
  cb: (data: { name?: string; email?: string } | null) => void,
): () => void {
  return onSnapshot(
    doc(db, 'managerAccounts', uid),
    (snap) => cb(snap.exists() ? (snap.data() as { name?: string; email?: string }) : null),
    () => cb(null),
  )
}

/** Register a manager account and create managerAccounts/{uid}. */
export async function registerManager(
  name: string,
  email: string,
  password: string,
): Promise<void> {
  const cred = await createUserWithEmailAndPassword(managerAuth, email, password)
  await updateProfile(cred.user, { displayName: name })
  await setDoc(doc(db, 'managerAccounts', cred.user.uid), {
    name,
    email,
    createdAt: Date.now(),
  })
  await appendAudit(name, 'manager_registered', cred.user.uid, null, `manager account created for ${email}`)
}

/** Sign in; ensures the managerAccounts/{uid} document exists. */
export async function loginManager(email: string, password: string): Promise<void> {
  const cred = await signInWithEmailAndPassword(managerAuth, email, password)
  const ref = doc(db, 'managerAccounts', cred.user.uid)
  const snap = await getDoc(ref)
  if (!snap.exists()) {
    await setDoc(ref, {
      name: cred.user.displayName ?? email.split('@')[0] ?? email,
      email,
      createdAt: Date.now(),
    })
  }
}

export function resetManagerPassword(email: string): Promise<void> {
  return sendPasswordResetEmail(managerAuth, email)
}

export function signOutManager(): Promise<void> {
  return signOut(managerAuth)
}

/** Plain-language mapping of the Firebase Auth error codes managers will hit. */
export function authErrorMessage(e: unknown): string {
  const code = (e as { code?: string }).code ?? ''
  switch (code) {
    case 'auth/invalid-credential':
    case 'auth/wrong-password':
    case 'auth/user-not-found':
      return 'Email or password is not recognised.'
    case 'auth/email-already-in-use':
      return 'An account already exists for this email — sign in instead.'
    case 'auth/invalid-email':
      return 'That email address is not valid.'
    case 'auth/weak-password':
      return 'Password must be at least 6 characters.'
    case 'auth/user-disabled':
      return 'This account has been disabled by an administrator.'
    case 'auth/too-many-requests':
      return 'Too many attempts — wait a moment and try again.'
    case 'auth/network-request-failed':
      return 'Could not reach the authentication service — check the connection.'
    default:
      return e instanceof Error ? e.message : 'Sign-in failed.'
  }
}

// ── invitations (invitations/{lowercase-email}, D-012) ─────────────────────

export interface InvitationDoc {
  /** The Firestore document id — the lowercase email (legacy docs: a phone). */
  id: string
  /** Lowercase email the clinician signs in with. Absent on legacy docs. */
  email?: string
  /** Legacy identifier from the removed phone/OTP era. Read-only. */
  phone?: string
  name: string
  role: 'nurse' | 'charge_nurse' | 'manager'
  /** Absent on invitations created before ward assignment existed. */
  wardId?: string
  signatureIdentity: string
  invitedBy: string
  /** Absent on invitations created before this field existed. */
  createdAt?: number
  claimedBy: string | null
}

export function watchInvitations(cb: (rows: InvitationDoc[]) => void): () => void {
  return onSnapshot(
    collection(db, 'invitations'),
    (snap) => {
      const rows = snap.docs.map(
        (d) => ({ ...(d.data() as Omit<InvitationDoc, 'id'>), id: d.id }) as InvitationDoc,
      )
      rows.sort((a, b) => (b.createdAt ?? 0) - (a.createdAt ?? 0))
      cb(rows)
    },
    (err) => console.warn('[afia] invitations snapshot error:', err.message),
  )
}

/**
 * Creates invitations/{lowercase-email} (D-012). The signature identity
 * written here is permanent (§2.5): the deployed rules let a claim fill only
 * `claimedBy`, and no update may touch email, name, role, or
 * signatureIdentity.
 */
export async function createInvitation(
  inv: Omit<InvitationDoc, 'id' | 'phone'> & { email: string },
): Promise<void> {
  const email = inv.email.trim().toLowerCase()
  await setDoc(doc(db, 'invitations', email), { ...inv, email })
  await appendAudit(
    inv.invitedBy,
    'invitation_created',
    email,
    null,
    `invited ${inv.name} (${inv.role}) — signature identity fixed as "${inv.signatureIdentity}"`,
  )
}

// ── patients ───────────────────────────────────────────────────────────────

export interface PatientDoc {
  id: string
  externalIdentifier: string | null
  createdAt: number
  fhirResource: 'Patient'
  name: string
  dateOfBirth: string
  wardId: string
  bed: string
  discharged?: boolean
}

export async function admitPatient(
  p: Omit<PatientDoc, 'id' | 'createdAt' | 'fhirResource' | 'externalIdentifier'>,
  actor: string,
): Promise<string> {
  const id = `pat-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 7)}`
  const patient: PatientDoc = {
    id,
    externalIdentifier: null,
    createdAt: Date.now(),
    fhirResource: 'Patient',
    name: p.name,
    dateOfBirth: p.dateOfBirth,
    wardId: p.wardId,
    bed: p.bed,
    discharged: false,
  }
  await setDoc(doc(db, 'patients', id), patient)
  await appendAudit(actor, 'patient_admitted', id, null, `${p.name} — bed ${p.bed}`)
  return id
}

/** Update is the only mutation — the rules forbid deleting a patient record. */
export async function updatePatient(
  id: string,
  patch: Partial<Pick<PatientDoc, 'name' | 'dateOfBirth' | 'bed' | 'wardId' | 'discharged'>>,
  actor: string,
  previous: unknown,
): Promise<void> {
  await updateDoc(doc(db, 'patients', id), patch)
  await appendAudit(
    actor,
    'patient_updated',
    id,
    previous,
    Object.entries(patch)
      .map(([k, v]) => `${k} → ${String(v)}`)
      .join(', '),
  )
}

// ── ward configuration ─────────────────────────────────────────────────────

export async function updateWardCommitment(
  wardId: string,
  committedReviewMinutes: number,
  reviewOwner: string,
  actor: string,
  previous: unknown,
): Promise<void> {
  await updateDoc(doc(db, 'wards', wardId), { committedReviewMinutes, reviewOwner })
  await appendAudit(
    actor,
    'ward_config_edited',
    wardId,
    previous,
    `committed review time ${committedReviewMinutes} min · owner ${reviewOwner}`,
  )
}

// ── audit (append-only; update/delete are denied by the rules) ─────────────

async function appendAudit(
  actor: string,
  action: string,
  entityId: string,
  previousValue: unknown,
  detail: string | null,
): Promise<void> {
  const id = `audit-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`
  try {
    await setDoc(doc(db, 'audit', id), {
      id,
      at: Date.now(),
      actor,
      action,
      entityId,
      previousValue: previousValue ?? null,
      detail,
    })
  } catch (e) {
    // The admin action itself succeeded; an audit write failure is logged, not fatal.
    console.warn('[afia] audit append failed:', e)
  }
}
