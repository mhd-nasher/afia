/// Speech-to-text seam. The current adapter is the device recogniser via
/// speech_to_text (locales ar_SA / en_GB), delivering live partial results
/// while the person talks. Recording is optional — typing is always enough,
/// and the describe screen keeps a large "type instead" field visible.
library;

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class TranscriberService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _available = false;

  final List<String> _finalSegments = [];
  String _partial = '';

  bool get available => _available;
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

  /// Seed the transcript when resuming an interrupted description.
  void resumeFrom(String transcript) {
    reset();
    if (transcript.trim().isNotEmpty) _finalSegments.add(transcript.trim());
  }
}
