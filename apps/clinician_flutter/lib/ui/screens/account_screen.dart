/// Screen 12 — Account. Ward devices are shared: sign out is PROMINENT with
/// a confirm sheet. The signature identity is displayed with a lock — it is
/// immutable (§2.5) and no editor exists anywhere.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/auth_service.dart';
import '../../state/app_model.dart';
import '../../state/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'assistant_sheet.dart';
import 'template_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final t = l10n(context);
    final model = AppModel.instance!;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.afia.raised,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(t.signOutConfirmTitle,
                style: sans(sheetContext, 18,
                    weight: FontWeight.w500, color: sheetContext.afia.text)),
            const SizedBox(height: 10),
            Text(t.signOutConfirmBody,
                textAlign: TextAlign.center,
                style: sans(sheetContext, 13,
                    color: sheetContext.afia.textDim, height: 1.5)),
            const SizedBox(height: 20),
            OutlinedAction(
              color: sheetContext.afia.text,
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await AuthService.instance.signOut(model.me.id);
              },
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.logOut),
                const SizedBox(width: 10),
                Text(t.signOut),
              ]),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(t.cancel,
                  style: sans(sheetContext, 14,
                      color: sheetContext.afia.textFaint)),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = AppModel.instance!;
    return ListenableBuilder(
      listenable: Listenable.merge([model, AppSettings.instance]),
      builder: (context, _) {
        final c = context.afia;
        final t = l10n(context);

        return Column(children: [
          Container(
            height: 50,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border))),
            child: Row(children: [
              Expanded(
                child: Text(t.accountTitle,
                    style: sans(context, 20,
                        weight: FontWeight.w500, color: c.text)),
              ),
              IconButton(
                onPressed: () => showAssistantSheet(context),
                icon: Icon(LucideIcons.sparkles, size: 20, color: c.machine),
                tooltip: t.assistantTitle,
              ),
            ]),
          ),
          // Signature block — locked, with the immutability note.
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 20),
            decoration: BoxDecoration(
              color: c.raised,
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(t.yourSignature.toUpperCase(),
                    style: sectionLabel(context)),
                const SizedBox(width: 8),
                Icon(LucideIcons.lock, size: 12, color: c.textFaint),
              ]),
              const SizedBox(height: 8),
              Text(model.me.name,
                  style: sans(context, 22,
                      weight: FontWeight.w500, color: c.text)),
              const SizedBox(height: 4),
              Text(model.me.signatureIdentity,
                  textDirection: TextDirection.ltr,
                  style: mono(context, 16, color: c.textDim)),
              const SizedBox(height: 8),
              Text(t.signatureLockNote,
                  style: sans(context, 13, color: c.textFaint, height: 1.4)),
            ]),
          ),
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              _infoRow(context, t.wardRow, model.ward?.name ?? '—'),
              _infoRow(
                  context,
                  t.templateRow,
                  model.templateVersion == null
                      ? '—'
                      : 'SBAR v${model.templateVersion!.version}'),
              // Appearance — Auto / Day / Night (dark is the default).
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.hairline))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.appearance,
                          style: sans(context, 11, color: c.textFaint)),
                      const SizedBox(height: 10),
                      Row(children: [
                        _themeOption(context, t.themeAuto, ThemeMode.system,
                            LucideIcons.monitor),
                        const SizedBox(width: 8),
                        _themeOption(context, t.themeDay, ThemeMode.light,
                            LucideIcons.sun),
                        const SizedBox(width: 8),
                        _themeOption(context, t.themeNight, ThemeMode.dark,
                            LucideIcons.moon),
                      ]),
                    ]),
              ),
              // Language — AR / EN only.
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.hairline))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.languageRow,
                          style: sans(context, 11, color: c.textFaint)),
                      const SizedBox(height: 10),
                      Row(children: [
                        _langOption(context, 'العربية', 'ar'),
                        const SizedBox(width: 8),
                        _langOption(context, 'English', 'en'),
                      ]),
                    ]),
              ),
              if (model.me.canViewTemplate)
                InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const TemplateScreen())),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 16),
                    decoration: BoxDecoration(
                        border:
                            Border(bottom: BorderSide(color: c.hairline))),
                    child: Row(children: [
                      Icon(LucideIcons.layoutList,
                          size: 18, color: c.textDim),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(t.viewTemplateRow,
                              style: sans(context, 15, color: c.text))),
                      Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? LucideIcons.chevronLeft
                              : LucideIcons.chevronRight,
                          size: 18,
                          color: c.textFaint),
                    ]),
                  ),
                ),
              const SizedBox(height: 20),
            ]),
          ),
          // Prominent sign out (§5 — shared devices).
          Container(
            padding: const EdgeInsetsDirectional.all(16),
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border))),
            child: Column(children: [
              OutlinedAction(
                onTap: () => _confirmSignOut(context),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(LucideIcons.logOut),
                  const SizedBox(width: 10),
                  Text(t.signOut),
                ]),
              ),
              const SizedBox(height: 8),
              Text(t.sharedDeviceNote,
                  style: sans(context, 11, color: c.textFaint)),
            ]),
          ),
        ]);
      },
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final c = context.afia;
    return Container(
      height: 64,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.hairline))),
      child: Row(children: [
        Expanded(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: sans(context, 11, color: c.textFaint)),
                const SizedBox(height: 3),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sans(context, 15, color: c.text)),
              ]),
        ),
      ]),
    );
  }

  Widget _themeOption(
      BuildContext context, String label, ThemeMode mode, IconData icon) {
    final c = context.afia;
    final selected = AppSettings.instance.themeMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => AppSettings.instance.setThemeMode(mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: selected ? c.machine : c.border),
            color: selected ? c.chipBg : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: selected ? c.machine : c.textDim),
            const SizedBox(width: 7),
            Text(label,
                style: sans(context, 14,
                    color: selected ? c.machine : c.textDim)),
          ]),
        ),
      ),
    );
  }

  Widget _langOption(BuildContext context, String label, String code) {
    final c = context.afia;
    final selected = AppSettings.instance.locale?.languageCode == code;
    return Expanded(
      child: InkWell(
        onTap: () => AppSettings.instance.setLocale(Locale(code)),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: selected ? c.machine : c.border),
            color: selected ? c.chipBg : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: sans(context, 14,
                  weight: selected ? FontWeight.w500 : FontWeight.w400,
                  color: selected ? c.machine : c.textDim)),
        ),
      ),
    );
  }
}
