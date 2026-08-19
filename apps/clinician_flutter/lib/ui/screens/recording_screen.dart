/// Screen 3 — Recording. Near-empty by design: a big mono timer, live
/// partial transcription, template chips, one control. Auto-checkpoints to
/// Firestore every ~4 s so putting the phone down is safe; reopening the app
/// returns directly to this interrupted draft (§5).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/entities.dart';
import '../../domain/handover.dart';
import '../../services/repo.dart';
import '../../services/recorder.dart';
import '../../services/structurer_service.dart';
import '../../services/transcriber.dart';
import '../../state/app_model.dart';
import '../../state/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'draft_review_screen.dart';

class RecordingScreen extends StatefulWidget {
  final Patient patient;
  final Handover? resume;
  const RecordingScreen({super.key, required this.patient, this.resume});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final TranscriberService _transcriber = TranscriberService();
  final RecorderService _recorder = RecorderService();

  Handover? _handover;
  Timer? _ticker;
  Timer? _checkpoint;
  int _elapsedSec = 0;
  bool _paused = false;
  bool _stopping = false;
  bool _speechAvailable = true;
  String _lastCheckpointed = '';

  AppModel get model => AppModel.instance!;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // Create or resume the handover document first — the checkpoint target.
    var h = widget.resume;
    if (h == null) {
      h = await Repo.instance.createHandover(widget.patient.id, model.me.id);
    } else if (widget.resume!.status == HandoverStatus.recording) {
      _transcriber.resumeFrom(widget.resume!.transcript);
      _elapsedSec = 0;
    }
    if (!mounted) return;
    setState(() => _handover = h);

