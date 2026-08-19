/// HANDOFF §3.1 — FHIR-shaped from day one. Same fields, Firestore's exact
/// (camelCase) names from packages/core/src/entities.ts, so this app reads
/// and writes the already-seeded cloud database without translation.
library;

class Patient {
  final String id;
  final String? externalIdentifier;
  final int createdAt;
  final String name;
  final String dateOfBirth;
  final String wardId;
  final String bed;

  const Patient({
    required this.id,
    required this.externalIdentifier,
    required this.createdAt,
    required this.name,
    required this.dateOfBirth,
    required this.wardId,
    required this.bed,
  });

  factory Patient.fromMap(Map<String, dynamic> m) => Patient(
        id: m['id'] as String,
        externalIdentifier: m['externalIdentifier'] as String?,
        createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
        name: m['name'] as String? ?? '',
        dateOfBirth: m['dateOfBirth'] as String? ?? '',
        wardId: m['wardId'] as String? ?? '',
        bed: m['bed'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'externalIdentifier': externalIdentifier,
        'createdAt': createdAt,
        'fhirResource': 'Patient',
        'name': name,
        'dateOfBirth': dateOfBirth,
        'wardId': wardId,
        'bed': bed,
      };

  /// "A. Okafor"-style short name used in the 12-row list.
  String get shortName {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return name;
    return '${parts.first.substring(0, 1)}. ${parts.sublist(1).join(' ')}';
  }
}

enum PractitionerRole { nurse, doctor, chargeNurse, manager }

extension PractitionerRoleWire on PractitionerRole {
  String get wire => switch (this) {
        PractitionerRole.nurse => 'nurse',
        PractitionerRole.doctor => 'doctor',
        PractitionerRole.chargeNurse => 'charge_nurse',
        PractitionerRole.manager => 'manager',
      };

  static PractitionerRole parse(String wire) => switch (wire) {
        'doctor' => PractitionerRole.doctor,
        'charge_nurse' => PractitionerRole.chargeNurse,
        'manager' => PractitionerRole.manager,
        _ => PractitionerRole.nurse,
      };
}

class Practitioner {
  final String id;
  final String? externalIdentifier;
  final int createdAt;
  final String name;
  final PractitionerRole role;

  /// HANDOFF §2.5 — signature identity is immutable: set at account creation
  /// from the invitation, `final` here, and never touched by any update this
  /// app can issue. firestore.rules rejects any write that changes it.
  final String signatureIdentity;
  final String invitedBy;

  const Practitioner({
    required this.id,
    required this.externalIdentifier,
    required this.createdAt,
    required this.name,
    required this.role,
    required this.signatureIdentity,
    required this.invitedBy,
  });

  factory Practitioner.fromMap(Map<String, dynamic> m) => Practitioner(
        id: m['id'] as String,
        externalIdentifier: m['externalIdentifier'] as String?,
        createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
        name: m['name'] as String? ?? '',
        role: PractitionerRoleWire.parse(m['role'] as String? ?? 'nurse'),
        signatureIdentity: m['signatureIdentity'] as String? ?? '',
        invitedBy: m['invitedBy'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'externalIdentifier': externalIdentifier,
        'createdAt': createdAt,
        'fhirResource': 'Practitioner',
        'name': name,
        'role': role.wire,
        'signatureIdentity': signatureIdentity,
        'invitedBy': invitedBy,
      };

  bool get canViewTemplate =>
      role == PractitionerRole.chargeNurse || role == PractitionerRole.manager;
}

class Ward {
  final String id;
  final String name;
  final int committedReviewMinutes;
  final String reviewOwner;

  const Ward({
    required this.id,
    required this.name,
    required this.committedReviewMinutes,
    required this.reviewOwner,
  });

  factory Ward.fromMap(Map<String, dynamic> m) => Ward(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        committedReviewMinutes:
            (m['committedReviewMinutes'] as num?)?.toInt() ?? 30,
        reviewOwner: m['reviewOwner'] as String? ?? '',
      );
}

/// invitations/{phoneE164} — accounts exist by invitation only (§5, §11).
/// The dashboard creates these; the first OTP sign-in claims one. The rules
/// let a claim fill ONLY `claimedBy`, once.
class Invitation {
  final String phone;
  final String name;
  final String role;
  final String signatureIdentity;
  final String invitedBy;
  final String? claimedBy;

  const Invitation({
    required this.phone,
    required this.name,
    required this.role,
    required this.signatureIdentity,
    required this.invitedBy,
    required this.claimedBy,
  });

  factory Invitation.fromMap(Map<String, dynamic> m) => Invitation(
        phone: m['phone'] as String? ?? '',
        name: m['name'] as String? ?? '',
        role: m['role'] as String? ?? 'nurse',
        signatureIdentity: m['signatureIdentity'] as String? ?? '',
        invitedBy: m['invitedBy'] as String? ?? '',
        claimedBy: m['claimedBy'] as String?,
      );
}

class TemplateVersionData {
  final int version;
  final List<Map<String, dynamic>> fields;
  final String editedBy;
  final int at;

  const TemplateVersionData({
    required this.version,
    required this.fields,
    required this.editedBy,
    required this.at,
  });

  factory TemplateVersionData.fromMap(Map<String, dynamic> m) =>
      TemplateVersionData(
        version: (m['version'] as num?)?.toInt() ?? 1,
        fields: (m['fields'] as List<dynamic>? ?? const [])
            .map((f) => (f as Map).cast<String, dynamic>())
            .toList(),
        editedBy: m['editedBy'] as String? ?? '',
        at: (m['at'] as num?)?.toInt() ?? 0,
      );
}
