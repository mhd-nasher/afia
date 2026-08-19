/// Root widget: theme (dark default), AR/EN locales with full RTL, and the
/// auth gate (splash → language choice → phone OTP → invitation check →
/// shell). Real-use pilot posture per HANDOFF Amendment 1.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'domain/entities.dart';
import 'l10n/gen/app_localizations.dart';
import 'services/assistant/assistant_service.dart';
import 'services/auth_service.dart';
import 'services/structurer_service.dart';
import 'state/app_model.dart';
import 'state/app_settings.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'ui/screens/auth/language_screen.dart';
import 'ui/screens/auth/not_invited_screen.dart';
import 'ui/screens/auth/phone_screen.dart';
import 'ui/shell.dart';
import 'ui/widgets/common.dart';

class AfiaClinicianApp extends StatelessWidget {
  const AfiaClinicianApp({super.key});

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
          title: 'Afia Handover',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildTheme(brightness: Brightness.light, arabic: arabic),
          darkTheme: buildTheme(brightness: Brightness.dark, arabic: arabic),
          themeMode: settings.themeMode, // dark is the default
          // HANDOFF Amendment A1.1 — the demo banner requirement is
          // withdrawn; screens own their top safe area directly.
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  ClaimOutcome? _claim;
  String? _claimForUid;
  bool _claiming = false;

  Future<void> _runClaim(User user) async {
    if (_claiming) return;
    _claiming = true;
    try {
      final outcome = await AuthService.instance.ensurePractitioner(user);
      Practitioner? me;
      if (outcome == ClaimOutcome.practitionerReady) {
        me = await AuthService.instance.currentPractitioner();
      }
      if (!mounted) return;
      setState(() {
        _claim = outcome;
        _claimForUid = user.uid;
      });
      if (me != null) {
        AppModel.instance?.dispose();
        AppModel.instance = AppModel(me: me);
        // Learned preferences feed the structurer (assistant memory).
        AssistantService.structuringContext(me.id).then((ctx) {
          StructuringService.instance.preferencesContext = ctx;
        }).catchError((_) {});
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _claim = ClaimOutcome.notInvited;
        _claimForUid = user.uid;
      });
    } finally {
      _claiming = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // First-run language choice (AR/EN) before anything else.
    if (!AppSettings.instance.localeChosen) {
      return const LanguageScreen();
    }

    return StreamBuilder<User?>(
      stream: AuthService.instance.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        final user = snapshot.data;
        if (user == null) {
          _claim = null;
          _claimForUid = null;
          final model = AppModel.instance;
          if (model != null) {
            AppModel.instance = null;
            WidgetsBinding.instance.addPostFrameCallback((_) => model.dispose());
          }
          return const PhoneScreen();
        }
        if (_claim == null || _claimForUid != user.uid) {
          _runClaim(user);
          return const _Splash();
        }
        if (_claim == ClaimOutcome.notInvited) {
          return const NotInvitedScreen();
        }
        if (AppModel.instance == null) return const _Splash();
        return const Shell();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Afia',
              style: sans(context, 34, weight: FontWeight.w500, color: c.text)),
          const SizedBox(height: 8),
          Text(l10n(context).checkingInvitation,
              style: sans(context, 13, color: c.textFaint)),
          const SizedBox(height: 24),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.machine),
          ),
        ]),
      ),
    );
  }
}
