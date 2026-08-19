/// The step host — one linear episode. NO tab bar, NO bottom navigation, NO
/// progress bar, NO step counter (F-050). Each step renders alone; the
/// emergency fixture and the dock live ABOVE this widget, outside its
/// hierarchy (F-051).
library;

import 'package:flutter/material.dart';

import '../domain/episode.dart';
import '../state/episode_model.dart';
import 'screens/account_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/describe_screen.dart';
import 'screens/entry_screen.dart';
import 'screens/functional_screen.dart';
import 'screens/red_flag_screen.dart';
import 'screens/review_screen.dart';
import 'screens/status_screen.dart';
import 'screens/update_confirm_screen.dart';
import 'screens/who_screen.dart';
import 'widgets/common.dart';

class FlowHost extends StatelessWidget {
  const FlowHost({super.key});

  @override
  Widget build(BuildContext context) {
    final model = EpisodeModel.instance;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final t = l10n(context);
        final e = model.episode;
        final step = e.step;

        switch (step.kind) {
          case StepKind.entry:
            return EntryScreen();

          case StepKind.redflag:
          case StepKind.updateRedflag:
            final isRepeat = step.kind == StepKind.updateRedflag;
            final qs = model.redFlagQuestions;
            final q = qs[step.index.clamp(0, qs.length - 1)];
            final answers = isRepeat
                ? (e.update ?? const UpdateDraft()).redFlagAnswers
                : e.redFlagAnswers;
            return RedFlagScreen(
              key: ValueKey('rf-${step.kind.name}-${q.id}'),
              question: q,
              isRepeat: isRepeat,
              current: answers[q.id],
            );

          case StepKind.who:
            return WhoScreen();

          case StepKind.voice:
            return DescribeScreen(
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
            return FunctionalScreen(
              key: ValueKey('fn-${q.id}'),
              question: q,
              current: e.functionalAnswers[q.id],
            );

          case StepKind.review:
            return ReviewScreen();

          case StepKind.auth:
            return AuthScreen();

          case StepKind.status:
            final caseId = e.caseId;
            if (caseId == null) return EntryScreen();
            return StatusScreen(caseId: caseId);

          case StepKind.account:
            return AccountScreen();

          case StepKind.updateDelta:
            final draft = e.update ?? const UpdateDraft();
            return DescribeScreen(
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

          case StepKind.updateConfirm:
            return UpdateConfirmScreen();
        }
      },
    );
  }
}
