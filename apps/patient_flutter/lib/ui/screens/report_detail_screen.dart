/// Report detail — the timeline of the initial report and every
/// condition-changed update, each with its HONEST sync state (F-057), the
/// MANDATORY honesty copy verbatim (§6 / F-058 — unchanged by D-015), and
/// «حالتي تغيرت» when this is the active report.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/patient_case.dart';
import '../../services/case_repo.dart';
import '../../state/episode_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'update_flow_screen.dart';

class ReportDetailScreen extends StatelessWidget {
  final String caseId;
  const ReportDetailScreen({super.key, required this.caseId});

  String _formatTime(BuildContext context, int at) {
    final d = DateTime.fromMillisecondsSinceEpoch(at);
    final l = MaterialLocalizations.of(context);
    return '${l.formatShortDate(d)} · ${l.formatTimeOfDay(TimeOfDay.fromDateTime(d))}';
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final model = EpisodeModel.instance;
    final isActive = model.activeCaseId == caseId;

    return StreamBuilder<CaseSyncSnapshot>(
      stream: CaseRepo.instance.watchCase(caseId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final c = data?.patientCase;
        return StepPage(children: [
          Row(children: [
            InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(PatientDimens.radius),
              child: Container(
                constraints: const BoxConstraints(
                    minWidth: PatientDimens.touch,
                    minHeight: PatientDimens.touch),
                alignment: Alignment.center,
                child: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? LucideIcons.chevronRight
                      : LucideIcons.chevronLeft,
                  size: 26,
                  color: PatientColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(t.detailTitle,
                  style: sans(context, 24, weight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 8),
          if (c == null && snapshot.connectionState == ConnectionState.waiting)
            Center(child: BodyText(t.loading))
          else if (c == null) ...[
            PageTitle(t.statusCaseGoneTitle),
            BodyText(t.statusCaseGoneBody),
          ] else ...[
            if (data != null && data.fromCache)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: PatientColors.raised,
                  border:
                      Border.all(color: PatientColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(PatientDimens.radius),
                ),
                child: Text(t.offlineStrip,
                    style: sans(context, 17,
                        weight: FontWeight.w600,
                        color: PatientColors.inkDim)),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Text(t.caseRefLabel, style: sans(context, 18)),
                const SizedBox(width: 8),
                Text(shortRef(c.id),
                    style: mono(context, 19, weight: FontWeight.w600)
                        .copyWith(letterSpacing: 2)),
              ]),
            ),
            for (final u in c.updates)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PatientColors.surface,
                  border:
                      Border.all(color: PatientColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(PatientDimens.radius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.kind == UpdateKind.initial
                          ? t.updateInitial
                          : t.updateConditionChanged,
                      style: sans(context, 19, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(_formatTime(context, u.at),
                        style:
                            sans(context, 17, color: PatientColors.inkDim)),
                    if (u.transcript.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(u.transcript,
                          style: sans(context, 17, height: 1.5)),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      u.syncState == SyncState.sent
                          ? t.syncSent
                          : t.syncQueued,
                      style: sans(
                        context,
                        17,
                        weight: FontWeight.w700,
                        height: 1.4,
                        color: u.syncState == SyncState.sent
                            ? PatientColors.ok
                            : PatientColors.warn,
                      ),
                    ),
                  ],
                ),
              ),
            // ── the mandatory copy — verbatim, prominent (F-058) ─────────
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: PatientColors.surface,
                border: Border.all(color: PatientColors.ink, width: 3),
                borderRadius: BorderRadius.circular(PatientDimens.radius),
              ),
              child: Text(t.mandatoryStatusCopy,
                  style: sans(context, 19,
                      weight: FontWeight.w600, height: 1.45)),
            ),
            if (isActive) ...[
              BodyText(t.statusChangeHint),
              const SizedBox(height: 6),
              PrimaryButton(
                label: t.conditionChanged,
                onTap: () {
                  model.startConditionChanged();
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const UpdateFlowScreen()));
                },
              ),
            ],
          ],
        ]);
      },
    );
  }
}
