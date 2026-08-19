/// Afia Assistant (مساعد عافية) — the personal shift assistant (D-013).
/// Gemini with function calling (firebase_ai), per-user memory, and a tool
/// set that lives entirely inside the HANDOFF §4 safety envelope: every tool
/// REORGANISES recorded facts. No tool that judges severity, suggests
/// treatment, or ranks importance exists — such an action cannot even be
/// expressed through the agent's action space, and ordering everywhere goes
/// through the §2.10 comparator (wait time, completeness — never risk).
///
/// Presentation contract (field feedback): ONE question → ONE answer. The
/// model must finish by calling `final_answer` with a structured payload
/// (no markdown anywhere); the app renders it natively. Intermediate tool
/// rounds surface only as a lightweight activity line. Plain text is a
/// fallback, stripped of markdown markers — `**` never reaches the user.
library;

import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';

import '../../domain/case_data.dart';
import '../../domain/entities.dart';
import '../../domain/formulary.dart';
import '../../domain/gaps.dart';
import '../../domain/handover.dart' as domain;
import '../../domain/structuring.dart';
import '../../domain/teamwork.dart';
import '../../domain/ward_order.dart';
import '../ai_config.dart';
import '../repo.dart';
import 'memory_service.dart';
import 'shift_tools.dart';

/// A row inside a structured answer section. [patientId] deep-links to the
/// patient's screen; [state] is a handover-state wire value rendered as the
/// standard status line.
class AssistantListRow {
  final String title;
  final String? subtitle;
  final String? trailingMono;
  final String? state;
  final String? patientId;
  const AssistantListRow({
    required this.title,
    this.subtitle,
    this.trailingMono,
    this.state,
    this.patientId,
  });
}

class AnswerSection {
  final String title;
  final List<AssistantListRow> rows;
  const AnswerSection({required this.title, required this.rows});
}

/// D-014 — a drafted colleague request. The assistant NEVER sends: the UI
/// renders this as a confirm card and sending takes one explicit human tap.
class RequestDraft {
  final RequestKind kind;
  final String toUid;
  final String toName;
  final String? bed;
  final String? note;
  const RequestDraft({
    required this.kind,
    required this.toUid,
    required this.toName,
    this.bed,
    this.note,
  });
}

/// The structured final answer the model must produce (field feedback):
/// calm, organized, native — no markdown, no walls of text.
class AssistantAnswer {
  final String? intro;
  final List<(String, String)> stats;
  final List<AnswerSection> sections;
  final String? note;

  /// Optional drafted request rendered as a one-tap confirm card (D-014).
  final RequestDraft? requestDraft;
  const AssistantAnswer({
    this.intro,
    this.stats = const [],
    this.sections = const [],
    this.note,
    this.requestDraft,
  });

  bool get isEmpty =>
      (intro == null || intro!.trim().isEmpty) &&
      stats.isEmpty &&
      sections.isEmpty &&
      (note == null || note!.trim().isEmpty) &&
      requestDraft == null;
}

/// One entry in the visible chat transcript.
class AssistantEntry {
  final bool fromUser;
  final String text;
  final AssistantAnswer? answer;

  const AssistantEntry._({
    required this.fromUser,
    required this.text,
    this.answer,
  });

  factory AssistantEntry.user(String text) =>
      AssistantEntry._(fromUser: true, text: text);
  factory AssistantEntry.assistant(String text) =>
      AssistantEntry._(fromUser: false, text: text);
  factory AssistantEntry.answerCard(AssistantAnswer answer) =>
      AssistantEntry._(fromUser: false, text: '', answer: answer);
}

/// True when [text] contains something a human can actually see — zero-width
/// characters and whitespace do not count. Empty turns never render.
bool hasVisibleText(String text) =>
    text.replaceAll(RegExp(r'[​‌‍⁠﻿\s]+'), '').isNotEmpty;

/// Fallback hygiene: markdown markers never reach the user (field feedback).
String stripMarkdown(String text) => text
    .replaceAll(RegExp(r'\*\*|__|\*|`+'), '')
    .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
    .replaceAll(RegExp(r'^\s*[-•]\s+', multiLine: true), '· ')
    .trim();

class AssistantService {
  final MemoryService _memory;
  final Practitioner _me;
  final List<TemplateField> _template;
  final List<Patient> _patients;
  final List<domain.Handover> _handovers;
  final Ward? _ward;
  final List<FormularyEntry> _formulary;

  /// D-014 — live colleagues (presence) and the ward-order setter, injected
  /// so the service stays testable.
  final List<PresenceEntry> Function() _presenceProvider;
  final Future<void> Function(WardOrder) _wardOrderSetter;

