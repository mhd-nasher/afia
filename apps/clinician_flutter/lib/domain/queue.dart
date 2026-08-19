/// HANDOFF §2.10 — the queue is never risk-ordered. Dart mirror of
/// packages/rules/src/queue.ts: entries carry ONLY arrival time and file
/// completeness — a risk sort cannot even be expressed through this API.
library;

class QueueEntry {
  final String id;

  /// Epoch ms the file arrived. Earlier = waited longer.
  final int receivedAt;

  /// 0..1 — share of the file with recorded content.
  final double completeness;

  const QueueEntry(
      {required this.id, required this.receivedAt, required this.completeness});
}

/// Longest wait first; among equal waits, more complete files first (they can
/// be reviewed immediately); id as the final deterministic tie-break.
List<T> orderQueue<T extends QueueEntry>(List<T> entries) {
  final sorted = [...entries]..sort((a, b) {
      final byWait = a.receivedAt.compareTo(b.receivedAt);
      if (byWait != 0) return byWait;
      final byCompleteness = b.completeness.compareTo(a.completeness);
      if (byCompleteness != 0) return byCompleteness;
      return a.id.compareTo(b.id);
    });
  return sorted;
}

/// The sort order, stated on screen and inside every tool output that lists
/// the queue (HANDOFF §2.10 / D-013).
const String queueSortStatement =
    'Sorted by wait time, then file completeness. Never by clinical risk.';
