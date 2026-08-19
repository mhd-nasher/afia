/// حسابي — name, email, language switcher, delete-my-data (§3.3 erasure),
/// and a PROMINENT sign out (D-015).
library;

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../state/app_settings.dart';
import '../../state/episode_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final TextEditingController _name = TextEditingController();
  PatientAccount? _account;
  bool _loaded = false;
  bool _savedFlash = false;
  bool _confirmingDelete = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    try {
      PatientAuthService.instance.currentAccount().then((a) {
        if (!mounted) return;
        setState(() {
          _account = a;
          _loaded = true;
          if (a != null) _name.text = a.name;
        });
      }).catchError((_) {
        if (mounted) setState(() => _loaded = true);
      });
    } catch (_) {
      // Firebase unavailable: show the tab with what we have locally.
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = PatientAuthService.instance.currentUser?.uid;
    if (uid == null) return;
    await PatientAuthService.instance
        .updateAccount(uid, name: _name.text.trim());
    EpisodeModel.instance.setName(_name.text.trim());
    if (!mounted) return;
    setState(() => _savedFlash = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _savedFlash = false);
    });
  }

  Future<void> _setLanguage(Locale l) async {
    await AppSettings.instance.setLocale(l);
    final uid = PatientAuthService.instance.currentUser?.uid;
    if (uid != null) {
      await PatientAuthService.instance
          .updateAccount(uid, locale: l.languageCode);
    }
  }

  Future<void> _signOut() async {
    await PatientAuthService.instance.signOut();
    EpisodeModel.instance.resetAfterErasure();
  }

  Future<void> _deleteMyData() async {
    setState(() => _busy = true);
    try {
      await PatientAuthService.instance
          .deleteMyData(consentId: EpisodeModel.instance.episode.consentId);
    } catch (_) {
      // Even a partial failure must not trap the person: fall through to a
      // local wipe + sign-out.
      try {
        await PatientAuthService.instance.signOut();
      } catch (_) {}
    }
    EpisodeModel.instance.resetAfterErasure();
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final locale = Localizations.localeOf(context);
    String email = '';
    try {
      email = PatientAuthService.instance.currentUser?.email ?? '';
    } catch (_) {
      // Firebase unavailable — fall back to the cached account contact.
    }
    if (email.isEmpty) email = _account?.contact ?? '';

    if (!_loaded) {
      return StepPage(children: [
        PageTitle(t.accountTitle),
        const SizedBox(height: 20),
        Center(child: BodyText(t.loading)),
      ]);
    }

    if (_confirmingDelete) {
      return StepPage(children: [
        PageTitle(t.deleteConfirmTitle),
        BodyText(t.deleteConfirmBody),
        const SizedBox(height: 12),
        GhostButton(
          label: t.deleteConfirmYes,
          color: PatientColors.warn,
          onTap: _busy ? null : _deleteMyData,
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          label: t.cancel,
          onTap:
              _busy ? null : () => setState(() => _confirmingDelete = false),
        ),
      ]);
    }

    return StepPage(children: [
      PageTitle(t.accountTitle),
      BigField(label: t.accountName, controller: _name),
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.accountEmail,
                style: sans(context, 18, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(email.isEmpty ? '—' : email,
                  style: mono(context, 18, color: PatientColors.inkDim)),
            ),
          ],
        ),
      ),
      PrimaryButton(label: _savedFlash ? t.saved : t.save, onTap: _save),
      const SizedBox(height: 18),
      Text(t.accountLanguage,
          style: sans(context, 18, weight: FontWeight.w600)),
      const SizedBox(height: 8),
      AnswerButton(
        label: t.languageEnglish,
        selected: locale.languageCode == 'en',
        onTap: () => _setLanguage(const Locale('en')),
      ),
      AnswerButton(
        label: t.languageArabic,
        selected: locale.languageCode == 'ar',
        onTap: () => _setLanguage(const Locale('ar')),
      ),
      const SizedBox(height: 10),
      BodyText(t.signOutNote, color: PatientColors.inkDim),
      GhostButton(label: t.signOut, onTap: _signOut),
      const SizedBox(height: 14),
      Center(
          child: QuietLink(
              label: t.deleteMyData,
              onTap: () => setState(() => _confirmingDelete = true))),
    ]);
  }
}
