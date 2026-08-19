import { useState, type ReactNode } from 'react'
import type { ApprovalRecord, FunctionalQuestion, RedFlagQuestion } from '@afia/rules'
import { actorName, fmtDateTime } from '../lib'
import { store } from '../store'
import { useManager } from '../session'

/**
 * Questions — every clinical rule carries an approval record (HANDOFF §7,
 * F-073). Editing a red-flag question opens a confirmation dialog that
 * REQUIRES the approver's name and role before Save enables; saving a changed
 * red-flag rule without a named approver is impossible in this UI.
 */

function ApprovalLine({ approval }: { approval: ApprovalRecord | null }): ReactNode {
  if (approval === null) {
    return (
      <div className="rule-approval">This rule has no governance approval on record.</div>
    )
  }
  return (
    <div className="rule-approval">
      Approved by {approval.approvedBy} · {approval.role} ·{' '}
      <span className="num">{fmtDateTime(approval.approvedAt)}</span>
    </div>
  )
}

function RuleRow({
  question,
  onEdit,
}: {
  question: RedFlagQuestion | FunctionalQuestion
  onEdit?: (() => void) | undefined
}): ReactNode {
  const unapproved = question.approval === null
  return (
    <div className={unapproved ? 'rule-row caution' : 'rule-row'}>
      <div className="rule-head">
        <span className="rule-text">{question.text}</span>
        <span style={{ display: 'flex', gap: 10, alignItems: 'center', flex: 'none' }}>
          {unapproved && <span className="awaiting">awaiting clinical approval</span>}
          {onEdit !== undefined && (
            <button className="btn btn-sm" onClick={onEdit}>
              Edit
            </button>
          )}
        </span>
      </div>
      <ApprovalLine approval={question.approval} />
    </div>
  )
}

/** The red-flag edit confirmation — approver name and role are mandatory. */
function RedFlagEditDialog({
  question,
  onClose,
}: {
  question: RedFlagQuestion
  onClose: () => void
}): ReactNode {
  const manager = useManager()
  const [text, setText] = useState(question.text)
  const [approverName, setApproverName] = useState('')
  const [approverRole, setApproverRole] = useState('')

  const canSave =
    text.trim() !== '' && approverName.trim() !== '' && approverRole.trim() !== ''

  const save = (): void => {
    if (!canSave) return
    store.saveRedFlagQuestion(
      {
        ...question,
        text: text.trim(),
        approval: {
          approvedBy: approverName.trim(),
          role: approverRole.trim(),
          approvedAt: Date.now(),
        },
      },
      manager.name,
    )
    onClose()
  }

  return (
    <div className="modal-overlay" role="dialog" aria-modal="true" aria-label="Edit red-flag rule">
      <div className="modal">
        <h3>Edit red-flag rule</h3>
        <p className="modal-caption">
          This rule is evaluated on patients&apos; devices and can trigger the
          emergency interrupt. A changed rule cannot be saved without a named
          clinical approver — there is no way around this.
        </p>
        <span>
          <span className="field-label">Question text</span>
          <textarea
            className="input"
            rows={2}
            value={text}
            onChange={(e) => setText(e.target.value)}
          />
        </span>
        <div className="modal-grid">
          <span>
            <span className="field-label">Approver name — required</span>
            <input
              className="input input-sm"
              placeholder="e.g. Dr T. Mensah"
              value={approverName}
              onChange={(e) => setApproverName(e.target.value)}
            />
          </span>
          <span>
            <span className="field-label">Approver role — required</span>
            <input
              className="input input-sm"
              placeholder="e.g. Clinical Governance Lead"
              value={approverRole}
              onChange={(e) => setApproverRole(e.target.value)}
            />
          </span>
        </div>
        <div className="modal-actions">
          <button className="btn btn-primary" onClick={save} disabled={!canSave}>
            Save with approval
          </button>
          <button className="btn" onClick={onClose}>
            Cancel
          </button>
        </div>
      </div>
    </div>
  )
}

type Tab = 'red' | 'functional' | 'gaps'

