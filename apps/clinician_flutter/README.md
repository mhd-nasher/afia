# Afia — Clinician app (Flutter)

Voice-first shift-handover app for nurses. Dark-default UI (IBM Plex Sans /
Mono, Arabic + English with full RTL), phone-OTP sign-in by invitation only,
offline-first Firestore, and the ten HANDOFF §2 constraints enforced in the
domain layer (`lib/domain/`) — not in the UI.

**Posture (HANDOFF Amendment 1)**: real-use pilot under the owner's control.
HANDOFF §9 remains true and open — transcription accuracy is unvalidated,
there is no hospital EMR write path, and regulatory classification is
undetermined. This system remains unsuitable for unsupervised clinical
deployment. The owner runs `scripts/purge-demo-data.sh` to purge the demo-era
synthetic clinical records; configuration (wards, formulary, template,
questions) is real configuration and stays.

## Run it

```bash
cd apps/clinician_flutter
flutter pub get
flutter gen-l10n            # generates lib/l10n/gen (also runs on build)
flutter test                # domain-constraint tests (T-001..T-006 mirrors)
flutter analyze

# iOS simulator
flutter build ios --simulator --debug
flutter run                 # picks a booted simulator

# Android
flutter build apk --debug
# apk lands at build/app/outputs/flutter-apk/app-debug.apk
```

### On a physical device

- **iOS**: open `ios/Runner.xcworkspace` in Xcode, select your team under
  Signing & Capabilities, choose the device, Run. Deployment target is iOS
  15.0 (Firebase SDK requirement). If pods are stale:
  `cd ios && pod install --repo-update`.
- **Android**: enable USB debugging, then
  `flutter install` or `adb install build/app/outputs/flutter-apk/app-debug.apk`.
  `minSdk` is 23 (firebase_auth requirement).

## Console steps the operator still must do

1. **Email/Password provider** must be enabled (Authentication → Sign-in
   method → Email/Password). Phone/OTP is removed from the product (D-012);
   the SMS region policy no longer matters.
2. **Anonymous auth** must stay enabled (used by the seed scripts and web
   surfaces, not by this app).
3. **Invitations are keyed by lowercase email** (`invitations/{email}`),
   created from the dashboard. Old phone-keyed invitation documents are
   inert — no code path reads them.

Firebase AI Logic (Gemini API) is enabled on the project; no toggle needed.

## Where things live

| Concern | Location |
|---|---|
| §2 constraints (escalate max-only, single-chip confirm, sign(), supersede, state machine, gaps, chips) | `lib/domain/` — pure Dart, mirrored from `packages/core` + `packages/rules` |
| Constraint tests | `test/domain_test.dart` (T-001..T-006 mirrors) |
| **Gemini model id** | `lib/services/ai_config.dart` → `geminiModelId` (one constant, with a fallback chain). The requested "gemini flash 3.7" does not exist; current Flash `gemini-3.5-flash` is used. |
| Structuring (swappable §4.1) | `lib/services/structurer_service.dart` — `GeminiStructurer` (temperature 0, JSON schema, output validated: known fieldIds only + content traceable to transcript) with deterministic `KeywordStructurer` fallback (`lib/domain/structuring.dart`) used automatically offline/on error |
| Afia Assistant (مساعد عافية) | `lib/services/assistant/` — tool-calling Gemini agent; tools are reorganisation-only (§4.3 judgements are not expressible); per-user memory at `aiMemory/{uid}` (owner-only rules) + learned drug corrections from the user's own audit events |
| Email auth + invitation claim (D-012) | `lib/services/auth_service.dart` (claim writes ONLY `claimedBy`, per rules) |
| Export acknowledgement (A1.2) | `lib/services/export_engine.dart` + `Repo.awaitServerPersistence` |
| FHIR DocumentReference generator | `lib/domain/export.dart` (port of `packages/export`) — viewable + copyable in-app. Wording: **FHIR-ready**, never "integrated". |
| Emergency numbers (Bahrain) | `lib/domain/emergency.dart` — 999 / 444, bundled, mirrors `packages/rules/src/redFlags.ts` |

## Export semantics (HANDOFF A1.2)

There is no hospital EMR integration (§9.1). The system of record is Afia's
own backend, and §5's rule — positive acknowledgement, never local
send-completion — is satisfied truthfully:

- Signing automatically queues the record (no manual export button).
- `confirmed_in_system` is reached **only** when a Firestore **server**
  snapshot (not cache, no pending writes) confirms the signed record is
  persisted. The UI labels this state **"Recorded in Afia"**
  (AR: «مسجَّل في عافية») — it does not imply receipt by any hospital system.
- Offline, signed handovers stay honestly **queued** until the server truly
  has them; write failures surface as **export_failed** with the real error
  and a retry on the shift board.
- The FHIR generator produces valid `DocumentReference` JSON for a future
  EMR exporter — **FHIR-ready**, displayed and copyable, sent nowhere.

## Auth flow (D-012 — email + password only)

splash → first-run language (AR/EN) → email + password (sign in / create
account with min-8-char password + confirmation / password reset email) →
invitation check on `invitations/{lowercase-email}`:

- unclaimed → creates `practitioners/{uid}` from the invitation (signature
  identity copied once, immutable — rules enforce), then sets `claimedBy`
  (the only field a claim may touch)
- claimed by this uid → proceeds
- no invitation → "This email has no invitation" gate with prominent
  sign-out. Creating an email account grants NO access — **access exists by
  dashboard invitation only**; nothing in this app can grant it.

## Known device caveat

Live speech recognition and AAC capture run simultaneously; on some devices
the two audio clients can contend. If speech is unavailable the screen says
so and "Type instead" keeps the flow usable.
