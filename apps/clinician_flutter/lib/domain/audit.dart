/// HANDOFF §3.4 — every state transition is recorded and immutable: actor,
/// timestamp, action, entityId, previousValue. The repository only ever
/// CREATES audit documents (firestore.rules denies update/delete on /audit).
/// There is no edit-in-place API here, deliberately.
library;

const List<String> auditActions = [
  'created',
  'recorded',
  'transcribed',
  'structured',
  'flagged',
  'corrected',
  'chip_confirmed',
  'signed',
  'exported',
  'export_failed',
  'confirmed',
  'superseded',
  'escalated',
  'case_submitted',
  'case_updated',
  'consent_granted',
  'consent_withdrawn',
  'sign_in',
  'sign_out',
  'template_edited',
  'rule_edited',
];

class AuditEvent {
  final String id;
  final int at;
  final String actor;
  final String action;
  final String entityId;
  final Object? previousValue;
  final String? detail;

  const AuditEvent({
    required this.id,
    required this.at,
    required this.actor,
    required this.action,
    required this.entityId,
    required this.previousValue,
    required this.detail,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'at': at,
        'actor': actor,
        'action': action,
        'entityId': entityId,
        'previousValue': previousValue,
        'detail': detail,
      };

  factory AuditEvent.fromMap(Map<String, dynamic> m) => AuditEvent(
        id: m['id'] as String,
        at: (m['at'] as num?)?.toInt() ?? 0,
        actor: m['actor'] as String? ?? '',
        action: m['action'] as String? ?? '',
        entityId: m['entityId'] as String? ?? '',
        previousValue: m['previousValue'],
        detail: m['detail'] as String?,
      );
}
