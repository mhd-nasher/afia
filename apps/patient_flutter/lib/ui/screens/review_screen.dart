/// Review — a neutral list of what's answered. What's missing is phrased
/// NEUTRALLY: "Not mentioned: X" — NEVER importance language, never ranking
/// (§4.3 — even ranking which missing information matters is a clinical
/// judgement). Nothing here implies the person is fine (§11). Edit buttons
/// jump back to a question and return here.
///
/// The optional AI "tidy" reorganises the patient's OWN words only; its
/// output renders in periwinkle (machine-made, unverified) until the
/// patient accepts it. The gap list itself is deterministic rules (§2.8) —
/// the model never touches it.
library;

import 'package:flutter/material.dart';

import '../../domain/answer.dart';
import '../../domain/patient_case.dart';
import '../../services/ai_service.dart';
import '../../state/episode_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  String _redFlagLabel(BuildContext context, AnswerState? a) {
    final t = l10n(context);
    return switch (a) {
      AnswerState.yes => t.answerYes,
      AnswerState.no => t.answerNo,
      _ => t.notAnswered,
    };
  }

  String _functionalLabel(BuildContext context, FunctionalValue? v) {
    final t = l10n(context);
    return switch (v) {
      FunctionalValue.sameAsNormal => t.fnSame,
      FunctionalValue.worse => t.fnWorse,
      FunctionalValue.muchWorse => t.fnMuchWorse,
      _ => t.notAnswered,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final lang = Localizations.localeOf(context).languageCode;
    final model = EpisodeModel.instance;
    final e = model.episode;
    final description = e.transcript.trim();

    final gaps = episodeGaps(
      redFlagQuestions: model.redFlagQuestions,
      redFlagAnswers: e.redFlagAnswers,
      functionalQuestions: model.functionalQuestions,
      functionalAnswers: e.functionalAnswers,
      transcript: e.transcript,
    );

    return StepPage(children: [
      PageTitle(t.reviewTitle),
      BodyText(t.reviewLead),
      const SizedBox(height: 8),

      _heading(context, t.reviewSafetyHeading),
      for (final (i, q) in model.redFlagQuestions.indexed)
        _item(
          context,
          question: q.text(lang),
          answer: _redFlagLabel(context, e.redFlagAnswers[q.id]),
          missing: isUnanswered(
              e.redFlagAnswers[q.id] ?? AnswerState.notAsked),
          onEdit: () => model.editRedFlag(i),
        ),

      _heading(context, t.reviewWhoHeading),
      _item(
        context,
        question: null,
        answer: e.completedBy == null
            ? t.notAnswered
            : e.completedBy == 'self'
                ? t.whoSelf
                : t.whoCarer,
        missing: e.completedBy == null,
        onEdit: model.editWho,
      ),

      _heading(context, t.reviewDescriptionHeading),
      _item(
        context,
        question: e.audio != null ? t.voiceIncluded : null,
        answer: description.isEmpty ? t.notAnswered : description,
        missing: description.isEmpty,
        body: description.isNotEmpty,
        onEdit: model.editVoice,
      ),
      if (description.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GhostButton(
            label: t.tidyAction,
            color: PatientColors.machine,
            onTap: () => _openTidySheet(context, description),
          ),
        ),

      _heading(context, t.reviewFunctionalHeading),
      for (final (i, q) in model.functionalQuestions.indexed)
        _item(
          context,
          question: q.text(lang),
          answer: _functionalLabel(context, e.functionalAnswers[q.id]),
          missing: e.functionalAnswers[q.id] == null ||
              e.functionalAnswers[q.id] == FunctionalValue.unknown,
          onEdit: () => model.editFunctional(i),
        ),

      // Deterministic, neutral gap list (§2.8, F-008). Plain order, no
      // ranking, no importance words.
      if (!gaps.isEmpty) ...[
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PatientColors.surface,
            border: Border.all(color: PatientColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(PatientDimens.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final id in gaps.unansweredRedFlags)
                _gapLine(
                    context,
                    t.notMentioned(model.redFlagQuestions
                        .firstWhere((q) => q.id == id)
                        .text(lang))),
              for (final id in gaps.unansweredFunctional)
                _gapLine(
                    context,
                    t.notMentioned(model.functionalQuestions
                        .firstWhere((q) => q.id == id)
                        .text(lang))),
              if (gaps.descriptionMissing)
                _gapLine(
                    context, t.notMentioned(t.notMentionedDescription)),
            ],
          ),
        ),
      ],

      const SizedBox(height: 18),
      PrimaryButton(label: t.sendToTeam, onTap: model.requestSend),
    ]);
  }

  Widget _heading(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(text,
            style: sans(context, 21, weight: FontWeight.w600)),
      );

  Widget _gapLine(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(text,
            style:
                sans(context, 17, color: PatientColors.inkDim, height: 1.4)),
      );

  Widget _item(
    BuildContext context, {
    required String? question,
    required String answer,
    required bool missing,
    required VoidCallback onEdit,
    bool body = false,
  }) {
    final t = l10n(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PatientColors.surface,
          border: Border.all(color: PatientColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(PatientDimens.radius),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (question != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(question,
                        style: sans(context, 17,
                            color: PatientColors.inkDim, height: 1.35)),
                  ),
                Text(
                  answer,
                  style: sans(
                    context,
                    19,
                    weight: body ? FontWeight.w500 : FontWeight.w700,
                    height: 1.4,
                    color:
                        missing ? PatientColors.inkDim : PatientColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: t.edit,
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(PatientDimens.radius),
              child: Container(
                constraints: const BoxConstraints(
                    minHeight: PatientDimens.touch,
                    minWidth: PatientDimens.touch),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: PatientColors.action, width: 2),
                  borderRadius: BorderRadius.circular(PatientDimens.radius),
                ),
                child: Text(t.edit,
                    style: sans(context, 18,
                        weight: FontWeight.w700,
                        color: PatientColors.action)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _openTidySheet(BuildContext context, String description) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PatientColors.pageBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => TidySheet(original: description),
    );
  }
}

/// The AI sheet: tidy / translate the patient's own words. Machine output is
/// periwinkle until accepted. Deterministic fallback offline. No triage, no
/// advice, no reassurance can come out of this sheet — the service's prompt
/// forbids it and its output is validated as the patient's own words.
class TidySheet extends StatefulWidget {
  final String original;
  const TidySheet({super.key, required this.original});

  @override
  State<TidySheet> createState() => _TidySheetState();
}

class _TidySheetState extends State<TidySheet> {
  String? _result;
  bool _fromModel = false;
  bool _working = true;
  bool _unavailable = false;

  @override
  void initState() {
    super.initState();
    _tidy();
  }

  Future<void> _tidy() async {
    setState(() {
      _working = true;
      _unavailable = false;
    });
    final r = await PatientAiService.instance.tidyDescription(widget.original);
    if (!mounted) return;
    setState(() {
      _result = r.text;
      _fromModel = r.fromModel;
      _working = false;
    });
  }

  Future<void> _translate({required bool toArabic}) async {
    setState(() {
      _working = true;
      _unavailable = false;
    });
    final r = await PatientAiService.instance
        .translateDescription(widget.original, toArabic: toArabic);
    if (!mounted) return;
    setState(() {
      _working = false;
      if (r == null) {
        _unavailable = true;
      } else {
        _result = r;
        _fromModel = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.tidySheetTitle,
                style: sans(context, 24, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(t.tidySheetNote,
                style: sans(context, 17,
                    color: PatientColors.inkDim, height: 1.4)),
            const SizedBox(height: 14),
            if (_working)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(children: [
                    const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: PatientColors.machine)),
                    const SizedBox(height: 10),
                    Text(t.tidyWorking,
                        style: sans(context, 17,
                            color: PatientColors.inkDim)),
                  ]),
                ),
              )
            else if (_unavailable)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(t.aiUnavailable,
                    style: sans(context, 18, height: 1.4)),
              )
            else ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 260),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PatientColors.machineBg,
                  border:
                      Border.all(color: PatientColors.machine, width: 1.5),
                  borderRadius:
                      BorderRadius.circular(PatientDimens.radius),
                ),
                child: SingleChildScrollView(
                  child: Text(_result ?? '',
                      style: sans(context, 19,
                          color: PatientColors.machine, height: 1.5)),
                ),
              ),
              if (!_fromModel) ...[
                const SizedBox(height: 8),
                Text(t.tidyOfflineNote,
                    style:
                        sans(context, 15, color: PatientColors.inkFaint)),
              ],
            ],
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: GhostButton(
                  label: t.translateToArabic,
                  color: PatientColors.machine,
                  onTap: _working ? null : () => _translate(toArabic: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GhostButton(
                  label: t.translateToEnglish,
                  color: PatientColors.machine,
                  onTap: _working ? null : () => _translate(toArabic: false),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            PrimaryButton(
              label: t.tidyUse,
              onTap: (_working || _unavailable || _result == null)
                  ? null
                  : () {
                      EpisodeModel.instance.acceptDescription(_result!);
                      Navigator.of(context).pop();
                    },
            ),
            const SizedBox(height: 10),
            GhostButton(
              label: t.tidyKeep,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
