/// Confirmation after a "my condition has changed" update (F-056). The copy
/// is EXPLICIT that the update joined the existing case — same case id,
/// never a new case, never a reset.
library;

import 'package:flutter/material.dart';

import '../../domain/patient_case.dart';
import '../../state/episode_model.dart';
import '../widgets/common.dart';

class UpdateConfirmScreen extends StatelessWidget {
  const UpdateConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final model = EpisodeModel.instance;
    final caseId = model.episode.caseId ?? '';
    return StepPage(children: [
      PageTitle(t.updateAddedTitle),
      BodyText(t.updateAddedBody),
      BodyText(t.caseRefStill(shortRef(caseId))),
      const SizedBox(height: 12),
      PrimaryButton(label: t.backToCase, onTap: model.backToStatus),
    ]);
  }
}
