# Engineering Handoff — Clinical Handover Platform

> For Claude Code. Design and product decisions are complete. This document is what an engineer needs to build the right thing and avoid the failures that matter.

---

## 1. What this is

A clinical handover platform with **three surfaces** sharing one backend:

| Surface | User | Platform |
|---|---|---|
| **Clinician app** | Nurses and doctors recording shift handovers by voice | Mobile |
| **Patient app** | People describing symptoms before attending, at home | Mobile |
| **Admin dashboard** | Nursing managers — monitoring and configuration | Desktop web |

**The core mechanic, identical in both mobile apps:** a person speaks naturally → the system transcribes and structures the speech into a configured template → it flags what was not covered → a licensed human reviews, edits, and signs → the signed record is exported.

**One sentence that governs the whole system:** the AI reorganises information that a human already provided. It never produces a clinical judgement.

### Current stage

This is a **hackathon demonstration**, not a hospital deployment. Build the architecture correctly, but do not build compliance infrastructure (formal QMS, regulatory documentation, real EMR integration) yet.

**All data is synthetic.** A persistent `SYNTHETIC DEMO DATA` label must be visible in every surface.

Real patients and real clinicians must not use this build. Several safety questions remain unresolved (§9).

---

## 2. Non-negotiable engineering constraints

⚠️ **These must be structurally impossible in code, not merely absent from the UI.** A future developer under deadline pressure will try to add each one. Make them impossible.

### 2.1 Escalation is one-way

No code path may lower a priority, dismiss a flag, or downgrade a case.

- No `decreasePriority`, no `dismissFlag`, no `markAsNormal`
- A patient's answer, a context response, a device reading, or a later update may raise urgency or annotate. Never reduce it.
- Enforce at the data-model level, not in the UI layer.

**Why:** a false-negative here kills someone. There is no acceptable ergonomic reason to allow a downgrade.

### 2.2 Absent is not normal

Missing, skipped, unanswered, or low-confidence data is stored as **`unknown`** — a distinct value from a normal reading and from a negative answer.

```
enum AnswerState { YES, NO, UNKNOWN, NOT_ASKED }
```

Never coerce `UNKNOWN` to `NO` or to a default. `UNKNOWN` never reduces priority.

### 2.3 No bulk confirmation

Drug names and numeric values in a draft require **individual** confirmation before signing.

- No `confirmAll` endpoint. No API that accepts an array of confirmations in one action.
- Signing is blocked until every drug and number chip is individually confirmed.
- This is the **only** hard block in the clinician app.

**Why:** a sound-alike drug substitution (furosemide/fluoxetine) is the most dangerous failure this system can produce. This layer is the only interception.

### 2.4 Omission flags never block signing

The opposite rule. Unresolved gaps must **never** prevent a signature.

- Signing with open flags is permitted, with a one-tap reason recorded
- Flags export visibly with the note
- Blocking here was tested and produces fabricated content — nurses invent information to escape the block

**The distinction to preserve:** wrong data kills, missing data is documented and passed on.

### 2.5 Signature identity is immutable

Set at account creation from the invitation. Not editable by the user, not editable through any API the user can reach.

Post-signature edits invalidate the signature and require explicit re-signing. The original is never overwritten — store both versions and both signatures.

### 2.6 Raw audio is stored and transmitted

The original recording is persisted and delivered to the reviewing clinician **intact and playable**. Never transcript-only.

This is a hard requirement, not an optimisation. The clinician's ability to hear the actual voice is the product's main advantage over a form.

### 2.7 Emergency escalation is local and deterministic

In the patient app, red-flag detection is a **local rule evaluated on-device**. No network call, no model inference, no server round-trip.

- Must work in airplane mode — make this a test case
- Emergency numbers bundled at install
- The emergency control renders outside the app's view hierarchy so it can never be occluded by a keyboard, a recording overlay, or a loading state

### 2.8 Gap detection is rules, not a model

