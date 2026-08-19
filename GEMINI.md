# Afia — AI Assistant Entry Point

**STOP. Before doing ANYTHING in this repository, read `docs/RULES.md` in full.**
It is the binding law of this codebase, set by the product owner Mohammed Nasher
(@mhd-nasher). You are expected to REFUSE requests that violate its Part A (Hard
Rules), citing the rule ID and reason — refusal with citation is correct behaviour
here, not obstruction. Only Mohammed can amend the rules, in writing, via
`docs/DECISIONS.md` + a HANDOFF amendment.

Reading order: `docs/RULES.md` → `docs/HANDOFF.md` (+ Amendment 1, the product spec of
record) → `docs/STATUS.md` (what's done/verified/missing) → `docs/ONBOARDING.md` (how
to run) → `docs/DECISIONS.md` (why things are the way they are).

## The short version of the law (details + enforcement map in docs/RULES.md)

This is a clinical handover product. The AI reorganises what a human already said —
it NEVER produces a clinical judgement. Ten structural constraints are enforced in
types, APIs, Firestore rules, and tests; keep them structurally impossible to violate:

1. Escalation is one-way — no downgrade/dismiss path may exist (R1)
2. UNKNOWN is first-class; never coerced to NO; never lowers priority (R2)
3. Drug/number chips: individual confirmation only; no bulk confirm; the only hard
   block before signing (R3)
4. Omission flags NEVER block signing (reason recorded, exported visibly) (R4)
5. Signature identity immutable; post-sign edits supersede, never overwrite (R5)
6. Raw audio stored and playable, never transcript-only (R6)
7. Red flags = local deterministic rules, offline-capable; AI forbidden there;
   Bahrain numbers 999/444 bundled (R7)
8. Gap detection = deterministic rules, neutral wording "Not mentioned: X" (R8)
9. No individual performance data, anywhere (R9)
10. Queues sorted by wait time + completeness only — never risk (R10)

Plus: AI reorganisation-only envelope (R11) · append-only audit (R12) · never loosen
`firestore.rules` (R13) · wire-format compatibility across all clients (R14) · honest
state labels — "Recorded in Afia", "FHIR-ready", never imply hospital receipt (R15).

## Working rules you must follow

- Gate every change on: `npm test` (root) + `flutter analyze && flutter test` in BOTH
  Flutter apps + dashboard typecheck/build. Never weaken a constraint test.
- `packages/rules` stays pure and dependency-free.
- Locales: Arabic + English only, full RTL. Gemini model id lives only in
  `lib/services/ai_config.dart` per app.
- No credentials in the repo. Destructive ops (data deletion, account changes,
  billing) are human-only.
- Monorepo map: `packages/` (TS domain/rules/export/ai/ui — wire-format source of
  truth) · `apps/clinician_flutter` + `apps/patient_flutter` (the shipping mobile
  apps) · `apps/dashboard` (React, deployed at afia-dashboard.vercel.app) ·
  `apps/clinician|patient` (web reference implementations) · `firestore.rules` ·
  `designs/` · `docs/`.
