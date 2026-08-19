# Afia — Patient app (Flutter)

The patient-side surface of the Afia clinical handover platform: describe
your symptoms before attending, at home. Warm, never clinical — this app is
opened once, alone, in fright. One question, one action, one screen. No tab
bar, no bottom navigation, no progress bar, no step counter (HANDOFF §6 /
F-050).

> **Owner decisions this build carries (deviations from HANDOFF as
> written):**
> 1. **Real accounts.** §6 said "no accounts"; the product owner requires
>    real self-registered patient accounts (phone OTP or email+password).
>    See "Why auth comes AFTER the red-flag questions" below.
> 2. **No demo banner.** The product is moving from demonstration to real
>    use, so the persistent `SYNTHETIC DEMO DATA` strip (F-090) and all
>    demo wording were removed from this app by owner instruction. The
>    mandatory status-screen safety copy is a product safety feature, not a
>    demo label — it stays, verbatim.
>
> Note the tension a reviewer should see: HANDOFF §9 lists unresolved
> safety questions (nurse review latency above all) and F-090 still stands
> in `docs/acceptance.md` for the other surfaces. Moving to real use is a
> product-owner call recorded here, not an engineering conclusion.

## Run it

```bash
cd apps/patient_flutter
flutter pub get
flutter gen-l10n            # generates lib/l10n/gen (also runs on build)
flutter test                # constraint tests (T-001/T-002/T-007 mirrors)
flutter analyze

# iOS simulator
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ios --simulator --debug
flutter run                 # picks a booted simulator

# Full UI walk + screenshots on a booted simulator (writes docs_screens/):
# entry → red flags → emergency interrupt → review → account gate → status.
# Signs in with a pre-created verification account and writes a synthetic
# case to the live database.
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/flow_screens_test.dart -d <simulator-id>

# Android
flutter build apk --debug
# apk lands at build/app/outputs/flutter-apk/app-debug.apk
```

### On a physical device

- **iOS**: open `ios/Runner.xcworkspace` in Xcode, select your team under
  Signing & Capabilities, choose the device, Run. Deployment target is iOS
  15.0 (Firebase SDK 12 requirement). If pods are stale:
  `cd ios && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install --repo-update`
  (the locale vars matter — CocoaPods crashes on an unset locale).
- **Android**: enable USB debugging, then `flutter install` or
  `adb install build/app/outputs/flutter-apk/app-debug.apk`. `minSdk` is 23
  (firebase_auth requirement).

### Console toggles the operator must do once

1. **Phone provider**: Firebase console → Authentication → Sign-in method →
   Phone → Enable. For testing without real SMS, add a test number (e.g.
   `+97333000001` with code `123456`). Patients self-register — no
   invitation seeding is needed for this app.
2. **Email/Password provider**: same screen → Email/Password → Enable
   (registration, sign-in, and password reset all use it).
3. Firebase AI Logic is already enabled for this app's ids (done via the
   Firebase MCP `firebase_init {ailogic}` for both the iOS and Android app
   registrations).

## Why auth comes AFTER the red-flag questions

HANDOFF §6 originally specified no accounts. The product owner requires
real patient accounts (self-registered, phone OTP with +973 default, or
email+password with reset). The ordering is the safety-preserving part of
that decision:

- **Red flags run before any account exists.** Evaluation is a local,
  deterministic, pure-Dart rule (§2.7) with the questions and the emergency
  numbers (999 / 444, Bahrain) bundled at build. A person in danger reaches
  the full-screen emergency interrupt with zero network, zero sign-in, zero
  typing beyond three 64px buttons.
- The account gate appears only at the moment an account is genuinely
  needed: attaching the finished description to a durable case record that
  the person can update later ("my condition has changed") and that the
  nursing team can attribute. Nothing typed before the gate can be lost —
  every answer persists on-device from the first tap (F-055).
- Safety gated behind a login screen would put registration friction inside
  the emergency path, which §2.7 exists to forbid.

## Where things live

