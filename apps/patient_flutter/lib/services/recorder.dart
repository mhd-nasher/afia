/// The raw voice recording is captured (record package → AAC m4a), stored as
/// a base64 data URI inside the case update, and delivered playable to the
/// nursing team (§2.6). Same <900KB Firestore-document convention as the
/// clinician app: oversized audio stays on-device with url '' and
/// urlOmittedReason set.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../domain/patient_case.dart';

/// Firestore rejects documents over ~1MB; keep headroom for the transcript
/// and answers.
const int maxSyncedAudioBytes = 700000;

class RecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;
  DateTime? _startedAt;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<bool> start(String tag) async {
    if (!await _recorder.hasPermission()) return false;
    final dir = await getApplicationDocumentsDirectory();
    _path = '${dir.path}/afia_patient_$tag.m4a';
    _startedAt = DateTime.now();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 32000, // modest — voice, short recordings
        sampleRate: 22050,
        numChannels: 1,
      ),
      path: _path!,
    );
    return true;
  }

  Future<bool> get isRecording => _recorder.isRecording();

  /// Stops and packages the capture. Returns null when nothing was recorded.
  Future<AudioRecordingData?> stop(String tag) async {
    final path = await _recorder.stop() ?? _path;
    if (path == null) return null;
    final file = File(path);
    if (!file.existsSync()) return null;

    final bytes = await file.readAsBytes();
    final durationSec = _startedAt == null
        ? 0.0
        : DateTime.now().difference(_startedAt!).inMilliseconds / 1000.0;

    if (bytes.length > maxSyncedAudioBytes) {
      return AudioRecordingData(
        id: 'audio_$tag',
        url: '',
        mimeType: 'audio/mp4',
        durationSec: durationSec,
        recordedAt: DateTime.now().millisecondsSinceEpoch,
        urlOmittedReason:
            'Recording exceeds the Firestore document limit — kept on the recording device. Enable Firebase Storage (Blaze plan) to sync audio.',
      );
    }

    return AudioRecordingData(
      id: 'audio_$tag',
      url: 'data:audio/mp4;base64,${base64Encode(bytes)}',
      mimeType: 'audio/mp4',
      durationSec: durationSec,
      recordedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> dispose() => _recorder.dispose();
}
