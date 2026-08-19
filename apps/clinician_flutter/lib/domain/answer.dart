/// HANDOFF §2.2 — Absent is not normal.
///
/// Missing, skipped, unanswered, or low-confidence data is UNKNOWN — a
/// distinct value from a normal reading and from a negative answer. UNKNOWN
/// is never coerced to NO or to a default, and UNKNOWN never reduces
/// priority. Mirrors packages/core (@afia/rules answer.ts) exactly.
library;

enum AnswerState { yes, no, unknown, notAsked }

/// Wire values match the TS core ('YES' | 'NO' | 'UNKNOWN' | 'NOT_ASKED').
extension AnswerStateWire on AnswerState {
  String get wire => switch (this) {
        AnswerState.yes => 'YES',
        AnswerState.no => 'NO',
        AnswerState.unknown => 'UNKNOWN',
        AnswerState.notAsked => 'NOT_ASKED',
      };

  static AnswerState parse(String wire) => switch (wire) {
        'YES' => AnswerState.yes,
        'NO' => AnswerState.no,
        'UNKNOWN' => AnswerState.unknown,
        'NOT_ASKED' => AnswerState.notAsked,
        // Anything unrecognised is UNKNOWN — never a default of NO (§2.2).
        _ => AnswerState.unknown,
      };
}

bool isAffirmative(AnswerState a) => a == AnswerState.yes;

/// UNKNOWN and NOT_ASKED are "unanswered", which is not the same as "no".
/// There is deliberately no isNegative() helper that lumps UNKNOWN with NO —
/// that helper is the code path §2.2 forbids.
bool isUnanswered(AnswerState a) =>
    a == AnswerState.unknown || a == AnswerState.notAsked;
