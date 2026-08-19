import {
  detectGaps,
  extractChips,
  type AnswerState,
  type FieldContent,
  type FormularyEntry,
  type FunctionalQuestion,
  type RedFlagQuestion,
  type TemplateField,
} from '@afia/rules'
import type { AuditEvent } from './audit'
import type { PatientCase } from './case'
import type {
  ConsentRecord,
  Patient,
  PlatformConfig,
  Practitioner,
  SignInEvent,
  Ward,
} from './entities'
import type { ConfirmableChip, Handover, HandoverFlag } from './handover'
import type { SeedData, TemplateVersion } from './store'

/**
 * SYNTHETIC DEMO DATA — every record in this file is invented. No real
 * patient, clinician, or hospital appears here. The seed is built with the
 * real rules functions (extractChips, detectGaps) so demo data is internally
 * consistent with what the system would actually produce.
 */

// ── playable synthetic audio (§2.6 requires audio that actually plays) ─────

/** A soft two-tone chime as a WAV data URI — genuinely playable, tiny, synthetic. */
export function synthDemoAudio(durationSec = 2): { url: string; durationSec: number } {
  const rate = 8000
  const samples = Math.floor(rate * durationSec)
  const data = new Int16Array(samples)
  for (let i = 0; i < samples; i++) {
    const t = i / rate
    const freq = t < durationSec / 2 ? 392 : 330
    const envelope = Math.exp(-1.5 * (t % (durationSec / 2)))
    data[i] = Math.round(Math.sin(2 * Math.PI * freq * t) * envelope * 12000)
  }
  const buffer = new ArrayBuffer(44 + data.length * 2)
  const view = new DataView(buffer)
  const writeStr = (offset: number, s: string) => {
    for (let i = 0; i < s.length; i++) view.setUint8(offset + i, s.charCodeAt(i))
  }
  writeStr(0, 'RIFF')
  view.setUint32(4, 36 + data.length * 2, true)
  writeStr(8, 'WAVE')
  writeStr(12, 'fmt ')
  view.setUint32(16, 16, true)
  view.setUint16(20, 1, true)
  view.setUint16(22, 1, true)
  view.setUint32(24, rate, true)
  view.setUint32(28, rate * 2, true)
  view.setUint16(32, 2, true)
  view.setUint16(34, 16, true)
  writeStr(36, 'data')
  view.setUint32(40, data.length * 2, true)
  for (let i = 0; i < data.length; i++) view.setInt16(44 + i * 2, data[i] as number, true)

  const bytes = new Uint8Array(buffer)
  let binary = ''
  for (let i = 0; i < bytes.length; i += 8192) {
    binary += String.fromCharCode(...bytes.subarray(i, i + 8192))
  }
  const base64 =
    typeof btoa === 'function'
      ? btoa(binary)
      : Buffer.from(binary, 'binary').toString('base64')
  return { url: `data:audio/wav;base64,${base64}`, durationSec }
}

// ── formulary with sound-alike clusters (§4.4) ─────────────────────────────

export const SEED_FORMULARY: FormularyEntry[] = [
  { id: 'drug-furosemide', name: 'furosemide', soundAlikeGroup: 'furo-fluo' },
  { id: 'drug-fluoxetine', name: 'fluoxetine', soundAlikeGroup: 'furo-fluo' },
  { id: 'drug-hydroxyzine', name: 'hydroxyzine', soundAlikeGroup: 'hydro' },
  { id: 'drug-hydralazine', name: 'hydralazine', soundAlikeGroup: 'hydro' },
  { id: 'drug-metformin', name: 'metformin', soundAlikeGroup: 'met' },
  { id: 'drug-metronidazole', name: 'metronidazole', soundAlikeGroup: 'met' },
  { id: 'drug-clonidine', name: 'clonidine', soundAlikeGroup: 'clo' },
  { id: 'drug-clozapine', name: 'clozapine', soundAlikeGroup: 'clo' },
  { id: 'drug-tramadol', name: 'tramadol', soundAlikeGroup: 'tra' },
  { id: 'drug-trazodone', name: 'trazodone', soundAlikeGroup: 'tra' },
  { id: 'drug-prednisone', name: 'prednisone', soundAlikeGroup: 'pred' },
  { id: 'drug-prednisolone', name: 'prednisolone', soundAlikeGroup: 'pred' },
  { id: 'drug-amlodipine', name: 'amlodipine', soundAlikeGroup: 'aml' },
  { id: 'drug-amiloride', name: 'amiloride', soundAlikeGroup: 'aml' },
  { id: 'drug-paracetamol', name: 'paracetamol', soundAlikeGroup: null },
  { id: 'drug-ibuprofen', name: 'ibuprofen', soundAlikeGroup: null },
  { id: 'drug-morphine', name: 'morphine', soundAlikeGroup: null },
  { id: 'drug-amoxicillin', name: 'amoxicillin', soundAlikeGroup: null },
  { id: 'drug-enoxaparin', name: 'enoxaparin', soundAlikeGroup: null },
  { id: 'drug-bisoprolol', name: 'bisoprolol', soundAlikeGroup: null },
  { id: 'drug-atorvastatin', name: 'atorvastatin', soundAlikeGroup: null },
  { id: 'drug-omeprazole', name: 'omeprazole', soundAlikeGroup: null },
  { id: 'drug-salbutamol', name: 'salbutamol', soundAlikeGroup: null },
  { id: 'drug-insulin', name: 'insulin', soundAlikeGroup: null },
]

