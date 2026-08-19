/// Patient-facing AI — the STRICTEST envelope in the platform (§4.3 + §11).
///
/// ALLOWED (reorganisation of the patient's own words only):
///   · tidy — clean and order the patient's description using ONLY their own
///     sentences, so it reads clearly to a nurse
///   · translate — AR↔EN translation of the patient's own text
///
/// FORBIDDEN — enforced three ways: (1) hard-coded into the system prompt,
/// (2) no tool exists through which a judgement could be expressed, and
/// (3) red-flag evaluation NEVER touches this file — it is local
/// deterministic Dart only (§2.7):
///   · triage, severity, urgency — in any wording
///   · diagnosis, medical advice, interpreting symptoms
///   · reassurance or ANY wording implying the patient is fine (§11)
///   · clinical numbers or urgency levels shown to the patient (§11)
///
/// Output is additionally validated in code: a tidy result whose words are
/// not traceable to the patient's own text is discarded in favour of the
/// deterministic fallback. Offline (or on any error) the deterministic
/// fallback runs instead — the flow never depends on the model.
library;

import 'package:firebase_ai/firebase_ai.dart';

/// The ONE place the Gemini model id lives — same id the clinician app uses
/// (apps/clinician_flutter/lib/services/ai_config.dart).
const String geminiModelId = 'gemini-3.5-flash';

/// Tried in order when the primary id is rejected at runtime.
const List<String> geminiModelFallbacks = [
  'gemini-3.1-flash-lite',
  'gemini-2.5-flash',
];

const String tidySystemPrompt = '''
You tidy up how a patient described their own symptoms, so a nurse can read
it easily. The patient may write in Arabic or English.

STRICT RULES — violating any of these makes your output unusable:
1. Use ONLY the patient's own words. You may re-order sentences, fix
   spacing/punctuation, and remove exact duplicates and filler sounds
   ("um", "اه"). Never add a word the patient did not use. Never summarise
   away information.
2. NEVER assess, triage, or classify anything: no severity, no urgency, no
   priority, in any wording.
3. NEVER diagnose, name a possible condition, or suggest any treatment,
   medication, or action.
4. NEVER reassure. No "this sounds fine", "don't worry", "this is probably
   nothing" — in any language.
5. NEVER add clinical numbers, scores, or urgency levels.
6. Keep the patient's language. Do not translate unless the separate
   translate instruction is given.
Respond with the tidied text only — no preamble, no commentary.
''';

const String translateSystemPrompt = '''
You translate a patient's own description of their symptoms between Arabic
and English. Translate faithfully and completely.
STRICT RULES:
1. Translate ONLY — never add, remove, soften, or strengthen anything.
2. NEVER assess, diagnose, advise, or reassure, in any language.
Respond with the translated text only — no preamble, no commentary.
''';

class PatientAiService {
  PatientAiService._();
  static final PatientAiService instance = PatientAiService._();

  GenerativeModel _model(String id, String systemPrompt) =>
      FirebaseAI.googleAI().generativeModel(
        model: id,
        systemInstruction: Content.system(systemPrompt),
        generationConfig: GenerationConfig(temperature: 0),
      );

  Future<String?> _generate(String systemPrompt, String userText) async {
    for (final id in [geminiModelId, ...geminiModelFallbacks]) {
      try {
        final response = await _model(id, systemPrompt)
            .generateContent([Content.text(userText)]).timeout(
                const Duration(seconds: 20));
        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) return text;
      } catch (_) {
        // Next fallback id; ultimately the deterministic path takes over.
      }
    }
    return null;
  }

  /// Tidy the patient's description. Falls back to [deterministicTidy] when
  /// offline, on error, or when the model output fails the own-words check.
  Future<TidyResult> tidyDescription(String transcript) async {
    final cleanedInput = deterministicTidy(transcript);
    final modelOut = await _generate(tidySystemPrompt, transcript);
    if (modelOut == null) {
      return TidyResult(text: cleanedInput, fromModel: false);
    }
    if (!_traceableToSource(modelOut, transcript)) {
      // The model added words that are not the patient's — discard (§4.3).
      return TidyResult(text: cleanedInput, fromModel: false);
    }
    return TidyResult(text: modelOut, fromModel: true);
  }

  /// Translate the patient's own text. [toArabic] true → AR, false → EN.
  /// Returns null when the model is unavailable — the UI simply keeps the
  /// original; there is no deterministic translation fallback and the flow
  /// never requires one.
  Future<String?> translateDescription(String transcript,
      {required bool toArabic}) {
    final direction = toArabic ? 'Translate to Arabic.' : 'Translate to English.';
    return _generate(translateSystemPrompt, '$direction\n\n$transcript');
  }

  /// The deterministic fallback (and the validator's baseline): trims,
  /// collapses whitespace, drops exact duplicate sentences and standalone
  /// filler tokens. Same input → same output; no I/O.
  static String deterministicTidy(String transcript) {
    final collapsed = transcript.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) return '';
    final parts = collapsed
        .split(RegExp(r'(?<=[.!؟?،])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final seen = <String>{};
    final kept = <String>[];
    const filler = {'um', 'uh', 'erm', 'اه', 'ااه', 'يعني'};
    for (final p in parts) {
      final key = p.toLowerCase();
      if (filler.contains(key.replaceAll(RegExp(r'[^\w؀-ۿ]'), ''))) {
        continue;
      }
      if (seen.add(key)) kept.add(p);
    }
    return kept.join(' ');
  }

  /// Every word of the model output must appear in the patient's own text
  /// (reorganisation, not generation). Punctuation-insensitive.
  static bool _traceableToSource(String output, String source) {
    Set<String> words(String s) => s
        .toLowerCase()
        .split(RegExp(r'[^\w؀-ۿ]+'))
        .where((w) => w.isNotEmpty)
        .toSet();
    final sourceWords = words(source);
    final outWords = words(output);
    if (outWords.isEmpty) return false;
    return outWords.every(sourceWords.contains);
  }
}

class TidyResult {
  final String text;

  /// True = machine-made and unverified → the UI renders it in periwinkle
  /// until the patient accepts it as their description.
  final bool fromModel;
  const TidyResult({required this.text, required this.fromModel});
}
