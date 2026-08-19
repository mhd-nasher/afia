/// Phone entry — E.164, Bahrain +973 default, international allowed. NO
/// email, NO password, NO self-registration anywhere (§5/§11). Handles the
/// Phone provider not being enabled yet with a clear bilingual message.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../widgets/common.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final TextEditingController _country = TextEditingController(text: '+973');
  final TextEditingController _number = TextEditingController();
  String? _error;
  bool _busy = false;

  String get _e164 {
    final cc = _country.text.trim().replaceAll(RegExp(r'[^\d+]'), '');
    final n = _number.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    final normalized = n.startsWith('0') ? n.substring(1) : n;
    return '$cc$normalized';
  }

  bool get _valid => RegExp(r'^\+\d{8,15}$').hasMatch(_e164);

  Future<void> _send() async {
    final t = l10n(context);
    if (!_valid) {
      setState(() => _error = t.phoneInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final phone = _e164;
    await AuthService.instance.startPhoneSignIn(
      phoneE164: phone,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() => _busy = false);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneE164: phone,
            verificationId: verificationId,
            resendToken: resendToken,
          ),
        ));
      },
      onFailed: (e) {
        if (!mounted) return;
        final msg = e.message ?? '';
        setState(() {
          _busy = false;
          // Firebase reports both "provider disabled" AND "SMS region policy /
          // quota blocked" as operation-not-allowed — distinguish them, the
          // remedies are different.
          if (e.code == 'quota-exceeded' ||
              msg.contains('region') ||
              msg.contains('quota')) {
            _error = t.smsRegionBlocked;
          } else if (e.code == 'operation-not-allowed') {
            _error = t.phoneAuthUnavailable;
          } else {
            _error = t.authError(msg.isEmpty ? e.code : msg);
          }
        });
      },
      onAutoSignedIn: () {
        // Android auto-retrieval: the AuthGate stream takes over.
        if (mounted) setState(() => _busy = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
            const SizedBox(height: 48),
            Text('Afia',
                style: sans(context, 28, weight: FontWeight.w500, color: c.text)),
            const SizedBox(height: 6),
            Text(t.signInTitle,
                style: sans(context, 15, color: c.textDim)),
            const SizedBox(height: 40),
            Text(t.phoneEntryTitle.toUpperCase(), style: sectionLabel(context)),
            const SizedBox(height: 10),
            Directionality(
              // Phone numbers are always LTR, even in the Arabic UI.
              textDirection: TextDirection.ltr,
              child: Row(children: [
                SizedBox(
                  width: 92,
                  child: _box(
                    child: TextField(
                      controller: _country,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      style: mono(context, 17, color: c.text),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                          border: InputBorder.none, isCollapsed: true),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _box(
                    child: TextField(
                      controller: _number,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      style: mono(context, 17, color: c.text),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: t.phoneHint,
                        hintStyle: mono(context, 17, color: c.textFaint),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Text(t.phoneEntryBody,
                style: sans(context, 13, color: c.textFaint, height: 1.5)),
            if (_error != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsetsDirectional.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: c.warn),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(LucideIcons.alertCircle, size: 16, color: c.warn),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_error!,
                        style: sans(context, 13, color: c.text, height: 1.5)),
                  ),
                ]),
              ),
            ],
                      const SizedBox(height: 24),
                    ]),
              ),
            ),
            PrimaryButton(
              onTap: _busy ? null : _send,
              child: _busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: c.onAccent))
                  : Text(t.sendCode),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _box({required Widget child}) {
    final c = context.afia;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
