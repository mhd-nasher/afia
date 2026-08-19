/// Screen 1 — Ward list. 12 rows, one screen, NO scroll (the rows share the
/// available height; on the 390×844 reference each lands at ≥56px). Signed
/// and confirmed_in_system are visually distinct states. Home after auth.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/entities.dart';
import '../../domain/handover.dart';
import '../../domain/ward_order.dart';
import '../../services/export_engine.dart';
import '../../state/app_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'assistant_sheet.dart';
import 'patient_detail_screen.dart';
import 'recording_screen.dart';

class WardListScreen extends StatelessWidget {
  const WardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppModel.instance!;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final c = context.afia;
        final t = l10n(context);
        // D-014 — the nurse's own saved order (bed default; §2.10 intact:
        // no risk mode exists in the enum).
        final patients = model.orderedPatients;
        final confirmed = patients
            .where((p) =>
                model.latestFor(p.id)?.status ==
                HandoverStatus.confirmedInSystem)
            .length;

        return Column(children: [
          // Header — ward name, shift metadata, counter.
          Container(
            height: 56,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border))),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(model.ward?.name ?? t.wardFallback,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sans(context, 19,
                            weight: FontWeight.w500, color: c.text)),
                    const SizedBox(height: 2),
                    Text(
                      '${model.templateVersion != null ? 'SBAR v${model.templateVersion!.version}' : '—'} · ${t.listAt(hhmm(DateTime.now().millisecondsSinceEpoch))}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sans(context, 11, color: c.textFaint),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => showAssistantSheet(context),
                icon: Icon(LucideIcons.sparkles, size: 20, color: c.machine),
                tooltip: t.assistantTitle,
              ),
              RichText(
                text: TextSpan(
                  style: mono(context, 20,
                      weight: FontWeight.w500, color: c.textDim),
                  children: [
                    TextSpan(
                        text: '$confirmed',
                        style: mono(context, 20,
                            weight: FontWeight.w500, color: c.text)),
                    TextSpan(text: ' / ${patients.length}'),
                  ],
                ),
              ),
            ]),
          ),
          // Custom-order indicator — quiet, with a one-tap reset.
          if (!model.wardOrder.isDefault)
            Container(
              height: 26,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: c.raised,
                border: Border(bottom: BorderSide(color: c.hairline)),
              ),
              child: Row(children: [
                Icon(LucideIcons.arrowUpDown, size: 11, color: c.textFaint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(t.customOrderActive,
                      style: sans(context, 11, color: c.textFaint)),
                ),
                InkWell(
                  onTap: () => model.setWardOrder(WardOrder.defaultOrder),
                  child: Text(t.resetToDefault,
                      style: sans(context, 11, color: c.machine)),
                ),
              ]),
            ),
          // The 12 rows — Expanded shares height exactly: no scroll, ever.
          Expanded(
            child: patients.isEmpty
                ? _EmptyState()
                : Column(children: [
                    for (var i = 0; i < patients.length; i++)
                      Expanded(
                          child: _PatientRow(index: i, patient: patients[i])),
                  ]),
          ),
        ]);
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(LucideIcons.bedDouble, size: 28, color: c.textFaint),
        const SizedBox(height: 12),
        Text(t.noPatients, style: sans(context, 15, color: c.textDim)),
        const SizedBox(height: 4),
        Text(t.noPatientsBody, style: sans(context, 13, color: c.textFaint)),
      ]),
    );
  }
}

class _PatientRow extends StatelessWidget {
  final int index;
  final Patient patient;
  const _PatientRow({required this.index, required this.patient});

  @override
  Widget build(BuildContext context) {
    final model = AppModel.instance!;
    final c = context.afia;
    final t = l10n(context);
    final latest = model.latestFor(patient.id);
    final status = latest?.status ?? HandoverStatus.notStarted;
    final active = status == HandoverStatus.recording;

    final int? timeMs = switch (status) {
      HandoverStatus.signed ||
      HandoverStatus.queued =>
        latest?.signature?.signedAt,
      HandoverStatus.confirmedInSystem => latest?.acknowledgedAt,
      _ => null,
    };

    Widget? trailing;
    if (status == HandoverStatus.exportFailed && latest != null) {
      trailing = Pill(
        label: t.retry,
        onTap: () => ExportEngine.instance.retry(latest, model.me.id),
      );
    } else if (status == HandoverStatus.recording && latest != null) {
      trailing = Pill(
        label: t.resume,
        icon: LucideIcons.play,
        color: c.draft,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RecordingScreen(patient: patient, resume: latest),
        )),
      );
    } else {
      trailing = Icon(
        Directionality.of(context) == TextDirection.rtl
            ? LucideIcons.chevronLeft
            : LucideIcons.chevronRight,
        size: 18,
        color: c.textFaint,
      );
    }

    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PatientDetailScreen(patientId: patient.id),
      )),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? c.raised : null,
          border: Border(bottom: BorderSide(color: c.hairline)),
        ),
        child: Row(children: [
          SizedBox(
            width: 24,
            child: Text(
              (index + 1).toString().padLeft(2, '0'),
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
              style: mono(context, 16,
                  weight: FontWeight.w500,
                  color: active ? c.text : c.textDim),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(patient.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sans(context, 15, color: c.text)),
                const SizedBox(height: 3),
                StatusLine(status: status, timeMs: timeMs),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ]),
      ),
    );
  }
}
