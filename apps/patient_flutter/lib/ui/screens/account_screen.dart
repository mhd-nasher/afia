/// Account — view/edit contact details, language, sign out, and the
/// delete-my-data flow (§3.3 erasure: account + AI memory deleted, consent
/// withdrawn by timestamp, device wiped; the submitted case stays with the
/// nursing team so care is not interrupted — the copy says so honestly).
library;

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../state/app_settings.dart';
import '../../state/episode_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _name = TextEditingController();
  PatientAccount? _account;
  bool _loaded = false;
  bool _savedFlash = false;
  bool _confirmingDelete = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = PatientAuthService.instance.currentUser?.uid;
    if (uid == null) return;
    await PatientAuthService.instance.updateAccount(uid, name: _name.text.trim());
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
      await PatientAuthService.instance.deleteMyData(
          consentId: EpisodeModel.instance.episode.consentId);
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
    final model = EpisodeModel.instance;
    final locale = Localizations.localeOf(context);

    if (!_loaded) {
      return StepPage(children: [
        const SizedBox(height: 40),
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
          onTap: _busy
              ? null
              : () => setState(() => _confirmingDelete = false),
        ),
      ]);
    }

    return StepPage(children: [
      PageTitle(t.accountTitle),
      if (_account != null) ...[
        BigField(label: t.accountName, controller: _name),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.accountContact,
                  style: sans(context, 18, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(_account!.contact,
                    style: mono(context, 18, color: PatientColors.inkDim)),
              ),
            ],
          ),
        ),
        PrimaryButton(label: _savedFlash ? t.saved : t.save, onTap: _save),
        const SizedBox(height: 18),
      ],
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
      const SizedBox(height: 14),
      Center(child: QuietLink(label: t.backLabel, onTap: model.backToStatus)),
    ]);
  }
}