// ── template (§5 screen 13 / §7 Templates) ─────────────────────────────────

export const SEED_TEMPLATE: TemplateField[] = [
  { id: 'situation', label: 'Situation', required: true, keywords: ['situation', 'admitted', 'presenting', 'diagnosis', 'day'] },
  { id: 'background', label: 'Background', required: true, keywords: ['background', 'history', 'previous', 'known'] },
  { id: 'medications', label: 'Medications given', required: true, keywords: ['medication', 'given', 'dose', 'administered', 'mg', 'due'] },
  { id: 'vitals', label: 'Latest vitals', required: true, keywords: ['vitals', 'obs', 'blood pressure', 'bp', 'heart rate', 'temp', 'sats', 'news'] },
  { id: 'pain', label: 'Pain', required: true, keywords: ['pain', 'analgesia', 'comfortable', 'score'] },
  { id: 'mobility', label: 'Mobility & falls', required: false, keywords: ['mobility', 'mobilising', 'falls', 'walking', 'frame', 'bed rest'] },
  { id: 'diet', label: 'Diet & fluids', required: false, keywords: ['diet', 'eating', 'drinking', 'fluids', 'nil by mouth', 'intake'] },
  { id: 'plan', label: 'Plan for next shift', required: true, keywords: ['plan', 'review', 'chase', 'due', 'tomorrow', 'overnight', 'monitor'] },
  { id: 'family', label: 'Family communication', required: false, keywords: ['family', 'daughter', 'son', 'wife', 'husband', 'next of kin', 'spoke'] },
]

// ── clinical rules (§7 Questions — approval records) ───────────────────────

const APPROVED = (by: string, at: number) => ({ approvedBy: by, role: 'Clinical Governance Lead', approvedAt: at })

export const SEED_RED_FLAGS: RedFlagQuestion[] = [
  { id: 'rf-chest-pain', text: 'Do you have chest pain or chest pressure right now?', approval: APPROVED('Dr T. Mensah', 1755000000000) },
  { id: 'rf-breathless', text: 'Are you so breathless you cannot finish a sentence?', approval: APPROVED('Dr T. Mensah', 1755000000000) },
  { id: 'rf-bleeding', text: 'Do you have bleeding that will not stop?', approval: APPROVED('Dr T. Mensah', 1755000000000) },
  { id: 'rf-confusion', text: 'Has someone with you become confused or hard to wake?', approval: APPROVED('Dr T. Mensah', 1755000000000) },
  { id: 'rf-faint', text: 'Have you fainted or blacked out today?', approval: null }, // unapproved → caution state in dashboard
]

export const SEED_FUNCTIONAL: FunctionalQuestion[] = [
  { id: 'fn-eating', text: 'Compared with your normal, how is your eating and drinking?', approval: APPROVED('Dr T. Mensah', 1755000000000) },
  { id: 'fn-mobility', text: 'Compared with your normal, how is your moving around?', approval: APPROVED('Dr T. Mensah', 1755000000000) },
  { id: 'fn-breathing', text: 'Compared with your normal, how is your breathing?', approval: APPROVED('Dr T. Mensah', 1755000000000) },
  { id: 'fn-sleep', text: 'Compared with your normal, how are you sleeping?', approval: APPROVED('Dr T. Mensah', 1755000000000) },
]

