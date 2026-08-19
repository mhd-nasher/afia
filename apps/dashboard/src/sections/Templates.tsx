import { useState, type ReactNode } from 'react'
import type { TemplateField } from '@afia/rules'
import { fmtDateTime } from '../lib'
import { store } from '../store'
import { useManager } from '../session'

/**
 * Templates — visual field builder with a live clinician preview, versioned
 * with attribution (HANDOFF §7, F-072). Saves are attributed to the signed-in
 * manager. An unsaved-change state names the wards the change will affect.
 */

interface EditableField {
  id: string
  label: string
  required: boolean
  /** Raw comma-separated text while editing; parsed on save. */
  keywordsText: string
}

function toEditable(fields: readonly TemplateField[]): EditableField[] {
  return fields.map((f) => ({
    id: f.id,
    label: f.label,
    required: f.required,
    keywordsText: f.keywords.join(', '),
  }))
}

function toTemplateFields(fields: readonly EditableField[]): TemplateField[] {
  return fields.map((f) => ({
    id: f.id,
    label: f.label,
    required: f.required,
    keywords: f.keywordsText
      .split(',')
      .map((k) => k.trim())
      .filter((k) => k !== ''),
  }))
}

export function Templates(): ReactNode {
  const manager = useManager()
  const [fields, setFields] = useState<EditableField[]>(() =>
    toEditable(store.template()),
  )
  const [savedMsg, setSavedMsg] = useState<string | null>(null)

  // Canonical shape for comparison — Firestore returns map keys in its own
  // order, so a plain JSON comparison would report phantom unsaved changes.
  const canon = (fs: readonly TemplateField[]): string =>
    JSON.stringify(fs.map((f) => [f.id, f.label, f.required, f.keywords.join(',')]))
  const dirty = canon(toTemplateFields(fields)) !== canon(store.template())
  const affectedWards = store
    .wards()
    .map((w) => w.name)
    .join(' · ')

  const patch = (id: string, change: Partial<EditableField>): void => {
    setSavedMsg(null)
    setFields((prev) => prev.map((f) => (f.id === id ? { ...f, ...change } : f)))
  }

  const move = (index: number, dir: -1 | 1): void => {
    setSavedMsg(null)
    setFields((prev) => {
      const j = index + dir
      if (j < 0 || j >= prev.length) return prev
      const a = prev[index]
      const b = prev[j]
      if (a === undefined || b === undefined) return prev
      const next = [...prev]
      next[index] = b
      next[j] = a
      return next
    })
  }

  const addField = (): void => {
    setSavedMsg(null)
    setFields((prev) => [
      ...prev,
      {
        id: `field-${Date.now().toString(36)}`,
        label: 'New field',
        required: false,
        keywordsText: '',
      },
    ])
  }

  const removeField = (id: string): void => {
    setSavedMsg(null)
    setFields((prev) => prev.filter((f) => f.id !== id))
  }

  const canSave = fields.length > 0 && dirty
  const save = (): void => {
    if (!canSave) return
    const version = store.saveTemplateVersion(toTemplateFields(fields), manager.name)
    setSavedMsg(`Saved as v${version.version}`)
  }

  const versions = [...store.templateVersions()].reverse()

  return (
    <>
      <h1 className="page-title">Templates</h1>
      <p className="page-caption">
        The handover template the clinician app structures speech into. Every save
        creates a new version with attribution — nothing is edited in place.
      </p>

      <div className="templates-layout">
        <section className="panel">
          <h2>Field builder</h2>
          <p className="panel-caption">
            Reorder, add, remove, rename. Required fields drive gap detection
            (deterministic rules — &quot;Not mentioned: X&quot;, never a judgement of
            importance).
          </p>

          {dirty && (
            <div className="caution-note">
              Unsaved changes — saving publishes a new template version to every
              ward using it: {affectedWards}.
            </div>
          )}

          {fields.map((f, i) => (
            <div className="field-row" key={f.id}>
              <span className="field-move">
                <button
                  className="btn btn-move"
                  onClick={() => move(i, -1)}
                  disabled={i === 0}
                  aria-label={`Move ${f.label} up`}
                >
                  ↑
                </button>
                <button
                  className="btn btn-move"
                  onClick={() => move(i, 1)}
                  disabled={i === fields.length - 1}
                  aria-label={`Move ${f.label} down`}
                >
                  ↓
                </button>
              </span>
              <span>
                <span className="field-label">Label</span>
                <input
                  className="input input-sm"
                  value={f.label}
                  onChange={(e) => patch(f.id, { label: e.target.value })}
                />
              </span>
              <span>
                <span className="field-label">Keywords (comma-separated)</span>
                <input
                  className="input input-sm"
                  value={f.keywordsText}
                  onChange={(e) => patch(f.id, { keywordsText: e.target.value })}
                />
              </span>
              <label className="field-required">
                <input
                  type="checkbox"
                  checked={f.required}
                  onChange={(e) => patch(f.id, { required: e.target.checked })}
                />
                required
              </label>
              <button className="btn btn-sm" onClick={() => removeField(f.id)}>
                Remove
              </button>
            </div>
          ))}

          <div style={{ marginTop: 12 }}>
            <button className="btn" onClick={addField}>
              Add field
            </button>
          </div>

          <div className="save-row">
            <button className="btn btn-primary" onClick={save} disabled={!canSave}>
              Save new version
            </button>
            <span className="save-as">saving as {manager.name}</span>
            {savedMsg !== null && <span className="save-msg">{savedMsg}</span>}
          </div>
        </section>

        <aside>
          <section className="preview" aria-label="Live preview of the clinician draft review">
            <div className="preview-title">Clinician draft review — live preview</div>
            {fields.map((f) => (
              <div className="preview-field" key={f.id}>
                <div className="preview-field-label">
                  <span>{f.label}</span>
                  {f.required && <span className="preview-req">required</span>}
                </div>
                <div className="preview-line" />
                <div className="preview-line short" />
              </div>
            ))}
          </section>
        </aside>
      </div>

      <section className="panel">
        <h2>Versions</h2>
        <p className="panel-caption">Every template change, attributed and dated.</p>
        <table className="data">
          <thead>
            <tr>
              <th>Version</th>
              <th>Edited by</th>
              <th>Date</th>
              <th>Fields</th>
            </tr>
          </thead>
          <tbody>
            {versions.map((v) => (
              <tr key={v.version}>
                <td className="num">v{v.version}</td>
                <td>{v.editedBy}</td>
                <td className="num">{fmtDateTime(v.at)}</td>
                <td>
                  <span className="num">{v.fields.length}</span> (
                  <span className="num">{v.fields.filter((f) => f.required).length}</span>{' '}
                  required)
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </>
  )
}
