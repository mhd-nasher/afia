/// OTP entry — 6 digits, auto-submit on the sixth, resend with cooldown.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../widgets/common.dart';

class OtpScreen extends StatefulWidget {
  final String phoneE164;
  final String verificationId;
  final int? resendToken;
  const OtpScreen({
    super.key,
    required this.phoneE164,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _code = TextEditingController();
  final FocusNode _focus = FocusNode();
  late String _verificationId = widget.verificationId;
  int? _resendToken;
  String? _error;
  bool _busy = false;
  int _cooldown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resendToken = widget.resendToken;
    _startCooldown();
    _code.addListener(() {
      if (_code.text.length == 6 && !_busy) _submit();
      setState(() {});
    });
  }

  void _startCooldown() {
    _cooldown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _cooldown -= 1;
        if (_cooldown <= 0) t.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.confirmOtp(_verificationId, _code.text);
      // AuthGate takes over; unwind the auth stack.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = (e.code == 'invalid-verification-code' ||
                e.code == 'invalid-credential')
            ? l10n(context).otpInvalid
            : l10n(context).authError(e.message ?? e.code);
        _code.clear();
      });
      _focus.requestFocus();
    }
  }

  Future<void> _resend() async {
    _startCooldown();
    await AuthService.instance.startPhoneSignIn(
      phoneE164: widget.phoneE164,
      resendToken: _resendToken,
      onCodeSent: (id, token) {
        _verificationId = id;
        _resendToken = token;
      },
      onFailed: (e) {
        if (!mounted) return;
        setState(() => _error = l10n(context).authError(e.message ?? e.code));
      },
      onAutoSignedIn: () {
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          ScreenHeader(
            title: Text(t.otpTitle,
                style: sans(context, 20, weight: FontWeight.w500, color: c.text)),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(t.otpSentTo(widget.phoneE164),
                    textAlign: TextAlign.center,
                    style: sans(context, 14, color: c.textDim)),
              ),
              const SizedBox(height: 26),
              // Six mono digit cells over an invisible field — auto-submit.
              GestureDetector(
                onTap: _focus.requestFocus,
                child: Stack(alignment: Alignment.center, children: [
                  Opacity(
                    opacity: 0,
                    child: SizedBox(
                      height: 1,
                      child: TextField(
                        controller: _code,
                        focusNode: _focus,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                      ),
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (i) {
                        final filled = i < _code.text.length;
                        final active = i == _code.text.length;
                        return Container(
                          width: 44,
                          height: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: active ? c.machine : c.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            filled ? _code.text[i] : '',
                            style: mono(context, 22,
                                weight: FontWeight.w500, color: c.text),
                          ),
                        );
                      }),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              if (_busy)
                Center(
                    child: Text(t.verifying,
                        style: sans(context, 13, color: c.textFaint))),
              if (_error != null)
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: sans(context, 13, color: c.warn, height: 1.5)),
              const SizedBox(height: 18),
              Center(
                child: _cooldown > 0
                    ? Text(t.resendIn(_cooldown),
                        style: sans(context, 13, color: c.textFaint))
                    : Pill(label: t.resendCode, onTap: _resend),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