// ── seed build ─────────────────────────────────────────────────────────────

export function makeSeed(): SeedData {
  const now = Date.now()
  const min = 60_000
  const audioA = synthDemoAudio(2)
  const audioB = synthDemoAudio(3)

  const wards: Ward[] = [
    { id: 'ward-a', externalIdentifier: null, createdAt: now - 400 * min, name: 'Ward A — Acute Medical', committedReviewMinutes: 30, reviewOwner: 'CN Amara Okafor' },
    { id: 'ward-b', externalIdentifier: null, createdAt: now - 400 * min, name: 'Ward B — Surgical', committedReviewMinutes: 45, reviewOwner: 'CN Daniel Reyes' },
  ]

  const practitioners: Practitioner[] = [
    { id: 'prac-amara', externalIdentifier: null, createdAt: now - 300 * min, fhirResource: 'Practitioner', name: 'Amara Okafor', role: 'charge_nurse', signatureIdentity: 'RN 88-1042 · Amara Okafor', invitedBy: 'system-demo' },
    { id: 'prac-jonas', externalIdentifier: null, createdAt: now - 300 * min, fhirResource: 'Practitioner', name: 'Jonas Berg', role: 'nurse', signatureIdentity: 'RN 88-2210 · Jonas Berg', invitedBy: 'prac-amara' },
    { id: 'prac-leila', externalIdentifier: null, createdAt: now - 300 * min, fhirResource: 'Practitioner', name: 'Leila Haddad', role: 'nurse', signatureIdentity: 'RN 88-3377 · Leila Haddad', invitedBy: 'prac-amara' },
    { id: 'prac-omar', externalIdentifier: null, createdAt: now - 300 * min, fhirResource: 'Practitioner', name: 'Omar Sy', role: 'manager', signatureIdentity: 'MGR 88-0007 · Omar Sy', invitedBy: 'system-demo' },
  ]

  const patientDefs: Array<[string, string, string]> = [
    ['Rosa Almeida', '1948-03-12', 'A1'],
    ['Harold Finch', '1939-11-02', 'A2'],
    ['Yuki Tanaka', '1957-07-24', 'A3'],
    ['Samuel Osei', '1970-01-30', 'A4'],
    ['Margaret Doyle', '1944-09-17', 'A5'],
    ['Ivan Petrov', '1962-05-08', 'A6'],
    ['Fatima Zahra', '1980-12-01', 'A7'],
    ['George Papadopoulos', '1951-04-19', 'A8'],
    ['Ana Sousa', '1966-08-27', 'A9'],
    ['Chen Wei', '1975-02-14', 'A10'],
    ['Elena Vasquez', '1958-10-05', 'A11'],
    ['Kwame Mensah', '1943-06-21', 'A12'],
  ]
  const patients: Patient[] = patientDefs.map(([name, dob, bed], i) => ({
    id: `pat-${i + 1}`,
    externalIdentifier: null,
    createdAt: now - 200 * min,
    fhirResource: 'Patient',
    name,
    dateOfBirth: dob,
    wardId: 'ward-a',
    bed,
  }))

  // Received handover for Rosa Almeida (signed by night shift, chips confirmed).
  const transcriptA =
    'Rosa Almeida, day three after her chest infection admission. She had furosemide 40 mg IV this morning and her regular bisoprolol 2.5 mg. Latest obs at six: blood pressure 110/70, sats 94% on two litres. Pain controlled with paracetamol 1 g. She is mobilising to the chair with one. Plan is to chase the repeat chest x-ray and wean oxygen as tolerated. Daughter called overnight and was updated.'
  const fieldsA: FieldContent[] = [
    { fieldId: 'situation', text: 'Day 3 of chest infection admission.' },
    { fieldId: 'background', text: 'Admitted with community-acquired chest infection.' },
    { fieldId: 'medications', text: 'furosemide 40 mg IV given this morning; regular bisoprolol 2.5 mg.' },
    { fieldId: 'vitals', text: 'BP 110/70 · sats 94% on 2 L · taken 06:00.' },
    { fieldId: 'pain', text: 'Controlled with paracetamol 1 g.' },
    { fieldId: 'mobility', text: 'Mobilising to chair with assistance of one.' },
    { fieldId: 'diet', text: '' },
    { fieldId: 'plan', text: 'Chase repeat chest x-ray; wean oxygen as tolerated.' },
    { fieldId: 'family', text: 'Daughter updated overnight.' },
  ]
  const chipsA: ConfirmableChip[] = extractChips(transcriptA, SEED_FORMULARY).map((c) => ({
    ...c,
    confirmedBy: 'prac-leila',
    confirmedAt: now - 95 * min,
    correctedTo: null,
  }))
  const gapsA = detectGaps(SEED_TEMPLATE, fieldsA)
  const flagsA: HandoverFlag[] = gapsA.map((g, i) => ({
    ...g,
    id: `flag-a-${i}`,
    state: 'acknowledged_in_signing' as const,
    signingNote: 'Night shift — intake chart with HCA, to be filed at breakfast round.',
  }))

  const handoverReceived: Handover = {
    id: 'hand-received-1',
    externalIdentifier: null,
    createdAt: now - 100 * min,
    fhirResource: 'DocumentReference',
    patientId: 'pat-1',
    authorId: 'prac-leila',
    status: 'confirmed_in_system',
    audio: { id: 'audio-1', url: audioA.url, mimeType: 'audio/wav', durationSec: audioA.durationSec, recordedAt: now - 100 * min },
    transcript: transcriptA,
    fields: fieldsA,
    chips: chipsA,
    flags: flagsA,
    signature: {
      practitionerId: 'prac-leila',
      signatureIdentity: 'RN 88-3377 · Leila Haddad',
      signedAt: now - 94 * min,
      openFlagReason: 'Night shift — intake chart with HCA, to be filed at breakfast round.',
    },
    version: 1,
    supersedes: null,
    supersededBy: null,
    exportError: null,
    acknowledgedAt: now - 93 * min,
  }

  // A second received handover, still unreviewed, with an open flag + low-confidence drug chip.
  const transcriptB =
    'Harold Finch, admitted yesterday with fast AF. He is on bisoprolol 5 mg and we started enoxaparin 60 mg this evening. Heart rate 92 at last check, blood pressure 128/84. He was given tramadol 50 mg for his back pain at eight. Plan overnight: repeat ECG if the rate climbs over 110 and keep him on the monitor.'
  const fieldsB: FieldContent[] = [
    { fieldId: 'situation', text: 'Admitted yesterday with fast AF.' },
    { fieldId: 'background', text: '' },
    { fieldId: 'medications', text: 'bisoprolol 5 mg; enoxaparin 60 mg started this evening; tramadol 50 mg at 20:00.' },
    { fieldId: 'vitals', text: 'HR 92 · BP 128/84.' },
    { fieldId: 'pain', text: 'Back pain, settled after tramadol 50 mg.' },
    { fieldId: 'plan', text: 'Repeat ECG if HR > 110; continuous monitoring overnight.' },
  ]
  const chipsB: ConfirmableChip[] = extractChips(transcriptB, SEED_FORMULARY).map((c) => ({
    ...c,
    confirmedBy: 'prac-jonas',
    confirmedAt: now - 55 * min,
    correctedTo: null,
  }))
  const gapsB = detectGaps(SEED_TEMPLATE, fieldsB)
  const flagsB: HandoverFlag[] = gapsB.map((g, i) => ({
    ...g,
    id: `flag-b-${i}`,
    state: 'acknowledged_in_signing' as const,
    signingNote: 'Background in yesterday’s clerking — not re-dictated.',
  }))

  const handoverReceived2: Handover = {
    id: 'hand-received-2',
    externalIdentifier: null,
    createdAt: now - 60 * min,
    fhirResource: 'DocumentReference',
    patientId: 'pat-2',
    authorId: 'prac-jonas',
    status: 'signed',
    audio: { id: 'audio-2', url: audioB.url, mimeType: 'audio/wav', durationSec: audioB.durationSec, recordedAt: now - 60 * min },
    transcript: transcriptB,
    fields: fieldsB,
    chips: chipsB,
    flags: flagsB,
    signature: {
      practitionerId: 'prac-jonas',
      signatureIdentity: 'RN 88-2210 · Jonas Berg',
      signedAt: now - 54 * min,
      openFlagReason: 'Background in yesterday’s clerking — not re-dictated.',
    },
    version: 1,
    supersedes: null,
    supersededBy: null,
    exportError: null,
    acknowledgedAt: null,
  }

  // An export failure the shift board + dashboard must surface (§5, §7).
  const handoverFailed: Handover = {
    ...handoverReceived2,
    id: 'hand-failed-1',
    patientId: 'pat-3',
    authorId: 'prac-leila',
    createdAt: now - 40 * min,
    status: 'export_failed',
    audio: { id: 'audio-3', url: audioA.url, mimeType: 'audio/wav', durationSec: audioA.durationSec, recordedAt: now - 40 * min },
    signature: {
      practitionerId: 'prac-leila',
      signatureIdentity: 'RN 88-3377 · Leila Haddad',
      signedAt: now - 38 * min,
      openFlagReason: null,
    },
    flags: [],
    exportError: 'Receiving system did not acknowledge within 60 s (demo simulation).',
    acknowledgedAt: null,
  }

  // Patient-app cases for the dashboard queue. Ward A commits to 30 min review.
  const mkCase = (
    id: string,
    patientName: string,
    minutesAgo: number,
    opts: { redFlagYes?: boolean; muchWorse?: boolean; unknowns?: boolean; sent?: boolean },
  ): PatientCase => {
    const at = now - minutesAgo * min
    const redFlagAnswers = SEED_RED_FLAGS.map((q): { questionId: string; answer: AnswerState } => ({
      questionId: q.id,
      answer:
        opts.redFlagYes === true && q.id === 'rf-breathless'
          ? 'YES'
          : opts.unknowns === true && q.id === 'rf-faint'
            ? 'UNKNOWN'
            : 'NO',
    }))
    const triggeredBy = redFlagAnswers.filter((a) => a.answer === 'YES').map((a) => a.questionId)
    const unanswered = redFlagAnswers.filter((a) => a.answer === 'UNKNOWN' || a.answer === 'NOT_ASKED').map((a) => a.questionId)
    return {
      id,
      externalIdentifier: null,
      createdAt: at,
      patientName,
      completedBy: 'self',
      status: 'submitted',
      priority: opts.redFlagYes === true ? 'urgent' : opts.muchWorse === true ? 'elevated' : 'routine',
      consentId: `consent-${id}`,
      updates: [
        {
          id: `${id}-u1`,
          at,
          kind: 'initial',
          transcript:
            opts.redFlagYes === true
              ? 'I have been getting more and more breathless since this morning and I cannot finish a sentence without stopping.'
              : 'My symptoms have been building for two days. I have been feverish, off my food, and I feel weaker than my usual self.',
          audio: null,
          redFlagAnswers,
          redFlags: { triggered: triggeredBy.length > 0, triggeredBy, unanswered },
          functionalAnswers: SEED_FUNCTIONAL.map((q) => ({
            questionId: q.id,
            value:
              opts.muchWorse === true && q.id === 'fn-eating'
                ? ('MUCH_WORSE' as const)
                : opts.unknowns === true && q.id === 'fn-sleep'
                  ? ('UNKNOWN' as const)
                  : ('WORSE' as const),
          })),
          syncState: opts.sent === false ? ('queued_on_device' as const) : ('sent' as const),
        },
      ],
    }
  }

  const cases: PatientCase[] = [
    mkCase('case-1', 'Priya N.', 52, { muchWorse: true }), // breach: > 30 min committed
    mkCase('case-2', 'Tom H.', 41, { unknowns: true }), // breach
    mkCase('case-3', 'Aisha B.', 24, { redFlagYes: true }), // urgent but NOT sorted ahead — queue is wait-time only
    mkCase('case-4', 'Marco D.', 12, {}),
    mkCase('case-5', 'Grace O.', 6, { unknowns: true }),
    mkCase('case-6', 'Lena K.', 2, { sent: false }),
  ]

  const consents: ConsentRecord[] = cases.map((c) => ({
    id: `consent-${c.id}`,
    externalIdentifier: null,
    createdAt: c.createdAt,
    subjectId: c.id,
    scope: 'symptom_submission',
    grantedAt: c.createdAt,
    withdrawnAt: null,
  }))

  const templateVersions: TemplateVersion[] = [
    { version: 1, fields: SEED_TEMPLATE.map((f) => ({ ...f, keywords: [...f.keywords] })), editedBy: 'Omar Sy', at: now - 300 * min },
  ]

  const signInLog: SignInEvent[] = [
    { id: 'si-1', practitionerId: 'prac-leila', at: now - 110 * min, kind: 'sign_in', device: 'Ward A tablet 1' },
    { id: 'si-2', practitionerId: 'prac-leila', at: now - 50 * min, kind: 'sign_out', device: 'Ward A tablet 1' },
    { id: 'si-3', practitionerId: 'prac-amara', at: now - 45 * min, kind: 'sign_in', device: 'Ward A tablet 1' },
  ]

  const config: PlatformConfig = {
    audioRetentionDays: 30,
    audioRetentionNote:
      'PROVISIONAL demo policy: recordings retained 30 days, accessible to the authoring and receiving clinicians only, then deleted. A real deployment sets this with governance sign-off.',
    dataResidency: 'undecided',
    syntheticDemo: true,
  }

  const auditEvents: AuditEvent[] = [
    { id: 'ae-1', at: now - 100 * min, actor: 'prac-leila', action: 'created', entityId: 'hand-received-1', previousValue: null, detail: null },
    { id: 'ae-2', at: now - 100 * min, actor: 'prac-leila', action: 'recorded', entityId: 'hand-received-1', previousValue: null, detail: 'recording started' },
    { id: 'ae-3', at: now - 96 * min, actor: 'prac-leila', action: 'structured', entityId: 'hand-received-1', previousValue: null, detail: null },
    { id: 'ae-4', at: now - 95 * min, actor: 'prac-leila', action: 'flagged', entityId: 'hand-received-1', previousValue: null, detail: 'Not mentioned: Diet & fluids' },
    { id: 'ae-5', at: now - 94 * min, actor: 'prac-leila', action: 'signed', entityId: 'hand-received-1', previousValue: null, detail: 'v1 signed as RN 88-3377 · Leila Haddad' },
    { id: 'ae-6', at: now - 93 * min, actor: 'system', action: 'confirmed', entityId: 'hand-received-1', previousValue: 'queued', detail: 'positive acknowledgement received' },
    { id: 'ae-7', at: now - 38 * min, actor: 'prac-leila', action: 'signed', entityId: 'hand-failed-1', previousValue: null, detail: 'v1 signed as RN 88-3377 · Leila Haddad' },
    { id: 'ae-8', at: now - 37 * min, actor: 'system', action: 'export_failed', entityId: 'hand-failed-1', previousValue: 'queued', detail: 'Receiving system did not acknowledge within 60 s (demo simulation).' },
    { id: 'ae-9', at: now - 52 * min, actor: 'Priya N.', action: 'case_submitted', entityId: 'case-1', previousValue: null, detail: null },
    { id: 'ae-10', at: now - 24 * min, actor: 'rules', action: 'escalated', entityId: 'case-3', previousValue: 'routine', detail: 'priority routine → urgent (one-way)' },
  ]

  return {
    patients,
    practitioners,
    wards,
    handovers: [handoverReceived, handoverReceived2, handoverFailed],
    cases,
    consents,
    formulary: SEED_FORMULARY,
    templateVersions,
    redFlagQuestions: SEED_RED_FLAGS,
    functionalQuestions: SEED_FUNCTIONAL,
    wellbeingScores: {
      'ward-a': [4, 3, 4, 2, 5, 3, 4], // n=7 → shown
      'ward-b': [2, 3, 4], // n=3 → suppressed
    },
    signInLog,
    config,
    auditEvents,
  }
}

/**
 * Amendment A1.1 — real-use posture: cloud-backed stores start EMPTY and fill
 * from server snapshots. Configuration (wards/formulary/template/questions)
 * lives in Firestore; no fake clinical records exist locally or remotely.
 */
export function emptySeed(): SeedData {
  return {
    patients: [],
    practitioners: [],
    wards: [],
    handovers: [],
    cases: [],
    consents: [],
    formulary: [],
    templateVersions: [],
    redFlagQuestions: [],
    functionalQuestions: [],
    wellbeingScores: {},
    signInLog: [],
    config: {
      audioRetentionDays: 30,
      audioRetentionNote:
        'PROVISIONAL pilot policy: recordings retained 30 days, accessible to the authoring and receiving clinicians only, then deleted. Confirm with governance before wider deployment.',
      dataResidency: 'undecided',
      syntheticDemo: true,
    },
    auditEvents: [],
  }
}
