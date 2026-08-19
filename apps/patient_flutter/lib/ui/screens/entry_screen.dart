/// Entry — a door, not a hub (§6). Two variants: FIRST OPEN, and resume
/// WITH AN UNFINISHED DESCRIPTION. Two SEPARATE toggles (HANDOFF §3.3):
/// terms acceptance and sharing consent are different records.
library;

import 'package:flutter/material.dart';

import '../../state/episode_model.dart';
import '../widgets/common.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  late final TextEditingController _name = TextEditingController(
      text: EpisodeModel.instance.episode.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final model = EpisodeModel.instance;
    final e = model.episode;

    // Resume variant — an unfinished description is waiting.
    if (model.resumeTarget != null) {
      return StepPage(children: [
        PageTitle(t.resumeTitle),
        BodyText(t.resumeBody),
        const SizedBox(height: 12),
        PrimaryButton(label: t.resumeContinue, onTap: model.resumeEpisode),
        const SizedBox(height: 10),
        Center(child: QuietLink(label: t.startOver, onTap: () {
          model.startOver();
          _name.text = '';
        })),
      ]);
    }

    final ready = e.termsAccepted && e.consentGiven;
    return StepPage(children: [
      PageTitle(t.entryTitle),
      BodyText(t.entryBody1),
      BodyText(t.entryBody2),
      const SizedBox(height: 8),
      BigField(
        label: t.entryNameLabel,
        controller: _name,
        keyboardType: TextInputType.name,
        onChanged: model.setName,
      ),
      ToggleRow(
          checked: e.termsAccepted,
          label: t.entryTerms,
          onChanged: model.setTerms),
      ToggleRow(
          checked: e.consentGiven,
          label: t.entryConsent,
          onChanged: model.setConsent),
      const SizedBox(height: 8),
      PrimaryButton(
          label: t.continueLabel,
          onTap: ready ? model.startEpisode : null),
      if (!ready) ...[
        const SizedBox(height: 10),
        BodyText(t.entryAgreeHint),
      ],
    ]);
  }
}
