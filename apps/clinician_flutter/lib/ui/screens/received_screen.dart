/// Screen 9 — Received handover. Built for a ten-second read: summary first,
/// flags INLINE (never behind an expand), PLAYABLE original audio (§2.6),
/// and the diff against the previous handover, stated neutrally.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/handover.dart';
import '../../domain/structuring.dart';
import '../../services/playback.dart';
import '../../state/app_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'fhir_screen.dart';

class ReceivedScreen extends StatefulWidget {
  final String handoverId;
  const ReceivedScreen({super.key, required this.handoverId});

  @override
  State<ReceivedScreen> createState() => _ReceivedScreenState();
}

class _ReceivedScreenState extends State<ReceivedScreen> {
  final PlaybackService _playback = PlaybackService();
  bool _playing = false;
  bool _acknowledged = false;

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

  Future<void> _togglePlay() async {
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
          SnackBar(content: Text(l10n(context).audioUnavailable)));
      return;
    }
    setState(() => _playing = true);
    _playback.stateStream.listen((s) {
      if (mounted && s.name != 'playing') setState(() => _playing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final c = context.afia;
        final t = l10n(context);
        final h = _handover;
        if (h == null) return Scaffold(body: Center(child: Text(t.loading)));
        final patient = model.patientById(h.patientId);
        final summary = tenSecondSummary(h.fields, model.template);
        final previous = model.previousFor(h);
        final diff = previous == null
            ? const <FieldDiff>[]
            : diffHandovers(previous.fields, h.fields, model.template)
                .where((d) => d.kind != DiffKind.unchanged)
                .toList();

        return Scaffold(
          body: SafeArea(
            child: Column(children: [
              ScreenHeader(
                title: Row(children: [
                  Text(patient?.bed ?? '',
                      textDirection: TextDirection.ltr,
                      style: mono(context, 16,
                          weight: FontWeight.w500, color: c.textDim)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(patient?.shortName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sans(context, 20,
                            weight: FontWeight.w500, color: c.text)),
                  ),
                ]),
              ),
              // Signed band — who verified this, when.
              Container(
                height: 40,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: c.raised,
                  border: Border(bottom: BorderSide(color: c.hairline)),
                ),
                child: Row(children: [
                  Icon(LucideIcons.edit3, size: 14, color: c.signedAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      h.signature == null
                          ? t.draftBand
                          : t.signedBand(h.signature!.signatureIdentity,
                              hhmm(h.signature!.signedAt)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mono(context, 10, color: c.signedAccent),
                    ),
                  ),
                  Text(t.verified,
                      style: sans(context, 11, color: c.textFaint)),
                ]),
              ),
              Expanded(
                child: ListView(padding: EdgeInsets.zero, children: [
                  // Ten-second summary — first thing on screen.
                  if (summary.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                          border:
                              Border(bottom: BorderSide(color: c.hairline))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.tenSecondSummary.toUpperCase(),
                                style: sectionLabel(context)),
                            const SizedBox(height: 6),
                            Text(summary,
                                style: sans(context, 14,
                                    color: c.text, height: 1.5)),
                          ]),
                    ),
                  // Play the original voice — §2.6, the main advantage.
                  InkWell(
                    onTap: _togglePlay,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 16),
                      decoration: BoxDecoration(
                          border:
                              Border(bottom: BorderSide(color: c.hairline))),
                      child: Row(children: [
                        Icon(
                            _playing
                                ? LucideIcons.square
                                : LucideIcons.play,
                            size: 18,
                            color: c.machine),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              _playing ? t.stopPlayback : t.playOriginal,
                              style:
                                  sans(context, 14, color: c.machine)),
                        ),
                        if (h.audio != null)
                          Text(
                              '${h.audio!.durationSec.toStringAsFixed(0)}s',
                              style: mono(context, 14, color: c.textFaint)),
                      ]),
                    ),
                  ),
                  if (h.audio != null && h.audio!.url.isEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          16, 8, 16, 0),
                      child: Text(t.audioUnavailable,
                          style: sans(context, 11,
                              color: c.textFaint, height: 1.4)),
                    ),
                  // Fields — compact rows, first letter as the key.
                  for (final field in model.template)
                    if (_fieldText(h, field.id).isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(minHeight: 52),
                        padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: c.hairline))),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 22,
                                child: Text(
                                    fieldLabel(context, field.id, field.label)
                                        .characters
                                        .first
                                        .toUpperCase(),
                                    style: sans(context, 11,
                                        color: c.textFaint)),
                              ),
                              Expanded(
                                child: Text(_fieldText(h, field.id),
                                    style: sans(context, 14,
                                        color: c.text, height: 1.4)),
                              ),
                            ]),
                      ),
                  // Open flags — INLINE, never behind an expand (§ screen 9).
                  if (h.flags.isNotEmpty) ...[
                    SectionHeader(t.openFlagsSection, height: 30),
                    for (final flag in h.flags)
                      Container(
                        constraints: const BoxConstraints(minHeight: 52),
                        padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(color: c.hairline))),
                        child: Row(children: [
                          Icon(LucideIcons.helpCircle,
                              size: 17, color: c.textDim),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                                t.notMentioned(fieldLabel(
                                    context, flag.fieldId, flag.label)),
                                style:
                                    sans(context, 14, color: c.textDim)),
                          ),
                          if (flag.signingNote != null)
                            Flexible(
                              child: Text(flag.signingNote!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: sans(context, 11,
                                      color: c.textFaint)),
                            ),
                        ]),
                      ),
                    Container(height: 1, color: c.hairline),
                  ],
                  // Diff vs previous — what changed, neutrally (§4.2).
                  if (diff.isNotEmpty) ...[
                    SectionHeader(t.whatChanged, height: 30),
                    for (final d in diff)
                      Container(
                        constraints: const BoxConstraints(minHeight: 52),
                        padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(color: c.hairline))),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 84,
                                child: Text(
                                  switch (d.kind) {
                                    DiffKind.added => t.diffAdded,
                                    DiffKind.changed => t.diffChanged,
                                    DiffKind.nowEmpty => t.diffNowEmpty,
                                    DiffKind.unchanged => '',
                                  },
                                  style: sans(context, 11,
                                      color: c.machine),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          fieldLabel(
                                              context, d.fieldId, d.label),
                                          style: sans(context, 11,
                                              color: c.textFaint)),
                                      if (d.text.isNotEmpty)
                                        Text(d.text,
                                            style: sans(context, 13,
                                                color: c.text,
                                                height: 1.4)),
                                    ]),
                              ),
                            ]),
                      ),
                    Container(height: 1, color: c.hairline),
                  ],
                  // FHIR-ready record.
                  InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => FhirScreen(handoverId: h.id))),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 16),
                      child: Row(children: [
                        Icon(LucideIcons.fileJson,
                            size: 17, color: c.textDim),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(t.fhirReady,
                                style:
                                    sans(context, 14, color: c.text))),
                        Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? LucideIcons.chevronLeft
                                : LucideIcons.chevronRight,
                            size: 18,
                            color: c.textFaint),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 18),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.border))),
                child: PrimaryButton(
                  onTap: _acknowledged
                      ? null
                      : () => setState(() => _acknowledged = true),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(LucideIcons.check, size: 20),
                    const SizedBox(width: 10),
                    Text(_acknowledged ? t.acknowledged : t.acknowledgeRead),
                  ]),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  String _fieldText(Handover h, String fieldId) {
    for (final f in h.fields) {
      if (f.fieldId == fieldId) return f.text.trim();
    }
    return '';
  }
}
