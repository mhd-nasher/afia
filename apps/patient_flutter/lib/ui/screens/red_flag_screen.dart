/// One red-flag question per screen. Three answers styled IDENTICALLY —
/// same size, same weight, same shape (F-053). "I don't know" is
/// first-class and stores UNKNOWN, never NO (§2.2). No step counter, no
/// progress bar (F-050). Evaluation after every answer is local,
/// deterministic and instant (§2.7).
library;

import 'package:flutter/material.dart';

import '../../domain/answer.dart';
import '../../domain/red_flags.dart';
import '../../state/episode_model.dart';
import '../widgets/common.dart';

class RedFlagScreen extends StatelessWidget {
  final RedFlagQuestion question;
  final bool isRepeat;
  final AnswerState? current;
  const RedFlagScreen({
    super.key,
    required this.question,
    required this.isRepeat,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final lang = Localizations.localeOf(context).languageCode;
    final model = EpisodeModel.instance;
    final options = [
      (AnswerState.yes, t.answerYes),
      (AnswerState.no, t.answerNo),
      (AnswerState.unknown, t.answerDontKnow),
    ];
    return StepPage(children: [
      Eyebrow(isRepeat
          ? t.safetyQuestionsRepeatEyebrow
          : t.safetyQuestionsEyebrow),
      PageTitle(question.text(lang)),
      const SizedBox(height: 8),
      for (final (value, label) in options)
        AnswerButton(
          label: label,
          selected: current == value,
          onTap: () => model.answerRedFlag(question.id, value),
        ),
    ]);
  }
}
