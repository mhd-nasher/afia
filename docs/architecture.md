# Architecture — Cairn (lean pass), confirming HANDOFF §8

> **2026-08-19 addendum — current state.** This document described the original TS
> monorepo; it remains accurate for `packages/` and the web apps. Since then (see
> DECISIONS.md D-002..D-010): the shipping mobile apps are **Flutter**
> (`apps/clinician_flutter`, `apps/patient_flutter`) with `lib/domain/` mirroring the
> TS wire format one-to-one; the backend is live **Firebase `afia-12f38`**
> (Firestore me-central2 + Auth + AI Logic/Gemini) with `firestore.rules` re-enforcing
> R1/R5/R12 at the DB boundary; the dashboard is rebuilt per
> `designs/dashboard-design-brief.md` and deployed to Vercel. The seam design below
> (DataStore interface, exporters, swappable AI) is exactly what made that pivot cheap.

## Structure (R-001)

```
/apps
  /clinician      mobile-first web (React + Vite, TS)
  /patient        mobile-first web (React + Vite, TS)
  /dashboard      desktop web (React + Vite, TS)
/packages
  /core           domain model, state machines, store, audit, seed data
  /rules          gap detection, red-flag evaluation, formulary matching, queue ordering
                  — pure functions, zero runtime deps, highest test coverage
  /export         ExportTarget implementations (clipboard, FHIR, HL7v2 stub)
  /ai             inference interfaces + adapters (browser speech, mock structurer)
  /ui             [deliberate addition] design tokens + tiny shared components
                  (SyntheticBanner, chips) so three apps render one design language
/functions        Firebase Functions — stub with README; not deployed in the demo
/docs             spec of record + run artifacts
```

## Dependency rules (R-002) — direction is law

- `rules` depends on **nothing** (not even `core` at runtime; shares types via `core` type-only imports is allowed but avoided — rules defines its own minimal input types).
- `core` may import types from `rules`. `export`, `ai`, `ui` may import `core`.
- Apps import packages; packages never import apps.
- No package imports Firebase. The store is an interface (`DataStore`) with a
  `LocalStore` (in-memory + localStorage) implementation for the demo. A future
  `FirestoreStore` implements the same interface — that is the Firebase seam (R-003).

## Enforcement of §2 at the model layer (R-004)

Constraints live in `core`'s state machines and `rules`' pure functions, not in UI:
- Priority: branded type + `escalate()` = max-only. No setter exists.
- `sign()` validates chip confirmations (each chip carries its own confirmation record).
- Post-sign edits go through `supersede()` which clones, preserves the original + signature.
- Audit: append-only event log; the store exposes `append` and `read`, no update/delete.

## Complexity budget (R-005)

- `core` + `rules`: full rigor — exhaustive types, state machines, tests per constraint.
- Apps: standard — plain React state + the store; no state-management library, no router
  library (hash-based screen switching is enough for a demo and keeps deps near zero).
- No CI/CD, no e2e suite (Relay skipped; demo is local).

## Honesty (R-006)

Firebase-ready ≠ Firebase-integrated. The `/functions` directory exists to hold the seam,
with a README stating nothing is deployed. Region choice (§8) is deferred and documented
as an open decision — it must be made before any real deployment.
