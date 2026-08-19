/// Root widget. Structure IS the safety argument (§2.7 / F-051):
///
///   MaterialApp.builder
///     └─ Stack
///         ├─ Navigator child    ← the ENTIRE step hierarchy lives here
///         ├─ EmergencyInterrupt ← full-screen overlay when triggered
///         └─ SafetyLayer        ← fixture + dock, above everything
///
/// The emergency control is composed OUTSIDE the step view hierarchy, so no
/// screen, keyboard, overlay or loading state can occlude it — a step cannot
/// even express covering it. Warm light theme only; AR/EN with full RTL.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/gen/app_localizations.dart';
import 'state/app_settings.dart';
import 'state/episode_model.dart';
import 'theme/app_theme.dart';
import 'ui/flow_host.dart';
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
              // The interrupt overlays the steps but sits BELOW the
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
        // layer is already present above it — emergency works from screen one.
        if (!AppSettings.instance.localeChosen) {
          return const LanguageScreen();
        }
        return const FlowHost();
      },
    );
  }
}
