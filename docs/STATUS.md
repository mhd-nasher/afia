# STATUS.md — what is done, what is verified, what is missing

> Snapshot: 2026-08-19 (end of the night build). Two tiers only: **VERIFIED** means
> evidence exists (tests/builds/live checks recorded in agent reports and READMEs);
> **BUILT-UNVERIFIED** means the code exists but nobody proved it end-to-end yet.
> Update this file when either list changes.

## VERIFIED ✅

**Clinician Flutter app** (`apps/clinician_flutter`) — analyze 0 issues · 54/54 tests
(the ten constraints + state machine + assistant tools + teamwork) · iOS release
archive + signed IPA at **1.0.0+6** · live-DB integration drive on simulator ·
screenshots in `docs_screens/`.
Features: email+password sign-in gated by EMAIL-KEYED invitations (D-012 — phone/OTP
does not exist), 12-row ward list, recording with 4s auto-checkpoint + resume, live
ar/en speech-to-text + type fallback, playable audio, chip extraction + per-chip
confirmation + sound-alike correction picker, flags with one-tap reasons, hold-to-sign,
REAL server-ack export ("Recorded in Afia") + failure/retry, received view (summary/
diff/inline flags/audio), shift board with LIVE presence (RTDB, D-014), teamwork preset
requests + split inbox (التسليم | الطلبات) + per-nurse ward ordering (manual/facts-only,
D-014), shift complete, account (locked identity, prominent sign-out), template
(role-gated), AR/EN RTL, Afia Assistant as full shift PA (D-013 — real data reads under
the nurse's own permissions, facts-only organization) + per-user memory (with
deterministic fallback verified).

**Patient Flutter app** (`apps/patient_flutter`) — analyze 0 · 22/22 tests (incl.
airplane-mode red flags, one-way priority, emergency-on-auth-screens invariant) · iOS
archive + signed IPA at **1.0.0+5** · on-device flow walk · live Firestore case
verified (urgent one-way, accountUid, server-acked sent) · screenshots.
Features (D-015 restructure — supersedes the old linear-episode design): auth FIRST
(self-registration, email+password ONLY, D-012), Home with one primary action + active-
report status card, bottom tabs (الرئيسية · تقاريري · حسابي), step indicators in the
report flow, red flags local/deterministic/offline at the start of every report,
emergency fixture on EVERY screen including auth (999/444, works offline, no account
needed), interrupt screen (999/444), voice + type, functional questions with UNKNOWN,
neutral review, status screen with verbatim mandatory copy AR/EN, condition-changed
appends to same case, delete-my-data, AR/EN RTL.

**Admin dashboard** — deployed **https://afia-dashboard.vercel.app** · register→login
round-trip verified on the deployed origin · invitation + patient-admission writes
verified against live rules. Six sections per the design brief; invitations UI;
patients management; no demo labels; charts honest-but-sparse until history accrues.

**Backend** — Firestore (me-central2) with deployed rules enforcing: one-way priority +
append-only case updates, immutable signature identity + invitation fields (email-keyed,
claim-only-claimedBy), append-only audit, owner-only aiMemory/patientAccounts/
managerAccounts, no deletes. Realtime Database (europe-west1) LIVE for the teamwork
layer (D-014) — presence own-write-only, requests sender-create/participant-update,
root deny; deployed rules verified identical to `database.rules.json`. Auth providers:
email/password + anonymous — email+password is the ONLY product sign-in (D-012; phone
does not exist). AI Logic enabled for all app ids. Invitations are EMAIL-KEYED:
`invitations/nasgo.uk@gmail.com` (unclaimed) and `invitations/mngnm17@gmail.com`
(claimed) verified live. Role accounts exist for manager + patient (credentials rotated
by owner); the deploy-smoke*/patient.verify.* test accounts are DISABLED in Auth.

**TS packages + web apps** — 38/38 vitest (the constraint suite), three web apps
typecheck/build; they are the reference implementation, Firebase-backed by default.

## BUILT-UNVERIFIED ⚠️ (first things to smoke-test)

1. **Live Gemini calls** (both apps): the deterministic fallback is what automated runs
   exercised. One manual assistant interaction on a networked device proves the path.
2. **Android**: configured (minSdk 23, permissions, google-services) but never built/run.
3. **Concurrent speech-to-text + AAC recording** may contend on some physical devices —
   "Type instead" covers it.
4. **TestFlight processing**: IPAs uploaded by owner; TestFlight-side review/processing
   not observed from this environment.

## MISSING / OPEN ❌

- **HANDOFF §9 items (owner-level, not engineering):** transcription accuracy on real
  ward speech unmeasured; no hospital EMR write path (product says "FHIR-ready" only);
  nurse review latency has no staffed written commitment; regulatory classification
  undetermined. These are LIVE risks in real use — Mohammed owns the go/no-go.
- **Synthetic demo records** may still exist in Firestore until
  `scripts/purge-demo-data.sh` is run by the owner (deletes are human-only, W8).
- HL7v2 exporter is a stub (says so). PDF exporter not built.
- Web clinician identity picker becomes empty after a purge (web apps are reference
  tools now, not the product).
- Dashboard is EN-only (managers) — by design, revisit if Mohammed wants AR there.
- No CI pipeline yet (tests run locally; see ONBOARDING.md) — good first task for the
  team, gating on the exact commands in RULES.md W1.