    _speechAvailable = await _transcriber.initialize();
    if (_speechAvailable && mounted) {
      final locale = AppSettings.instance.locale?.languageCode == 'ar'
          ? 'ar_SA'
          : 'en_GB';
      await _transcriber.start(
        localeId: locale,
        onUpdate: () {
          if (mounted) setState(() {});
        },
      );
    }
    await _recorder.start(h.id);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused && mounted) setState(() => _elapsedSec += 1);
    });
    // §5 — auto-checkpoint every ~4 s. Firestore's offline cache makes this
    // durable with or without a network.
    _checkpoint =
        Timer.periodic(const Duration(seconds: 4), (_) => _doCheckpoint());
  }

  Future<void> _doCheckpoint() async {
    final h = _handover;
    if (h == null || _stopping) return;
    final transcript = _transcriber.mergedTranscript;
    if (transcript == _lastCheckpointed) return;
    _lastCheckpointed = transcript;
    try {
      final updated = await Repo.instance.checkpointDraft(
        h,
        transcript: transcript,
        formulary: model.formulary,
        template: model.template,
      );
      _handover = updated;
    } catch (_) {
      // Offline writes queue locally; nothing is lost.
    }
  }

  Future<void> _togglePause() async {
    if (_paused) {
      await _recorder.resume();
      if (_speechAvailable) {
        final locale = AppSettings.instance.locale?.languageCode == 'ar'
            ? 'ar_SA'
            : 'en_GB';
        await _transcriber.start(
            localeId: locale,
            onUpdate: () {
              if (mounted) setState(() {});
            });
      }
    } else {
      await _transcriber.stop();
      await _recorder.pause();
    }
    if (mounted) setState(() => _paused = !_paused);
  }

  Future<void> _stopAndStructure() async {
    if (_stopping || _handover == null) return;
    setState(() => _stopping = true);
    _ticker?.cancel();
    _checkpoint?.cancel();

    await _transcriber.stop();
    final audio = await _recorder.stop(_handover!.id);
    final transcript = _transcriber.mergedTranscript;

    // §4.2 — structure into template fields (Gemini, deterministic fallback).
    final result = await StructuringService.instance
        .structure(transcript, model.template);

    try {
      var updated = await Repo.instance.checkpointDraft(
        _handover!,
        transcript: transcript,
        fields: result.fields,
        audio: audio,
        formulary: model.formulary,
        template: model.template,
      );
      await Repo.instance.appendAudit(
          actor: model.me.id,
          action: 'transcribed',
          entityId: updated.id,
          detail: 'device speech recognition');
      await Repo.instance.appendAudit(
          actor: model.me.id,
          action: 'structured',
          entityId: updated.id,
          detail: 'engine: ${result.engine}');
      for (final f in updated.flags) {
        await Repo.instance.appendAudit(
            actor: model.me.id,
            action: 'flagged',
            entityId: updated.id,
            detail: f.message);
      }
      updated = await Repo.instance
          .setStatus(updated, HandoverStatus.draftReady, model.me.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => DraftReviewScreen(handoverId: updated.id)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _stopping = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n(context).errorGeneric)));
    }
  }

  Future<void> _typeInstead() async {
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
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 5,
              minLines: 3,
              style: sans(sheetContext, 15, color: sheetContext.afia.text),
              decoration: InputDecoration(
                hintText: t.typeHandoverHint,
                hintStyle:
                    sans(sheetContext, 15, color: sheetContext.afia.textFaint),
                border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: sheetContext.afia.border)),
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
    if (text != null && text.isNotEmpty) {
      _transcriber.appendTyped(text);
      await _doCheckpoint();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _checkpoint?.cancel();
    _transcriber.stop();
    _recorder.dispose();
    super.dispose();
  }

  String get _timer {
    final m = (_elapsedSec ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    final t = l10n(context);
    final offline = model.syncStatus.fromCache;
    final segments = _transcriber.finalSegments;
    final settledTail = segments.isEmpty ? '' : segments.last;
    final partial = _transcriber.partial;

    // Which template fields already have matching content (chips row).
    final transcript = _transcriber.mergedTranscript.toLowerCase();
    final covered = <String>{
      for (final f in model.template)
        if (f.keywords.any((k) => transcript.contains(k.toLowerCase()))) f.id,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Context band: bed + patient + offline state.
          Container(
            height: 56,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: c.raised,
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(children: [
              Icon(LucideIcons.lock, size: 16, color: c.textDim),
              const SizedBox(width: 10),
              Text(t.bed(widget.patient.bed),
                  style: mono(context, 16,
                      weight: FontWeight.w500, color: c.text)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.patient.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sans(context, 15, color: c.text)),
              ),
              if (offline)
                Container(
                  height: 28,
                  padding:
                      const EdgeInsetsDirectional.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Icon(LucideIcons.wifiOff, size: 12, color: c.textDim),
                    const SizedBox(width: 5),
                    Text(t.offlineSavedOnDevice,
                        style: sans(context, 11, color: c.textDim)),
                  ]),
                ),
            ]),
          ),
          // The near-empty center: timer + state + live words.
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_timer,
                      textDirection: TextDirection.ltr,
                      style: mono(context, 44,
                          weight: FontWeight.w500, color: c.text)),
                  const SizedBox(height: 10),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        _paused
                            ? LucideIcons.pauseCircle
                            : LucideIcons.circleDot,
                        size: 14,
                        color: _paused ? c.textDim : c.machine),
                    const SizedBox(width: 7),
                    Text(_paused ? t.paused : t.recordingLabel,
                        style: sans(context, 13,
                            color: _paused ? c.textDim : c.machine)),
                  ]),
                  const SizedBox(height: 30),
                  _Waveform(active: !_paused && !_stopping),
                  const SizedBox(height: 30),
                  if (!_speechAvailable)
                    Text(t.micDenied,
                        textAlign: TextAlign.center,
                        style: sans(context, 13, color: c.warn, height: 1.5))
                  else ...[
                    Text(settledTail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: sans(context, 14,
                            color: c.textFaint, height: 1.55)),
                    const SizedBox(height: 8),
                    Text(partial,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style:
                            sans(context, 14, color: c.text, height: 1.55)),
                  ],
                ],
              ),
            ),
          ),
          // Template coverage chips.
          if (model.template.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: 16, end: 16, bottom: 16),
              child: SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final f in model.template)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Container(
                          height: 34,
                          padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 13),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: covered.contains(f.id)
                                    ? c.machine
                                    : c.border),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(children: [
                            if (covered.contains(f.id)) ...[
                              Icon(LucideIcons.check,
                                  size: 13, color: c.machine),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              fieldLabel(context, f.id, f.label),
                              style: sans(context, 13,
                                  color: covered.contains(f.id)
                                      ? c.machine
                                      : c.textFaint),
                            ),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          // Stop control.
          Container(
            padding: const EdgeInsetsDirectional.only(top: 24, bottom: 20),
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.hairline))),
            child: Column(children: [
              GestureDetector(
                onTap: _stopping ? null : _stopAndStructure,
                onLongPress: _stopping ? null : _togglePause,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.machine, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: _stopping
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: c.machine))
                      : Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: c.machine,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Text(_stopping ? t.structuring : t.tapToStopHoldToPause,
                  style: sans(context, 13, color: c.textDim)),
              const SizedBox(height: 4),
              SizedBox(
                height: 44,
                child: TextButton.icon(
                  onPressed: _stopping ? null : _typeInstead,
                  icon: Icon(LucideIcons.keyboard,
                      size: 16, color: c.textFaint),
                  label: Text(t.typeInstead,
                      style: sans(context, 14, color: c.textFaint)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Decorative live waveform — bars pulse while recording.
class _Waveform extends StatefulWidget {
  final bool active;
  const _Waveform({required this.active});

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  static const List<double> _heights = [
    10, 22, 40, 16, 52, 28, 60, 36, 14, 46, 24, 56, 32, 18, 42, 54, 26, 12, 38, 48, 20, 30
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.afia;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < _heights.length; i++)
              Container(
                width: 3,
                height: widget.active
                    ? _heights[i] *
                        (0.55 +
                            0.45 *
                                (0.5 +
                                    0.5 *
                                        (1 +
                                                (i.isEven ? 1 : -1) *
                                                    (2 * _controller.value -
                                                        1)) /
                                            2))
                    : _heights[i] * 0.35,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: widget.active ? c.machine : c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        );
      },
    );
  }
}