  ChatSession? _chat;
  AssistantMemory? _loadedMemory;
  int _modelIndex = -1; // -1 = primary, then fallbacks by index

  /// The visible transcript. The UI listens via [entries] + [onChanged].
  final List<AssistantEntry> entries = [];

  /// Name of the tool currently running (intermediate rounds render only a
  /// lightweight activity line — never bubbles). null when idle.
  String? activity;

  void Function()? onChanged;

  AssistantService({
    required Practitioner me,
    required List<TemplateField> template,
    required List<Patient> patients,
    required List<domain.Handover> handovers,
    Ward? ward,
    List<FormularyEntry> formulary = const [],
    List<PresenceEntry> Function()? presenceProvider,
    Future<void> Function(WardOrder)? wardOrderSetter,
    MemoryService? memory,
  })  : _me = me,
        _template = template,
        _patients = patients,
        _handovers = handovers,
        _ward = ward,
        _formulary = formulary,
        _presenceProvider = presenceProvider ?? (() => const []),
        _wardOrderSetter = wardOrderSetter ?? ((_) async {}),
        _memory = memory ?? MemoryService.instance;

  // ── tools (§4.2 / D-013 — reorganisation of recorded facts only) ────────

  List<Tool> get _tools => [
        Tool.functionDeclarations([
          FunctionDeclaration(
            'shift_overview',
            'Per ward-patient: handover state (not_started/recording/'
                'draft_ready/signed/queued/confirmed_in_system=recorded in '
                'Afia/export_failed), unconfirmed chip count, open flag '
                'count, plus shift totals. Facts only.',
            parameters: {},
          ),
          FunctionDeclaration(
            'incoming_cases',
            'Incoming patient-app cases: count and list with patient name, '
                'received time, wait duration in minutes, file completeness, '
                'update count. Ordered by wait time then completeness ONLY — '
                'never clinical risk. filter: today | all | unreviewed.',
            parameters: {'filter': Schema.string()},
            optionalParameters: ['filter'],
          ),
          FunctionDeclaration(
            'whats_left',
            'The shift checklist from facts: patients without a signed '
                'handover, drafts with unconfirmed chips (counts), export '
                'failures needing retry, submitted incoming cases. No '
                'ranking beyond bed/wait order.',
            parameters: {},
          ),
          FunctionDeclaration(
            'ward_info',
            'Ward name, committed review time and its named owner, and the '
                'bed/patient list.',
            parameters: {},
          ),
          FunctionDeclaration(
            'formulary_lookup',
            'Fuzzy-match a drug term against the ward formulary; sound-alike '
                'clusters are always shown together.',
            parameters: {'term': Schema.string()},
          ),
          FunctionDeclaration(
            'who_is_on_shift',
            'Colleagues currently present in this ward (live presence): '
                'uid, name, role. Only people present right now.',
            parameters: {},
          ),
          FunctionDeclaration(
            'draft_request',
            'DRAFT a preset request to a present colleague — never sends. '
                'Return it in final_answer.requestDraft so the nurse can send '
                'with one tap. kind must be one of: break_cover, lift_turn, '
                'med_witness, take_over, iv_help, urgent_review, supplies, '
                'family_talk. toUid must come from who_is_on_shift.',
            parameters: {
              'kind': Schema.string(),
              'toUid': Schema.string(),
              'bed': Schema.string(),
              'note': Schema.string(),
            },
            optionalParameters: ['bed', 'note'],
          ),
          FunctionDeclaration(
            'set_ward_order',
            'Set the nurse\'s own ward-list order. mode must be one of: bed '
                '(default), unsigned_first, unconfirmed_chips_first, manual. '
                'For manual, pass patientIds in the nurse\'s dictated order '
                '(ids from shift_overview/ward_info). The order persists for '
                'this nurse. There is NO risk mode and none can be requested.',
            parameters: {
              'mode': Schema.string(),
              'patientIds': Schema.array(items: Schema.string()),
            },
            optionalParameters: ['patientIds'],
          ),
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
          // Field feedback — the REQUIRED last step of every reply: the
          // structured answer the app renders natively. No markdown anywhere.
          FunctionDeclaration(
            'final_answer',
            'REQUIRED: finish EVERY reply by calling this exactly once with '
                'your complete answer, structured. Plain sentences only — no '
                'markdown syntax (no *, **, #, `, bullets) in any field. Use '
                'the user\'s language. Put counts in stats; lists in sections '
                'with one row per item (carry patientId through from tool '
                'outputs when present, and the handover state wire value in '
                'row.state). Keep intro to one or two short sentences.',
            parameters: {
              'intro': Schema.string(),
              'stats': Schema.array(
                items: Schema.object(properties: {
                  'label': Schema.string(),
                  'value': Schema.string(),
                }),
              ),
              'sections': Schema.array(
                items: Schema.object(properties: {
                  'title': Schema.string(),
                  'rows': Schema.array(
                    items: Schema.object(
                      properties: {
                        'primary': Schema.string(),
                        'secondary': Schema.string(),
                        'trailing': Schema.string(),
                        'state': Schema.string(),
                        'patientId': Schema.string(),
                      },
                      optionalProperties: [
                        'secondary',
                        'trailing',
                        'state',
                        'patientId'
                      ],
                    ),
                  ),
                }),
              ),
              'note': Schema.string(),
              'requestDraft': Schema.object(
                properties: {
                  'kind': Schema.string(),
                  'toUid': Schema.string(),
                  'toName': Schema.string(),
                  'bed': Schema.string(),
                  'note': Schema.string(),
                },
                optionalProperties: ['bed', 'note'],
              ),
            },
            optionalParameters: [
              'intro',
              'stats',
              'sections',
              'note',
              'requestDraft'
            ],
          ),
        ]),
      ];

