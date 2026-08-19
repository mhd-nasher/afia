/// AUTH FIRST (D-015): welcome door → إنشاء حساب / تسجيل الدخول. Email +
/// password is the only method (D-012): register, sign in, password reset.
/// After registering, one short profile step (name + terms). The session
/// persists — later launches go straight to Home.
///
/// The emergency fixture floats above ALL of these screens (§2.7 — calling
/// 999 needs no account).
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../state/episode_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

/// The door: what this is, in one breath, and two big obvious buttons.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return StepPage(children: [
      const SizedBox(height: 24),
      Center(
          child: Text('Afia · عافية',
              style: sans(context, 34, weight: FontWeight.w500))),
      const SizedBox(height: 20),
      PageTitle(t.welcomeTitle),
      BodyText(t.welcomeBody),
      const SizedBox(height: 16),
      PrimaryButton(
        label: t.createAccount,
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const RegisterScreen())),
      ),
      const SizedBox(height: 12),
      GhostButton(
        label: t.signIn,
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const SignInScreen())),
      ),
    ]);
  }
}

// ── shared bits ──────────────────────────────────────────────────────────

bool _validEmail(String s) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

Widget _errorBox(BuildContext context, String message) => Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: PatientColors.warn, width: 2),
        borderRadius: BorderRadius.circular(PatientDimens.radius),
      ),
      child: Text(message, style: sans(context, 17, height: 1.4)),
    );

Widget _infoBox(BuildContext context, String message) => Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: PatientColors.ok, width: 2),
        borderRadius: BorderRadius.circular(PatientDimens.radius),
      ),
      child: Text(message, style: sans(context, 17, height: 1.4)),
    );

String _authErrorText(BuildContext context, FirebaseAuthException e) {
  final t = l10n(context);
  return switch (e.code) {
    'email-already-in-use' => t.emailInUse,
    'wrong-password' || 'invalid-credential' || 'user-not-found' =>
      t.wrongPassword,
    'weak-password' => t.passwordTooShort,
    'invalid-email' => t.emailInvalid,
    _ => t.authError(e.message ?? e.code),
  };
}

// ── register → profile step ──────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _name = TextEditingController();
  bool _busy = false;
  bool _profileStep = false;
  bool _terms = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // The profile Continue button enables live as the name is typed.
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final t = l10n(context);
    if (!_validEmail(_email.text)) {
      setState(() => _error = t.emailInvalid);
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = t.passwordTooShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await PatientAuthService.instance
          .registerWithEmail(_email.text.trim(), _password.text);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _profileStep = true; // the account exists; one short step remains
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _authErrorText(context, e);
      });
    }
  }

  Future<void> _finishProfile() async {
    final locale = Localizations.localeOf(context).languageCode;
    setState(() => _busy = true);
    final user = PatientAuthService.instance.currentUser;
    final name = _name.text.trim();
    EpisodeModel.instance.setName(name);
    if (user != null) {
      try {
        await PatientAuthService.instance
            .ensurePatientAccount(user: user, name: name, locale: locale);
      } catch (_) {
        // Offline: the account doc write queues; Home works meanwhile.
      }
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    if (_profileStep) {
      return StepPage(children: [
        PageTitle(t.profileTitle),
        BodyText(t.profileLead),
        BigField(
          label: t.entryNameLabel,
          controller: _name,
          keyboardType: TextInputType.name,
        ),
        ToggleRow(
            checked: _terms,
            label: t.entryTerms,
            onChanged: (v) => setState(() => _terms = v)),
        const SizedBox(height: 8),
        PrimaryButton(
          label: t.continueLabel,
          onTap: (_busy || !_terms || _name.text.trim().isEmpty)
              ? null
              : _finishProfile,
        ),
        if (!_terms || _name.text.trim().isEmpty) ...[
          const SizedBox(height: 10),
          BodyText(t.profileHint, color: PatientColors.inkDim),
        ],
      ]);
    }

    return StepPage(children: [
      PageTitle(t.emailRegisterTitle),
      BodyText(t.registerLead),
      BigField(
        label: t.emailLabel,
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        fieldDirection: TextDirection.ltr,
      ),
      BigField(
        label: t.passwordLabel,
        controller: _password,
        obscure: true,
        fieldDirection: TextDirection.ltr,
      ),
      const SizedBox(height: 8),
      PrimaryButton(
          label: t.createAccount, onTap: _busy ? null : _register),
      const SizedBox(height: 10),
      GhostButton(
        label: t.haveAccount,
        onTap: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const SignInScreen())),
      ),
      const SizedBox(height: 4),
      Center(
          child: QuietLink(
              label: t.backLabel,
              onTap: () => Navigator.of(context).maybePop())),
      if (_error != null) _errorBox(context, _error!),
    ]);
  }
}

