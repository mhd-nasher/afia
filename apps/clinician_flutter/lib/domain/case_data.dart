/// Read model for patient-app cases as the ASSISTANT sees them (D-013).
///
/// Deliberately narrower than the stored document: `priority` is NOT parsed.
/// The assistant layer orders and reports by wait time, completeness, and
/// state only (§2.10) — a risk field cannot flow through this type because
/// the type cannot carry one.
library;

import 'answer.dart';

class CaseUpdateData {
  final int at;
  final String kind; // 'initial' | 'condition_changed'
  final String transcript;
  final String syncState; // 'queued_on_device' | 'sent'
  final List<AnswerState> redFlagAnswers;
  final List<String> functionalValues; // FunctionalValue wire strings

  const CaseUpdateData({
    required this.at,
    required this.kind,
    required this.transcript,
    required this.syncState,
    required this.redFlagAnswers,
    required this.functionalValues,
  });

  factory CaseUpdateData.fromMap(Map<String, dynamic> m) => CaseUpdateData(
        at: (m['at'] as num?)?.toInt() ?? 0,
        kind: m['kind'] as String? ?? 'initial',
        transcript: m['transcript'] as String? ?? '',
        syncState: m['syncState'] as String? ?? 'sent',
        redFlagAnswers: (m['redFlagAnswers'] as List<dynamic>? ?? const [])
            .map((a) => AnswerStateWire.parse(
                ((a as Map)['answer'] ?? 'NOT_ASKED').toString()))
            .toList(),
        functionalValues: (m['functionalAnswers'] as List<dynamic>? ?? const [])
            .map((a) => ((a as Map)['value'] ?? 'NOT_ASKED').toString())
            .toList(),
      );
}

class CaseData {
  final String id;
  final String patientName;
  final int createdAt;
  final String status; // 'in_progress' | 'submitted'
  final List<CaseUpdateData> updates;

  const CaseData({
    required this.id,
    required this.patientName,
    required this.createdAt,
    required this.status,
    required this.updates,
  });

  factory CaseData.fromMap(Map<String, dynamic> m) => CaseData(
        id: m['id'] as String,
        patientName: m['patientName'] as String? ?? '',
        createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
        status: m['status'] as String? ?? 'submitted',
        updates: (m['updates'] as List<dynamic>? ?? const [])
            .map((u) => CaseUpdateData.fromMap((u as Map).cast<String, dynamic>()))
            .toList(),
      );

  /// File completeness, 0..1 — the share of questions in the latest update
  /// that carry a RECORDED answer. UNKNOWN counts as answered ("I don't
  /// know" is a first-class answer, §2.2); NOT_ASKED does not. With no
  /// questions recorded, a non-empty transcript counts as a complete file.
  double get completeness {
    if (updates.isEmpty) return 0;
    final latest = updates.last;
    final total =
        latest.redFlagAnswers.length + latest.functionalValues.length;
    if (total == 0) return latest.transcript.trim().isEmpty ? 0 : 1;
    final answered = latest.redFlagAnswers
            .where((a) => a != AnswerState.notAsked)
            .length +
        latest.functionalValues.where((v) => v != 'NOT_ASKED').length;
    return answered / total;
  }

  int get conditionChangedCount =>
      updates.where((u) => u.kind == 'condition_changed').length;
}
