/// The guided REPORT flow (pushed from Home's one big action). One question,
/// one action, one screen — now with a clear back affordance on every step
/// and a simple, calm step indicator («٢ من ٥») for orientation, which
/// D-015 explicitly permits. Exiting mid-flow keeps the draft (F-055) and
/// Home offers «أكمل تقريرك».
///
/// Safety unchanged: red flags open the flow, evaluated locally and
/// deterministically after every answer (§2.7); a YES raises the emergency
/// interrupt above this route.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/episode.dart';
import '../../state/episode_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'describe_screen.dart';
import 'functional_screen.dart';
import 'red_flag_screen.dart';
import 'review_screen.dart';
import 'who_screen.dart';

/// The small back + step-indicator capsule, top-start — the mirror of the
/// emergency fixture (top-end). Both float above the step content.
class FlowHeader extends StatelessWidget {
  final int stepNumber;
  final int stepCount;
  final VoidCallback onBack;
  const FlowHeader({
    super.key,
    required this.stepNumber,
    required this.stepCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return PositionedDirectional(
      top: MediaQuery.of(context).padding.top + 10,
      start: 12,
      child: Material(
        color: PatientColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PatientDimens.radius),
          side: const BorderSide(color: PatientColors.border, width: 2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Semantics(
            button: true,
            label: t.backLabel,
            child: InkWell(
              onTap: onBack,
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
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 14),
            child: Text(
              t.stepOf(stepNumber, stepCount),
              style: sans(context, 16,
                  weight: FontWeight.w600, color: PatientColors.inkDim),
            ),
          ),
        ]),
      ),
    );
  }
}

class ReportFlowScreen extends StatelessWidget {
  const ReportFlowScreen({super.key});

  int _stepNumber(StepKind kind) => switch (kind) {
        StepKind.redflag => 1,
        StepKind.who => 2,
        StepKind.voice => 3,
        StepKind.functional => 4,
        _ => 5, // review
      };

  void _back(BuildContext context, EpisodeModel model) {
    if (!model.goBackStep()) {
      Navigator.of(context).maybePop(); // draft stays saved (F-055)
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = EpisodeModel.instance;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!model.goBackStep()) Navigator.of(context).pop();
      },
      child: ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          final t = l10n(context);
          final e = model.episode;
          final step = e.step;

          Widget content;
          switch (step.kind) {
            case StepKind.redflag:
              final qs = model.redFlagQuestions;
              final q = qs[step.index.clamp(0, qs.length - 1)];
              content = RedFlagScreen(
                key: ValueKey('rf-${q.id}'),
                question: q,
                isRepeat: false,
                current: e.redFlagAnswers[q.id],
              );
            case StepKind.who:
              content = WhoScreen();
            case StepKind.voice:
              content = DescribeScreen(
                key: const ValueKey('describe-initial'),
                eyebrowText: t.voiceEyebrow,
                title: t.voiceTitle,
                lead: t.voiceLead,
                transcript: e.transcript,
                audio: e.audio,
                continueLabel: t.continueLabel,
                onTranscript: model.setTranscript,
                onAudio: model.setAudio,
                onContinue: model.continueFromVoice,
              );
            case StepKind.functional:
              final qs = model.functionalQuestions;
              final q = qs[step.index.clamp(0, qs.length - 1)];
              content = FunctionalScreen(
                key: ValueKey('fn-${q.id}'),
                question: q,
                current: e.functionalAnswers[q.id],
              );
            default:
              content = ReviewScreen(
                onSent: () => Navigator.of(context).maybePop(),
              );
          }

          return Stack(children: [
            content,
            FlowHeader(
              stepNumber: _stepNumber(step.kind),
              stepCount: 5,
              onBack: () => _back(context, model),
            ),
          ]);
        },
      ),
    );
  }
}
