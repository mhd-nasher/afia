# Admin Dashboard — UI Build Prompt (captured from the Claude Design project)

> The authoritative design brief for `Admin Dashboard.dc.html`. Desktop web, 1440px.
> Captured 2026-08-19 from the design project chat. The rendered .dc.html file
> is in the project archive (designs/afia-dashboard-design.html once exported).

## Who this is for

A nursing manager or clinical lead, seated at a desk, on a large screen, unhurried. They are looking for patterns and problems, not for individual patients. Density relaxes, but sobriety does not — clinical infrastructure, never a consumer analytics product.

## What this dashboard is and is not

🔒 **It is not in the clinical path.** A patient's file goes to the nurse directly. The dashboard never relays, routes, or gates anything. It observes and it configures.

**It exists to answer one question:** is the system doing what it promised, and where is it failing?

The most important thing on it is not a chart. It is a **review-time breach alert** — because the entire product depends on "a nurse will review this" being true, and this dashboard is the only place that can prove it.

## Visual language

Sober, structured, quiet. Bordered rows over cards. No shadows, no gradients, no rounded consumer styling.

```
canvas #F7F7F5   text-primary #1A2438
surface #FFFFFF  text-secondary #5A6478
border #E2DFD9   text-muted #8A9099

action #2D4A8A   accent #7B6FD4
critical #C0392B caution #B8730C stable #1E8449
```

**Typography:** IBM Plex Sans, IBM Plex Mono. Two weights only, 400 and 500. Three text tones only.

🔒 Every number in tabular mono. Counts, durations, timestamps, percentages.
🔒 The clinical trio is reserved. Never as chart series, never as category colours, never decoratively. Chart categories use indigo tints only.
🔒 System failure is not a colour. Export failures and integration outages use a full-width inverted banner — filled dark background, icon, plain language, action. Never clinical red.

**Charts:** lines and bars only. No gauges, no donuts, no radial meters, no gradients, no sparkline decoration.

## Layout

Left sidebar navigation, fixed. Six sections: Live · Templates · Questions · Users · Wards · Quality.

## 1 · Live — the operational screen (default landing)

- Top row — four metric tiles, large mono numbers: files awaiting review · longest current wait · signed but not confirmed in hospital system · export failures today.
- ⚠️ Breach panel directly beneath, unmissable: any file waiting longer than the committed review time. Inverted banner. Wait duration in mono, the ward, how far past commitment. If none: states so plainly — it never disappears (absence would be indistinguishable from a broken query).
- Incoming queue table: received time · ward · source (patient or caregiver) · completeness · wait duration · review state. 🔒 Ordered by wait time only, with a visible label stating the sort order.
- Export failures table: handover · ward · signed at · failure reason · retry action.
- System state strip: transcription service · export integration · last successful sync, each with a timestamp.

## 2 · Templates — the customisation showpiece

Left: list of templates (SBAR handover, ward variants, department overrides; which wards use each). Centre: field builder — drag to reorder, add, remove, rename; field types text/number/drug/date/list; required marker. Right: live preview of the clinician app. Beneath: version history with who/when and restore. ⚠️ Show an unsaved-change state with which wards it affects.

## 3 · Questions and rules — governed customisation

Three tabs: Red flags · Functional questions · Gap rules. Each rule: text, status, last reviewed.
🔒 Every clinical rule carries a governance row: approved by, role, date, note. Unapproved → caution state + `awaiting clinical approval` label.
🔒 Editing a red-flag rule opens a confirmation requiring the approver's name and role (the single most persuasive detail for a clinical audience).
Version history — clinical rules must be reconstructable to any past date.

## 4 · Users

Table: name · role · ward · signature identity · status · last sign-in. Roles: ward nurse · triage nurse · nursing manager · template owner · IT admin.
Invite panel — email, role, ward. Accounts are never self-created.
🔒 Signature identity read-only with a lock indicator + note (fixed at account creation; appears on every legal signature).
Sign-in log — device, time, ward (shared ward devices → safety record).
🔒 No performance metrics of any kind + a visible line stating the system does not track individual performance.

## 5 · Wards and configuration

Wards list — name, bed count, active template, assigned staff count. Shift patterns per ward. Formulary — searchable, sound-alike pairs marked, import and edit. ⚠️ Review-time commitment — committed max review time per ward + named owner, prominent (the setting the Live breach alert measures against).

## 6 · Quality

Most frequently missing information (bar, indigo tints — closes the template-revision loop) · drug correction rate over time (line; rising = transcription degradation) · committed vs actual review time (line, two series — the single most important chart) · export success rate (line) · audit log (searchable, filterable, exportable; every rule/template/role/export event with actor + timestamp).
🔒 All charts aggregate. Ward-level at the finest grain. Never individual.

## Also show

Breach alert active with two files past commitment · an export failure banner · the red-flag edit confirmation dialog with approver field · Live empty state.

## Do not build

Any individual staff metric · leaderboards or rankings · staff mood data linked to identity · patient severity scoring · case prioritisation or ordering by risk · clinical content editing from the dashboard · gauges, donuts, radial charts · gradients · shadows · notification settings · a chat or messaging feature.

## Acceptance test

- [ ] Live is the landing screen and the breach panel is impossible to miss
- [ ] The queue's sort order is stated on screen and is wait-time only
- [ ] Every number is tabular mono
- [ ] No clinical colour appears as a chart series
- [ ] Export failure uses an inverted banner, never red
- [ ] Every clinical rule shows who approved it and when
- [ ] Signature identity is visibly locked
- [ ] No individual performance data appears anywhere
- [ ] Exactly two text weights and three text tones throughout
