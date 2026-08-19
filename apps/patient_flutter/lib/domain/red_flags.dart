/// HANDOFF §2.7 — Emergency escalation is local and deterministic.
///
/// Red-flag evaluation is a pure function with zero I/O: no network call, no
/// model inference, no server round-trip, no import of any networked code.
/// It must produce identical output in airplane mode — that property is a
/// test case (T-007 mirror in test/domain_test.dart).
///
/// The questions themselves are BUNDLED AT BUILD, in both languages, for the
/// same reason the emergency numbers are: fetching a safety question from a
/// server puts the network in the escalation path, which §2.7 forbids. The
/// question ids match the seeded `redFlagQuestions` collection so the
/// dashboard and nurse views correlate answers to the configured rules.
library;

import 'answer.dart';

class RedFlagQuestion {
  final String id;
  final String textEn;
  final String textAr;
  const RedFlagQuestion(
      {required this.id, required this.textEn, required this.textAr});

  String text(String languageCode) => languageCode == 'ar' ? textAr : textEn;
}

class RedFlagAnswer {
  final String questionId;
  final AnswerState answer;
  const RedFlagAnswer({required this.questionId, required this.answer});

  Map<String, dynamic> toMap() => {'questionId': questionId, 'answer': answer.wire};

  factory RedFlagAnswer.fromMap(Map<String, dynamic> m) => RedFlagAnswer(
        questionId: m['questionId'] as String,
        answer: AnswerState.parse(m['answer'] as String? ?? 'NOT_ASKED'),
      );
}

class RedFlagResult {
  /// True iff at least one question is answered YES.
  final bool triggered;

  /// Question ids answered YES.
  final List<String> triggeredBy;

  /// Question ids left UNKNOWN or NOT_ASKED. Listed, never coerced to NO
  /// (§2.2). Unanswered questions do not trigger, and they never reduce
  /// whatever priority the case already has.
  final List<String> unanswered;

  const RedFlagResult(
      {required this.triggered,
      required this.triggeredBy,
      required this.unanswered});

  Map<String, dynamic> toMap() => {
        'triggered': triggered,
        'triggeredBy': triggeredBy,
        'unanswered': unanswered,
      };

  factory RedFlagResult.fromMap(Map<String, dynamic> m) => RedFlagResult(
        triggered: m['triggered'] as bool? ?? false,
        triggeredBy:
            (m['triggeredBy'] as List<dynamic>? ?? const []).cast<String>(),
        unanswered:
            (m['unanswered'] as List<dynamic>? ?? const []).cast<String>(),
      );
}

RedFlagResult evaluateRedFlags(
  List<RedFlagQuestion> questions,
  List<RedFlagAnswer> answers,
) {
  final byId = <String, AnswerState>{
    for (final a in answers) a.questionId: a.answer,
  };
  final triggeredBy = <String>[];
  final unanswered = <String>[];
  for (final q in questions) {
    final answer = byId[q.id] ?? AnswerState.notAsked;
    if (answer == AnswerState.yes) {
      triggeredBy.add(q.id);
    } else if (isUnanswered(answer)) {
      unanswered.add(q.id);
    }
  }
  return RedFlagResult(
    triggered: triggeredBy.isNotEmpty,
    triggeredBy: triggeredBy,
    unanswered: unanswered,
  );
}

/// HANDOFF §2.7 — emergency numbers are bundled at install, never fetched.
/// Bahrain (deployment jurisdiction, Firestore region me-central2):
/// 999 = unified emergency (ambulance/police/fire) · 444 = Ministry of
/// Health advice line. Mirrors packages/rules/src/redFlags.ts.
class EmergencyNumbers {
  static const String emergency = '999';
  static const String urgentAdvice = '444';
}

/// Functional questions carry the same bundled-bilingual shape.
class FunctionalQuestion {
  final String id;
  final String textEn;
  final String textAr;
  const FunctionalQuestion(
      {required this.id, required this.textEn, required this.textAr});

  String text(String languageCode) => languageCode == 'ar' ? textAr : textEn;
}

class FunctionalAnswer {
  final String questionId;
  final FunctionalValue value;
  const FunctionalAnswer({required this.questionId, required this.value});

  Map<String, dynamic> toMap() => {'questionId': questionId, 'value': value.wire};

  factory FunctionalAnswer.fromMap(Map<String, dynamic> m) => FunctionalAnswer(
        questionId: m['questionId'] as String,
        value: FunctionalValue.parse(m['value'] as String? ?? 'NOT_ASKED'),
      );
}

/// Deterministic, configured escalation from the patient's own answers —
/// this is the patient's information raising urgency (§2.1 allows raising),
/// not a model judging severity (§4.3 forbids that). Returns the floor
/// priority the answers justify; the caller merges it with escalate(),
/// which can only raise. UNKNOWN contributes nothing — it never reduces and
/// never raises.
enum FunctionalEscalation { none, elevated }

FunctionalEscalation functionalEscalation(List<FunctionalAnswer> answers) =>
    answers.any((a) => a.value == FunctionalValue.muchWorse)
        ? FunctionalEscalation.elevated
        : FunctionalEscalation.none;

/// The five configured red-flag questions (ids mirror packages/core seed —
/// the dashboard's rule records carry the approval trail for these ids).
const List<RedFlagQuestion> bundledRedFlagQuestions = [
  RedFlagQuestion(
    id: 'rf-chest-pain',
    textEn: 'Do you have chest pain or chest pressure right now?',
    textAr: 'هل تشعر الآن بألم أو ضغط في الصدر؟',
  ),
  RedFlagQuestion(
    id: 'rf-breathless',
    textEn: 'Are you so breathless you cannot finish a sentence?',
    textAr: 'هل ضيق التنفس لديك شديد لدرجة أنك لا تستطيع إكمال جملة؟',
  ),
  RedFlagQuestion(
    id: 'rf-bleeding',
    textEn: 'Do you have bleeding that will not stop?',
    textAr: 'هل لديك نزيف لا يتوقف؟',
  ),
  RedFlagQuestion(
    id: 'rf-confusion',
    textEn: 'Has someone with you become confused or hard to wake?',
    textAr: 'هل أصبح شخص معك مشوّشاً أو يصعب إيقاظه؟',
  ),
  RedFlagQuestion(
    id: 'rf-faint',
    textEn: 'Have you fainted or blacked out today?',
    textAr: 'هل أُغمي عليك أو فقدت الوعي اليوم؟',
  ),
];

/// The four configured baseline-anchored functional questions.
const List<FunctionalQuestion> bundledFunctionalQuestions = [
  FunctionalQuestion(
    id: 'fn-eating',
    textEn: 'Compared with your normal, how is your eating and drinking?',
    textAr: 'مقارنةً بوضعك المعتاد، كيف هو أكلك وشربك؟',
  ),
  FunctionalQuestion(
    id: 'fn-mobility',
    textEn: 'Compared with your normal, how is your moving around?',
    textAr: 'مقارنةً بوضعك المعتاد، كيف هي حركتك وتنقلك؟',
  ),
  FunctionalQuestion(
    id: 'fn-breathing',
    textEn: 'Compared with your normal, how is your breathing?',
    textAr: 'مقارنةً بوضعك المعتاد، كيف هو تنفسك؟',
  ),
  FunctionalQuestion(
    id: 'fn-sleep',
    textEn: 'Compared with your normal, how are you sleeping?',
    textAr: 'مقارنةً بوضعك المعتاد، كيف هو نومك؟',
  ),
];
