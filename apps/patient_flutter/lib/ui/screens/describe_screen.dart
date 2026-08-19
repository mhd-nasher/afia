/// Voice description (and the "what has changed" delta capture — the same
/// screen, different words). Big Record/Stop, live speech-to-text
/// (ar_SA / en_GB), the raw audio kept playable (§2.6), and ALWAYS a large
/// "type instead" field — recording is optional, typing is enough. Every
/// keystroke and speech segment persists immediately (F-055).
///
/// A first tap on Record shows the mic primer once — a plain-words
/// explanation BEFORE the OS permission dialog.
library;

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/patient_case.dart';
import '../../services/prefs.dart';
import '../../services/recorder.dart';
import '../../services/transcriber.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

class DescribeScreen extends StatefulWidget {
  final String eyebrowText;
  final String title;
  final String lead;
  final String transcript;
  final AudioRecordingData? audio;
  final String continueLabel;
  final ValueChanged<String> onTranscript;
  final ValueChanged<AudioRecordingData> onAudio;
  final VoidCallback onContinue;

  const DescribeScreen({
    super.key,
    required this.eyebrowText,
    required this.title,
    required this.lead,
    required this.transcript,
    required this.audio,
    required this.continueLabel,
    required this.onTranscript,
    required this.onAudio,
    required this.onContinue,
  });

  @override
  State<DescribeScreen> createState() => _DescribeScreenState();
}

class _DescribeScreenState extends State<DescribeScreen> {
  final RecorderService _recorder = RecorderService();
  final TranscriberService _transcriber = TranscriberService();
  final ap.AudioPlayer _player = ap.AudioPlayer();

  late final TextEditingController _text =
      TextEditingController(text: widget.transcript);
  bool _recording = false;
  bool _playing = false;
  bool _showPrimer = false;
  String? _note;
  String _baseTranscript = '';

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _transcriber.stop();
    _recorder.dispose();
    _player.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _onRecordTap() async {
    if (_recording) {
      await _stopCapture();
      return;
    }
    if (!Prefs.instance.micPrimerSeen) {
      setState(() => _showPrimer = true);
      return;
    }
    await _startCapture();
  }

  Future<void> _startCapture() async {
    setState(() => _note = null);
    _baseTranscript = _text.text.trim();
    final lang = Localizations.localeOf(context).languageCode;
    final localeId = lang == 'ar' ? 'ar_SA' : 'en_GB';

    final speechOk = await _transcriber.initialize(
        onError: (_) {});
    if (speechOk) {
      _transcriber.reset();
      await _transcriber.start(
        localeId: localeId,
        onUpdate: () {
          if (!mounted) return;
          final merged = [
            if (_baseTranscript.isNotEmpty) _baseTranscript,
            _transcriber.mergedTranscript,
          ].where((s) => s.trim().isNotEmpty).join(' ');
          _text.text = merged;
          widget.onTranscript(merged); // persists immediately (F-055)
          setState(() {});
        },
      );
    } else {
      if (mounted) setState(() => _note = l10n(context).speechUnavailable);
    }

    final started =
        await _recorder.start(DateTime.now().millisecondsSinceEpoch.toString());
    if (!started && !speechOk) {
      // Neither speech nor audio — typing carries the flow.
      return;
    }
    if (mounted) setState(() => _recording = true);
  }

  Future<void> _stopCapture() async {
    await _transcriber.stop();
    final audio = await _recorder.stop('capture');
    if (audio != null) widget.onAudio(audio);
    final merged = [
      if (_baseTranscript.isNotEmpty) _baseTranscript,
      _transcriber.mergedTranscript,
    ].where((s) => s.trim().isNotEmpty).join(' ');
    if (merged.trim().isNotEmpty) {
      _text.text = merged;
      widget.onTranscript(merged);
    }
    if (mounted) setState(() => _recording = false);
  }

  Future<void> _togglePlayback() async {
    final audio = widget.audio;
    if (audio == null || audio.url.isEmpty) return;
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    final comma = audio.url.indexOf(',');
    if (comma < 0) return;
    final bytes = Uri.parse(audio.url).data?.contentAsBytes();
    if (bytes == null) return;
    await _player.play(ap.BytesSource(bytes));
    setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    if (_showPrimer) return _primer(t);

    final hasAudio = widget.audio != null && widget.audio!.url.isNotEmpty;
    return StepPage(children: [
      Eyebrow(widget.eyebrowText),
      PageTitle(widget.title),
      BodyText(widget.lead),
      const SizedBox(height: 8),
      // Big Record / Stop — bordered, indigo; red is never spent here.
      Semantics(
        button: true,
        label: _recording ? t.stopRecording : t.startTalking,
        child: InkWell(
          onTap: _onRecordTap,
          borderRadius: BorderRadius.circular(PatientDimens.radius),
          child: Container(
            constraints: const BoxConstraints(minHeight: 80),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _recording
                  ? PatientColors.actionBg
                  : PatientColors.surface,
              border: Border.all(color: PatientColors.action, width: 3),
              borderRadius: BorderRadius.circular(PatientDimens.radius),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_recording ? LucideIcons.square : LucideIcons.mic,
                  size: 26, color: PatientColors.action),
              const SizedBox(width: 12),
              Text(
                _recording
                    ? t.stopRecording
                    : hasAudio
                        ? t.recordAgain
                        : t.startTalking,
                style: sans(context, 22,
                    weight: FontWeight.w700, color: PatientColors.action),
              ),
            ]),
          ),
        ),
      ),
      if (_recording) ...[
        const SizedBox(height: 10),
        BodyText(
          _transcriber.partial.isEmpty
              ? t.listeningHint
              : '${t.listeningHint} “${_transcriber.partial}”',
          color: PatientColors.inkDim,
        ),
      ],
      if (_note != null) ...[
        const SizedBox(height: 10),
        BodyText(_note!, color: PatientColors.inkDim),
      ],
      if (hasAudio && !_recording) ...[
        const SizedBox(height: 10),
        GhostButton(
          label: _playing ? t.stopPlayback : t.playRecording,
          onTap: _togglePlayback,
        ),
      ],
      const SizedBox(height: 18),
      BigField(
        label: t.typeInstead,
        controller: _text,
        minLines: 5,
        keyboardType: TextInputType.multiline,
        onChanged: widget.onTranscript,
      ),
      const SizedBox(height: 8),
      PrimaryButton(label: widget.continueLabel, onTap: widget.onContinue),
    ]);
  }

  Widget _primer(dynamic t) {
    return StepPage(children: [
      PageTitle(t.micPrimerTitle),
      BodyText(t.micPrimerBody),
      const SizedBox(height: 12),
      PrimaryButton(
        label: t.micPrimerOk,
        onTap: () async {
          await Prefs.instance.setMicPrimerSeen();
          setState(() => _showPrimer = false);
          await _startCapture();
        },
      ),
      const SizedBox(height: 10),
      GhostButton(
        label: t.micPrimerSkip,
        onTap: () async {
          await Prefs.instance.setMicPrimerSeen();
          setState(() => _showPrimer = false);
        },
      ),
    ]);
  }
}
