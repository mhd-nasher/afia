/**
 * HANDOFF §2.8 — Gap detection is rules, not a model.
 *
 * "Is the medication field empty?" is a schema check against the configured
 * template: deterministic, unit-testable, reproducible, auditable.
 *
 * HANDOFF §4.3 — output wording is neutral. "Not mentioned: X", never
 * "Critical information missing": ranking which omission matters is a
 * clinical judgement, and this system never makes one.
 */

export interface TemplateField {
  id: string
  label: string
  required: boolean
  /** Routing keywords used by the (swappable) structurer. Config data, not logic. */
  keywords: string[]
}

export interface FieldContent {
  fieldId: string
  text: string
}

export interface OmissionFlag {
  fieldId: string
  label: string
  /** Always the neutral form: `Not mentioned: ${label}`. */
  message: string
}

export function detectGaps(
  template: readonly TemplateField[],
  contents: readonly FieldContent[],
): OmissionFlag[] {
  const filled = new Map<string, string>()
  for (const c of contents) filled.set(c.fieldId, c.text)

  const flags: OmissionFlag[] = []
  // Template order, not importance order — importance is a clinical judgement.
  for (const field of template) {
    if (!field.required) continue
    const text = filled.get(field.id)
    if (text === undefined || text.trim() === '') {
      flags.push({
        fieldId: field.id,
        label: field.label,
        message: `Not mentioned: ${field.label}`,
      })
    }
  }
  return flags
}

/** Share of template fields with any content, 0..1 — the queue's second sort key. */
export function fileCompleteness(
  template: readonly TemplateField[],
  contents: readonly FieldContent[],
): number {
  if (template.length === 0) return 1
  const filled = new Set(
    contents.filter((c) => c.text.trim() !== '').map((c) => c.fieldId),
  )
  const covered = template.filter((f) => filled.has(f.id)).length
  return covered / template.length
}
