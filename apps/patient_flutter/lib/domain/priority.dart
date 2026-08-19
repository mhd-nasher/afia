/// HANDOFF §2.1 — Escalation is one-way.
///
/// escalate() is the ONLY function in this app that changes a priority, and
/// it is monotonic: it returns the higher of the two values. There is no
/// decreasePriority, no markAsNormal, no reset. A downgrade cannot be
/// expressed through this module — and the deployed firestore.rules reject
/// any write that lowers a case priority, so the constraint holds even
/// against a modified client.
library;

enum Priority {
  routine('routine', 0),
  elevated('elevated', 1),
  urgent('urgent', 2);

  final String wire;
  final int rank;
  const Priority(this.wire, this.rank);

  static Priority parse(String wire) => Priority.values.firstWhere(
        (p) => p.wire == wire,
        // Unrecognised priority never silently downgrades a record.
        orElse: () => Priority.urgent,
      );
}

Priority escalate(Priority current, Priority proposed) =>
    proposed.rank > current.rank ? proposed : current;
