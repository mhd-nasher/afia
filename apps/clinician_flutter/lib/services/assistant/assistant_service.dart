/// Afia Assistant (مساعد عافية) — the in-app agent. Gemini with function
/// calling (firebase_ai), a per-user memory, and a tool set that lives
/// entirely inside the HANDOFF §4 safety envelope: every tool REORGANISES
/// information humans already recorded. No tool that judges severity,
/// suggests treatment, or ranks importance exists — such an action cannot
/// even be expressed through the agent's action space.
library;

import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';

import '../../domain/entities.dart';
import '../../domain/gaps.dart';
import '../../domain/handover.dart' as domain;
import '../../domain/structuring.dart';
import '../ai_config.dart';
import 'memory_service.dart';

/// One entry in the visible chat transcript. Tool results the UI renders as
/// proper widgets (summary card, diff card, fields card) ride along typed.
class AssistantEntry {
  final bool fromUser;
  final String text;
  final List<FieldDiff>? diff;
  final List<FieldContent>? fields;
  final String? summary;
  final String? patientLabel;

  const AssistantEntry._({
    required this.fromUser,
    required this.text,
    this.diff,
    this.fields,
    this.summary,
    this.patientLabel,
  });

  factory AssistantEntry.user(String text) =>
      AssistantEntry._(fromUser: true, text: text);
  factory AssistantEntry.assistant(String text) =>
      AssistantEntry._(fromUser: false, text: text);
  factory AssistantEntry.summaryCard(String patientLabel, String summary) =>
      AssistantEntry._(
          fromUser: false,
          text: '',
          summary: summary,
          patientLabel: patientLabel);
  factory AssistantEntry.diffCard(String patientLabel, List<FieldDiff> diff) =>
      AssistantEntry._(
          fromUser: false, text: '', diff: diff, patientLabel: patientLabel);
  factory AssistantEntry.fieldsCard(List<FieldContent> fields) =>
      AssistantEntry._(fromUser: false, text: '', fields: fields);
}

class AssistantService {
  final MemoryService _memory;
  final Practitioner _me;
  final List<TemplateField> _template;
  final List<Patient> _patients;
  final List<domain.Handover> _handovers;

  ChatSession? _chat;
  AssistantMemory? _loadedMemory;
  int _modelIndex = -1; // -1 = primary, then fallbacks by index

  /// The visible transcript. The UI listens via [entries] + [onChanged].
  final List<AssistantEntry> entries = [];
  void Function()? onChanged;

  AssistantService({
    required Practitioner me,
    required List<TemplateField> template,
    required List<Patient> patients,
    required List<domain.Handover> handovers,
    MemoryService? memory,
  })  : _me = me,
        _template = template,
        _patients = patients,
        _handovers = handovers,
        _memory = memory ?? MemoryService.instance;

  // ── tools (§4.2 only — reorganisation) ──────────────────────────────────

  List<Tool> get _tools => [
        Tool.functionDeclarations([
          FunctionDeclaration(
            'structure_transcript',
            'Reorganise a dictated handover transcript into the ward template '
                'fields. Uses only verbatim sentences from the transcript.',
            parameters: {'transcript': Schema.string()},
          ),
          FunctionDeclaration(
            'ten_second_summary',
            'Ten-second summary of the latest recorded handover for a patient '
                '(by name or bed). Reorganises what the author already said.',
            parameters: {'patient': Schema.string()},
          ),
          FunctionDeclaration(
            'diff_vs_previous',
            'What changed between the last two recorded handovers for a '
                'patient (by name or bed). Neutral wording, field by field.',
            parameters: {'patient': Schema.string()},
          ),
          FunctionDeclaration(
            'find_patient_recorded_info',
            'Quote information the care team already recorded about a patient '
                '(by name or bed): identity, latest handover fields, open '
                'omission flags, signature and export state.',
            parameters: {'patient': Schema.string()},
          ),
          FunctionDeclaration(
            'remember',
            'Store a one-line memory note about how this user works '
                '(preferences, habits). Never clinical judgements.',
            parameters: {'note': Schema.string(), 'topic': Schema.string()},
          ),
          FunctionDeclaration(
            'get_my_preferences',
            'Read the user\'s stored preferences.',
            parameters: {},
          ),
          FunctionDeclaration(
            'set_preference',
            'Store one user preference (e.g. summary_style, dictation_habit).',
            parameters: {'key': Schema.string(), 'value': Schema.string()},
          ),
        ]),
      ];

