/// Screenshot capture against the LIVE seeded Firestore database.
///
/// This harness signs in anonymously (a rules-permitted auth state used by
/// the seed scripts) purely to READ the seeded ward and exercise the draft
/// flow for screenshots. It builds the Shell directly with an in-memory
/// practitioner — the app's own invitation-only OTP flow is untouched and no
/// self-registration path exists in the shipped app.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:afia_clinician/domain/entities.dart';
import 'package:afia_clinician/domain/handover.dart' as domain;
import 'package:afia_clinician/domain/structuring.dart';
import 'package:afia_clinician/firebase_options.dart';
import 'package:afia_clinician/l10n/gen/app_localizations.dart';
import 'package:afia_clinician/services/prefs.dart';
import 'package:afia_clinician/services/repo.dart';
import 'package:afia_clinician/state/app_model.dart';
import 'package:afia_clinician/state/app_settings.dart';
import 'package:afia_clinician/theme/app_theme.dart';
import 'package:afia_clinician/ui/screens/confirm_screen.dart';
import 'package:afia_clinician/ui/screens/draft_review_screen.dart';
import 'package:afia_clinician/ui/shell.dart';

const me = Practitioner(
  id: 'prac-amara',
  externalIdentifier: null,
  createdAt: 0,
  name: 'Amara Okafor',
  role: PractitionerRole.chargeNurse,
  signatureIdentity: 'RN 88-1042 · Amara Okafor',
  invitedBy: 'system-demo',
);

Widget app(Widget home, {bool arabic = false}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(arabic ? 'ar' : 'en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(brightness: Brightness.dark, arabic: arabic),
      darkTheme: buildTheme(brightness: Brightness.dark, arabic: arabic),
      themeMode: ThemeMode.dark,
      home: home,
    );

Future<void> pumpUntil(WidgetTester tester, bool Function() condition,
    {int seconds = 25}) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (condition()) return;
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture screens from the live seeded ward', (tester) async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuth.instance.signInAnonymously();
    await Prefs.load();
    AppSettings.instance.loadFromPrefs();
    await AppSettings.instance.setLocale(const Locale('en'));

    AppModel.instance = AppModel(me: me);
    final model = AppModel.instance!;

    // ── 1 · Ward list (12 rows, live data) ──────────────────────────────
    await tester.pumpWidget(app(const Shell()));
    await pumpUntil(tester,
        () => model.patients.length >= 12 && model.templateVersion != null);
    await tester.pump(const Duration(seconds: 1));
    await binding.takeScreenshot('03-ward-list');

    // Dispose the Shell BEFORE mutating handovers — its interrupted-draft
    // resume listener would otherwise push the recording screen (and the
    // simulator's mic permission dialog) mid-test.
    await tester.pumpWidget(app(const Scaffold(body: SizedBox())));
    await tester.pump(const Duration(milliseconds: 300));

    // ── Draft flow: create a real draft on pat-4 (Samuel Osei) ──────────
    var draft = await Repo.instance.createHandover('pat-4', me.id);
    const transcript =
        'Samuel Osei, day two after his admission. He had ferosemide 40 mg IV '
        'this morning and paracetamol 1 g at six. Latest obs: blood pressure '
        '124/78, sats 96%. Pain is settled. Plan is to chase bloods and '
        'mobilise to the chair after lunch.';
    const structurer = KeywordStructurer();
    final fields = structurer.structureSync(transcript, model.template);
    draft = await Repo.instance.checkpointDraft(
      draft,
      transcript: transcript,
      fields: fields,
      formulary: model.formulary,
      template: model.template,
    );
    draft = await Repo.instance
        .setStatus(draft, domain.HandoverStatus.draftReady, me.id);
    await pumpUntil(
        tester, () => model.handovers.any((h) => h.id == draft.id));

    // ── 2 · Draft review (periwinkle chips, flags, confirm CTA) ─────────
    await tester.pumpWidget(app(DraftReviewScreen(handoverId: draft.id)));
    await pumpUntil(tester, () => true, seconds: 2);
    await binding.takeScreenshot('04-draft-review');

    // ── 3 · Confirmation layer (sound-alike, one at a time) ─────────────
    await tester.pumpWidget(app(ConfirmScreen(handoverId: draft.id)));
    await pumpUntil(tester, () => true, seconds: 2);
    await binding.takeScreenshot('05-confirm-chip');

    // Confirm every chip INDIVIDUALLY (§2.3 — one call per chip).
    var current = model.handovers.firstWhere((h) => h.id == draft.id);
    for (final chip in current.chips) {
      current = await Repo.instance.confirmSingleChip(current, chip.id, me);
    }
    await pumpUntil(
        tester,
        () => model.handovers
            .firstWhere((h) => h.id == draft.id)
            .chips
            .every((c) => c.confirmed));

    // ── 4 · Sign sheet (hold-to-sign, flag reasons) ─────────────────────
    await tester.pumpWidget(app(DraftReviewScreen(handoverId: draft.id)));
    await pumpUntil(tester, () => true, seconds: 2);
    final signButton = find.text('Sign');
    if (signButton.evaluate().isNotEmpty) {
      await tester.tap(signButton);
      await tester.pump(const Duration(milliseconds: 800));
      await binding.takeScreenshot('06-sign-sheet');
    }

    // ── 5 · Ward list in Arabic (RTL) ───────────────────────────────────
    await tester.pumpWidget(app(const Shell(), arabic: true));
    await pumpUntil(tester, () => true, seconds: 3);
    await binding.takeScreenshot('07-ward-list-ar');
  });
}