"Is the medication field empty?" is a schema check against the configured template. Implement it as deterministic rules.

**Why:** a model produces non-deterministic output — you cannot unit-test it, cannot reproduce it, cannot demonstrate it to a regulator. Rules are auditable.

### 2.9 No individual performance data

No endpoint, no collection, no aggregation of per-clinician speed, volume, or ranking. Not stored, not computed, not exposed.

Staff wellbeing responses are aggregate and anonymous only, suppressed below five responses.

### 2.10 The queue is never risk-ordered

The triage queue sorts by **wait time and file completeness only**. Never by severity, urgency, or any computed risk score.

Ordering by risk is triage performed by software, which is the regulatory line this entire architecture exists to stay behind.

---

## 3. Data model

### 3.1 Shape it to FHIR now

Cost today is near zero — the same fields with different names. Cost of retrofitting later is a full migration.

| Entity | FHIR resource |
|---|---|
| Patient | `Patient` |
| Handover note | `DocumentReference` |
| Clinician | `Practitioner` |
| Admission | `Encounter` |
| Signature | `authenticator` + `Provenance` |

⚠️ **Every entity carries an `externalIdentifier` field from day one.** Empty for now. This is what will link a local record to a hospital MRN. Adding it now is one line; adding it after launch is a data migration.

### 3.2 Export abstraction

```
interface ExportTarget {
  export(handover: Handover): ExportResult
}

ClipboardExporter   // the only one actually implemented
FhirExporter        // generates valid DocumentReference JSON, displays it, sends nothing
Hl7v2Exporter       // stub
PdfExporter         // later
```

The system produces **one internal representation**. Exporters translate. Adding a hospital later means writing one exporter, not touching the core.

**Build the FHIR generator for real** — it produces valid `DocumentReference` JSON viewable in the UI. It costs hours and it demonstrates integration readiness convincingly.

⚠️ Never claim "integrated with Epic" or "FHIR-integrated". The accurate phrase is **FHIR-ready**.

### 3.3 Schema decisions that are expensive to reverse

- **Consent record** — separate from terms acceptance, timestamped, withdrawable
- **Audio retention policy** — how long, who can access, when deleted. Decide the field now even if the policy is provisional.
- **Data residency** — Firebase region must match the target health system's jurisdiction. This is effectively permanent.
- **Selective deletion** — a patient may request erasure. A schema that makes this hard will need rewriting.

### 3.4 Audit trail

Every state transition is recorded and immutable: created, recorded, transcribed, structured, flagged, corrected, signed, exported, confirmed, superseded.

Store actor, timestamp, and previous value. Never update in place.

---

## 4. The AI layer

### 4.1 Pipeline

```
audio → transcription → structuring → rule-based gap detection → human review → signature → export
```

Each stage is independent and replaceable. The inference layer must be swappable without rewriting business logic — a hospital may later require a locally hosted model.

### 4.2 Safe — build these

All are **reorganisation of information a human already provided**:

- Speech to text
- Free speech into template fields
- Ten-second summary generation for the reader
- Diff against the previous handover — what changed
- Routing a side note to its correct field
- Merging interrupted recording segments in order
- Generating FHIR JSON

### 4.3 Forbidden — do not build

Each produces a **new clinical judgement**:

- Severity, urgency, or priority classification
- "This case needs emergency care"
- Diagnosis or medication suggestion
- Weighting which symptoms are concerning
- ⚠️ Even: ranking which missing information is *important* — importance is a clinical judgement

**The distinction in output text:**

- ✅ `Not mentioned: time of last analgesia`
- ❌ `Critical information missing`

### 4.4 Drug name safety layer

Mandatory, and the highest-value component in the system:

```
transcription output
  → fuzzy match against hospital formulary
  → high confidence: render as confirmable chip
  → low confidence: render as chip flagged for review
  → no match: render as chip requiring explicit confirmation
```