  // ── model / chat lifecycle ───────────────────────────────────────────────

  String get _currentModelId => _modelIndex < 0
      ? geminiModelId
      : geminiModelFallbacks[_modelIndex.clamp(0, geminiModelFallbacks.length - 1)];

  Future<ChatSession> _ensureChat() async {
    if (_chat != null) return _chat!;
    final memory = _loadedMemory ??= await _memory.load(_me.id);
    final context = StringBuffer(assistantSystemPrompt)
      ..writeln('\nSigned-in user: ${_me.name} (${_me.role.wire}).')
      ..writeln('Ward template fields: '
          '${_template.map((f) => '${f.id} (${f.label})').join(', ')}.');
    if (!memory.isEmpty) {
      context
        ..writeln('\n--- USER MEMORY (loaded at session start) ---')
        ..writeln(memory.toContext());
    }

    final model = FirebaseAI.googleAI().generativeModel(
      model: _currentModelId,
      systemInstruction: Content.system(context.toString()),
      tools: _tools,
      generationConfig: GenerationConfig(temperature: 0.2),
    );
    return _chat = model.startChat();
  }

  bool _isModelNotFound(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('not found') ||
        s.contains('not_found') ||
        s.contains('unsupported') ||
        s.contains('invalid model');
  }

  // ── the agent loop ───────────────────────────────────────────────────────

  Future<void> send(String userText) async {
    entries.add(AssistantEntry.user(userText));
    onChanged?.call();
    try {
      await _sendInner(Content.text(userText));
    } catch (e) {
      if (_isModelNotFound(e) && _modelIndex < geminiModelFallbacks.length - 1) {
        // Fallback chain: rebuild the chat on the next model id and retry.
        _modelIndex += 1;
        _chat = null;
        try {
          await _sendInner(Content.text(userText));
          return;
        } catch (e2) {
          _fail(e2);
          return;
        }
      }
      _fail(e);
    }
  }

  void _fail(Object e) {
    // Offline / console not enabled / quota — stated plainly, bilingual.
    entries.add(AssistantEntry.assistant(
        'I need a connection to answer — I could not reach the assistant '
        'service. Your recordings and drafts are unaffected and stay on this '
        'device.\n'
        'أحتاج اتصالًا للإجابة — تعذّر الوصول إلى خدمة المساعد. تسجيلاتك '
        'ومسوداتك غير متأثرة وتبقى على هذا الجهاز.'));
    onChanged?.call();
    // ignore: avoid_print
    print('[afia assistant] $e');
  }

  Future<void> _sendInner(Content message) async {
    final chat = await _ensureChat();
    var response = await chat
        .sendMessage(message)
        .timeout(const Duration(seconds: 30));

    // Tool loop — bounded so a misbehaving model cannot spin.
    for (var turn = 0; turn < 6; turn++) {
      final calls = response.functionCalls.toList();
      if (calls.isEmpty) break;
      final responses = <FunctionResponse>[];
      for (final call in calls) {
        final result = await _runTool(call.name, call.args);
        responses.add(FunctionResponse(call.name, result, id: call.id));
      }
      response = await chat
          .sendMessage(Content.functionResponses(responses))
          .timeout(const Duration(seconds: 30));
    }

    final text = response.text?.trim();
    if (text != null && text.isNotEmpty) {
      entries.add(AssistantEntry.assistant(text));
      onChanged?.call();
    }
  }

  // ── tool implementations ────────────────────────────────────────────────

