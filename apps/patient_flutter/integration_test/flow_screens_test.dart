/// Drives the real app end-to-end on a simulator through the D-015
/// structure (auth first → Home → report flow → active card → detail) and
/// captures the verification screenshots. Uses the REAL Firebase backend:
/// signs in with a pre-created verification account and submits a synthetic
/// case.
///
/// Run:
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/flow_screens_test.dart -d SIMULATOR_ID
library;

import 'package:afia_patient/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const verifyEmail = 'patient.verify.1@nasgo.uk';
const verifyPassword = 'AfiaPatient!2026';

Future<void> pumpFor(WidgetTester tester, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Waits for [text]; when absent, nudges the page's scrollable downward so
/// lazily built ListView children below the fold get realised.
Future<void> waitForText(WidgetTester tester, String text,
    {int timeoutMs = 15000}) async {
  final end = DateTime.now().add(Duration(milliseconds: timeoutMs));
  var drags = 0;
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 150));
    if (find.textContaining(text).evaluate().isNotEmpty) return;
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      if (drags > 0 && drags % 6 == 0) {
        await tester.drag(scrollable.first, const Offset(0, 4000),
            warnIfMissed: false);
      } else {
        await tester.drag(scrollable.first, const Offset(0, -350),
            warnIfMissed: false);
      }
      drags++;
      await tester.pump(const Duration(milliseconds: 150));
    }
  }
  throw StateError('Timed out waiting for "$text"');
}

Future<void> tapText(WidgetTester tester, String text) async {
  await waitForText(tester, text);
  final f = find.textContaining(text).first;
  try {
    await tester.ensureVisible(f);
    await tester.pump(const Duration(milliseconds: 150));
  } catch (_) {}
  await tester.tap(f, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> tapExact(WidgetTester tester, String text) async {
  final f = find.text(text);
  await tester.ensureVisible(f.first);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.tap(f.first, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('walk the D-015 app and capture screens', (tester) async {
    await app.main();
    await pumpFor(tester, 2500);

    // First run → language choice.
    if (find.textContaining('Continue in English').evaluate().isNotEmpty) {
      await tapText(tester, 'Continue in English');
      await pumpFor(tester, 800);
    }

    // ── auth first: welcome → sign in (Firebase Auth may persist in the
    // simulator keychain across reinstalls, landing straight on Home). ─────
    if (find.textContaining('Create account').evaluate().isNotEmpty) {
      await pumpFor(tester, 600);
      await binding.takeScreenshot('01-welcome');
      await tapExact(tester, 'Sign in');
      await waitForText(tester, 'Sign in with email');
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), verifyEmail);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(fields.at(1), verifyPassword);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 300));
      await tapExact(tester, 'Sign in');
    }

    // ── home ───────────────────────────────────────────────────────────────
    await waitForText(tester, 'Report my condition', timeoutMs: 40000);
    await pumpFor(tester, 800);
    await binding.takeScreenshot('02-home');

    // ── report flow: red flags first, local and instant ────────────────────
    await tapText(tester, 'Report my condition');
    await waitForText(tester, 'chest pain');
    await pumpFor(tester, 600);
    await binding.takeScreenshot('03-red-flag');

    await tapExact(tester, 'Yes');
    await waitForText(tester, 'Call 999 now');
    await pumpFor(tester, 600);
    await binding.takeScreenshot('04-emergency-interrupt');
    await tapText(tester, 'Go back');

    for (final probe in [
      'finish a sentence',
      'bleeding',
      'confused',
      'fainted'
    ]) {
      await waitForText(tester, probe);
      await tapExact(tester, 'No');
    }

    // ── who / describe / functional ────────────────────────────────────────
    await tapText(tester, 'Myself');
    await waitForText(tester, 'Describe how you feel');
    await tester.enterText(find.byType(TextField).first,
        'I have been feverish since yesterday and my chest feels tight when I climb the stairs.');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 300));
    await tapExact(tester, 'Continue');

    for (var i = 0; i < 4; i++) {
      await waitForText(tester, 'Compared with your normal');
      await tapText(tester, 'Worse than normal');
    }

    // ── review: consent, then send ─────────────────────────────────────────
    await waitForText(tester, 'Check what you are sending');
    await pumpFor(tester, 600);
    await binding.takeScreenshot('05-review');
    await tapText(tester, 'shared with the nursing team');
    await tapText(tester, 'Send to the nursing team');

    // ── back on home: the active report's status card ──────────────────────
    await waitForText(tester, 'Your current report', timeoutMs: 40000);
    await pumpFor(tester, 2500); // let the first sync acknowledgement land
    await binding.takeScreenshot('06-home-active');

    // ── report detail: timeline + the MANDATORY honesty copy verbatim ─────
    await tapText(tester, 'View details');
    await waitForText(tester, 'No one is watching your condition');
    await pumpFor(tester, 800);
    await binding.takeScreenshot('07-report-detail');

    expect(find.textContaining('No one is watching your condition'),
        findsOneWidget);
  });
}
