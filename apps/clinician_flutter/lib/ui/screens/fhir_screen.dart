/// The FHIR-ready record viewer: a valid DocumentReference JSON generated on
/// demand and displayed. Nothing is sent anywhere — FHIR-ready, never
/// "integrated" (§3.2). Copy to clipboard for demonstration.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/export.dart';
import '../../domain/handover.dart';
import '../../state/app_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

class FhirScreen extends StatelessWidget {
  final String handoverId;
  const FhirScreen({super.key, required this.handoverId});

  @override
  Widget build(BuildContext context) {
    final model = AppModel.instance!;
    final c = context.afia;
    final t = l10n(context);

    Handover? handover;
    for (final h in model.handovers) {
      if (h.id == handoverId) handover = h;
    }
    final patient =
        handover == null ? null : model.patientById(handover.patientId);
    if (handover == null || patient == null) {
      return Scaffold(body: Center(child: Text(t.loading)));
    }

    final fhir = const FhirExporter().export(handover, patient);
    final clip = const ClipboardExporter().export(handover, patient);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          ScreenHeader(
            title: Text(t.fhirReady,
                style:
                    sans(context, 20, weight: FontWeight.w500, color: c.text)),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.raised,
              border: Border(bottom: BorderSide(color: c.hairline)),
            ),
            child: Text(t.fhirNote,
                style: sans(context, 12, color: c.textDim, height: 1.5)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(16),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: SelectableText(
                  fhir.payload ?? '',
                  style: mono(context, 11, color: c.text, height: 1.5),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsetsDirectional.all(16),
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border))),
            child: Row(children: [
              Expanded(
                child: PrimaryButton(
                  onTap: () async {
                    await Clipboard.setData(
                        ClipboardData(text: fhir.payload ?? ''));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t.copied)));
                    }
                  },
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(LucideIcons.copy, size: 18),
                    const SizedBox(width: 8),
                    Text(t.copyJson),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Pill(
                  label: t.copyText,
                  icon: LucideIcons.clipboard,
                  onTap: () async {
                    await Clipboard.setData(
                        ClipboardData(text: clip.payload ?? ''));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t.copied)));
                    }
                  },
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
