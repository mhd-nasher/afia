/// HANDOFF §2.8 — Gap detection is rules, not a model.
///
/// "Is the medication field empty?" is a schema check against the configured
/// template: deterministic, unit-testable, reproducible, auditable.
///
/// HANDOFF §4.3 — output wording is neutral. "Not mentioned: X", never
/// "Critical information missing": ranking which omission matters is a
/// clinical judgement, and this system never makes one.
/// Dart mirror of packages/rules/src/gaps.ts.
library;

class TemplateField {
  final String id;
  final String label;
  final bool required;

  /// Routing keywords used by the (swappable) structurer. Config data, not logic.
  final List<String> keywords;

  const TemplateField({
    required this.id,
    required this.label,
    required this.required,
    required this.keywords,
  });

  factory TemplateField.fromMap(Map<String, dynamic> m) => TemplateField(
        id: m['id'] as String,
        label: m['label'] as String,
        required: m['required'] as bool? ?? false,
        keywords: (m['keywords'] as List<dynamic>? ?? const []).cast<String>(),
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'label': label, 'required': required, 'keywords': keywords};
}

class FieldContent {
  final String fieldId;
  final String text;

  const FieldContent({required this.fieldId, required this.text});

  factory FieldContent.fromMap(Map<String, dynamic> m) => FieldContent(
      fieldId: m['fieldId'] as String, text: m['text'] as String? ?? '');

  Map<String, dynamic> toMap() => {'fieldId': fieldId, 'text': text};
}

class OmissionFlagData {
  final String fieldId;
  final String label;

  /// Always the neutral form: `Not mentioned: $label`.
  final String message;

  const OmissionFlagData(
      {required this.fieldId, required this.label, required this.message});
}

List<OmissionFlagData> detectGaps(
    List<TemplateField> template, List<FieldContent> contents) {
  final filled = {for (final c in contents) c.fieldId: c.text};

  final flags = <OmissionFlagData>[];
  // Template order, not importance order — importance is a clinical judgement.
  for (final field in template) {
    if (!field.required) continue;
    final text = filled[field.id];
    if (text == null || text.trim().isEmpty) {
      flags.add(OmissionFlagData(
        fieldId: field.id,
        label: field.label,
        message: 'Not mentioned: ${field.label}',
      ));
    }
  }
  return flags;
}

/// Share of template fields with any content, 0..1.
double fileCompleteness(
    List<TemplateField> template, List<FieldContent> contents) {
  if (template.isEmpty) return 1;
  final filled = contents
      .where((c) => c.text.trim().isNotEmpty)
      .map((c) => c.fieldId)
      .toSet();
  final covered = template.where((f) => filled.contains(f.id)).length;
  return covered / template.length;
}