| Concern | Location |
|---|---|
| §2 constraints (escalate max-only, appendUpdate one-way, UNKNOWN semantics, bundled red flags/numbers, deterministic gaps) | `lib/domain/` — pure Dart, mirrored from `packages/rules` + `packages/core` |
| Constraint tests incl. the airplane-mode test | `test/domain_test.dart` |
| The emergency fixture + dock (outside the step hierarchy, §2.7/F-051) | `lib/ui/widgets/safety_layer.dart`, composed in `lib/app.dart`'s MaterialApp builder — above the Navigator, so no screen/keyboard/overlay can occlude it |
| The one red screen | `lib/ui/screens/emergency_interrupt.dart` |
| Flow engine + incremental save | `lib/state/episode_model.dart` + `lib/domain/episode.dart` (SharedPreferences JSON on every change) |
| Firestore case seam + sync honesty | `lib/services/case_repo.dart` — `cases` collection, shape mirrors `packages/core/src/case.ts` + additive `accountUid` |
| Auth (phone OTP +973 / email+password, self-registration) | `lib/services/auth_service.dart` → `patientAccounts/{uid}` (owner-only rules) |
| **Gemini model id** | `lib/services/ai_service.dart` → `geminiModelId` (`gemini-3.5-flash`, same constant as the clinician app, with a fallback chain) |
| AI memory (workflow prefs only) | `lib/services/memory_service.dart` → `aiMemory/{uid}` (owner-only, deletable) |
| Voice capture / speech-to-text | `lib/services/recorder.dart` (AAC → base64 data URI, <900KB convention) / `lib/services/transcriber.dart` (`ar_SA` / `en_GB`) |
| Copy, AR+EN, full RTL | `lib/l10n/app_en.arb` / `app_ar.arb` |

## The AI safety envelope (§4.3 + §11 — patient-facing, extra strict)

**Allowed** — reorganisation of the patient's own words, nothing else:
tidying their description (own sentences only, validated in code: any output
word not present in their text discards the result), and AR↔EN translation
of their own text. Machine output renders in periwinkle (machine-made,
unverified) until the patient explicitly accepts it.

**Forbidden and structurally absent**: triage/severity/urgency, diagnosis,
medical advice, symptom interpretation, reassurance or any wording implying
the patient is fine, clinical numbers or urgency levels. These are (1)
prohibited in the system prompt, (2) inexpressible — no tool exists through
which a judgement could flow, and (3) irrelevant to safety logic: red-flag
evaluation never touches the model (it is local deterministic Dart, §2.7).

**Offline**: a deterministic tidy fallback (whitespace/duplicate/filler
cleanup — same input, same output) runs instead. The flow never depends on
the model.

## What is real vs simulated

- **Real**: Firestore reads/writes against the live `afia-12f38` database
  (me-central2) with offline persistence; phone OTP and email+password auth
  (once the providers are enabled); consent records; one-way priority
  escalation enforced by the deployed rules; device speech-to-text; AAC
  audio capture stored as a playable base64 data URI in the case update
  (oversized audio stays on-device with `urlOmittedReason` — same
  convention as the clinician app); Gemini tidy/translate via Firebase AI
  Logic.
- **Still bounded by the platform's honesty rules**: nobody is watching
  continuously, and the app says so — the status screen's mandatory copy is
  verbatim and non-negotiable. The red-flag question set is bundled at
  build (ids match the seeded `redFlagQuestions` collection) rather than
  fetched — deliberate, per §2.7: a server config fetch would put the
  network inside the escalation path.
- **Sync honesty (F-057)**: an update is marked *sent* only when the
  Firestore SERVER acknowledges the write (`set()` completing), never on
  local echo. Until then the status screen says, in so many words, that it
  is saved on this phone and the nursing team has NOT seen it.

## Erasure (§3.3)

Account screen → "Delete my data": deletes `patientAccounts/{uid}` and
`aiMemory/{uid}` (owner-only rules allow it), stamps `withdrawnAt` on the
consent record (withdrawal is a timestamp, not a deletion), wipes the
device-local episode, and signs out. The submitted case record itself stays
with the nursing team — the deployed rules forbid case deletion (a clinical
record cannot silently vanish), and the confirmation copy says so honestly.
