/// First-run language choice (AR/EN). Shown once, before anything else.
library;

import 'package:flutter/material.dart';

import '../../state/app_settings.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return StepPage(children: [
      const SizedBox(height: 40),
      Center(
          child:
              Text('Afia · عافية', style: sans(context, 34, weight: FontWeight.w500))),
      const SizedBox(height: 10),
      Center(child: Text(t.languageChoiceTitle, style: sans(context, 19))),
      const SizedBox(height: 30),
      PrimaryButton(
        label: t.chooseEnglish,
        onTap: () => AppSettings.instance.setLocale(const Locale('en')),
      ),
      const SizedBox(height: 12),
      PrimaryButton(
        label: t.chooseArabic,
        onTap: () => AppSettings.instance.setLocale(const Locale('ar')),
      ),
    ]);
  }
}
