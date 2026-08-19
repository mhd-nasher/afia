/// Drives the real app end-to-end on a simulator and captures the
/// verification screenshots (entry, a red-flag question, the emergency
/// interrupt, review, status). Uses the REAL Firebase backend: signs in with
/// a pre-created verification account and submits a synthetic case.
///
/// Run:
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/flow_screens_test.dart -d SIMULATOR_ID
library;

import 'package:afia_patient/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Pass real values at run time — no credentials live in the repo:
//   flutter drive ... --dart-define=AFIA_VERIFY_EMAIL=... --dart-define=AFIA_VERIFY_PASSWORD=...
const verifyEmail = String.fromEnvironment('AFIA_VERIFY_EMAIL', defaultValue: 'set-me@example.test');
const verifyPassword = String.fromEnvironment('AFIA_VERIFY_PASSWORD', defaultValue: 'set-me');

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
      // Scroll down; every ~6 nudges, rewind to the top and start again.
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

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('walk the episode and capture screens', (tester) async {
    await app.main();
    await pumpFor(tester, 2000);

    // First run → language choice (if state survived a previous run, skip).
    if (find.textContaining('Continue in English').evaluate().isNotEmpty) {
      await tapText(tester, 'Continue in English');
    }

    // ── entry ──────────────────────────────────────────────────────────────
    await waitForText(tester, 'Tell the nursing team');
    await pumpFor(tester, 600);
    await binding.takeScreenshot('01-entry');

    await tester.enterText(find.byType(TextField).first, 'Sara');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 300));
    await tapText(tester, 'I agree to the terms of use');
    await tapText(tester, 'shared with the nursing team');
    await tapText(tester, 'Continue');

    // ── red flag 1 ─────────────────────────────────────────────────────────
    await waitForText(tester, 'chest pain');
    await pumpFor(tester, 600);
    await binding.takeScreenshot('02-red-flag');

    // YES → the emergency interrupt, locally and instantly.
    await tapText(tester, 'Yes');
    await waitForText(tester, 'Call 999 now');
    await pumpFor(tester, 600);
    await binding.takeScreenshot('03-emergency-interrupt');

    // Quiet path back — the answer stays recorded.
    await tapText(tester, 'Go back');

    // Remaining red flags → No.
    for (final probe in [
      'finish a sentence',
      'bleeding',
      'confused',
      'fainted'
    ]) {
      await waitForText(tester, probe);
      await tapText(tester, 'No');
    }

    // ── who / voice ────────────────────────────────────────────────────────
    await tapText(tester, 'Myself');
    await waitForText(tester, 'Describe how you feel');
    await tester.enterText(find.byType(TextField).first,
        'I have been feverish since yesterday and my chest feels tight when I climb the stairs.');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 300));
    await tapText(tester, 'Continue');

    // ── functional ×4 ──────────────────────────────────────────────────────
    for (var i = 0; i < 4; i++) {
      await waitForText(tester, 'Compared with your normal');
      await tapText(tester, 'Worse than normal');
    }

    // ── review ─────────────────────────────────────────────────────────────
    await waitForText(tester, 'Check what you are sending');
    await pumpFor(tester, 600);
    await binding.takeScreenshot('04-review');

    await tapText(tester, 'Send to the nursing team');

    // ── account gate → email sign-in ───────────────────────────────────────
    // Firebase Auth persists in the simulator keychain across reinstalls, so
    // on a re-run the gate is skipped and send goes straight to status.
    var sawGate = false;
    final gateEnd = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(gateEnd)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.textContaining('Sign in to send').evaluate().isNotEmpty) {
        sawGate = true;
        break;
      }
      if (find.textContaining('What you have sent').evaluate().isNotEmpty) {
        break;
      }
    }
    if (sawGate) {
      // D-012: the gate goes straight to the email form (register variant);
      // switch to sign-in for the pre-created verification account.
      await tapText(tester, 'I already have an account');
      await waitForText(tester, 'Sign in with email');
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), verifyEmail);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(fields.at(1), verifyPassword);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 300));
      // Exact match: 'Sign in' the button, not the 'Sign in with email'
      // title.
      final signInButton = find.text('Sign in');
      await tester.ensureVisible(signInButton.first);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(signInButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    }

    // ── status ─────────────────────────────────────────────────────────────
    await waitForText(tester, 'What you have sent', timeoutMs: 40000);
    final pending = tester.takeException();
    if (pending != null) {
      debugPrint('PENDING EXCEPTION on status: $pending');
    }
    await pumpFor(tester, 2500); // let the first sync acknowledgement land
    final pending2 = tester.takeException();
    if (pending2 != null) {
      debugPrint('PENDING EXCEPTION 2 on status: $pending2');
    }
    await binding.takeScreenshot('05-status');

    expect(find.textContaining('No one is watching your condition'),
        findsOneWidget);
  });
}
