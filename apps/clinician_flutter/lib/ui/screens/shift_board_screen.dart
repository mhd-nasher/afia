/// Screen 10 — Shift board. Signature and export state for every patient.
/// signed ≠ confirmed_in_system, visually distinct (§5). Export failure uses
/// the INVERTED banner — colour means the patient, inversion means the
/// system, never clinical red. Retry re-queues; nothing else can.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/handover.dart';
import '../../services/export_engine.dart';
import '../../services/prefs.dart';
import '../../state/app_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'assistant_sheet.dart';
import 'draft_review_screen.dart';
import 'shift_complete_screen.dart';

class ShiftBoardScreen extends StatelessWidget {
  const ShiftBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppModel.instance!;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final c = context.afia;
        final t = l10n(context);
        final patients = model.patients;
        final latest = {
          for (final p in patients) p.id: model.latestFor(p.id),
        };
        final recorded = latest.values
            .where((h) => h != null && h.status != HandoverStatus.notStarted)
            .length;
        final signed =
            latest.values.where((h) => h?.signature != null).length;
        final confirmed = latest.values
            .where((h) => h?.status == HandoverStatus.confirmedInSystem)
            .length;
        final failed = latest.values
            .where((h) => h?.status == HandoverStatus.exportFailed)
            .toList();

        final allDone = patients.isNotEmpty && confirmed == patients.length;
        final dayKey = DateTime.now().toIso8601String().substring(0, 10);
        final completeAvailable =
            allDone && Prefs.instance.shiftCompleteShownFor != dayKey;

        return Column(children: [
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
                    Text(t.shiftBoardTitle,
                        style: sans(context, 19,
                            weight: FontWeight.w500, color: c.text)),
                    const SizedBox(height: 2),
                    Text(model.ward?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sans(context, 11, color: c.textFaint)),
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
                        text: '$signed',
                        style: mono(context, 20,
                            weight: FontWeight.w500, color: c.text)),
                    TextSpan(text: ' / ${patients.length}'),
                  ],
                ),
              ),
            ]),
          ),
          // Inverted system banner — export failures (§ shared parts).
          if (failed.isNotEmpty)
            InvertedBanner(
              icon: LucideIcons.rotateCw,
              title: failed.length == 1
                  ? t.notReachedBanner
                  : t.notReachedBannerMany(failed.length),
              subtitle:
                  '${t.lastTried(model.patientById(failed.first!.patientId)?.bed ?? '—', hhmm(failed.first!.createdAt))} · ${t.safeOnDevice}',
              actionLabel: t.retry,
              onAction: () =>
                  ExportEngine.instance.retry(failed.first!, model.me.id),
            ),
          // Stats row.
          Container(
            height: 56,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border))),
            child: Row(children: [
              _stat(context, recorded, t.recordedStat),
              const SizedBox(width: 16),
              _stat(context, signed, t.signedStat),
              const SizedBox(width: 16),
              _stat(context, confirmed, t.confirmedStat),
            ]),
          ),
          // Column headers.
          Container(
            height: 28,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                  child: Text(t.patientCol.toUpperCase(),
                      style: sectionLabel(context))),
              SizedBox(
                  width: 70,
                  child: Text(t.signedCol.toUpperCase(),
                      style: sectionLabel(context))),
              SizedBox(
                  width: 92,
                  child: Text(t.inSystemCol.toUpperCase(),
                      style: sectionLabel(context))),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: patients.length + (completeAvailable ? 1 : 0),
              itemBuilder: (context, i) {
                if (completeAvailable && i == patients.length) {
                  return Padding(
                    padding: const EdgeInsetsDirectional.all(16),
                    child: PrimaryButton(
                      onTap: () async {
                        await Prefs.instance.setShiftCompleteShownFor(dayKey);
                        if (context.mounted) {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const ShiftCompleteScreen()));
                        }
                      },
                      child: Text(t.endShift),
                    ),
                  );
                }
                final p = patients[i];
                final h = latest[p.id];
                return InkWell(
                  onTap: h == null
                      ? null
                      : () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              DraftReviewScreen(handoverId: h.id))),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: h?.status == HandoverStatus.exportFailed
                            ? c.raised
                            : null,
                        border:
                            Border(top: BorderSide(color: c.hairline))),
                    child: Row(children: [
                      SizedBox(
                        width: 24,
                        child: Text((i + 1).toString().padLeft(2, '0'),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.ltr,
                            style: mono(context, 16,
                                weight: FontWeight.w500, color: c.textDim)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(p.shortName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sans(context, 15, color: c.text)),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(
                          h?.signature != null
                              ? hhmm(h!.signature!.signedAt)
                              : '—',
                          textDirection: TextDirection.ltr,
                          style: mono(context, 14, color: c.textDim),
                        ),
                      ),
                      SizedBox(width: 92, child: _inSystem(context, h)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]);
      },
    );
  }

  Widget _stat(BuildContext context, int n, String label) {
    final c = context.afia;
    return Row(crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('$n',
              style:
                  mono(context, 20, weight: FontWeight.w500, color: c.text)),
          const SizedBox(width: 6),
          Text(label, style: sans(context, 11, color: c.textFaint)),
        ]);
  }

  /// The distinct visual states: Yes (green) · Queued (accent) · Failed
  /// (plain + retry) · — (nothing signed yet). Icon + word, never colour alone.
  Widget _inSystem(BuildContext context, Handover? h) {
    final c = context.afia;
    final t = l10n(context);
    if (h == null || h.signature == null) {
      return Text('—', style: sans(context, 13, color: c.textFaint));
    }
    return switch (h.status) {
      HandoverStatus.confirmedInSystem => Row(children: [
          Icon(LucideIcons.checkCircle2, size: 15, color: c.ok),
          const SizedBox(width: 5),
          Text(t.yes, style: sans(context, 13, color: c.ok)),
        ]),
      HandoverStatus.exportFailed => Row(children: [
          Icon(LucideIcons.rotateCw, size: 15, color: c.text),
          const SizedBox(width: 5),
          Text(t.failedLabel, style: sans(context, 13, color: c.text)),
        ]),
      _ => Row(children: [
          Icon(LucideIcons.arrowUpCircle, size: 15, color: c.signedAccent),
          const SizedBox(width: 5),
          Text(t.queuedLabel,
              style: sans(context, 13, color: c.signedAccent)),
        ]),
    };
  }
}
