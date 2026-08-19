/// The «حالتي تغيرت» flow: the safety questions again (local, deterministic
/// — §2.7), then the delta description, then an explicit confirmation that
/// the update JOINED THE SAME CASE (F-056 — never a new case, never a
/// reset). Two steps, a calm «١ من ٢» indicator, back on every step.
library;

import 'package:flutter/material.dart';

import '../../domain/episode.dart';
import '../../state/episode_model.dart';
import '../widgets/common.dart';
import 'describe_screen.dart';
import 'red_flag_screen.dart';
import 'report_flow_screen.dart' show FlowHeader;
import 'update_confirm_screen.dart';

class UpdateFlowScreen extends StatelessWidget {
  const UpdateFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = EpisodeModel.instance;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final kind = model.episode.step.kind;
        if (kind == StepKind.updateConfirm) {
          model.finishUpdateFlow();
          Navigator.of(context).pop();
          return;
        }
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
            case StepKind.updateRedflag:
              final qs = model.redFlagQuestions;
              final q = qs[step.index.clamp(0, qs.length - 1)];
              final answers =
                  (e.update ?? const UpdateDraft()).redFlagAnswers;
              content = RedFlagScreen(
                key: ValueKey('urf-${q.id}'),
                question: q,
                isRepeat: true,
                current: answers[q.id],
              );
            case StepKind.updateDelta:
              final draft = e.update ?? const UpdateDraft();
              content = DescribeScreen(
                key: const ValueKey('describe-delta'),
                eyebrowText: t.updateEyebrow,
                title: t.updateTitle,
                lead: t.updateLead,
                transcript: draft.transcript,
                audio: draft.audio,
                continueLabel: t.addToCase,
                onTranscript: model.setTranscript,
                onAudio: model.setAudio,
                onContinue: model.sendConditionChanged,
              );
            default: // updateConfirm — the update was appended
              content = UpdateConfirmScreen(
                onDone: () {
                  model.finishUpdateFlow();
                  Navigator.of(context).maybePop();
                },
              );
          }

          return Stack(children: [
            content,
            if (step.kind != StepKind.updateConfirm)
              FlowHeader(
                stepNumber: step.kind == StepKind.updateRedflag ? 1 : 2,
                stepCount: 2,
                onBack: () {
                  if (!model.goBackStep()) Navigator.of(context).maybePop();
                },
              ),
          ]);
        },
      ),
    );
  }
}