export function Questions(): ReactNode {
  const [tab, setTab] = useState<Tab>('red')
  const [editingId, setEditingId] = useState<string | null>(null)

  const redFlags = store.redFlagQuestions()
  const functional = store.functionalQuestions()
  const gapRules = store.template().filter((f) => f.required)
  const latestVersion = store.templateVersions()[store.templateVersions().length - 1]
  const editing = redFlags.find((q) => q.id === editingId)

  const ruleHistory = store
    .auditTrail()
    .filter((e) => e.action === 'rule_edited' || e.action === 'template_edited')
    .slice()
    .reverse()

  return (
    <>
      <h1 className="page-title">Questions</h1>
      <p className="page-caption">
        The clinical rules the platform evaluates — red flags, functional baseline
        questions, and gap rules. Every rule shows who approved it; unapproved rules
        carry a caution state.
      </p>

      <section className="panel">
        <div className="tabs" role="tablist">
          <button
            className={tab === 'red' ? 'tab active' : 'tab'}
            role="tab"
            aria-selected={tab === 'red'}
            onClick={() => setTab('red')}
          >
            Red flags
          </button>
          <button
            className={tab === 'functional' ? 'tab active' : 'tab'}
            role="tab"
            aria-selected={tab === 'functional'}
            onClick={() => setTab('functional')}
          >
            Functional questions
          </button>
          <button
            className={tab === 'gaps' ? 'tab active' : 'tab'}
            role="tab"
            aria-selected={tab === 'gaps'}
            onClick={() => setTab('gaps')}
          >
            Gap rules
          </button>
        </div>

        {tab === 'red' && (
          <>
            <p className="panel-caption">
              Evaluated locally on the patient&apos;s device, deterministically — a YES
              triggers the emergency interrupt. Editing a rule requires a named approver.
            </p>
            {redFlags.map((q) => (
              <RuleRow key={q.id} question={q} onEdit={() => setEditingId(q.id)} />
            ))}
          </>
        )}

        {tab === 'functional' && (
          <>
            <p className="panel-caption">
              Baseline-anchored questions from the patient app — always compared with
              the patient&apos;s own normal.
            </p>
            {functional.map((q) => (
              <RuleRow key={q.id} question={q} />
            ))}
          </>
        )}

        {tab === 'gaps' && (
          <>
            <p className="panel-caption">
              One rule per required template field: &quot;Not mentioned: X&quot; when
              the field is empty. Deterministic schema checks, never a model — edit in
              Templates.
            </p>
            {gapRules.map((f) => (
              <div className="rule-row" key={f.id}>
                <div className="rule-head">
                  <span className="rule-text">Not mentioned: {f.label}</span>
                  <span className="status-neutral">read-only — edit in Templates</span>
                </div>
                <div className="rule-approval">
                  {latestVersion !== undefined ? (
                    <>
                      From template <span className="num">v{latestVersion.version}</span> —
                      edited by {latestVersion.editedBy} ·{' '}
                      <span className="num">{fmtDateTime(latestVersion.at)}</span>
                    </>
                  ) : (
                    'No template version on record.'
                  )}
                </div>
              </div>
            ))}
          </>
        )}
      </section>

      <section className="panel">
        <h2>Rule change history</h2>
        <p className="panel-caption">
          Every rule and template edit, append-only — clinical rules are
          reconstructable to any past date from this record and the version table.
        </p>
        {ruleHistory.length === 0 ? (
          <p className="empty-note">No rule changes recorded.</p>
        ) : (
          <table className="data">
            <thead>
              <tr>
                <th>Time</th>
                <th>Actor</th>
                <th>Change</th>
                <th>Detail</th>
              </tr>
            </thead>
            <tbody>
              {ruleHistory.map((e) => (
                <tr key={e.id}>
                  <td className="num">{fmtDateTime(e.at)}</td>
                  <td>{actorName(e.actor)}</td>
                  <td className="mono">{e.entityId}</td>
                  <td>{e.detail ?? '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      {editing !== undefined && (
        <RedFlagEditDialog question={editing} onClose={() => setEditingId(null)} />
      )}
    </>
  )
}
