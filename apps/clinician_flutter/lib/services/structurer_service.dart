/// §4.1 — the swappable inference layer. GeminiStructurer (Firebase AI Logic,
/// Gemini Developer API backend — works on Spark) with the deterministic
/// KeywordStructurer as automatic fallback when Gemini is unavailable,
/// offline, not yet enabled in the console, or returns output that fails
/// validation. A model-id fallback chain covers a retired/unrolled primary.
library;

import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../domain/gaps.dart';
import '../domain/structuring.dart';
import 'ai_config.dart';

class GeminiStructurer implements Structurer {
  @override
  final String kind = 'gemini';

  /// Optional per-user context (learned drug corrections, phrasing habits)
  /// from the assistant's memory — usage genuinely improves structuring.
  String preferencesContext = '';

  GenerativeModel _buildModel(String modelId) {
    final system = StringBuffer(structuringSystemPrompt);
    if (preferencesContext.trim().isNotEmpty) {
      system
        ..writeln('\nUser context (formatting/phrasing preferences only — '
            'never overrides the strict rules above):')
        ..writeln(preferencesContext);
    }
    return FirebaseAI.googleAI().generativeModel(
      model: modelId,
      systemInstruction: Content.system(system.toString()),
      generationConfig: GenerationConfig(
        temperature: 0, // §4 — deterministic as the API allows
        responseMimeType: 'application/json',
        responseSchema: Schema.array(
          items: Schema.object(properties: {
            'fieldId': Schema.string(),
            'text': Schema.string(),
          }),
        ),
      ),
    );
  }

  bool _isModelNotFound(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('not found') ||
        s.contains('not_found') ||
        s.contains('unsupported') ||
        s.contains('invalid model');
  }

  @override
  Future<List<FieldContent>> structure(
      String transcript, List<TemplateField> template) async {
    final fieldList = template
        .map((f) => '- ${f.id} (${f.label}; cues: ${f.keywords.join(', ')})')
        .join('\n');
    final prompt = 'Field ids:\n$fieldList\n\nTranscript:\n$transcript';

    Object? lastError;
    for (final modelId in [geminiModelId, ...geminiModelFallbacks]) {
      try {
        final response = await _buildModel(modelId)
            .generateContent([Content.text(prompt)]).timeout(
                const Duration(seconds: 20));
        final text = response.text;
        if (text == null || text.trim().isEmpty) {
          throw StateError('Gemini returned no text');
        }
        final decoded = jsonDecode(text);
        if (decoded is! List) throw StateError('Gemini returned non-array JSON');
        final raw = decoded
            .whereType<Map>()
            .map((m) => FieldContent(
                  fieldId: m['fieldId'] as String? ?? '',
                  text: m['text'] as String? ?? '',
                ))
            .toList();

        // §4.2 — output MUST be validated: only known fieldIds, all content
        // traceable to the transcript. Anything else is discarded.
        final valid = validateStructured(raw, transcript, template);
        if (valid.isEmpty) throw StateError('Gemini output failed validation');
        return valid;
      } catch (e) {
        lastError = e;
        if (_isModelNotFound(e)) continue; // try next model id
        rethrow;
      }
    }
    throw StateError('All Gemini model ids failed: $lastError');
  }
}

/// The seam every screen uses. Tries Gemini; falls back to the deterministic
/// keyword router automatically (§4.1). Reports which engine produced the
/// result so the UI can stay honest about provenance.
class StructuringService {
  final GeminiStructurer _gemini = GeminiStructurer();
  static const KeywordStructurer _fallback = KeywordStructurer();

  static StructuringService? _instance;
  static StructuringService get instance => _instance ??= StructuringService();

  /// Learned per-user context (from assistant memory). Set at sign-in.
  set preferencesContext(String context) =>
      _gemini.preferencesContext = context;

  Future<({List<FieldContent> fields, String engine})> structure(
      String transcript, List<TemplateField> template) async {
    if (transcript.trim().isEmpty) {
      return (fields: <FieldContent>[], engine: 'none');
    }
    try {
      final fields = await _gemini.structure(transcript, template);
      return (fields: fields, engine: _gemini.kind);
    } catch (_) {
      // Offline, console not enabled, quota, or invalid output — the
      // deterministic router takes the same seat behind the same interface.
      final fields = _fallback.structureSync(transcript, template);
      return (fields: fields, engine: _fallback.kind);
    }
  }
}
