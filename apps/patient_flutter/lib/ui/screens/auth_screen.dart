/// THE ACCOUNT GATE — deliberately placed AFTER the red-flag questions and
/// the whole description (product-owner decision): safety is never gated
/// behind an account, and nothing typed so far can be lost (it is already
/// saved on the device, F-055). Patients SELF-REGISTER — phone OTP (+973
/// default) or email + password (register / sign in / reset). There are no
/// invitations here; invitations are clinician-only.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../state/episode_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

enum _Phase { choice, phone, otp, emailSignIn, emailRegister, reset, sending }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _Phase _phase = _Phase.choice;
  String? _error;
  String? _info;
  bool _busy = false;

  // Phone.
  final TextEditingController _country = TextEditingController(text: '+973');
  final TextEditingController _number = TextEditingController();
  final TextEditingController _code = TextEditingController();
  String _verificationId = '';
  int? _resendToken;
  String _phoneE164 = '';

  // Email.
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _code.addListener(() {
      if (_code.text.length == 6 && !_busy && _phase == _Phase.otp) {
        _confirmOtp();
      }
    });
  }

  @override
  void dispose() {
    _country.dispose();
    _number.dispose();
    _code.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String get _e164 {
    final cc = _country.text.trim().replaceAll(RegExp(r'[^\d+]'), '');
    final n = _number.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    final normalized = n.startsWith('0') ? n.substring(1) : n;
    return '$cc$normalized';
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

  // ── phone ────────────────────────────────────────────────────────────────

  Future<void> _sendCode() async {
    final t = l10n(context);
    if (!RegExp(r'^\+\d{8,15}$').hasMatch(_e164)) {
      setState(() => _error = t.phoneInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    _phoneE164 = _e164;
    await PatientAuthService.instance.startPhoneSignIn(
      phoneE164: _phoneE164,
      resendToken: _resendToken,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _verificationId = verificationId;
          _resendToken = resendToken;
          _phase = _Phase.otp;
        });
      },
      onFailed: (e) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = e.code == 'operation-not-allowed'
              ? t.phoneAuthUnavailable
              : t.authError(e.message ?? e.code);
        });
      },
      onAutoSignedIn: () {
        if (mounted) _finish();
      },
    );
  }

  Future<void> _confirmOtp() async {
    final t = l10n(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await PatientAuthService.instance
          .confirmOtp(_verificationId, _code.text);
      if (mounted) await _finish();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = (e.code == 'invalid-verification-code' ||
                e.code == 'invalid-credential')
            ? t.otpInvalid
            : t.authError(e.message ?? e.code);
        _code.clear();
      });
    }
  }

  // ── email ────────────────────────────────────────────────────────────────

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
        _Phase.choice => _choice(t),
        _Phase.phone => _phone(t),
        _Phase.otp => _otp(t),
        _Phase.emailSignIn => _emailForm(t, register: false),
        _Phase.emailRegister => _emailForm(t, register: true),
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

  List<Widget> _choice(dynamic t) => [
        PageTitle(t.authTitle),
        BodyText(t.authLead),
        const SizedBox(height: 12),
        PrimaryButton(
            label: t.authPhone,
            onTap: () => setState(() {
                  _phase = _Phase.phone;
                  _error = null;
                })),
        const SizedBox(height: 12),
        PrimaryButton(
            label: t.authEmail,
            onTap: () => setState(() {
                  _phase = _Phase.emailRegister;
                  _error = null;
                })),
        const SizedBox(height: 10),
        Center(
            child: QuietLink(
                label: t.backLabel,
                onTap: EpisodeModel.instance.backToReview)),
      ];

  List<Widget> _phone(dynamic t) => [
        PageTitle(t.phoneEntryTitle),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [
            SizedBox(
              width: 104,
              child: _box(TextField(
                controller: _country,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                  LengthLimitingTextInputFormatter(5),
                ],
                style: mono(context, 19),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                    border: InputBorder.none, isCollapsed: true),
              )),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _box(TextField(
                controller: _number,
                keyboardType: TextInputType.phone,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                style: mono(context, 19),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: t.phoneHint,
                  hintStyle: mono(context, 19,
                      color: PatientColors.inkFaint),
                ),
                onSubmitted: (_) => _sendCode(),
              )),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
            label: t.sendCode, onTap: _busy ? null : _sendCode),
        const SizedBox(height: 10),
        Center(
            child: QuietLink(
                label: t.backLabel,
                onTap: () => setState(() {
                      _phase = _Phase.choice;
                      _error = null;
                    }))),
      ];

  List<Widget> _otp(dynamic t) => [
        PageTitle(t.otpTitle),
        Directionality(
          textDirection: TextDirection.ltr,
          child: BodyText(t.otpSentTo(_phoneE164)),
        ),
        const SizedBox(height: 8),
        _box(
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: mono(context, 26, weight: FontWeight.w500)
                  .copyWith(letterSpacing: 10),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                  border: InputBorder.none, isCollapsed: true),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_busy) BodyText(t.verifying, color: PatientColors.inkDim),
        const SizedBox(height: 8),
        GhostButton(label: t.resendCode, onTap: _busy ? null : _sendCode),
        const SizedBox(height: 10),
        Center(
            child: QuietLink(
                label: t.backLabel,
                onTap: () => setState(() {
                      _phase = _Phase.phone;
                      _error = null;
                    }))),
      ];

  List<Widget> _emailForm(dynamic t, {required bool register}) => [
        PageTitle(register ? t.emailRegisterTitle : t.emailSignInTitle),
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
            _phase = register ? _Phase.emailSignIn : _Phase.emailRegister;
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
                onTap: () => setState(() {
                      _phase = _Phase.choice;
                      _error = null;
                    }))),
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
                      _phase = _Phase.emailSignIn;
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

  Widget _box(Widget child) => Container(
        constraints: const BoxConstraints(minHeight: PatientDimens.touch),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: PatientColors.surface,
          border: Border.all(color: PatientColors.inkDim, width: 2),
          borderRadius: BorderRadius.circular(PatientDimens.radius),
        ),
        child: child,
      );
}
