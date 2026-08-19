/// §2.6 — the raw audio is captured (record package → AAC m4a), stored as a
/// base64 data URI inside the handover document, and delivered playable to
/// the receiving clinician. Bitrate is kept modest: handovers are short and
/// the whole Firestore document must stay under ~900KB — otherwise the audio
/// stays on this device and audio.url is '' with urlOmittedReason (same
/// convention as packages/core/src/firebase.ts fitForSync).
library;

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../domain/handover.dart';

/// Firestore rejects documents over ~1MB; keep headroom for the transcript,
/// fields, chips and flags.
const int maxSyncedAudioBytes = 700_000;

class RecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;
  DateTime? _startedAt;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<bool> start(String handoverId) async {
    if (!await _recorder.hasPermission()) return false;
    final dir = await getApplicationDocumentsDirectory();
    // Timestamped per session so resuming an interrupted recording never
    // truncates an earlier segment (earlier segments stay on disk).
    _path =
        '${dir.path}/afia_${handoverId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _startedAt = DateTime.now();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 32000, // modest — voice, short recordings (§ audio budget)
        sampleRate: 22050,
        numChannels: 1,
      ),
      path: _path!,
    );
    return true;
  }

  Future<bool> get isRecording => _recorder.isRecording();
  Future<void> pause() => _recorder.pause();
  Future<void> resume() => _recorder.resume();

  /// Stops and packages the capture. Returns null when nothing was recorded.
  Future<AudioRecordingData?> stop(String handoverId) async {
    final path = await _recorder.stop() ?? _path;
    if (path == null) return null;
    final file = File(path);
    if (!file.existsSync()) return null;

    final bytes = await file.readAsBytes();
    final durationSec = _startedAt == null
        ? 0.0
        : DateTime.now().difference(_startedAt!).inMilliseconds / 1000.0;

    if (bytes.length > maxSyncedAudioBytes) {
      // Keep it local; the synced document says so honestly.
      return AudioRecordingData(
        id: 'audio_$handoverId',
        url: '',
        mimeType: 'audio/mp4',
        durationSec: durationSec,
        recordedAt: DateTime.now().millisecondsSinceEpoch,
        urlOmittedReason:
            'Recording exceeds the Firestore document limit — kept on the recording device. Enable Firebase Storage (Blaze plan) to sync audio.',
      );
    }

    return AudioRecordingData(
      id: 'audio_$handoverId',
      url: 'data:audio/mp4;base64,${base64Encode(bytes)}',
      mimeType: 'audio/mp4',
      durationSec: durationSec,
      recordedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> dispose() => _recorder.dispose();
}