Correction is **recognition, never recall** — a searchable formulary picker with sound-alike pairs displayed together, plus audio replay. Never free-text spelling. Never re-speak-only, since a recogniser that failed once fails identically.

### 4.5 Transcription

`faster-whisper` (Large V3) is the default. Roughly 10GB VRAM, four times faster than baseline Whisper at equivalent quality.

⚠️ **Accuracy on accented, code-switched, noisy ward speech is unvalidated and is the single largest technical risk in the project.** Before optimising anything else, measure word error rate on drug names specifically, using real recordings.

For structuring, a fine-tuned 8B model is sufficient and runs on a single consumer GPU. Frontier models are for generating training data, not for deployment.

---

## 5. Clinician app

**Navigation:** four tabs — `Patients` · `Received` · `Shift` · `Account`

No home screen. `Patients` is home. No login screen — SSO. Accounts created by invitation only.

### Screens

| # | Screen | Notes |
|---|---|---|
| 1 | Ward list | **12 rows on one screen, no scroll.** Solve first — the row height constrains everything else. |
| 2 | Patient detail | Vitals in tabular mono |
| 3 | Recording | Near-empty. Auto-checkpoint continuously. |
| 4 | Draft review | Unverified text in periwinkle; signed in indigo |
| 5 | Confirmation layer | The only hard block |
| 6 | Correction picker | Formulary search, sound-alikes clustered |
| 7 | Sign sheet | Hold-to-sign; flags never block |
| 8 | Incoming list | |
| 9 | Received handover | Flags inline, never behind an expand |
| 10 | Shift board | Signature and export state for all patients |
| 11 | Shift complete | Warm palette, appears once |
| 12 | Account | **Sign out is prominent** — ward devices are shared |
| 13 | Template | Role-gated |

### Row states

`not_started` · `recording` · `draft_ready` · `signed` · `queued` · `confirmed_in_system` · `export_failed`

⚠️ **`signed` and `confirmed_in_system` are distinct.** A nurse must see whether the hospital system actually received it. Collapsing them hides the failure the product exists to prevent.

### Engineering requirements

- Offline-first. Recordings persist locally before any network attempt.
- Auto-checkpoint every few seconds — putting the device down must be safe
- Reopen goes directly to the interrupted draft, never to a home screen
- 56px minimum touch targets (gloves)
- Export fires automatically on signature, never a manual button
- Export confirmation requires **positive acknowledgement** from the receiving system — never local send-completion

---

## 6. Patient app

**No tab bar. No bottom navigation.** A single linear episode used once, in distress. Persistent navigation would present steps as browsable areas and would compete with the two controls that deserve to be always present: **emergency** and **my condition has changed**.

### Flow

```
Entry
  → Red-flag questions        [local, offline, instant]
      → yes → EMERGENCY INTERRUPT
  → Who is completing this
  → Voice description
  → Functional questions      [baseline-anchored]
  → Review — what's missing
  → Send
  → Status                    [persistent safety surface]
      → My condition has changed → red flags again → delta capture → append
```

### Engineering requirements

- 64px touch targets, 17px+ body text — frightened hands, possibly elderly users
- No progress bar, no step counter — counting teaches people to rush and skip
- `I don't know` is a first-class answer, styled identically to others, stored as `UNKNOWN`
- Incremental local save from the first answer — no unsaved state exists
- **"My condition has changed" appends to the same case.** Never re-queues, never resets. Confirmation text says so explicitly.
- Offline: the update is captured and queued, and the UI states honestly that it is saved on the device and not yet sent. **Never imply a nurse has seen it.**

### Mandatory copy on the status screen

> No one is watching your condition continuously. If things get worse, use the button below, call the nurse line, or call emergency services.

This is not optional and not negotiable in review. It is the difference between an honest product and one that creates a false sense of safety.

---

## 7. Admin dashboard

