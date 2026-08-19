/// One baseline-anchored functional question per screen. All four answers
/// styled identically (F-053); "I don't know" stores UNKNOWN and is never
/// coerced (§2.2).
library;

import 'package:flutter/material.dart';

import '../../domain/answer.dart';
import '../../domain/red_flags.dart';
import '../../state/episode_model.dart';
import '../widgets/common.dart';

class FunctionalScreen extends StatelessWidget {
  final FunctionalQuestion question;
  final FunctionalValue? current;
  const FunctionalScreen(
      {super.key, required this.question, required this.current});

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final lang = Localizations.localeOf(context).languageCode;
    final model = EpisodeModel.instance;
    final options = [
      (FunctionalValue.sameAsNormal, t.fnSame),
      (FunctionalValue.worse, t.fnWorse),
      (FunctionalValue.muchWorse, t.fnMuchWorse),
      (FunctionalValue.unknown, t.answerDontKnow),
    ];
    return StepPage(children: [
      Eyebrow(t.functionalEyebrow),
      PageTitle(question.text(lang)),
      const SizedBox(height: 8),
      for (final (value, label) in options)
        AnswerButton(
          label: label,
          selected: current == value,
          onTap: () => model.answerFunctional(question.id, value),
        ),
    ]);
  }
}
