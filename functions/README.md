# /functions — Firebase Functions (seam only)

**Nothing here is deployed.** This directory exists to hold the Firebase seam described in
`docs/architecture.md` (R-003): the demo runs entirely on `LocalStore` from `@afia/core`.

When the project moves toward a real deployment:

1. Choose the Firebase region **deliberately** — it determines the applicable data-protection
   regime and is effectively permanent (HANDOFF §8).
2. Implement `FirestoreStore implements DataStore` (same interface as `LocalStore`).
3. Export acknowledgement (`confirmed_in_system`) must come from a **positive acknowledgement**
   by the receiving system, never local send-completion (HANDOFF §5).

The accurate phrase for the current state is **Firebase-ready**, not Firebase-integrated.
