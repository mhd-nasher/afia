# Forge Run — Afia Clinical Handover Platform (Hackathon Demo)

> Conducted by Forge. Discovery ran once (2026-08-19); every phase reads this block.

## Step 0 — Shared Discovery

- **Project:** Afia — clinical handover platform demo. Three surfaces, one backend model.
- **Stage:** Hackathon demonstration. ALL DATA SYNTHETIC. Not for real patients/clinicians.
- **Stack decision:** TypeScript monorepo (npm workspaces). The handoff's §8 structure —
  `/packages/core|rules|export|ai` shared by `/apps/*` and `/functions` — requires one language
  across apps and functions, so the two "mobile" surfaces are built as mobile-first web apps
  (React + Vite), the dashboard as a desktop web app (React + Vite). Firebase (Firestore/Auth/
  Storage/Functions) stays behind a `DataStore` interface; the demo runs on a local
  in-memory + localStorage adapter with seeded synthetic data. **Firebase-ready, not
  Firebase-integrated** — same honesty rule as "FHIR-ready".
- **Complexity budget (Cairn):** standard for apps; **full** for `packages/core` and
  `packages/rules` (deterministic, dependency-free, highest test coverage — the regulator-facing
  part per handoff §8).
- **User level:** expert (solo dev). Conversation in Arabic, code/docs in English.
- **Memory:** no `_PROJECT_CONTROL` brain exists. Artifacts live in `docs/` at project root.
  The full handoff is preserved verbatim in `docs/HANDOFF.md` — it is the spec of record.

## Phase plan (skips named, per the Conductor's Law)

| # | Phase | Member | Disposition |
|---|-------|--------|-------------|
| 1 | Decide | Helm | **SKIPPED** — handoff states product decisions are complete; the bet (hackathon demo) is already placed. |
| 2 | Define | Loom | **LEAN** — the handoff IS the spec. Loom's output reduces to acceptance criteria extracted from §2, §5, §6, §7 (see `docs/acceptance.md`). |
| 3 | Face | Facet | **LEAN** — design decisions are in the handoff (periwinkle/indigo, warm shift-complete palette, 56/64px targets, 17px+ body, no tab bar in patient app). Facet emits tokens in `packages/ui`. |
| 4 | Structure | Cairn | **LEAN** — §8 gives the structure. Cairn confirms it, adds `packages/ui` (shared tokens/components) as a deliberate extension, and sets dependency rules (see `docs/architecture.md`). |
| 5 | Build | — | **FULL** — implements the spec and nothing else. New scope routes back to the spec, never absorbed. |
| 6 | Prove | Anvil | **FULL** — Vitest over `packages/rules` + `packages/core`: the ten §2 constraints each get tests, incl. the airplane-mode red-flag case. |
| 7 | Clean | Lens | **QUICK PASS** on the final diff. |
| 8 | Guard | Bastion | **LEAN** — structural-invariant verification of §2 (no downgrade path, no confirmAll, no perf metrics). Deep pentest skipped: no deployed surface, synthetic data only. |
| 9 | Ship | Relay | **SKIPPED** — local demo; run scripts only, no CI/CD or deploy. |
| 10 | Read | Helm | **SKIPPED** — no measurement window exists yet. |

## Phase results (updated 2026-08-19, second session)

- **Build + Anvil:** all three apps built and browser-verified by their build agents;
  38/38 unit tests green (`npm test`); typecheck clean across packages and apps.
- **Firebase (user-directed addition):** project **afia-12f38 ("Afia")**, Firestore
  `(default)` in **me-central2 (Saudi Arabia — user-confirmed jurisdiction)**; emergency
  numbers localised to 997/937. Web app registered; anonymous auth enabled;
  `firestore.rules` deployed with §2 enforced at the DB boundary — live violation attempts
  (priority downgrade, audit tamper, signature change) all return `permission-denied`
  (see rules-proof run). `FirestoreStore extends LocalStore` in
  `packages/core/src/firebase.ts` (separate entry point so local-only builds skip the SDK);
  sync goes online only after initial snapshots, union-merges (system has no deletes),
  diffs by canonical JSON, and marks synced only after server ack. `flush()` resolves on
  SERVER acknowledgement — the patient app marks an update "sent" only then (§6 honesty).
  Live integration test: `npx vitest run --config vitest.live.config.ts`.
- **Blaze not enabled** (Spark plan): Cloud Functions and Storage are deferred — audio
  syncs inline while under the Firestore document limit; oversized audio stays on-device
  with an explicit reason field. Upgrading to Blaze is a user/billing decision.
- **Bastion structural greps:** no downgrade/dismiss/confirmAll APIs, no per-clinician
  metrics, no risk-ordered queue, no network primitives in `packages/rules` — confirmed
  post-build across all apps.

## Honesty lines carried into the final report

- Transcription accuracy on real ward speech is UNVALIDATED (handoff §9.2) — the demo uses the
  browser's speech recognition + a deterministic mock structurer behind the `packages/ai` interface.
- Export integration is UNPROVEN (§9.1) — `ClipboardExporter` is the only real exporter; the FHIR
  generator produces valid JSON but sends nothing.
- Nothing here is a medical device. Real patients and clinicians must not use this build.
