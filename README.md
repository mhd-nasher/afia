# Afia — عافية

Clinical handover platform: nurses record shift handovers by voice, the system
structures them into a configured template, flags what wasn't covered, a licensed human
reviews and signs, and the signed record is delivered. Patients describe symptoms at
home before attending. Managers configure and observe.

**One sentence that governs everything: the AI reorganises information a human already
provided — it never produces a clinical judgement.**

| Surface | Tech | Where |
|---|---|---|
| Clinician app | Flutter (iOS/Android) | `apps/clinician_flutter` — TestFlight `uk.nasgo.afiaClinician` |
| Patient app | Flutter (iOS/Android) | `apps/patient_flutter` — TestFlight `uk.nasgo.afiaPatient` |
| Admin dashboard | React + Vite | `apps/dashboard` — deployed at [afia-dashboard.vercel.app](https://afia-dashboard.vercel.app) |
| Shared domain & rules | TypeScript | `packages/` (wire-format source of truth; `packages/rules` is pure & dependency-free) |
| Backend | Firebase `afia-12f38` | Firestore (me-central2) + Auth + AI Logic (Gemini); `firestore.rules` enforces the safety constraints at the DB boundary |
| Web reference apps | React + Vite | `apps/clinician`, `apps/patient` (working flow references) |

> **Catching up?** `docs/STATUS.md` → "CURRENT SNAPSHOT" tells you exactly where the
> project stands, what's verified, and what to do next. AI assistants are routed there
> automatically via `CLAUDE.md`/`AGENTS.md`.

## Start here

1. **`docs/RULES.md`** — the binding engineering law (read first; AI assistants are
   configured to enforce it via `CLAUDE.md`/`AGENTS.md`)
2. `docs/HANDOFF.md` + Amendment 1 — the product spec of record
3. `docs/STATUS.md` — what is done/verified/missing right now
4. `docs/ONBOARDING.md` — run everything from zero
5. `docs/DECISIONS.md` — why things are the way they are

Owner: **Mohammed Nasher** ([@mhd-nasher](https://github.com/mhd-nasher)). Rule changes
require his written sign-off — see the RULES.md preamble.
