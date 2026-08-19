/// Email + password sign-in — the ONLY sign-in method (D-012 / RULES W7).
/// Three modes in one screen: sign in, create account (min 8 chars +
/// confirmation), reset password. Creating an account grants NO access —
/// the invitation gate in AuthService decides that after auth. Errors are
/// mapped to neutral localized messages (wrong password and unknown user
/// are indistinguishable on purpose).
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../widgets/common.dart';

enum _Mode { signIn, create, reset }

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  _Mode _mode = _Mode.signIn;
  String? _error;
  String? _info;
  bool _busy = false;
  bool _obscure = true;

  bool get _emailValid =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim());

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String _mapError(FirebaseAuthException e) {
    final t = l10n(context);
    return switch (e.code) {
      // Neutral on purpose: never reveal whether the email exists.
      'wrong-password' ||
      'user-not-found' ||
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' =>
        t.authBadCredentials,
      'email-already-in-use' => t.authEmailInUse,
      'weak-password' => t.authWeakPassword,
      'invalid-email' => t.authInvalidEmail,
      'network-request-failed' => t.authNetwork,
      'too-many-requests' => t.authTooManyRequests,
      _ => t.authError(e.message ?? e.code),
    };
  }

  Future<void> _submit() async {
    final t = l10n(context);
    setState(() {
      _error = null;
      _info = null;
    });
    if (!_emailValid) {
      setState(() => _error = t.authInvalidEmail);
      return;
    }
    if (_mode != _Mode.reset && _password.text.length < 8) {
      setState(() => _error = t.authWeakPassword);
      return;
    }
    if (_mode == _Mode.create && _password.text != _confirm.text) {
      setState(() => _error = t.authPasswordMismatch);
      return;
    }

    setState(() => _busy = true);
    try {
      switch (_mode) {
        case _Mode.signIn:
          await AuthService.instance.signIn(_email.text, _password.text);
        // The AuthGate stream takes over (invitation gate → shell/not-invited).
        case _Mode.create:
          await AuthService.instance
              .createAccount(_email.text, _password.text);
        case _Mode.reset:
          await AuthService.instance.sendPasswordReset(_email.text);
          if (mounted) {
            setState(() {
              _busy = false;
              _info = t.resetSent(_email.text.trim().toLowerCase());
              _mode = _Mode.signIn;
            });
          }
          return;
      }
      if (mounted) setState(() => _busy = false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _mapError(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = t.errorGeneric;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    final title = switch (_mode) {
      _Mode.signIn => t.signInTitle,
      _Mode.create => t.createAccountAction,
      _Mode.reset => t.resetPasswordTitle,
    };
    final action = switch (_mode) {
      _Mode.signIn => t.signInTitle,
      _Mode.create => t.createAccountAction,
      _Mode.reset => t.sendResetLink,
    };

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).vertical),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Text('Afia',
                      style: sans(context, 28,
                          weight: FontWeight.w500, color: c.text)),
                  const SizedBox(height: 6),
                  Text(title, style: sans(context, 15, color: c.textDim)),
                  const SizedBox(height: 36),
                  Text(t.emailLabel.toUpperCase(), style: sectionLabel(context)),
                  const SizedBox(height: 8),
                  _box(
                    child: TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofocus: true,
                      textDirection: TextDirection.ltr,
                      textAlign: Directionality.of(context) == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                      style: mono(context, 15, color: c.text),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: 'name@example.com',
                        hintStyle: mono(context, 15, color: c.textFaint),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (_mode != _Mode.reset) ...[
                    const SizedBox(height: 16),
                    Text(t.passwordLabel.toUpperCase(),
                        style: sectionLabel(context)),
                    const SizedBox(height: 8),
                    _box(
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _password,
                            obscureText: _obscure,
                            autocorrect: false,
                            textDirection: TextDirection.ltr,
                            style: mono(context, 15, color: c.text),
                            decoration: const InputDecoration(
                                border: InputBorder.none, isCollapsed: true),
                            onSubmitted: (_) =>
                                _mode == _Mode.signIn ? _submit() : null,
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.all(6),
                            child: Icon(
                                _obscure
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
                                size: 18,
                                color: c.textFaint),
                          ),
                        ),
                      ]),
                    ),
                  ],
                  if (_mode == _Mode.create) ...[
                    const SizedBox(height: 16),
                    Text(t.confirmPasswordLabel.toUpperCase(),
                        style: sectionLabel(context)),
                    const SizedBox(height: 8),
                    _box(
                      child: TextField(
                        controller: _confirm,
                        obscureText: _obscure,
                        autocorrect: false,
                        textDirection: TextDirection.ltr,
                        style: mono(context, 15, color: c.text),
                        decoration: const InputDecoration(
                            border: InputBorder.none, isCollapsed: true),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    _mode == _Mode.reset ? t.resetPasswordBody : t.emailEntryBody,
                    style: sans(context, 13, color: c.textFaint, height: 1.5),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _notice(_error!, c.warn, LucideIcons.alertCircle),
                  ],
                  if (_info != null) ...[
                    const SizedBox(height: 16),
                    _notice(_info!, c.ok, LucideIcons.checkCircle2),
                  ],
                  const SizedBox(height: 28),
                  PrimaryButton(
                    onTap: _busy ? null : _submit,
                    child: _busy
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: c.onAccent))
                        : Text(action),
                  ),
                  const SizedBox(height: 14),
                  if (_mode == _Mode.signIn) ...[
                    _link(t.createAccountSwitch, () => _switch(_Mode.create)),
                    _link(t.forgotPassword, () => _switch(_Mode.reset)),
                  ] else
                    _link(t.backToSignIn, () => _switch(_Mode.signIn)),
                  const SizedBox(height: 24),
                ]),
          ),
        ),
      ),
    );
  }

  void _switch(_Mode mode) => setState(() {
        _mode = mode;
        _error = null;
        _info = null;
      });

  Widget _box({required Widget child}) {
    final c = context.afia;
    return Container(
      height: 56,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _notice(String text, Color color, IconData icon) {
    final c = context.afia;
    return Container(
      padding: const EdgeInsetsDirectional.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child:
              Text(text, style: sans(context, 13, color: c.text, height: 1.5)),
        ),
      ]),
    );
  }

  Widget _link(String label, VoidCallback onTap) {
    final c = context.afia;
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: _busy ? null : onTap,
        child: Text(label, style: sans(context, 14, color: c.machine)),
      ),
    );
  }
}
