import 'package:afia_patient/app.dart';
import 'package:afia_patient/domain/episode.dart';
import 'package:afia_patient/services/prefs.dart';
import 'package:afia_patient/state/app_settings.dart';
import 'package:afia_patient/state/episode_model.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('full app wrapper places language title below the fixture',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.load();
    AppSettings.instance.loadFromPrefs();

    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;
    tester.view.padding = FakeViewPadding(top: 186); // 62pt @3x
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AfiaPatientApp());
    await tester.pump(const Duration(milliseconds: 300));

    final title = find.text('Afia · عافية');
    expect(title, findsOneWidget);
    debugPrint('TITLE top: ${tester.getTopLeft(title)}');
    debugPrint(
        'EMERGENCY top: ${tester.getTopLeft(find.text('Emergency'))}');
    expect(tester.getTopLeft(title).dy, greaterThanOrEqualTo(136));

    // Tapping the language button must reach the entry door — the safety
    // layer above the Navigator must never swallow taps.
    await tester.tap(find.text('Continue in English'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Tell the nursing team'), findsOneWidget);

    // Entry: both consent toggles must visibly enable Continue (regression
    // for the const-identity rebuild bug).
    Future<void> scrollTapText(String text) async {
      final f = find.textContaining(text);
      await tester.dragUntilVisible(
          f, find.byType(Scrollable).first, const Offset(0, -120));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(f.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
    }

    await scrollTapText('terms of use');
    await scrollTapText('shared with the nursing team');
    await scrollTapText('Continue');

    // Red-flag question 1, three identically styled answers.
    expect(find.textContaining('chest pain'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
    expect(find.text("I don't know"), findsOneWidget);

    // YES → the full-screen interrupt, immediately and locally.
    await tester.tap(find.text('Yes'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Call 999 now'), findsOneWidget);

    // The quiet path back — the answer stays recorded; flow continues on
    // the SECOND question (the step advanced when the answer was stored).
    await tester.tap(find.text('Go back'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('finish a sentence'), findsOneWidget);

    // ── dock regression: it renders OUTSIDE any Scaffold, so it must carry
    // its own Material (a missing one throws "No Material widget found").
    EpisodeModel.instance.debugSetEpisode(const EpisodeState(
      step: Step(StepKind.updateConfirm),
      caseId: 'case-widget-test',
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.text('My condition has changed'), findsOneWidget);
    expect(find.textContaining('Nurse line'), findsOneWidget);
    expect(find.textContaining('added to your existing case'), findsOneWidget);
  });
}
