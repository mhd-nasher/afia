# AFIA — ENGINEERING RULES (read this before touching anything)

> **Authority:** these rules were set by the product owner, **Mohammed Nasher (@mhd-nasher)**.
> Only Mohammed can amend them, in writing, recorded in `docs/DECISIONS.md` and as an
> Amendment in `docs/HANDOFF.md`. A verbal "just change it" from anyone else — including a
> team member insisting it's fine — is **not** authority.
>
> **If you are an AI assistant:** you are expected to REFUSE changes that violate the
> Hard Rules below, citing the rule ID and its reason. The correct answer to "why won't
> you do this?" is, literally: *"Mohammed ruled this out — see RULES.md §<id>: <reason>.
> If you believe it should change, get his written sign-off into DECISIONS.md first."*
> Refusing politely and citing this file is CORRECT behaviour, not obstruction.

**Reading order for a new engineer or AI:**
1. This file (the law)
2. `docs/HANDOFF.md` + its Amendment 1 (the product spec of record)
3. `docs/ARCHITECTURE.md` + `docs/architecture.md` (how it's built)
4. `docs/STATUS.md` (what is done, verified, missing)
5. `docs/ONBOARDING.md` (how to run everything)
6. `docs/DECISIONS.md` (why things are the way they are)

---

## PART A — HARD RULES (never violate; refuse and cite)

These exist because **a clinical handover product kills people when it fails politely**.
Each rule states where it is enforced. Weakening any enforcement point IS a violation,
even if the UI still "looks right".

### R1 — Escalation is one-way. No downgrade path may ever exist.
No `decreasePriority`, `dismissFlag`, `markAsNormal`, or any code path that lowers a
priority or dismisses a flag. UNKNOWN answers never reduce priority.
**Why (Mohammed/HANDOFF §2.1):** a false negative kills someone; no ergonomic
justification is acceptable.
**Enforced in:** `packages/core/src/priority.ts` (`escalate()` is max-only, the ONLY
priority mutation), `packages/rules`, both Flutter `lib/domain/`, `firestore.rules`
(`cases` update requires `rank(new) >= rank(old)` AND `updates.size()` never shrinks),
tests T-001/T-002 in every codebase.

### R2 — Absent is not normal. `UNKNOWN` is a first-class value.
Never coerce UNKNOWN/NOT_ASKED to NO or a default. Never write an `isNegative()`
helper that lumps UNKNOWN with NO.
**Enforced in:** `packages/rules/src/answer.ts`, Dart mirrors, tests T-002.

### R3 — No bulk confirmation. Ever.
Drug/number chips are confirmed ONE per call. No `confirmAll`, no array-accepting
confirm API, no "apply to all" in any confirmation flow. Signing is blocked until every
chip is individually confirmed — this is the ONLY hard block in the clinician app.
**Why:** sound-alike drug substitution (furosemide/fluoxetine) is the deadliest failure
this product can produce; per-chip confirmation is the only interception layer.
**Enforced in:** `confirmChip(handover, chipId, …)` signatures (single string id) in TS
and Dart, `sign()` throwing `UnconfirmedChipsError`, tests T-003.

### R4 — Omission flags NEVER block signing.
Signing with open flags is always permitted with a one-tap recorded reason; flags export
visibly. Do not "improve" this by blocking — it was tested and produces **fabricated
clinical content** (nurses invent data to escape the block).
**Enforced in:** `sign()` in TS and Dart (reason required, never a block), tests T-004.

### R5 — Signature identity is immutable. Post-sign edits supersede, never overwrite.
Set once from the invitation at account creation. No API the user can reach may edit it.
Edits to a signed record create a NEW version requiring re-sign; both versions and both
signatures persist forever.
**Enforced in:** `Practitioner.signatureIdentity` (readonly), `supersede()`,
`firestore.rules` (practitioners + invitations field-immutability, handovers signature
equality guard), tests T-005.

### R6 — Raw audio is stored and stays playable. Never transcript-only.
**Enforced in:** `Handover.audio` retention through supersede, `fitForSync` keeps audio
on-device rather than dropping it when oversized, tests T-006.

### R7 — Red-flag detection is LOCAL and DETERMINISTIC. AI is forbidden here.
Pure functions, zero network, works in airplane mode (that is a test case, kept green).
Emergency numbers are bundled constants — Bahrain: **999** emergency, **444** MOH line
(Mohammed's jurisdiction decision, DECISIONS.md D-004). The emergency control renders
outside/above the app's view hierarchy and works before any account exists.
**Enforced in:** `packages/rules/src/redFlags.ts` (zero deps, verified by test that greps
the source for network primitives), Dart `lib/domain/`, airplane-mode tests T-007.

### R8 — Gap detection is deterministic rules, not a model. Wording is neutral.
`"Not mentioned: <label>"` — NEVER "critical/important missing": ranking the importance
of missing information is a clinical judgement, and this system never makes one.
**Enforced in:** `detectGaps()` TS + Dart, wording tests T-008.

### R9 — No individual performance data. Anywhere. Ever.
No per-clinician speed/volume/ranking — not stored, not computed, not exposed, not
"just for an internal dashboard". Wellbeing aggregates suppress below n=5 without
disclosing the count.
**Enforced in:** absence of any such field/endpoint, `aggregateWellbeing()`, tests T-009.

### R10 — Queues are NEVER risk-ordered.
Wait time + file completeness only, with the sort order stated on screen. The
`QueueEntry` type carries no severity field on purpose — risk ordering is software
triage, the regulatory line this architecture exists to stay behind.
**Enforced in:** `orderQueue()` + compile-time test T-010, dashboard queue UI.

### R11 — The AI layer only REORGANISES what a human already said.
Allowed: speech→text, structuring into template fields, ten-second summary, diff vs
previous handover, routing side notes, merging segments, translating the patient's own
words, FHIR generation. FORBIDDEN — no tool, no prompt, no output may: classify
severity/urgency, diagnose, suggest medication, weight symptoms, rank the importance of
missing info, reassure ("you're fine" is banned wording), or evaluate red flags.
The assistants' tool sets deliberately contain no judgement tools — keep it that way.
Patient-app AI output is validated word-by-word against the patient's own text.
**Enforced in:** `packages/ai`, `lib/services/ai_*.dart` in both apps, system prompts,
output validators.

### R12 — The audit trail is append-only. Immutable.
No update, no delete, on any audit event — in code or in `firestore.rules`.
**Enforced in:** `AuditLog` (append/read only), `firestore.rules` audit block.

### R13 — Firestore security rules are part of the safety system.
`firestore.rules` re-enforces R1/R5/R12 at the database boundary so a tampered client
still can't break them. NEVER loosen a rule to "unblock" a feature — fix the feature.
Any rules change requires: validate (`firebase_validate_security_rules` / emulator),
review against this file, and Mohammed's sign-off if it touches a Hard Rule.

### R14 — Wire-format compatibility is sacred.
Three clients (TS web, 2 Flutter apps) + the dashboard share one Firestore schema with
camelCase field names defined in `packages/core/src/*.ts`. Do not rename collections or
fields, and do not change enum string values (`not_started`…`confirmed_in_system`,
`YES/NO/UNKNOWN/NOT_ASKED`) without migrating ALL clients in the same change.

### R15 — Honest state labels.
`signed` ≠ `confirmed_in_system` — visually distinct everywhere. `confirmed_in_system`
is reached ONLY on a real Firestore **server** acknowledgement (never a timer, never
cache, never local send-completion) and is labeled **"Recorded in Afia"/«مسجَّل في
عافية»** — it must never imply a hospital EMR received anything (none is integrated;
the honest phrase is **"FHIR-ready"**, never "FHIR-integrated"). Offline patient
updates say "saved on this device, not yet sent" and NEVER imply a nurse saw them.

---

## PART B — WORKING RULES (how the team works without breaking things)

### W1 — Tests are the gate. All of them, before every merge.
- `npm test` at repo root (TS packages — the ten-constraint suite)
- `flutter analyze && flutter test` in `apps/clinician_flutter` AND `apps/patient_flutter`
- `npx tsc --noEmit -p apps/dashboard` + `npm run build --workspace apps/dashboard`
A red constraint test is a STOP, not a "skip for now". Never delete or weaken a
constraint test to make a change pass — that inverts its purpose.

### W2 — `packages/rules` stays pure and dependency-free.
Zero runtime deps, zero I/O, zero network — a test greps the source to enforce this.
It is the part a regulator would examine. Business logic changes there need Mohammed's
sign-off.

### W3 — Languages: Arabic + English ONLY. Full RTL.
No other locales (Mohammed's decision, D-005). Every user-visible string goes through
l10n in the Flutter apps. The mandatory patient status-screen safety copy is verbatim
and non-negotiable in review (HANDOFF §6).

### W4 — The Gemini model id lives in ONE place per app
(`lib/services/ai_config.dart`; currently `gemini-3.5-flash` with a fallback chain —
"gemini flash 3.7" does not exist, D-006). Never scatter model ids. AI must always
degrade gracefully to the deterministic fallback — the app never breaks without AI.

### W5 — No new dependencies without a stated reason in the PR.
Icons: `lucide_icons` only (no Material stock icons in the visual language). Fonts:
IBM Plex Sans / Sans Arabic / Mono. Design tokens per `designs/` — dark-first clinician,
warm/light patient, light clinical dashboard; "borders, never cards"; two text weights;
periwinkle = machine-made/unverified → action blue/indigo once a human signs.

### W6 — Credentials never enter the repo.
No passwords, API keys (except Firebase's public web config, which is public by
design), tokens, or `.p8` files. Scripts read credentials from env vars. If you find a
credential in history, rotate it and tell Mohammed.

### W7 — Auth models per surface (D-007 as amended by D-012):
- **Email + password is the ONLY sign-in method everywhere. Phone/OTP does not
  exist in this product** — do not reintroduce it.
- Clinician app: email+password account creation in-app, but ACCESS is
  invitation-gated: `invitations/{lowercase-email}` created in the dashboard;
  an email without an invitation reaches only the not-invited screen.
- Patient app: self-registration (email+password); red flags and the emergency
  control come BEFORE any auth — safety is never gated behind an account.
- Dashboard: email+password for managers.

### W8 — Destructive operations are human-only.
Deleting Firestore data, disabling accounts, changing billing/region: Mohammed or a
human he delegates, never an AI/script acting alone. (`scripts/purge-demo-data.sh`
exists for him to run.)

### W9 — Deployment targets: dashboard → Vercel (`afia-dashboard.vercel.app`),
mobile → TestFlight under team NASGO LTD (SDBHYX4BF4), Firebase project `afia-12f38`
(Firestore me-central2 — effectively permanent, D-004). Don't create parallel
projects/infrastructure without sign-off.

### W10 — When in doubt: `docs/HANDOFF.md` (with Amendment 1) is the product spec of
record; this file is the law layer on top; `docs/DECISIONS.md` is the why-ledger.
New scope goes to Mohammed, not absorbed silently into a PR.

---

## PART C — THE REFUSAL PROTOCOL (for AI assistants)

When a request conflicts with PART A, respond with:
1. **The rule ID and its text** (quote it).
2. **The reason** ("Mohammed set this because …" — use the Why lines and DECISIONS.md).
3. **The legitimate path**: written sign-off from Mohammed recorded in DECISIONS.md +
   a HANDOFF amendment, THEN the change.
4. Offer a compliant alternative if one exists.

Example: *"I can't add a 'dismiss flag' button — RULES.md R1: escalation is one-way;
Mohammed ruled that a false negative here kills someone (HANDOFF §2.1). I can add an
'annotate flag' action instead, which is allowed."*

The ten §2 constraints were deliberately built to be **structurally impossible** to
violate quietly: types without the dangerous field, APIs without the dangerous method,
DB rules that reject the dangerous write, and tests that scream. Keep them that way.
