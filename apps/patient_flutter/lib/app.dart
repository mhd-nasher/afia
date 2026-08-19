/// Root widget (D-015: a conventional, obvious app — auth first, then Home
/// with a bottom tab bar). Structure is still the safety argument
/// (§2.7 / F-051):
///
///   MaterialApp.builder
///     └─ Stack
///         ├─ Navigator child    ← routes: gate → welcome/auth → tabs/flows
///         ├─ EmergencyInterrupt ← full-screen overlay when triggered
///         └─ SafetyLayer        ← the emergency fixture, above EVERYTHING —
///                                 including the welcome/auth screens: a
///                                 person in distress at the login wall can
///                                 still reach 999 with one tap.
///
/// Warm light theme only; AR/EN with full RTL.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/gen/app_localizations.dart';
import 'services/auth_service.dart';
import 'state/app_settings.dart';
import 'state/episode_model.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'ui/home_shell.dart';
import 'ui/screens/auth_screens.dart';
import 'ui/screens/emergency_interrupt.dart';
import 'ui/screens/language_screen.dart';
import 'ui/widgets/safety_layer.dart';

class AfiaPatientApp extends StatelessWidget {
  const AfiaPatientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final settings = AppSettings.instance;
        final locale = settings.resolveLocale(
            WidgetsBinding.instance.platformDispatcher.locales);
        final arabic = locale.languageCode == 'ar';
        return MaterialApp(
          title: 'Afia',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildPatientTheme(arabic: arabic),
          builder: (context, child) {
            return Stack(children: [
              child ?? const SizedBox.shrink(),
              // The interrupt overlays every route but sits BELOW the
              // safety layer's decision to yield to it.
              ListenableBuilder(
                listenable: EpisodeModel.instance,
                builder: (context, _) =>
                    EpisodeModel.instance.episode.emergency
                        ? const EmergencyInterrupt()
                        : const SizedBox.shrink(),
              ),
              const SafetyLayer(),
            ]);
          },
          home: const _Root(),
        );
      },
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    // Listens directly: `home:` keeps the same const widget across
    // MaterialApp rebuilds, so the swap must happen INSIDE this widget.
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        // First-run language choice (AR/EN) before anything else. The safety
        // layer is already present above it — emergency works from screen
        // one, before any account exists (§2.7).
        if (!AppSettings.instance.localeChosen) {
          return const LanguageScreen();
        }
        return const AuthGate();
      },
    );
  }
}

/// Auth FIRST (D-015): no session → welcome (register / sign in); an
/// existing session goes straight to Home. Firebase being unreachable never
/// blocks the screen (the fixture and 999 work regardless).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authState = _safeAuthState();

  static Stream<User?> _safeAuthState() {
    try {
      return PatientAuthService.instance.authState;
    } catch (_) {
      // Firebase failed to initialise (offline first start / tests): show
      // the welcome door; the emergency fixture works regardless.
      return Stream<User?>.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: PatientColors.pageBg,
            body: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: PatientColors.action),
              ),
            ),
          );
        }
        if (snapshot.data == null) return const WelcomeScreen();
        return const HomeShell();
      },
    );
  }
}