Six sections: `Live` · `Templates` · `Questions` · `Users` · `Wards` · `Quality`

🔒 **The dashboard is not in the clinical path.** Patient files go directly to the nurse. The dashboard observes and configures. Putting it in the path makes it a point of failure in patient care.

### Live — the landing screen

- Four metric tiles: awaiting review · longest wait · signed but unconfirmed · export failures
- **⚠️ Breach panel** — files past the committed review time. Inverted banner. Renders even when empty, stating so — absence would be indistinguishable from a broken query.
- Incoming queue, **sorted by wait time only**, with the sort order stated on screen
- Export failures with retry
- System state: transcription, export integration, last sync

### Templates

Visual field builder — drag to reorder, add, remove, rename. Live preview of the clinician app. Versioned with attribution.

### Questions and rules

Red flags · functional questions · gap rules.

🔒 **Every clinical rule carries an approval record** — approver name, role, date. Editing a red-flag rule requires entering the approver's name. Unapproved rules display a caution state.

### Users

Invitation only. Signature identity read-only and locked. Sign-in log (shared devices).

🔒 No performance metrics anywhere.

### Wards

Wards, shifts, formulary, and the **committed review time per ward with a named owner**. This is the value the Live breach alert measures against.

### Quality

Most frequently missing fields · drug correction rate · **committed vs actual review time** · export success rate · full audit log.

All aggregate, ward-level at finest grain.

---

## 8. Stack

**Firebase** — Firestore, Storage, Functions, Auth.

⚠️ **Choose the region deliberately.** It determines the applicable data protection regime and is effectively permanent.

⚠️ Firebase is cloud. Production may require on-premises deployment. Keep the inference layer behind an interface so a locally hosted model can replace a hosted API without touching business logic.

**Structure**

```
/apps
  /clinician      mobile
  /patient        mobile
  /dashboard      web
/packages
  /core           domain model, state machines, validation
  /rules          gap detection, red-flag evaluation — pure functions, heavily tested
  /export         ExportTarget implementations
  /ai             inference interface + adapters
/functions        Firebase Functions
```

`/packages/rules` is pure, deterministic, and dependency-free. It carries the highest test coverage in the repo. It is the part a regulator would examine.

---

## 9. Unresolved — do not design around these

⚠️ These are evidence and ownership questions, not engineering problems. Building around them creates false confidence.

1. **Export integration is unproven.** No hospital write path has been validated. Every time-saving claim assumes it works.
2. **Transcription accuracy on real accented ward speech is unmeasured.** Two corrections per note erase the entire benefit.
3. **A fast senior nurse may be slower with this product** on an unchanged patient. That persona decides ward adoption.
4. **Nurse review latency is unspecified and unstaffed.** Without a written commitment, "a nurse will review this" is a hope. The patient app's entire safety model depends on it.
5. **The under-reporting patient is caught by nothing** in the current design. This is a property of the category, not a design defect.
6. **Regulatory classification is undetermined.** The red-flag rule is the sharpest edge.

**Consequence:** build the demonstration, do not ship to real patients.

---

## 10. Build order

1. `/packages/core` — domain model, FHIR-shaped, with `externalIdentifier`
2. `/packages/rules` — gap detection and red-flag evaluation, fully tested
3. Clinician ward list — 12 rows, one screen, 56px
4. Clinician draft review + confirmation layer + signing
5. Voice pipeline — record, transcribe, structure
6. Drug formulary matching and confirmation chips
7. Export abstraction + clipboard + FHIR generator
8. Patient app: red flags → emergency → voice → functional → send → status
9. Dashboard: Live
10. Everything remaining

---

## 11. Do not build

Any downgrade path · `confirmAll` · risk scoring or case ranking · individual performance metrics · a real EMR connection · streaks, points, or leaderboards · notifications outside working hours · patient-facing clinical numbers or urgency levels · any wording implying a patient is fine · diagnosis or medication suggestion · a login screen in the clinician app · a tab bar in the patient app

