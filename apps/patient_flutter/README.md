# Afia — Patient app (Flutter)

The patient-side surface of the Afia clinical handover platform: describe
your symptoms before attending, at home. Warm, never clinical. Since owner
decision **D-015** (docs/DECISIONS.md + HANDOFF Amendment 2) this is a
conventional, extremely obvious app: **auth first → Home with one big
action → bottom tab bar** (الرئيسية · تقاريري · حسابي). The star
requirement, verbatim: "لازم يكون التطبيق واضح جدا ومنطقي وسهل".

> **Owner decisions this build carries:**
> 1. **Real accounts, email + password only** (D-012 removed phone/OTP
>    entirely): register, sign in, password reset. Patients self-register.
> 2. **No demo banner / no demo wording** (owner real-use pivot). The
>    mandatory status honesty copy is a product safety feature, not a demo
>    label — it stays, verbatim.
> 3. **D-015 restructure**: auth first, Home + tabs + reports history,
>    step indicators allowed in the flows. Supersedes HANDOFF §6's
>    no-tab-bar/no-home design and §11's tab-bar ban (Amendment 2).

## The structure

- **Launch** → first-run language choice (AR/EN, full RTL) → **welcome**
  (إنشاء حساب / تسجيل الدخول) → after register: one short profile step
  (name + terms). Sessions persist — later launches go straight to Home.
- **الرئيسية (Home)**: greeting by name, ONE big action «أبلغ عن حالتي»,
  the active report's status card («حالتي تغيرت», tap → detail), a resume
  card when a draft is unfinished, and a quiet help card (nurse line 444 ·
  emergency 999).
- **تقاريري (My reports)**: the account's cases, newest first (equality
  query on `accountUid`, client-side sort — no composite index needed).
  Tap → detail: full timeline + the MANDATORY honesty copy verbatim.
- **حسابي (Account)**: name, email, language, delete-my-data (§3.3),
  prominent sign out.
- **Report flow** (from Home): red flags → who → describe (voice/type) →
  functional → review (+ sharing-consent toggle) → send → back to Home.
  A calm step indicator («٢ من ٥») and a back affordance on every step
  (both explicitly permitted/required by D-015). Exiting mid-flow keeps
  the draft; Home offers «أكمل تقريرك».
- **Active-case rule**: one active case at a time. «أبلغ عن حالتي» with an
  active case routes to an explanation screen → add an update (APPENDS to
  the same case, F-056) or explicitly start a separate new report.

## Safety invariants (unchanged by any amendment)

- **The emergency fixture is on EVERY screen INCLUDING welcome/auth** —
  composed in the MaterialApp builder ABOVE the Navigator, so no screen,
  keyboard, overlay or loading state can occlude it (§2.7/F-051). It is
  not red; red is spent entirely on the interrupt screen. It works before
  any account exists and offline (numbers bundled: 999 / 444, Bahrain).
- **Red flags are local, deterministic, offline** — pure Dart, bundled
  bilingual questions, evaluated after every answer; a YES raises the
  full-screen interrupt instantly. Airplane-mode test in
  `test/domain_test.dart` stays green.
- **Mandatory honesty copy verbatim** (EN + faithful AR) on the report
  detail view. Sync honesty: an update is *sent* only on Firestore SERVER
  acknowledgement; until then the UI says saved-on-this-phone, not sent.
- **UNKNOWN is first-class** (§2.2); escalation is one-way (§2.1); no
  clinical numbers, no urgency levels, no risk language anywhere a patient
  can see (§11).

## Run it

```bash
cd apps/patient_flutter
flutter pub get
flutter gen-l10n
flutter test                # domain constraints + widget flow tests
flutter analyze

# iOS simulator
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ios --simulator --debug
flutter run

# Full UI walk + screenshots on a booted simulator (writes docs_screens/):
# welcome → sign-in → home → report flow → emergency interrupt → review →
# active card → detail. Signs in with a pre-created verification account
# and writes a synthetic case to the live database.
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/flow_screens_test.dart -d SIMULATOR_ID

# Release IPA (App Store Connect method, team SDBHYX4BF4)
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist
```

On a physical device: open `ios/Runner.xcworkspace`, set the team, run
(deployment target iOS 15.0; if pods are stale:
`cd ios && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install --repo-update`).
Android: `flutter build apk --debug`, `minSdk` 23.

Console prerequisites (once): Authentication → Email/Password enabled (the
ONLY method, D-012). Firebase AI Logic is enabled for this app's ids.

## Where things live

| Concern | Location |
|---|---|
| §2 constraints (escalate max-only, appendUpdate one-way, UNKNOWN semantics, bundled red flags/numbers, deterministic gaps) | `lib/domain/` — pure Dart, mirrored from `packages/rules` + `packages/core` |
| Constraint tests incl. the airplane-mode test | `test/domain_test.dart` |
| Emergency fixture (above the Navigator, every screen incl. auth) | `lib/ui/widgets/safety_layer.dart` + `lib/app.dart` builder |
| The one red screen | `lib/ui/screens/emergency_interrupt.dart` |
| Auth first (welcome / register+profile / sign-in / reset) | `lib/ui/screens/auth_screens.dart` + `lib/services/auth_service.dart` → `patientAccounts/{uid}` |
| Tabs shell + Home / Reports / Account | `lib/ui/home_shell.dart`, `lib/ui/screens/{home_tab,reports_tab,account_tab}.dart` |
| Report flow + update flow + active-case gate | `lib/ui/screens/{report_flow_screen,update_flow_screen,active_case_gate_screen}.dart` |
| Report detail (timeline + mandatory copy) | `lib/ui/screens/report_detail_screen.dart` |
| Flow engine + incremental draft save (F-055) | `lib/state/episode_model.dart` + `lib/domain/episode.dart` |
| Firestore case seam + sync honesty | `lib/services/case_repo.dart` — `cases` collection + additive `accountUid` |
| **Gemini model id** | `lib/services/ai_service.dart` → `geminiModelId` (`gemini-3.5-flash`) |
| Voice capture / speech-to-text | `lib/services/recorder.dart` / `lib/services/transcriber.dart` (`ar_SA`/`en_GB`) |
| Copy, AR+EN, full RTL | `lib/l10n/app_en.arb` / `app_ar.arb` |

## The AI safety envelope (§4.3 + §11 — unchanged)

Allowed: reorganising the patient's OWN words (tidy, AR↔EN translate) —
output validated word-by-word against their text, rendered in periwinkle
until accepted, deterministic offline fallback. Forbidden and structurally
absent: triage/severity/urgency, diagnosis, advice, reassurance, clinical
numbers. Red-flag evaluation never touches the model.

## Erasure (§3.3)

Account tab → "Delete my data": deletes `patientAccounts/{uid}` and
`aiMemory/{uid}`, stamps `withdrawnAt` on the consent record, wipes the
device-local state, signs out. Case records stay with the nursing team
(rules forbid case deletion) — the copy says so honestly.
