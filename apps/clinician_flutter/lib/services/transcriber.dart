/// Speech-to-text seam (§4.1). The demo adapter is the device recogniser via
/// speech_to_text (locales ar-SA / en-GB), delivering live partial results to
/// the recording screen. In production this seat is taken by faster-whisper
/// behind the same interface — accuracy on real ward speech is UNVALIDATED
/// either way (HANDOFF §9.2).
library;

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class TranscriberService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _available = false;

  /// Segments finalized by the recogniser so far (§4.2 — merged in order).
  final List<String> _finalSegments = [];
  String _partial = '';

  bool get available => _available;
  List<String> get finalSegments => List.unmodifiable(_finalSegments);
  String get partial => _partial;

  String get mergedTranscript => [
        ..._finalSegments,
        if (_partial.trim().isNotEmpty) _partial,
      ].map((s) => s.trim()).where((s) => s.isNotEmpty).join(' ');

  Future<bool> initialize({void Function(String message)? onError}) async {
    if (_initialized) return _available;
    try {
      _available = await _speech.initialize(
        onError: (e) => onError?.call(e.errorMsg),
      );
    } catch (e) {
      _available = false;
      onError?.call(e.toString());
    }
    _initialized = true;
    return _available;
  }

  /// [localeId] 'ar_SA' or 'en_GB' per the app language.
  Future<void> start({
    required String localeId,
    required void Function() onUpdate,
    void Function(String message)? onError,
  }) async {
    if (!_available) return;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          if (result.recognizedWords.trim().isNotEmpty) {
            _finalSegments.add(result.recognizedWords);
          }
          _partial = '';
        } else {
          _partial = result.recognizedWords;
        }
        onUpdate();
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        localeId: localeId,
      ),
    );
  }

  Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
  }

  void reset() {
    _finalSegments.clear();
    _partial = '';
  }

  /// Seed the transcript when resuming an interrupted draft.
  void resumeFrom(String transcript) {
    reset();
    if (transcript.trim().isNotEmpty) _finalSegments.add(transcript.trim());
  }

  void appendTyped(String text) {
    if (text.trim().isNotEmpty) _finalSegments.add(text.trim());
  }
}
