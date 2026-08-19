/// Who is completing — two identical 64px options.
library;

import 'package:flutter/material.dart';

import '../../state/episode_model.dart';
import '../widgets/common.dart';

class WhoScreen extends StatelessWidget {
  const WhoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final model = EpisodeModel.instance;
    final current = model.episode.completedBy;
    return StepPage(children: [
      PageTitle(t.whoTitle),
      const SizedBox(height: 8),
      AnswerButton(
        label: t.whoSelf,
        selected: current == 'self',
        onTap: () => model.chooseCompletedBy('self'),
      ),
      AnswerButton(
        label: t.whoCarer,
        selected: current == 'carer',
        onTap: () => model.chooseCompletedBy('carer'),
      ),
    ]);
  }
}
