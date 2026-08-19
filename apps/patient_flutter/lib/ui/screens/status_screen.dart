/// Status — the persistent safety surface (HANDOFF §6). The mandatory copy
/// (F-058) renders prominently and VERBATIM. Sync copy is HONEST (F-057):
/// an update is "sent" only once the SERVER acknowledged the write; a queued
/// update says plainly that the nursing team has NOT seen it, and nothing
/// here ever implies a nurse is watching.
library;

import 'package:flutter/material.dart';

import '../../domain/patient_case.dart';
import '../../services/case_repo.dart';
import '../../state/episode_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

class StatusScreen extends StatelessWidget {
  final String caseId;
  const StatusScreen({super.key, required this.caseId});

  String _formatTime(BuildContext context, int at) {
    final d = DateTime.fromMillisecondsSinceEpoch(at);
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatShortDate(d)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(d))}';
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final model = EpisodeModel.instance;

    return StreamBuilder<CaseSyncSnapshot>(
      stream: CaseRepo.instance.watchCase(caseId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final c = data?.patientCase;
        if (snapshot.connectionState == ConnectionState.waiting &&
            c == null) {
          return StepPage(children: [
            const SizedBox(height: 40),
            Center(child: BodyText(t.loading)),
          ]);
        }
        if (c == null) {
          return StepPage(children: [
            PageTitle(t.statusCaseGoneTitle),
            BodyText(t.statusCaseGoneBody),
            const SizedBox(height: 12),
            PrimaryButton(
                label: t.startAgain, onTap: model.resetAfterErasure),
          ]);
        }
        final offline = data != null && data.fromCache;
        return StepPage(children: [
          if (offline)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          PageTitle(t.statusTitle),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Text(t.caseRefLabel, style: sans(context, 19)),
              const SizedBox(width: 8),
              Text(shortRef(c.id),
                  style: mono(context, 20, weight: FontWeight.w600)
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
                  const SizedBox(height: 8),
                  Text(
                    u.syncState == SyncState.sent
                        ? t.syncSent
                        : t.syncQueued,
                    style: sans(
                      context,
                      18,
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
          // ── the mandatory copy — verbatim, prominent (F-058) ───────────
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
          BodyText(t.statusChangeHint),
          const SizedBox(height: 10),
          Center(
              child: QuietLink(
                  label: t.yourAccount, onTap: model.openAccount)),
        ]);
      },
    );
  }
}
