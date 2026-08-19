/// الرئيسية — greeting, ONE big primary action («أبلغ عن حالتي»), the active
/// report's status card, a resume-draft card when a report is unfinished,
/// and a quiet help card (nurse line 444 · emergency 999). No clutter
/// (D-015: obvious > clever).
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/patient_case.dart';
import '../../domain/red_flags.dart';
import '../../services/case_repo.dart';
import '../../state/episode_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/safety_layer.dart' show dial;
import 'active_case_gate_screen.dart';
import 'report_detail_screen.dart';
import 'report_flow_screen.dart';
import 'update_flow_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  void _onReport(BuildContext context, EpisodeModel model) {
    if (model.hasActiveCase) {
      // One active case at a time: route to the update flow with a clear
      // explanation (D-015).
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const ActiveCaseGateScreen()));
    } else {
      model.startNewReport();
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const ReportFlowScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final model = EpisodeModel.instance;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final name = model.episode.name.trim();
        return StepPage(children: [
          Text(
            name.isEmpty ? t.homeGreetingNoName : t.homeGreeting(name),
            style: sans(context, 28, weight: FontWeight.w600, height: 1.25),
          ),
          const SizedBox(height: 4),
          BodyText(t.homeLead, color: PatientColors.inkDim),
          const SizedBox(height: 12),

          // ── the one big action ────────────────────────────────────────
          PrimaryButton(
            label: t.reportAction,
            leading: const Icon(LucideIcons.messageSquarePlus),
            onTap: () => _onReport(context, model),
          ),

          // ── resume an unfinished draft ────────────────────────────────
          if (model.hasDraft) ...[
            const SizedBox(height: 14),
            _Card(children: [
              Text(t.resumeCardTitle,
                  style: sans(context, 19, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(t.resumeCardBody,
                  style: sans(context, 17,
                      color: PatientColors.inkDim, height: 1.4)),
              const SizedBox(height: 10),
              GhostButton(
                label: t.resumeContinue,
                onTap: () {
                  model.resumeDraft();
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const ReportFlowScreen()));
                },
              ),
              const SizedBox(height: 6),
              Center(
                  child: QuietLink(
                      label: t.discardDraft, onTap: model.discardDraft)),
            ]),
          ],

          // ── the active report's status card ───────────────────────────
          if (model.hasActiveCase) ...[
            const SizedBox(height: 14),
            _ActiveCaseCard(caseId: model.activeCaseId!),
          ],

          // ── quiet help card ───────────────────────────────────────────
          const SizedBox(height: 14),
          _Card(children: [
            Text(t.helpCardTitle,
                style: sans(context, 19, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => dial(EmergencyNumbers.urgentAdvice),
              child: Container(
                constraints:
                    const BoxConstraints(minHeight: PatientDimens.touch),
                alignment: AlignmentDirectional.centerStart,
                child: Row(children: [
                  const Icon(LucideIcons.phoneCall,
                      size: 20, color: PatientColors.action),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        t.callNurseLine(EmergencyNumbers.urgentAdvice),
                        style: sans(context, 17,
                            weight: FontWeight.w600,
                            color: PatientColors.action)),
                  ),
                ]),
              ),
            ),
            Text(t.emergencyInfoLine(EmergencyNumbers.emergency),
                style: sans(context, 17,
                    color: PatientColors.inkDim, height: 1.45)),
          ]),
        ]);
      },
    );
  }
}

class _ActiveCaseCard extends StatelessWidget {
  final String caseId;
  const _ActiveCaseCard({required this.caseId});

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return StreamBuilder<CaseSyncSnapshot>(
      stream: _safeWatch(caseId),
      builder: (context, snapshot) {
        final c = snapshot.data?.patientCase;
        return _Card(children: [
          Row(children: [
            Expanded(
              child: Text(t.activeCardTitle,
                  style: sans(context, 19, weight: FontWeight.w700)),
            ),
            Text(shortRef(caseId),
                style: mono(context, 16, color: PatientColors.inkDim)
                    .copyWith(letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 6),
          if (c == null)
            Text(t.loading,
                style: sans(context, 17, color: PatientColors.inkDim))
          else ...[
            Text(
              c.updates.isNotEmpty &&
                      c.updates.every((u) => u.syncState == SyncState.sent)
                  ? t.syncSent
                  : t.syncQueued,
              style: sans(
                context,
                17,
                weight: FontWeight.w700,
                height: 1.4,
                color: c.updates.isNotEmpty &&
                        c.updates.every((u) => u.syncState == SyncState.sent)
                    ? PatientColors.ok
                    : PatientColors.warn,
              ),
            ),
            const SizedBox(height: 4),
            Text(t.reportRowUpdates(c.updates.length),
                style: sans(context, 17, color: PatientColors.inkDim)),
          ],
          const SizedBox(height: 10),
          PrimaryButton(
            label: t.conditionChanged,
            onTap: () {
              EpisodeModel.instance.startConditionChanged();
              Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const UpdateFlowScreen()));
            },
          ),
          const SizedBox(height: 6),
          Center(
            child: QuietLink(
              label: t.viewDetails,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ReportDetailScreen(caseId: caseId))),
            ),
          ),
        ]);
      },
    );
  }

  static Stream<CaseSyncSnapshot> _safeWatch(String id) {
    try {
      return CaseRepo.instance.watchCase(id);
    } catch (_) {
      return const Stream<CaseSyncSnapshot>.empty();
    }
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        border: Border.all(color: PatientColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(PatientDimens.radius),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