  // ── model / chat lifecycle ───────────────────────────────────────────────

  String get _currentModelId => _modelIndex < 0
      ? geminiModelId
      : geminiModelFallbacks[
          _modelIndex.clamp(0, geminiModelFallbacks.length - 1)];

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
      generationConfig: GenerationConfig(temperature: 0),
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
      if (_isModelNotFound(e) &&
          _modelIndex < geminiModelFallbacks.length - 1) {
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
    } finally {
      activity = null;
      onChanged?.call();
    }
  }

  void _fail(Object e) {
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
    var response =
        await chat.sendMessage(message).timeout(const Duration(seconds: 30));

    var answered = false;

    // Tool loop — bounded so a misbehaving model cannot spin. Intermediate
    // turns NEVER render as bubbles; only the activity line updates.
    for (var turn = 0; turn < 8; turn++) {
      final calls = response.functionCalls.toList();
      if (calls.isEmpty) break;
      final responses = <FunctionResponse>[];
      for (final call in calls) {
        activity = call.name;
        onChanged?.call();
        if (call.name == 'final_answer') {
          final answer = _parseAnswer(call.args);
          if (!answer.isEmpty) {
            entries.add(AssistantEntry.answerCard(answer));
            answered = true;
            onChanged?.call();
          }
          responses.add(FunctionResponse(
              call.name, {'rendered': answer.isEmpty ? false : true},
              id: call.id));
        } else {
          final result = await _runTool(call.name, call.args);
          responses.add(FunctionResponse(call.name, result, id: call.id));
        }
      }
      response = await chat
          .sendMessage(Content.functionResponses(responses))
          .timeout(const Duration(seconds: 30));
    }

    // One question → one answer. Trailing prose after a rendered answer is
    // dropped; without a structured answer, plain text (markdown-stripped)
    // is the fallback — and empty turns never render at all.
    if (!answered) {
      final text = stripMarkdown(response.text ?? '');
      if (hasVisibleText(text)) {
        entries.add(AssistantEntry.assistant(text));
        onChanged?.call();
      }
    }
  }

  AssistantAnswer _parseAnswer(Map<String, Object?> args) {
    List<T> listOf<T>(Object? v, T Function(Map<String, Object?>) parse) =>
        v is List
            ? v
                .whereType<Map>()
                .map((m) => parse(m.cast<String, Object?>()))
                .toList()
            : const [];

    String? cleanText(Object? v) {
      if (v == null) return null;
      final s = stripMarkdown(v.toString());
      return hasVisibleText(s) ? s : null;
    }

    return AssistantAnswer(
      intro: cleanText(args['intro']),
      stats: listOf(args['stats'],
              (m) => (cleanText(m['label']) ?? '', cleanText(m['value']) ?? ''))
          .where((s) => s.$1.isNotEmpty || s.$2.isNotEmpty)
          .toList(),
      sections: listOf(args['sections'], (m) {
        return AnswerSection(
          title: cleanText(m['title']) ?? '',
          rows: listOf(
              m['rows'],
              (r) => AssistantListRow(
                    title: cleanText(r['primary']) ?? '',
                    subtitle: cleanText(r['secondary']),
                    trailingMono: cleanText(r['trailing']),
                    state: cleanText(r['state']),
                    patientId: cleanText(r['patientId']),
                  )),
        );
      }).where((s) => s.title.isNotEmpty || s.rows.isNotEmpty).toList(),
      note: cleanText(args['note']),
      requestDraft: _parseRequestDraft(args['requestDraft']),
    );
  }

  RequestDraft? _parseRequestDraft(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.cast<String, Object?>();
    final kind = RequestKindWire.parse((m['kind'] ?? '').toString());
    final toUid = (m['toUid'] ?? '').toString();
    if (kind == null || toUid.isEmpty) return null;
    // The recipient must be present NOW — a stale draft cannot be sent.
    final colleague =
        _presenceProvider().where((p) => p.uid == toUid).firstOrNull;
    if (colleague == null) return null;
    return RequestDraft(
      kind: kind,
      toUid: colleague.uid,
      toName: colleague.name,
      bed: m['bed']?.toString(),
      note: m['note']?.toString(),
    );
  }

  // ── tool implementations (data only — rendering is final_answer's job) ──

  Future<Map<String, Object?>> _runTool(
      String name, Map<String, Object?> args) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    switch (name) {
      case 'shift_overview':
        return shiftOverview(patients: _patients, handovers: _handovers);

      case 'incoming_cases':
        return incomingCases(
            cases: await _fetchCasesSafe(),
            filter: (args['filter'] ?? 'all').toString(),
            nowMs: nowMs);

      case 'whats_left':
        return whatsLeft(
            patients: _patients,
            handovers: _handovers,
            cases: await _fetchCasesSafe(),
            nowMs: nowMs);

      case 'ward_info':
        return wardInfo(ward: _ward, patients: _patients);

      case 'who_is_on_shift':
        final present = _presenceProvider();
        return {
          'count': present.length,
          'colleagues': [
            for (final p in present)
              {'uid': p.uid, 'name': p.name, 'role': p.role}
          ],
        };

      case 'draft_request':
        final kind = RequestKindWire.parse((args['kind'] ?? '').toString());
        if (kind == null) return {'error': 'unknown kind'};
        final toUid = (args['toUid'] ?? '').toString();
        final colleague = _presenceProvider()
            .where((p) => p.uid == toUid)
            .firstOrNull;
        if (colleague == null) {
          return {'error': 'recipient is not present on shift right now'};
        }
        // Draft only — the human sends with one explicit tap (D-014).
        return {
          'drafted': true,
          'requestDraft': {
            'kind': kind.wire,
            'toUid': colleague.uid,
            'toName': colleague.name,
            if (args['bed'] != null) 'bed': args['bed'].toString(),
            if (args['note'] != null) 'note': args['note'].toString(),
          },
          'note': 'Return this in final_answer.requestDraft — the nurse '
              'sends it with one tap. Never claim it was sent.',
        };

      case 'set_ward_order':
        final mode =
            WardOrderModeWire.parse((args['mode'] ?? '').toString());
        if (mode == null) {
          return {
            'error': 'unknown mode',
            'allowedModes': [
              for (final m in WardOrderMode.values) m.wire
            ],
          };
        }
        final ids = (args['patientIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];
        final knownIds = _patients.map((p) => p.id).toSet();
        final validIds = ids.where(knownIds.contains).toList();
        if (mode == WardOrderMode.manual && validIds.isEmpty) {
          return {'error': 'manual mode needs patientIds from this ward'};
        }
        await _wardOrderSetter(WardOrder(mode: mode, manualIds: validIds));
        return {
          'applied': mode.wire,
          if (mode == WardOrderMode.manual) 'order': validIds,
          'persisted': true,
        };

      case 'formulary_lookup':
        return formularyLookup(
            term: (args['term'] ?? '').toString(), formulary: _formulary);

      case 'structure_transcript':
        final transcript = (args['transcript'] ?? '').toString();
        const structurer = KeywordStructurer();
        final fields = validateStructured(
            structurer.structureSync(transcript, _template),
            transcript,
            _template);
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
        return {
          'patient': found.name,
          'patientId': found.id,
          'summary': tenSecondSummary(latest.fields, _template),
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
        final diff = diffHandovers(versions[versions.length - 2].fields,
            versions.last.fields, _template);
        return {
          'patient': found.name,
          'patientId': found.id,
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
            'patientId': found.id,
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

  Future<List<CaseData>> _fetchCasesSafe() async {
    try {
      return await Repo.instance.fetchCases();
    } catch (_) {
      return const []; // offline / rules — the tool reports zero honestly
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
