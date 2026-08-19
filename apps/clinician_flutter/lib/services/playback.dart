/// §2.6 — audio playback everywhere the recording travels (draft replay,
/// received handover, confirmation layer). Plays the base64 data URI stored
/// in handover.audio.url.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import '../domain/handover.dart';

class PlaybackService {
  final AudioPlayer _player = AudioPlayer();

  Stream<PlayerState> get stateStream => _player.onPlayerStateChanged;

  /// Returns false when the recording is not on this device (url omitted).
  Future<bool> play(AudioRecordingData audio) async {
    if (audio.url.isEmpty) return false;
    final comma = audio.url.indexOf(',');
    if (!audio.url.startsWith('data:') || comma < 0) return false;
    final bytes = Uint8List.fromList(base64Decode(audio.url.substring(comma + 1)));
    await _player.stop();
    await _player.play(BytesSource(bytes, mimeType: audio.mimeType));
    return true;
  }

  Future<void> stop() => _player.stop();
  Future<void> dispose() => _player.dispose();
}
