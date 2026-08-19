/// THE ACCOUNT GATE — deliberately placed AFTER the red-flag questions and
/// the whole description (product-owner decision): safety is never gated
/// behind an account, and nothing typed so far can be lost (it is already
/// saved on the device, F-055). Patients SELF-REGISTER with email + password
/// — the ONLY sign-in method (owner decision D-012, docs/DECISIONS.md):
/// register, sign in, password reset. There are no invitations here;
/// invitations are clinician-only.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../state/episode_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

enum _Phase { register, signIn, reset, sending }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Straight to the email form — registering is the common first path.
  _Phase _phase = _Phase.register;
  String? _error;
  String? _info;
  bool _busy = false;

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() {
      _phase = _Phase.sending;
      _busy = true;
      _error = null;
    });
    final locale = Localizations.localeOf(context).languageCode;
    try {
      await EpisodeModel.instance.onAuthenticated(locale);
    } catch (_) {
      // send() is resilient; any residual failure keeps the episode saved.
    }
  }

  bool _validEmailForm() {
    final t = l10n(context);
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) {
      setState(() => _error = t.emailInvalid);
      return false;
    }
    if (_password.text.length < 8) {
      setState(() => _error = t.passwordTooShort);
      return false;
    }
    return true;
  }

  Future<void> _emailAuth({required bool register}) async {
    final t = l10n(context);
    if (!_validEmailForm()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (register) {
        await PatientAuthService.instance
            .registerWithEmail(_email.text.trim(), _password.text);
      } else {
        await PatientAuthService.instance
            .signInWithEmail(_email.text.trim(), _password.text);
      }
      if (mounted) await _finish();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = switch (e.code) {
          'email-already-in-use' => t.emailInUse,
          'wrong-password' ||
          'invalid-credential' ||
          'user-not-found' =>
            t.wrongPassword,
          'weak-password' => t.passwordTooShort,
          'invalid-email' => t.emailInvalid,
          _ => t.authError(e.message ?? e.code),
        };
      });
    }
  }

  Future<void> _sendReset() async {
    final t = l10n(context);
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) {
      setState(() => _error = t.emailInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await PatientAuthService.instance
          .sendPasswordReset(_email.text.trim());
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

  // ── ui ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return StepPage(children: [
      ...switch (_phase) {
        _Phase.register => _emailForm(t, register: true),
        _Phase.signIn => _emailForm(t, register: false),
        _Phase.reset => _resetForm(t),
        _Phase.sending => _sending(t),
      },
      if (_error != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: PatientColors.warn, width: 2),
            borderRadius: BorderRadius.circular(PatientDimens.radius),
          ),
          child: Text(_error!, style: sans(context, 17, height: 1.4)),
        ),
      ],
      if (_info != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: PatientColors.ok, width: 2),
            borderRadius: BorderRadius.circular(PatientDimens.radius),
          ),
          child: Text(_info!, style: sans(context, 17, height: 1.4)),
        ),
      ],
    ]);
  }

  List<Widget> _emailForm(dynamic t, {required bool register}) => [
        // The gate frame appears only on the entry (register) variant —
        // sign-in keeps one clear title (one question, one action).
        if (register) ...[
          PageTitle(t.authTitle),
          BodyText(t.authLead),
          const SizedBox(height: 8),
        ] else
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
        PrimaryButton(
          label: register ? t.createAccount : t.signIn,
          onTap: _busy ? null : () => _emailAuth(register: register),
        ),
        const SizedBox(height: 10),
        GhostButton(
          label: register ? t.haveAccount : t.noAccount,
          onTap: () => setState(() {
            _phase = register ? _Phase.signIn : _Phase.register;
            _error = null;
          }),
        ),
        if (!register) ...[
          const SizedBox(height: 10),
          Center(
              child: QuietLink(
                  label: t.forgotPassword,
                  onTap: () => setState(() {
                        _phase = _Phase.reset;
                        _error = null;
                        _info = null;
                      }))),
        ],
        const SizedBox(height: 4),
        Center(
            child: QuietLink(
                label: t.backLabel,
                onTap: EpisodeModel.instance.backToReview)),
      ];

  List<Widget> _resetForm(dynamic t) => [
        PageTitle(t.resetTitle),
        BodyText(t.resetLead),
        BigField(
          label: t.emailLabel,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          fieldDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 8),
        PrimaryButton(
            label: t.sendResetLink, onTap: _busy ? null : _sendReset),
        const SizedBox(height: 10),
        Center(
            child: QuietLink(
                label: t.backLabel,
                onTap: () => setState(() {
                      _phase = _Phase.signIn;
                      _error = null;
                      _info = null;
                    }))),
      ];

  List<Widget> _sending(dynamic t) => [
        const SizedBox(height: 60),
        const Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: PatientColors.action),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: BodyText(t.loading)),
      ];
}
