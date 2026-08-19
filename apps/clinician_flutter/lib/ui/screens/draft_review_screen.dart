/// Screen 4 — Draft review. Periwinkle/violet left border = machine-produced
/// and unverified; it becomes the signed accent the moment a nurse signs.
/// Drug & number chips render inline in mono; unverified chips carry the
/// machine colour. Omission flags appear as neutral "Not mentioned: X" rows
/// with an Add action — they never block anything (§2.4).
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/gaps.dart';
import '../../domain/handover.dart';
import '../../services/playback.dart';
import '../../services/repo.dart';
import '../../state/app_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'confirm_screen.dart';
import 'fhir_screen.dart';
import 'sign_sheet.dart';

class DraftReviewScreen extends StatefulWidget {
  final String handoverId;
  const DraftReviewScreen({super.key, required this.handoverId});

  @override
  State<DraftReviewScreen> createState() => _DraftReviewScreenState();
}

class _DraftReviewScreenState extends State<DraftReviewScreen> {
  final PlaybackService _playback = PlaybackService();
  bool _playing = false;

  AppModel get model => AppModel.instance!;

  @override
  void dispose() {
    _playback.dispose();
    super.dispose();
  }

  Handover? get _handover {
    for (final h in model.handovers) {
      if (h.id == widget.handoverId) return h;
    }
    return null;
  }

  Future<void> _replay() async {
    final h = _handover;
    if (h?.audio == null) return;
    if (_playing) {
      await _playback.stop();
      setState(() => _playing = false);
      return;
    }
    final ok = await _playback.play(h!.audio!);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n(context).audioKeptOnDevice)));
      return;
    }
    setState(() => _playing = true);
    _playback.stateStream.listen((s) {
      if (mounted && s.name != 'playing') setState(() => _playing = false);
    });
  }

  Future<void> _addToField(HandoverFlag flag) async {
    final h = _handover;
    if (h == null) return;
    final controller = TextEditingController();
    final t = l10n(context);
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.afia.raised,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                  fieldLabel(sheetContext, flag.fieldId, flag.label)
                      .toUpperCase(),
                  style: sectionLabel(sheetContext)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              style: sans(sheetContext, 15, color: sheetContext.afia.text),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: sheetContext.afia.border)),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              onTap: () =>
                  Navigator.of(sheetContext).pop(controller.text.trim()),
              child: Text(t.addField),
            ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
    if (text == null || text.isEmpty || !mounted) return;

    final existing = h.fields.where((f) => f.fieldId == flag.fieldId);
    final fields = existing.isEmpty
        ? [...h.fields, FieldContent(fieldId: flag.fieldId, text: text)]
        : h.fields
            .map((f) => f.fieldId == flag.fieldId
                ? FieldContent(
                    fieldId: f.fieldId,
                    text: f.text.trim().isEmpty ? text : '${f.text} $text')
                : f)
            .toList();
    await Repo.instance.checkpointDraft(
      h,
      fields: fields,
      formulary: model.formulary,
      template: model.template,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final c = context.afia;
        final t = l10n(context);
        final h = _handover;
        if (h == null) {
          return Scaffold(body: Center(child: Text(t.loading)));
        }
        final patient = model.patientById(h.patientId);
        final unsigned = h.signature == null;
        final accent = unsigned ? c.draft : c.signedAccent;
        final unconfirmed = unconfirmedChips(h);
        final canEdit = h.status == HandoverStatus.draftReady;

        return Scaffold(
          body: SafeArea(
            child: Column(children: [
              ScreenHeader(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(unsigned ? t.draftTitle : t.handoverTitle,
                        style: sans(context, 20,
                            weight: FontWeight.w500, color: c.text)),
                    Text(
                      '${t.bed(patient?.bed ?? '—')} · ${patient?.shortName ?? ''} · ${t.recordedAt(hhmm(h.createdAt))}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sans(context, 11, color: c.textFaint),
                    ),
                  ],
                ),
                trailing: h.audio == null
                    ? null
                    : Pill(
                        label: _playing ? t.stopPlayback : t.replay,
                        icon: LucideIcons.fileAudio,
                        onTap: _replay,
                      ),
              ),
              // Provenance band — machine-produced vs verified by a human.
              Container(
                height: 34,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: c.raised,
                  border: Border(bottom: BorderSide(color: c.hairline)),
                ),
                child: Row(children: [
                  Icon(unsigned ? LucideIcons.fileText : LucideIcons.edit3,
                      size: 14, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      unsigned
                          ? t.draftBand
                          : t.signedBand(h.signature!.signatureIdentity,
                              hhmm(h.signature!.signedAt)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: unsigned
                          ? sans(context, 11, color: accent)
                              .copyWith(letterSpacing: 1)
                          : mono(context, 10, color: accent),
                    ),
                  ),
                  Text(unsigned ? t.producedBySystem : t.verifiedByHuman,
                      style: sans(context, 11, color: c.textFaint)),
                ]),
              ),
              Expanded(
                child: ListView(padding: EdgeInsets.zero, children: [
                  // The machine-provenance body: coloured left border.
                  Container(
                    margin: const EdgeInsetsDirectional.only(top: 16),
                    padding:
                        const EdgeInsetsDirectional.only(start: 13, end: 16),
                    decoration: BoxDecoration(
                      border: BorderDirectional(
                          start: BorderSide(color: accent, width: 3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final field in model.template)
                          if (_fieldText(h, field.id).isNotEmpty) ...[
                            Text(
                                fieldLabel(context, field.id, field.label)
                                    .toUpperCase(),
                                style: sectionLabel(context)),
                            const SizedBox(height: 5),
                            _ChipRichText(
                                text: _fieldText(h, field.id),
                                chips: h.chips,
                                unsigned: unsigned),
                            const SizedBox(height: 16),
                          ],
                        if (h.fields.isEmpty && h.transcript.isNotEmpty) ...[
                          _ChipRichText(
                              text: h.transcript,
                              chips: h.chips,
                              unsigned: unsigned),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  // Omission flags — neutral wording, Add action, never block.
                  if (h.flags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final flag in h.flags)
                      Container(
                        constraints: const BoxConstraints(minHeight: 56),
                        padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(color: c.hairline))),
                        child: Row(children: [
                          Icon(LucideIcons.helpCircle,
                              size: 18, color: c.textDim),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.notMentioned(fieldLabel(
                                      context, flag.fieldId, flag.label)),
                                  style: sans(context, 14,
                                      color: c.textDim, height: 1.3),
                                ),
                                if (flag.signingNote != null)
                                  Text(flag.signingNote!,
                                      style: sans(context, 11,
                                          color: c.textFaint)),
                              ],
                            ),
                          ),
                          if (canEdit)
                            Pill(
                                label: t.addField,
                                color: c.machine,
                                onTap: () => _addToField(flag)),
                        ]),
                      ),
                    Container(height: 1, color: c.hairline),
                  ],
                  const SizedBox(height: 24),
                ]),
              ),
              // Bottom action area.
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 18),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.border))),
                child: canEdit
                    ? Column(children: [
                        if (unconfirmed.isNotEmpty)
                          PrimaryButton(
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => ConfirmScreen(
                                        handoverId: h.id))),
                            child: Text(
                                t.confirmChipsButton(unconfirmed.length)),
                          )
                        else
                          PrimaryButton(
                            onTap: () => showSignSheet(context, h.id),
                            child: Text(t.signButton),
                          ),
                        const SizedBox(height: 10),
                        Text(t.flagsNeverBlock,
                            style: sans(context, 11, color: c.textFaint)),
                      ])
                    : Column(children: [
                        _StatusRow(handover: h),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: Pill(
                              label: t.fhirReady,
                              icon: LucideIcons.fileJson,
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          FhirScreen(handoverId: h.id))),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (h.supersededBy == null)
                            Expanded(
                              child: Pill(
                                label: t.amendHandover,
                                icon: LucideIcons.edit3,
                                onTap: () => _confirmAmend(h),
                              ),
                            ),
                        ]),
                      ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _confirmAmend(Handover h) async {
    final t = l10n(context);
    final c = context.afia;
    final go = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: c.raised,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsetsDirectional.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(t.amendHandover,
              style: sans(sheetContext, 18,
                  weight: FontWeight.w500, color: sheetContext.afia.text)),
          const SizedBox(height: 10),
          Text(t.amendNote,
              textAlign: TextAlign.center,
              style: sans(sheetContext, 13,
                  color: sheetContext.afia.textDim, height: 1.5)),
          const SizedBox(height: 18),
          PrimaryButton(
              onTap: () => Navigator.of(sheetContext).pop(true),
              child: Text(t.amendHandover)),
          const SizedBox(height: 10),
          TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(false),
              child: Text(t.cancel,
                  style: sans(sheetContext, 14,
                      color: sheetContext.afia.textFaint))),
        ]),
      ),
    );
    if (go != true || !mounted) return;
    final result = await Repo.instance.supersedeHandover(h, model.me.id);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => DraftReviewScreen(handoverId: result.draft.id)));
  }

  String _fieldText(Handover h, String fieldId) {
    for (final f in h.fields) {
      if (f.fieldId == fieldId) return f.text.trim();
    }
    return '';
  }
}

