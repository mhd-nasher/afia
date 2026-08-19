# Patient App — design principles (captured from the Claude Design project page)

> Captured 2026-08-19 from `Patient App.dc.html`'s intro on the design canvas.
> The full rendered file exports with the project archive
> (designs/afia-patient-design.html once downloaded). HANDOFF.md §6 remains the
> functional spec; these are the visual/tonal laws the design adds.

**The counterpart to the clinician app, inverted in every way that matters.**
Warm, never clinical — because this is opened once, alone, in fright.
One question, one action, one screen. No tab bar, no progress, no assessment.
Ubiquity belongs to safety: only Emergency is always present, in the same place on every screen.

```
390 × 844 · 64px targets · 17px body floor · red on ONE screen only ·
periwinkle = machine-made, unverified
```

## 00 · Emergency control — a fixture, not a screen

- 64px · top right · above the keyboard and above the recording UI.
- **Not red.** Red is spent entirely on the interrupt screen, so the first time
  this person sees red it means something absolute.
- Works before an account exists and without connectivity.

## 01 · Entry — a door, not a hub

- Two states shown: FIRST OPEN, and WITH AN UNFINISHED DESCRIPTION (resume path).
- Warm light palette (cream surfaces, dark warm ink), mono clock, Emergency fixture top-right.

## Tweakable props (design-level constants)

- `nurseLine` (design showed 0800 123 4567 — UK placeholder; our deployment is Bahrain: 444 MOH health line)
- `emergencyNumber` (design showed 999 — matches Bahrain's unified 999)
- `sentAt` timestamp shown on the status screen.

## Notes for implementation

- The four design pages mirror the clinician file's structure (screens laid out on a 390×844 canvas, dark/light variants where relevant).
- Same IBM Plex family; the patient app leans warm/light where the clinician app is dark-first.
- Mandatory status-screen copy from HANDOFF §6 is non-negotiable and must appear verbatim (translated for AR).