  Future<Map<String, Object?>> _runTool(
      String name, Map<String, Object?> args) async {
    switch (name) {
      case 'structure_transcript':
        final transcript = (args['transcript'] ?? '').toString();
        // Deterministic router + validation — same seam as the recording flow.
        const structurer = KeywordStructurer();
        final fields = validateStructured(
            structurer.structureSync(transcript, _template),
            transcript,
            _template);
        if (fields.isNotEmpty) {
          entries.add(AssistantEntry.fieldsCard(fields));
          onChanged?.call();
        }
        return {
          'fields': fields.map((f) => f.toMap()).toList(),
          'note': 'verbatim sentences routed to fields; nothing added',
        };

      case 'ten_second_summary':
        final found = _findPatient((args['patient'] ?? '').toString());
        if (found == null) return {'error': 'no matching patient'};
        final latest = _latestHandover(found.id);
        if (latest == null) {
          return {'patient': found.name, 'error': 'no recorded handover'};
        }
        final summary = tenSecondSummary(latest.fields, _template);
        entries.add(AssistantEntry.summaryCard(
            '${found.shortName} · ${found.bed}', summary));
        onChanged?.call();
        return {
          'patient': found.name,
          'summary': summary,
          'signed': latest.signature?.signatureIdentity ?? 'unsigned',
        };

      case 'diff_vs_previous':
        final found = _findPatient((args['patient'] ?? '').toString());
        if (found == null) return {'error': 'no matching patient'};
        final versions = _handovers
            .where((h) => h.patientId == found.id)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        if (versions.length < 2) {
          return {
            'patient': found.name,
            'error': 'fewer than two recorded handovers'
          };
        }
        final diff = diffHandovers(
            versions[versions.length - 2].fields,
            versions[versions.length - 1].fields,
            _template);
        entries.add(AssistantEntry.diffCard(
            '${found.shortName} · ${found.bed}', diff));
        onChanged?.call();
        return {
          'patient': found.name,
          'diff': [
            for (final d in diff)
              {'field': d.label, 'kind': d.kind.name, 'text': d.text}
          ],
        };

      case 'find_patient_recorded_info':
        final found = _findPatient((args['patient'] ?? '').toString());
        if (found == null) return {'error': 'no matching patient'};
        final latest = _latestHandover(found.id);
        return {
          'patient': {
            'name': found.name,
            'bed': found.bed,
            'dateOfBirth': found.dateOfBirth,
          },
          if (latest != null)
            'latestHandover': {
              'status': latest.status.wire,
              'signed': latest.signature?.signatureIdentity,
              'fields': latest.fields.map((f) => f.toMap()).toList(),
              'openFlags': latest.flags
                  .map((f) => {'message': f.message, 'note': f.signingNote})
                  .toList(),
            }
          else
            'latestHandover': null,
        };

      case 'remember':
        final note = (args['note'] ?? '').toString();
        final topic = (args['topic'] ?? 'general').toString();
        if (note.trim().isEmpty) return {'stored': false};
        await _memory.remember(_me.id, note, topic);
        return {'stored': true};

      case 'get_my_preferences':
        final memory = _loadedMemory ??= await _memory.load(_me.id);
        return {'preferences': memory.preferences};

      case 'set_preference':
        final key = (args['key'] ?? '').toString();
        final value = (args['value'] ?? '').toString();
        if (key.isEmpty) return {'stored': false};
        await _memory.setPreference(_me.id, key, value);
        return {'stored': true};

      default:
        return {'error': 'unknown tool $name'};
    }
  }

  Patient? _findPatient(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;
    for (final p in _patients) {
      if (p.name.toLowerCase() == q || p.bed.toLowerCase() == q) return p;
    }
    for (final p in _patients) {
      if (p.name.toLowerCase().contains(q) ||
          p.shortName.toLowerCase().contains(q) ||
          ('bed ${p.bed}').toLowerCase() == q ||
          p.bed.toLowerCase() == q.replaceAll('bed', '').trim()) {
        return p;
      }
    }
    return null;
  }

  domain.Handover? _latestHandover(String patientId) {
    final list = _handovers.where((h) => h.patientId == patientId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list.isEmpty ? null : list.last;
  }

  /// Learned-preferences context for the structuring prompt — usage
  /// genuinely improves structuring per user over time.
  static Future<String> structuringContext(String uid) async {
    final memory = await MemoryService.instance.load(uid);
    if (memory.isEmpty) return '';
    return memory.toContext();
  }
}