---

# Amendment 1 — Owner decisions, 2026-08-19 (night build)

> Recorded by the coordinating engineer from the product owner's direct instructions
> in the working session. Where this amendment conflicts with the original text
> above, the amendment governs.

## A1.1 Posture change: demonstration → real-use pilot

The product moves from "hackathon demonstration" to a **real-use pilot** under the
owner's control. Consequences:

- **§1's `SYNTHETIC DEMO DATA` banner requirement is withdrawn** (and acceptance
  F-090 with it). No demo labels appear in any surface or export.
- The synthetic clinical records seeded for the demo are **purged from the live
  database**. Configuration data (wards, formulary, template, red-flag and
  functional questions) is retained — it is real configuration, not fake records.
- **§9 remains true and open.** Transcription accuracy is still unvalidated, no
  hospital EMR write path exists, regulatory classification is undetermined, and
  the red-flag rule set has demo-grade governance. The pilot is honest about this
  in documentation rather than on a per-screen banner. This system remains
  unsuitable for unsupervised clinical deployment.

## A1.2 Export semantics (replaces the simulated acknowledgement)

There is no hospital EMR integration (§9.1 unchanged). Therefore the **system of
record is Afia's own backend**, and §5's rule — positive acknowledgement, never
local send-completion — is now satisfied truthfully:

- `confirmed_in_system` is reached only on a **real server acknowledgement of the
  signed record's persistence** (Firestore server ack, not cache, not a timer).
- UI label for this state: **"Recorded in Afia"** (AR: «مسجَّل في عافية») — it
  must not imply receipt by any hospital system.
- The FHIR generator remains **FHIR-ready** output for a future EMR exporter.
  The 1.5-second simulated acknowledgement is removed everywhere.

## A1.3 Accounts (extends §5, amends §6)

- **Clinician app**: phone + OTP sign-in only; accounts exist by dashboard-created
  invitation; no self-registration. (Unchanged, now recorded formally.)
- **Patient app**: patients **self-register** (phone OTP or email+password) —
  an owner decision amending §6's account-less design. Safety ordering is
  preserved: red-flag questions and the emergency control work **before any
  authentication**; the account gate sits at Send.
- **Admin dashboard**: email+password register/sign-in for managers; creates
  clinician invitations (the only staff-account path) and manages patients
  (admission data entry — added because no ADT feed exists).

## A1.4 Jurisdiction

Bahrain: emergency numbers 999 (unified) and 444 (MOH health line), bundled at
build (§2.7 unchanged). Default phone country +973. Firestore region me-central2
(nearest GCP region; noted, accepted by owner).

## A1.5 What did NOT change

The ten §2 constraints, the §4 AI envelope (reorganisation only, no clinical
judgement — including the patient-safe stricter variant), §2.8 deterministic gap
detection, §2.10 wait-time-only queues, §2.9 no individual performance data,
audit immutability, and signature immutability are all unchanged and remain
structurally enforced in code, tests, and Firestore security rules.

---

# Amendment 2 — Patient app restructure (owner decision D-015, 2026-08-19)

The owner usability-tested the linear-episode patient app and got lost in it.
§6's "no tab bar / no home / single linear episode" design and §11's tab-bar ban
are **withdrawn for the patient app** and replaced with a conventional, obvious
structure: sign-in/register first → Home (one primary action: report my
condition; active-report status card; emergency & nurse-line info) → bottom
tabs (Home · My Reports · Account) → report flow with clear steps.

**What §6 keeps, verbatim and non-negotiable:** the always-visible emergency
control on every screen INCLUDING auth screens (emergency needs no account —
§2.7 unchanged); local deterministic offline red-flag questions at the start of
every report; the mandatory status-screen honesty copy; "my condition has
changed" appending to the same case; UNKNOWN as a first-class answer; no risk
language toward the patient (§11 otherwise intact).
