/// Widget tests for the D-015 structure. Run WITHOUT Firebase — every
/// Firebase-touching seam degrades gracefully, which is itself a §2.7
/// property: the door and the emergency fixture must exist before any
/// backend does.
library;

import 'package:afia_patient/app.dart';
import 'package:afia_patient/domain/episode.dart';
import 'package:afia_patient/l10n/gen/app_localizations.dart';
import 'package:afia_patient/services/prefs.dart';
import 'package:afia_patient/state/app_settings.dart';
import 'package:afia_patient/state/episode_model.dart';
import 'package:afia_patient/ui/home_shell.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _appShell(Widget home) => MaterialApp(
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.load();
    AppSettings.instance.loadFromPrefs();
  });

  testWidgets(
      'auth-first: language → welcome; the EMERGENCY FIXTURE is on the '
      'language, welcome AND sign-in screens (D-015 invariant)',
      (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;
    tester.view.padding = FakeViewPadding(top: 186); // 62pt @3x
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AfiaPatientApp());
    await tester.pump(const Duration(milliseconds: 300));

    // First run: the language choice — with the fixture already present.
    expect(find.text('Continue in English'), findsOneWidget);
    expect(find.text('Emergency'), findsOneWidget);

    await tester.tap(find.text('Continue in English'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400)); // auth stream event

    // Auth first: the welcome door with two big obvious buttons — and the
    // fixture still present (a person in distress at the login wall can
    // still call 999, §2.7).
    expect(find.textContaining('Tell the nursing team'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Emergency'), findsOneWidget);

    // Into the sign-in form — fixture still there.
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Sign in with email'), findsOneWidget);
    expect(find.text('Emergency'), findsOneWidget);

    // The fixture opens the interrupt — the app's only red screen — from
    // the auth wall, before any account exists.
    await tester.tap(find.text('Emergency'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Call 999 now'), findsOneWidget);
    await tester.tap(find.text('Go back'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Sign in with email'), findsOneWidget);
  });

  testWidgets('Home shows the resume-draft card and reopens the flow at the '
      'saved step (F-055 + D-015 resume)', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;
    tester.view.padding = FakeViewPadding(top: 186);
    addTearDown(tester.view.reset);

    EpisodeModel.instance.debugSetEpisode(const EpisodeState(
      name: 'Sara',
      draftStarted: true,
      step: Step(StepKind.voice),
      transcript: 'I feel dizzy since morning.',
    ));

    await tester.pumpWidget(_appShell(const HomeShell()));
    await tester.pump(const Duration(milliseconds: 300));

    // Greeting + the one big action + the resume card.
    expect(find.textContaining('Hello, Sara'), findsOneWidget);
    expect(find.text('Report my condition'), findsOneWidget);
    expect(find.text('Finish your report'), findsOneWidget);

    // Resume → the flow reopens exactly at the saved step (describe),
    // with the calm step indicator D-015 permits.
    await tester.tap(find.text('Continue where you left off'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(find.text('Describe how you feel'), findsOneWidget);
    expect(find.text('Step 3 of 5'), findsOneWidget);
    // The draft text survived the round trip (F-055).
    expect(EpisodeModel.instance.episode.transcript,
        'I feel dizzy since morning.');
  });

  testWidgets('flow back affordance walks one step back and preserves data',
      (tester) async {
    EpisodeModel.instance.debugSetEpisode(const EpisodeState(
      name: 'Sara',
      draftStarted: true,
      step: Step(StepKind.voice),
      transcript: 'Still saved.',
    ));
    final model = EpisodeModel.instance;
    expect(model.goBackStep(), isTrue);
    expect(model.episode.step.kind, StepKind.who);
    expect(model.goBackStep(), isTrue);
    expect(model.episode.step.kind, StepKind.redflag);
    expect(model.episode.step.index, 4);
    for (var i = 0; i < 4; i++) {
      expect(model.goBackStep(), isTrue);
    }
    // First step: back exits the flow (false) — the draft stays saved.
    expect(model.goBackStep(), isFalse);
    expect(model.episode.transcript, 'Still saved.');
    expect(model.episode.hasDraft, isTrue);
  });
}
