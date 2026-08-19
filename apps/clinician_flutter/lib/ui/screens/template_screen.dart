/// Screen 13 — Template. Role-gated to charge_nurse/manager. Read-only:
/// editing lives in the admin dashboard (templateVersions are append-only in
/// the rules — never edited in place).
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../state/app_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

class TemplateScreen extends StatelessWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppModel.instance!;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final c = context.afia;
        final t = l10n(context);
        if (!model.me.canViewTemplate) {
          return Scaffold(
            body: SafeArea(
              child: Column(children: [
                ScreenHeader(
                    title: Text(t.templateTitle,
                        style: sans(context, 20,
                            weight: FontWeight.w500, color: c.text))),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 32),
                      child: Text(t.templateRoleGate,
                          textAlign: TextAlign.center,
                          style: sans(context, 14,
                              color: c.textDim, height: 1.5)),
                    ),
                  ),
                ),
              ]),
            ),
          );
        }

        final version = model.templateVersion;
        final fields = model.template;

        return Scaffold(
          body: SafeArea(
            child: Column(children: [
              ScreenHeader(
                title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.templateTitle,
                          style: sans(context, 20,
                              weight: FontWeight.w500, color: c.text)),
                      Text(t.templateSubtitle,
                          style: sans(context, 11, color: c.textFaint)),
                    ]),
                trailing: Text('v${version?.version ?? '—'}',
                    style: mono(context, 16,
                        weight: FontWeight.w500, color: c.textDim)),
              ),
              Expanded(
                child: ListView(padding: EdgeInsets.zero, children: [
                  SectionHeader(t.fieldsSection,
                      height: 34,
                      trailing: Text('${fields.length}',
                          style: mono(context, 13, color: c.textFaint))),
                  for (var i = 0; i < fields.length; i++)
                    Container(
                      height: 64,
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 16),
                      decoration: BoxDecoration(
                          border:
                              Border(top: BorderSide(color: c.hairline))),
                      child: Row(children: [
                        Icon(LucideIcons.lock, size: 14, color: c.textFaint),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 24,
                          child: Text('${i + 1}',
                              textDirection: TextDirection.ltr,
                              style: mono(context, 15, color: c.textFaint)),
                        ),
                        Expanded(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    fieldLabel(context, fields[i].id,
                                        fields[i].label),
                                    style:
                                        sans(context, 15, color: c.text)),
                                const SizedBox(height: 3),
                                Text(
                                    fields[i].required
                                        ? t.requiredLabel
                                        : t.optionalLabel,
                                    style: sans(context, 13,
                                        color: c.textFaint)),
                              ]),
                        ),
                      ]),
                    ),
                  Container(height: 1, color: c.hairline),
                ]),
              ),
              if (version != null)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 20),
                  decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.border))),
                  child: Text(
                    '${t.templateEditedBy(version.editedBy)} · ${hhmm(version.at)}',
                    style: sans(context, 11, color: c.textFaint),
                  ),
                ),
            ]),
          ),
        );
      },
    );
  }
}
