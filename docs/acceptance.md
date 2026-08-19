# Acceptance Criteria — extracted by Loom (lean pass) from HANDOFF.md

> The handoff is the spec of record. This file converts its constraints into testable criteria.
> IDs: F-0xx = spec criteria. Each maps to an Anvil test (T-) or a Bastion structural check (B-).

## The ten structural constraints (§2) — must be impossible, not just absent

| ID | Criterion | Verified by |
|----|-----------|-------------|
| F-001 | No API in any package lowers a priority, dismisses a flag, or downgrades a case. `escalate()` is monotonic (max-only). Flag lifecycle has no `dismissed` state — only `open` → `annotated`/`resolved-by-signing-note`. | T-001, B-SEC-001 |
| F-002 | `AnswerState = YES \| NO \| UNKNOWN \| NOT_ASKED`. No code path coerces UNKNOWN→NO or UNKNOWN→default. UNKNOWN never reduces priority. | T-002 |
| F-003 | Chip confirmation API accepts exactly one chip id per call. No function accepts an array of chip ids. `sign()` throws while any drug/number chip is unconfirmed. | T-003, B-SEC-002 |
| F-004 | `sign()` succeeds with open omission flags when a reason string is provided; flags + reason appear in every export output. | T-004 |
| F-005 | Signature identity is set at account creation and readonly; post-sign edit creates a superseding version, keeps both versions and both signatures, and requires explicit re-sign. | T-005 |
| F-006 | A handover stores its audio recording; the received-handover view renders a playable audio element. | T-006 (model), manual check (UI) |
| F-007 | Red-flag evaluation is a pure function in `packages/rules` with zero imports of network/inference code. It produces identical output with networking disabled (airplane-mode test). Emergency numbers are bundled constants. | T-007 |
| F-008 | Gap detection = deterministic schema check against the configured template. Same input → same output, property-tested. Output wording is neutral: "Not mentioned: X", never importance-ranked. | T-008 |
| F-009 | No field, type, function, or aggregation anywhere computes per-clinician speed/volume/ranking. Wellbeing aggregates suppress below n=5. | T-009, B-SEC-003 (grep-level audit) |
| F-010 | Queue comparator uses wait time + file completeness only; comparator source contains no severity/risk input. Sort order is stated on the dashboard screen. | T-010 |

## Data model (§3)

- F-020: Every entity carries `externalIdentifier: string | null` (empty now).
- F-021: Entities map to FHIR: Patient, DocumentReference, Practitioner, Encounter, Provenance.
- F-022: Consent is its own timestamped, withdrawable record — separate from terms acceptance.
- F-023: `audioRetention` policy field exists on config (provisional value allowed).
- F-024: Audit trail is append-only: actor, timestamp, action, previousValue. No in-place update API.
- F-025: FHIR exporter emits a valid `DocumentReference` JSON viewable in the UI; clipboard exporter works; HL7v2 is a stub that says so. Wording everywhere: **FHIR-ready**.

## Clinician app (§5)

- F-030: Four tabs: Patients · Received · Shift · Account. No home screen; no login screen (demo identity picker stands in for SSO, labeled as such).
- F-031: Ward list fits 12 rows on one mobile screen without scroll.
- F-032: Row states exactly: not_started, recording, draft_ready, signed, queued, confirmed_in_system, export_failed — signed ≠ confirmed_in_system, visually distinct.
- F-033: Recording screen auto-checkpoints continuously; reopen returns to the interrupted draft.
- F-034: Draft review renders unverified text in periwinkle, signed in indigo.
- F-035: Touch targets ≥ 56px.
- F-036: Export fires automatically on signature; no manual export button. confirmed_in_system only on positive acknowledgement (demo: simulated ack with a visible failure path).
- F-037: Received handover shows flags inline (never behind an expand) and playable audio.
- F-038: Sign sheet is hold-to-sign; open flags never block, one-tap reason recorded.
- F-039: Shift complete screen: warm palette, appears once. Account: prominent sign out.

## Patient app (§6)

- F-050: No tab bar, no bottom navigation, no progress bar/step counter.
- F-051: Emergency control + "my condition has changed" rendered outside the step view hierarchy, always visible, never occluded.
- F-052: Red-flag questions first; a YES triggers full-screen emergency interrupt with bundled numbers.
- F-053: "I don't know" is a first-class answer, styled identically, stored UNKNOWN.
- F-054: 64px targets, ≥17px body text.
- F-055: Incremental local save from the first answer.
- F-056: "My condition has changed" → red flags again → delta capture → **appends to same case**; confirmation copy says so.
- F-057: Offline update: honest copy — saved on device, not yet sent, never implies a nurse saw it.
- F-058: Status screen carries the mandatory copy verbatim: "No one is watching your condition continuously. If things get worse, use the button below, call the nurse line, or call emergency services."

## Dashboard (§7)

- F-070: Six sections: Live · Templates · Questions · Users · Wards · Quality. Dashboard is not in the clinical path.
- F-071: Live: four tiles (awaiting review, longest wait, signed-but-unconfirmed, export failures); breach panel renders even when empty, stating so; queue sorted by wait time only with the sort order stated on screen; export failures with retry; system state block.
- F-072: Templates: field builder (reorder/add/remove/rename), live clinician preview, versioned with attribution.
- F-073: Every clinical rule carries an approval record (name, role, date); editing a red-flag rule requires approver name; unapproved rules show caution state.
- F-074: Users: invitation only; signature identity locked; sign-in log. No performance metrics.
- F-075: Wards: committed review time per ward with named owner — the value the breach alert measures against.
- F-076: Quality: missing-field frequency, drug correction rate, committed vs actual review time, export success — all aggregate, ward-level at finest.

## Global

- F-090: ~~Persistent `SYNTHETIC DEMO DATA` label on every surface.~~ **WITHDRAWN by HANDOFF Amendment A1.1 (2026-08-19)** — real-use pilot posture; no demo labels on any surface.
- F-091: §11 "Do not build" list holds across the repo.
