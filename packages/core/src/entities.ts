/**
 * HANDOFF §3.1 — FHIR-shaped from day one. Same fields, FHIR's names, so a
 * later integration is an exporter, not a migration. Every entity carries
 * `externalIdentifier` (the future hospital MRN link) — empty for now.
 */

export interface BaseEntity {
  id: string
  /** Links a local record to a hospital identifier (MRN etc.). Empty until integration. */
  externalIdentifier: string | null
  createdAt: number
}

/** FHIR `Patient` */
export interface Patient extends BaseEntity {
  fhirResource: 'Patient'
  name: string
  dateOfBirth: string
  wardId: string
  bed: string
}

/** FHIR `Practitioner` */
export interface Practitioner extends BaseEntity {
  fhirResource: 'Practitioner'
  name: string
  role: 'nurse' | 'doctor' | 'charge_nurse' | 'manager'
  /**
   * HANDOFF §2.5 — signature identity is immutable: set here at account
   * creation from the invitation, readonly thereafter. No API mutates it.
   */
  readonly signatureIdentity: string
  invitedBy: string
}

/** FHIR `Encounter` */
export interface Encounter extends BaseEntity {
  fhirResource: 'Encounter'
  patientId: string
  wardId: string
  admittedAt: number
  reason: string
}

export interface Ward extends BaseEntity {
  name: string
  /** HANDOFF §7 Wards — the committed review time the breach alert measures against. */
  committedReviewMinutes: number
  /** The named owner of that commitment. */
  reviewOwner: string
}

/**
 * HANDOFF §3.3 — consent is its own timestamped, withdrawable record,
 * separate from terms acceptance.
 */
export interface ConsentRecord extends BaseEntity {
  subjectId: string
  scope: 'symptom_submission' | 'audio_recording'
  grantedAt: number
  withdrawnAt: number | null
}

export interface TermsAcceptance extends BaseEntity {
  subjectId: string
  version: string
  acceptedAt: number
}

export interface SignInEvent {
  id: string
  practitionerId: string
  at: number
  kind: 'sign_in' | 'sign_out'
  device: string
}

/** HANDOFF §3.3 — decide the retention fields now, even provisionally. */
export interface PlatformConfig {
  audioRetentionDays: number
  audioRetentionNote: string
  /** Must be decided before any real deployment; permanent once chosen (§8). */
  dataResidency: 'undecided'
  syntheticDemo: true
}
