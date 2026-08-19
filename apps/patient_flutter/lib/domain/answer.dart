/// HANDOFF §2.2 — Absent is not normal.
///
/// Missing, skipped, unanswered, or low-confidence data is UNKNOWN — a
/// distinct value from a normal reading and from a negative answer. UNKNOWN
/// is never coerced to NO or to a default, and UNKNOWN never reduces
/// priority. Wire strings mirror packages/rules/src/answer.ts exactly so all
/// three surfaces read the same Firestore documents.
library;

enum AnswerState {
  yes('YES'),
  no('NO'),
  unknown('UNKNOWN'),
  notAsked('NOT_ASKED');

  final String wire;
  const AnswerState(this.wire);

  static AnswerState parse(String wire) => AnswerState.values.firstWhere(
        (v) => v.wire == wire,
        // A value this app does not recognise is UNANSWERED, never "no".
        orElse: () => AnswerState.unknown,
      );
}

bool isAffirmative(AnswerState a) => a == AnswerState.yes;

/// UNKNOWN and NOT_ASKED are "unanswered", which is not the same as "no".
/// There is deliberately no isNegative() helper that lumps UNKNOWN with NO —
/// that helper is the code path §2.2 forbids.
bool isUnanswered(AnswerState a) =>
    a == AnswerState.unknown || a == AnswerState.notAsked;

/// Baseline-anchored functional answers (patient app, HANDOFF §6).
/// "I don't know" is first-class and stored as UNKNOWN.
enum FunctionalValue {
  sameAsNormal('SAME_AS_NORMAL'),
  worse('WORSE'),
  muchWorse('MUCH_WORSE'),
  unknown('UNKNOWN'),
  notAsked('NOT_ASKED');

  final String wire;
  const FunctionalValue(this.wire);

  static FunctionalValue parse(String wire) => FunctionalValue.values.firstWhere(
        (v) => v.wire == wire,
        orElse: () => FunctionalValue.unknown,
      );
}
