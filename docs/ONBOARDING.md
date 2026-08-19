# ONBOARDING.md — run everything from zero

> Prereqs: Node 22+, npm 10+, Flutter 3.35+ (Dart 3.9+), Xcode 16+ with CocoaPods,
> a Mac for iOS work. Access needed from Mohammed: GitHub repo, Firebase project
> `afia-12f38` (IAM), Vercel project `afia-dashboard`, App Store Connect (NASGO LTD).

## 1. First: read the law
`docs/RULES.md` → `docs/HANDOFF.md` (incl. Amendment 1) → `docs/STATUS.md`. If you use
an AI assistant, it reads `CLAUDE.md`/`AGENTS.md` at the root automatically — do not
delete those files.

## 2. TS workspace (packages + web reference apps + dashboard)
```bash
npm install
npm test                      # 38 tests — the constraint suite. Must be green.
npm run dev:clinician         # web reference app  → http://localhost:5171
npm run dev:patient           # web reference app  → http://localhost:5172
npm run dev:dashboard         # dashboard (local)  → http://localhost:5173
```
All web surfaces default to the LIVE Firebase backend (`VITE_AFIA_BACKEND=local` for an
offline, seeded, on-device store).

## 3. Flutter apps
```bash
cd apps/clinician_flutter     # or apps/patient_flutter
flutter pub get
flutter analyze && flutter test          # must be green (RULES.md W1)
cd ios && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install && cd ..
open ios/Runner.xcworkspace              # ALWAYS the .xcworkspace, never .xcodeproj
```
Run on simulator or a device (Signing & Capabilities → team). Deployment target is
iOS 15.0 (Firebase SDK 12 requires it) — do not lower it.
CocoaPods crashes without a UTF-8 locale — keep the LANG/LC_ALL prefix.

## 4. Sign in (dev/test)
Email + password is the ONLY sign-in method everywhere (D-012 / RULES.md W7 — phone/OTP
does not exist in this product).
- **Clinician app**: ACCESS is invitation-gated. Create an invitation in the dashboard
  (Users → Invite clinician) — invitations are keyed by **lowercase email**
  (`invitations/{email}`) — then create the account IN THE APP with that same email +
  a password. An email without an invitation reaches only the not-invited screen.
- **Patient app**: self-register in the app (email+password).
- **Dashboard**: https://afia-dashboard.vercel.app — register a manager account, or ask
  Mohammed for the admin account.

## 5. Firebase
Project `afia-12f38` · Firestore `(default)` in me-central2 · rules in
`/firestore.rules` (deploy: `firebase deploy --only firestore` after validating —
see RULES.md R13/W8). Web SDK config is public and lives in
`packages/core/src/firebase.ts`. AI Logic (Gemini) is enabled; model constant per app in
`lib/services/ai_config.dart`.

## 6. Dashboard deploy (Vercel)
```bash
npm run build --workspace apps/dashboard
npx vercel deploy --prod       # project afia-dashboard (ask Mohammed for access)
```
SPA rewrites are in `apps/dashboard/vercel.json`.

## 7. TestFlight (iOS release)
```bash
cd apps/clinician_flutter                 # or patient_flutter
flutter build ios --release --no-codesign
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release \
  -destination 'generic/platform=iOS' -archivePath ../build/ios/archive/Runner.xcarchive \
  archive -allowProvisioningUpdates
xcodebuild -exportArchive -archivePath ../build/ios/archive/Runner.xcarchive \
  -exportPath ../build/ios/ipa -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates
```
Team: NASGO LTD (SDBHYX4BF4). Bump `version:` in pubspec.yaml (`1.0.0+2`, `+3`, …)
before each upload. Upload the `.ipa` via Transporter or Xcode Organizer.

## 8. Useful maps
- Domain model / wire format: `packages/core/src/` (TS source of truth) mirrored in each
  app's `lib/domain/`.
- Pure clinical rules: `packages/rules/src/` (dependency-free — keep it that way).
- Designs: `designs/` (clinician design HTML + dashboard brief + patient notes).
- Per-app details: each app's `README.md`.
- What's broken/missing right now: `docs/STATUS.md`.
