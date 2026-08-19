/// HANDOFF §2.1 — Escalation is one-way.
///
/// [escalate] is the ONLY function in this app that changes a priority, and
/// it is monotonic: it returns the higher of the two values. There is no
/// decreasePriority, no markAsNormal, no reset. A downgrade cannot be
/// expressed through this module — which is the point.
library;

enum Priority { routine, elevated, urgent }

const Map<Priority, int> _rank = {
  Priority.routine: 0,
  Priority.elevated: 1,
  Priority.urgent: 2,
};

Priority escalate(Priority current, Priority proposed) =>
    _rank[proposed]! > _rank[current]! ? proposed : current;

int priorityRank(Priority p) => _rank[p]!;

extension PriorityWire on Priority {
  String get wire => name; // 'routine' | 'elevated' | 'urgent' — same as TS.
  static Priority parse(String wire) =>
      Priority.values.firstWhere((p) => p.name == wire,
          orElse: () => Priority.urgent); // unknown input never lowers (§2.2)
}