/// After signing: queued / confirmed / failed line (signed ≠ confirmed).
class _StatusRow extends StatelessWidget {
  final Handover handover;
  const _StatusRow({required this.handover});

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    return Container(
      height: 56,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
      child: Row(children: [
        Expanded(
            child: StatusLine(
                status: handover.status,
                timeMs: handover.acknowledgedAt ??
                    handover.signature?.signedAt)),
        if (handover.exportError != null)
          Expanded(
            child: Text(handover.exportError!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: sans(context, 11, color: c.textFaint)),
          ),
      ]),
    );
  }
}

/// Field text with drug/number chips inline: mono, machine-coloured while
/// unverified, quiet once the note is signed.
class _ChipRichText extends StatelessWidget {
  final String text;
  final List<ConfirmableChip> chips;
  final bool unsigned;
  const _ChipRichText(
      {required this.text, required this.chips, required this.unsigned});

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final baseStyle = sans(context, 14, color: c.text, height: 1.5);

    // Find chip substrings in this field's text.
    final marks = <(int, int, ConfirmableChip)>[];
    for (final chip in chips) {
      var from = 0;
      while (true) {
        final i = text.indexOf(chip.text, from);
        if (i < 0) break;
        marks.add((i, i + chip.text.length, chip));
        from = i + chip.text.length;
      }
    }
    marks.sort((a, b) => a.$1.compareTo(b.$1));

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final (start, end, chip) in marks) {
      if (start < cursor) continue; // overlapping duplicate
      if (start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, start)));
      }
      final confirmed = chip.confirmed;
      final display = chip.correctedTo ?? text.substring(start, end);
      spans.add(TextSpan(
        text: display,
        style: mono(context, 14,
            weight: FontWeight.w500,
            color: confirmed || !unsigned ? c.text : c.machine),
      ));
      cursor = end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}