// ── sign in ──────────────────────────────────────────────────────────────

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final t = l10n(context);
    if (!_validEmail(_email.text)) {
      setState(() => _error = t.emailInvalid);
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _error = t.passwordTooShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await PatientAuthService.instance
          .signInWithEmail(_email.text.trim(), _password.text);
      final user = PatientAuthService.instance.currentUser;
      if (user != null) {
        try {
          final account = await PatientAuthService.instance
              .ensurePatientAccount(
                  user: user,
                  name: '',
                  locale:
                      // ignore: use_build_context_synchronously
                      mounted ? Localizations.localeOf(context).languageCode : 'en');
          if (account.name.isNotEmpty) {
            EpisodeModel.instance.setName(account.name);
          }
        } catch (_) {
          // Offline: Home still works from local state.
        }
      }
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _authErrorText(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return StepPage(children: [
      PageTitle(t.emailSignInTitle),
      BigField(
        label: t.emailLabel,
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        fieldDirection: TextDirection.ltr,
      ),
      BigField(
        label: t.passwordLabel,
        controller: _password,
        obscure: true,
        fieldDirection: TextDirection.ltr,
      ),
      const SizedBox(height: 8),
      PrimaryButton(label: t.signIn, onTap: _busy ? null : _signIn),
      const SizedBox(height: 10),
      GhostButton(
        label: t.noAccount,
        onTap: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const RegisterScreen())),
      ),
      const SizedBox(height: 10),
      Center(
          child: QuietLink(
              label: t.forgotPassword,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const ResetScreen())))),
      const SizedBox(height: 4),
      Center(
          child: QuietLink(
              label: t.backLabel,
              onTap: () => Navigator.of(context).maybePop())),
      if (_error != null) _errorBox(context, _error!),
    ]);
  }
}

// ── password reset ───────────────────────────────────────────────────────

class ResetScreen extends StatefulWidget {
  const ResetScreen({super.key});

  @override
  State<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen> {
  final TextEditingController _email = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = l10n(context);
    if (!_validEmail(_email.text)) {
      setState(() => _error = t.emailInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await PatientAuthService.instance.sendPasswordReset(_email.text.trim());
      if (!mounted) return;
      setState(() {
        _busy = false;
        _info = t.resetSent;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.code == 'invalid-email'
            ? t.emailInvalid
            : t.authError(e.message ?? e.code);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return StepPage(children: [
      PageTitle(t.resetTitle),
      BodyText(t.resetLead),
      BigField(
        label: t.emailLabel,
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        fieldDirection: TextDirection.ltr,
      ),
      const SizedBox(height: 8),
      PrimaryButton(label: t.sendResetLink, onTap: _busy ? null : _send),
      const SizedBox(height: 10),
      Center(
          child: QuietLink(
              label: t.backLabel,
              onTap: () => Navigator.of(context).maybePop())),
      if (_error != null) _errorBox(context, _error!),
      if (_info != null) _infoBox(context, _info!),
    ]);
  }
}
