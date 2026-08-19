/// D-015 active-case rule: one active case at a time. Tapping «أبلغ عن
/// حالتي» while a case is active lands here — a plain explanation and an
/// obvious primary path (add an update to the SAME case, F-056). Starting a
/// genuinely new report is the quiet secondary choice; the old case stays in
/// the history and with the nursing team.
library;

import 'package:flutter/material.dart';

import '../../state/episode_model.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'report_flow_screen.dart';
import 'update_flow_screen.dart';

class ActiveCaseGateScreen extends StatelessWidget {
  const ActiveCaseGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final model = EpisodeModel.instance;
    return StepPage(children: [
      PageTitle(t.activeGateTitle),
      BodyText(t.activeGateBody),
      const SizedBox(height: 12),
      PrimaryButton(
        label: t.activeGateUpdate,
        onTap: () {
          model.startConditionChanged();
          Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
              builder: (_) => const UpdateFlowScreen()));
        },
      ),
      const SizedBox(height: 12),
      GhostButton(
        label: t.backLabel,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      const SizedBox(height: 16),
      BodyText(t.activeGateNewLead, color: PatientColors.inkDim),
      Center(
        child: QuietLink(
          label: t.activeGateNew,
          onTap: () {
            model.startNewReportDespiteActive();
            Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                builder: (_) => const ReportFlowScreen()));
          },
        ),
      ),
    ]);
  }
}
