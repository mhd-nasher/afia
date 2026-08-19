/// First-run language choice — AR / EN only. Persisted; switchable later in
/// Account.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../state/app_settings.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../widgets/common.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'ar';

  @override
  void initState() {
    super.initState();
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    _selected = device.languageCode == 'ar' ? 'ar' : 'en';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(LucideIcons.languages, size: 34, color: c.machine),
              const SizedBox(height: 18),
              Text(t.chooseLanguage,
                  textAlign: TextAlign.center,
                  style:
                      sans(context, 24, weight: FontWeight.w500, color: c.text)),
              const SizedBox(height: 10),
              Text(t.chooseLanguageBody,
                  textAlign: TextAlign.center,
                  style: sans(context, 14, color: c.textDim, height: 1.5)),
              const SizedBox(height: 32),
              _option('العربية', 'ar'),
              const SizedBox(height: 10),
              _option('English', 'en'),
              const Spacer(),
              PrimaryButton(
                onTap: () =>
                    AppSettings.instance.setLocale(Locale(_selected)),
                child: Text(t.continueLabel),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(String label, String code) {
    final c = context.afia;
    final selected = _selected == code;
    return InkWell(
      onTap: () => setState(() => _selected = code),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 64,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? c.machine : c.border),
          color: selected ? c.chipBg : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: sans(context, 17,
                    weight: FontWeight.w500,
                    color: selected ? c.machine : c.text)),
          ),
          if (selected) Icon(LucideIcons.check, size: 18, color: c.machine),
        ]),
      ),
    );
  }
}
