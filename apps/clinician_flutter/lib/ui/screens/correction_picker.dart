/// Screen 6 — Correction picker. Recognition, never recall (§4.4): a
/// searchable formulary bottom sheet with sound-alike clusters displayed
/// together at the top, plus an audio replay button. The chosen name is
/// returned to the caller, which confirms THAT single chip with the
/// correction — no free-text spelling exists anywhere.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/formulary.dart';
import '../../domain/handover.dart';
import '../../services/playback.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

Future<String?> showCorrectionPicker(
  BuildContext context, {
  required ConfirmableChip chip,
  required List<FormularyEntry> formulary,
  required PlaybackService playback,
  AudioRecordingData? audio,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.afia.raised,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (_) => _CorrectionSheet(
        chip: chip, formulary: formulary, playback: playback, audio: audio),
  );
}

class _CorrectionSheet extends StatefulWidget {
  final ConfirmableChip chip;
  final List<FormularyEntry> formulary;
  final PlaybackService playback;
  final AudioRecordingData? audio;
  const _CorrectionSheet({
    required this.chip,
    required this.formulary,
    required this.playback,
    this.audio,
  });

  @override
  State<_CorrectionSheet> createState() => _CorrectionSheetState();
}

class _CorrectionSheetState extends State<_CorrectionSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    // Empty query searches on what was heard — the near-misses surface first.
    final clusters = searchFormulary(
        _query.isEmpty ? widget.chip.text : _query, widget.formulary);
    final soundAlike = clusters.where((cl) => cl.length > 1).toList();
    final singles = clusters.where((cl) => cl.length == 1).toList();
    final allSingles =
        _query.isEmpty && singles.isEmpty ? searchFormulary('', widget.formulary).where((cl) => cl.length == 1).toList() : singles;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: c.border, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.correctDrugName,
                        style: sans(context, 20,
                            weight: FontWeight.w500, color: c.text)),
                    const SizedBox(height: 3),
                    Text(t.heardAs(widget.chip.text),
                        style: sans(context, 13, color: c.textFaint)),
                  ]),
            ),
            if (widget.audio != null)
              InkWell(
                onTap: () => widget.playback.play(widget.audio!),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(LucideIcons.fileAudio, size: 20, color: c.text),
                ),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
          child: Container(
            height: 56,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(LucideIcons.search, size: 18, color: c.textFaint),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  autofocus: false,
                  style: sans(context, 15, color: c.text),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: t.searchDrugName,
                    hintStyle: sans(context, 15, color: c.textFaint),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(t.recognitionNotRecall,
                style: sans(context, 11, color: c.textFaint)),
          ),
        ),
        Expanded(
          child: ListView(controller: scroll, padding: EdgeInsets.zero, children: [
            if (soundAlike.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 6),
                child: Row(children: [
                  Icon(LucideIcons.alertCircle, size: 13, color: c.warn),
                  const SizedBox(width: 7),
                  Text(t.soundsAlikeCheck.toUpperCase(),
                      style: sectionLabel(context, color: c.warn)),
                ]),
              ),
              for (final cluster in soundAlike)
                for (final entry in cluster)
                  _entryRow(entry,
                      highlight: entry.name.toLowerCase() ==
                          (widget.chip.match?.entryName ?? '').toLowerCase()),
              Container(height: 1, color: c.hairline),
            ],
            SectionHeader(t.wardFormulary, height: 34),
            for (final cluster in allSingles)
              for (final entry in cluster) _entryRow(entry),
            const SizedBox(height: 24),
          ]),
        ),
      ]),
    );
  }

  Widget _entryRow(FormularyEntry entry, {bool highlight = false}) {
    final c = context.afia;
    final t = l10n(context);
    return InkWell(
      onTap: () => Navigator.of(context).pop(entry.name),
      child: Container(
        height: 56,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: highlight ? c.chipBg : null,
          border: Border(top: BorderSide(color: c.hairline)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    textDirection: TextDirection.ltr,
                    style: sans(context, 15, color: c.text)),
                if (highlight)
                  Text(t.currentEntry,
                      style: sans(context, 13, color: c.textFaint)),
              ],
            ),
          ),
          Icon(LucideIcons.check,
              size: 18, color: highlight ? c.machine : c.textFaint),
        ]),
      ),
    );
  }
}
