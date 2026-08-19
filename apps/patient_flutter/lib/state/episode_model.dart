/// The flow engine. One linear episode, one question per screen, no tab bar,
/// no progress (F-050). Every mutation persists to the device BEFORE it
/// renders (F-055) — no unsaved state exists; reopening resumes exactly.
///
/// Red flags are evaluated LOCALLY after EVERY answer (§2.7 — a pure Dart
/// function, no network, instant, works in airplane mode). A YES shows the
/// emergency interrupt immediately. Going back un-does nothing: the answer
/// stays recorded, and once a case exists its priority is escalated one-way.
library;

import 'package:flutter/foundation.dart';

import '../domain/answer.dart';
import '../domain/episode.dart';
import '../domain/patient_case.dart';
import '../domain/priority.dart';
import '../domain/red_flags.dart';
import '../services/auth_service.dart';
import '../services/case_repo.dart';
import '../services/memory_service.dart';
import '../services/prefs.dart';

/// Why the interrupt is on screen: a red-flag YES (the answer is recorded)
/// or the always-present emergency fixture (nothing was answered).
enum InterruptSource { redFlagYes, fixture }

class EpisodeModel extends ChangeNotifier {
  EpisodeModel._() {
    _episode = EpisodeState.fromJson(Prefs.instance.episodeJson ?? '');
    // Resume variant of the entry door: mid-flow state re-enters through the
    // entry screen ("continue where you left off"), a submitted case goes
    // straight back to status. The auth step never survives a restart —
    // review re-runs the gate when needed.
    if (_episode.step.kind == StepKind.auth) {
      _episode = _episode.copyWith(step: const Step(StepKind.review));
    }
    if (_episode.hasUnfinishedDescription) {
      _resumeTarget = _episode.step;
      _episode = _episode.copyWith(step: const Step(StepKind.entry));
    }
    if (_episode.caseId != null) {
      try {
        CaseRepo.instance.resumeAckWatch(_episode.caseId!);
      } catch (_) {
        // Firebase unavailable (offline first start): the episode and the
        // emergency path never depend on it (§2.7).
      }
    }
  }

  static final EpisodeModel instance = EpisodeModel._();

  late EpisodeState _episode;
  Step? _resumeTarget;
  InterruptSource _interruptSource = InterruptSource.fixture;

  final List<RedFlagQuestion> redFlagQuestions = bundledRedFlagQuestions;
  final List<FunctionalQuestion> functionalQuestions =
      bundledFunctionalQuestions;

  EpisodeState get episode => _episode;
  Step? get resumeTarget => _resumeTarget;
  InterruptSource get interruptSource => _interruptSource;
  bool get hasCase => _episode.caseId != null;

  /// The single write path: persist first, then render (F-055).
  void _update(EpisodeState next) {
    _episode = next;
    Prefs.instance.setEpisodeJson(next.toJson());
    notifyListeners();
  }

  // ── entry ────────────────────────────────────────────────────────────────

  void setName(String v) => _update(_episode.copyWith(name: v));
  void setTerms(bool v) => _update(_episode.copyWith(termsAccepted: v));
  void setConsent(bool v) => _update(_episode.copyWith(consentGiven: v));

  void startEpisode() {
    _resumeTarget = null;
    _update(_episode.copyWith(step: const Step(StepKind.redflag, 0)));
  }

  void resumeEpisode() {
    final target = _resumeTarget ?? const Step(StepKind.redflag, 0);
    _resumeTarget = null;
    _update(_episode.copyWith(step: target));
  }

  void startOver() {
    _resumeTarget = null;
    Prefs.instance.clearEpisode();
    _update(const EpisodeState());
  }

  // ── red flags (initial + condition-changed repeat) ───────────────────────

  void answerRedFlag(String questionId, AnswerState answer) {
    final isUpdateFlow = _episode.step.kind == StepKind.updateRedflag;
    final answers = Map<String, AnswerState>.from(isUpdateFlow
        ? (_episode.update ?? const UpdateDraft()).redFlagAnswers
        : _episode.redFlagAnswers);
    answers[questionId] = answer;

    // LOCAL, deterministic, instant (§2.7). Zero network in this path.
    final pairs = answers.entries
        .map((e) => RedFlagAnswer(questionId: e.key, answer: e.value))
        .toList();
    final result = evaluateRedFlags(redFlagQuestions, pairs);
    final fired = answer == AnswerState.yes && result.triggered;

    if (fired && _episode.caseId != null) {
      // The case already exists — escalate NOW. escalate() is monotonic;
      // there is no downgrade API and none is built here (§2.1).
      _escalateExistingCase(Priority.urgent);
    }

    Step nextStep;
    var returnToReview = _episode.returnToReview;
    if (!isUpdateFlow && _episode.returnToReview) {
      nextStep = const Step(StepKind.review);
      returnToReview = false;
    } else {
      final nextIndex = _episode.step.index + 1;
      if (nextIndex < redFlagQuestions.length) {
        nextStep = Step(
            isUpdateFlow ? StepKind.updateRedflag : StepKind.redflag, nextIndex);
      } else {
        nextStep = isUpdateFlow
            ? const Step(StepKind.updateDelta)
            : const Step(StepKind.who);
      }
    }

    if (fired) _interruptSource = InterruptSource.redFlagYes;
    _update(_episode.copyWith(
      redFlagAnswers: isUpdateFlow ? null : answers,
      update: isUpdateFlow
          ? (_episode.update ?? const UpdateDraft()).copyWith(
              redFlagAnswers: answers)
          : _episode.update,
      emergency: fired ? true : _episode.emergency,
      step: nextStep,
      returnToReview: returnToReview,
    ));
  }

  Future<void> _escalateExistingCase(Priority proposed) async {
    final id = _episode.caseId;
    if (id == null) return;
    final current = await CaseRepo.instance.getCase(id);
    if (current != null) {
      await CaseRepo.instance.escalateCase(current, proposed);
    }
  }

  // ── emergency interrupt ──────────────────────────────────────────────────

  /// The fixture (top-right, every screen) opens the interrupt directly.
  void openEmergency() {
    _interruptSource = InterruptSource.fixture;
    _update(_episode.copyWith(emergency: true));
  }

  /// The quiet "go back" path. The answer stays recorded and any escalated
  /// priority stays raised (§2.1) — dismissing the screen un-does nothing.
  void dismissEmergency() => _update(_episode.copyWith(emergency: false));

  // ── who / voice / functional ─────────────────────────────────────────────

  void chooseCompletedBy(String value) {
    _update(_episode.copyWith(
      completedBy: value,
      step: _episode.returnToReview
          ? const Step(StepKind.review)
          : const Step(StepKind.voice),
      returnToReview: false,
    ));
  }

  void setTranscript(String t) {
    if (_episode.step.kind == StepKind.updateDelta) {
      _update(_episode.copyWith(
          update:
              (_episode.update ?? const UpdateDraft()).copyWith(transcript: t)));
    } else {
      _update(_episode.copyWith(transcript: t));
    }
  }

  void setAudio(AudioRecordingData a) {
    if (_episode.step.kind == StepKind.updateDelta) {
      _update(_episode.copyWith(
          update: (_episode.update ?? const UpdateDraft()).copyWith(audio: a)));
    } else {
      _update(_episode.copyWith(audio: a));
    }
  }

  void continueFromVoice() {
    _update(_episode.copyWith(
      step: _episode.returnToReview
          ? const Step(StepKind.review)
          : const Step(StepKind.functional, 0),
      returnToReview: false,
    ));
  }

  void answerFunctional(String questionId, FunctionalValue value) {
    final answers = Map<String, FunctionalValue>.from(_episode.functionalAnswers);
    answers[questionId] = value;
    Step step;
    var returnToReview = _episode.returnToReview;
    if (_episode.returnToReview) {
      step = const Step(StepKind.review);
      returnToReview = false;
    } else {
      final nextIndex = _episode.step.index + 1;
      step = nextIndex < functionalQuestions.length
          ? Step(StepKind.functional, nextIndex)
          : const Step(StepKind.review);
    }
    _update(_episode.copyWith(
        functionalAnswers: answers, step: step, returnToReview: returnToReview));
  }

  // ── review edits ─────────────────────────────────────────────────────────

  void editRedFlag(int index) => _update(_episode.copyWith(
      returnToReview: true, step: Step(StepKind.redflag, index)));
  void editWho() => _update(
      _episode.copyWith(returnToReview: true, step: const Step(StepKind.who)));
  void editVoice() => _update(
      _episode.copyWith(returnToReview: true, step: const Step(StepKind.voice)));
  void editFunctional(int index) => _update(_episode.copyWith(
      returnToReview: true, step: Step(StepKind.functional, index)));

  /// The patient accepted a tidied/translated version of their own words.
  void acceptDescription(String text) =>
      _update(_episode.copyWith(transcript: text));

  // ── send (account gate → case) ───────────────────────────────────────────

  /// Review's send action. Auth comes AFTER the safety questions by design:
  /// safety is never gated behind an account. No account → the auth step;
  /// signed in → straight to send.
  void requestSend() {
    if (PatientAuthService.instance.currentUser == null) {
      _update(_episode.copyWith(step: const Step(StepKind.auth)));
    } else {
      send();
    }
  }

  /// Called by the auth step once sign-in/registration completes.
  Future<void> onAuthenticated(String locale) async {
    final user = PatientAuthService.instance.currentUser;
    if (user == null) return;
    try {
      await PatientAuthService.instance.ensurePatientAccount(
        user: user,
        name: _episode.name.trim(),
        locale: locale,
      );
    } catch (_) {
      // Offline: the account doc write queues; sending continues.
    }
    await send();
    // Workflow preferences only — never anything clinical.
    PatientMemoryService.instance.rememberPreferences(
      user.uid,
      language: locale,
      inputHabit: _episode.audio != null ? 'voice' : 'typed',
    );
  }

  Future<void> send() async {
    final user = PatientAuthService.instance.currentUser;
    if (user == null) return;

    var consentId = _episode.consentId;
    consentId ??= await CaseRepo.instance.grantConsent(
        _episode.name.trim().isEmpty ? 'anonymous' : _episode.name.trim(),
        'symptom_submission');

    var caseId = _episode.caseId;
    PatientCase c;
    if (caseId == null) {
      c = CaseRepo.instance.buildCase(
        patientName:
            _episode.name.trim().isEmpty ? 'Anonymous' : _episode.name.trim(),
        completedBy: _episode.completedBy ?? 'self',
        consentId: consentId,
        accountUid: user.uid,
      );
      caseId = c.id;
    } else {
      c = await CaseRepo.instance.getCase(caseId) ??
          CaseRepo.instance.buildCase(
            patientName: _episode.name.trim().isEmpty
                ? 'Anonymous'
                : _episode.name.trim(),
            completedBy: _episode.completedBy ?? 'self',
            consentId: consentId,
            accountUid: user.uid,
          );
    }

    final pairs = _episode.redFlagPairs();
    final update = CaseUpdate(
      id: newId('update'),
      at: DateTime.now().millisecondsSinceEpoch,
      kind: UpdateKind.initial,
      transcript: _episode.transcript.trim(),
      audio: _episode.audio,
      redFlagAnswers: pairs,
      redFlags: evaluateRedFlags(redFlagQuestions, pairs),
      functionalAnswers: _episode.functionalPairs(),
      // Honest default: queued until the SERVER acknowledges (§6).
      syncState: SyncState.queuedOnDevice,
    );
    await CaseRepo.instance.appendCaseUpdate(c, update);
    _update(_episode.copyWith(
        caseId: caseId, consentId: consentId, step: const Step(StepKind.status)));
  }

  // ── "my condition has changed" — appends to the SAME case (F-056) ────────

  void startConditionChanged() {
    if (_episode.caseId == null) return;
    final k = _episode.step.kind;
    if (k == StepKind.updateRedflag ||
        k == StepKind.updateDelta ||
        k == StepKind.updateConfirm) {
      return;
    }
    _update(_episode.copyWith(
      update: const UpdateDraft(),
      step: const Step(StepKind.updateRedflag, 0),
      returnToReview: false,
    ));
  }

  Future<void> sendConditionChanged() async {
    final caseId = _episode.caseId;
    final draft = _episode.update;
    if (caseId == null || draft == null) return;
    final current = await CaseRepo.instance.getCase(caseId);
    if (current == null) return;

    final pairs = draft.redFlagAnswers.entries
        .map((e) => RedFlagAnswer(questionId: e.key, answer: e.value))
        .toList();
    final update = CaseUpdate(
      id: newId('update'),
      at: DateTime.now().millisecondsSinceEpoch,
      kind: UpdateKind.conditionChanged,
      transcript: draft.transcript.trim(),
      audio: draft.audio,
      redFlagAnswers: pairs,
      redFlags: evaluateRedFlags(redFlagQuestions, pairs),
      functionalAnswers: const [],
      syncState: SyncState.queuedOnDevice,
    );
    // APPENDS to the same case — never re-queues, never resets. Priority
    // merges one-way inside appendUpdate (a calm update never lowers).
    await CaseRepo.instance.appendCaseUpdate(current, update);
    _update(_episode.copyWith(
        update: null, step: const Step(StepKind.updateConfirm)));
  }

  void backToStatus() =>
      _update(_episode.copyWith(step: const Step(StepKind.status)));

  // ── account ──────────────────────────────────────────────────────────────

  void openAccount() =>
      _update(_episode.copyWith(step: const Step(StepKind.account)));

  /// After delete-my-data: wipe the local episode and return to the door.
  void resetAfterErasure() {
    Prefs.instance.clearEpisode();
    _resumeTarget = null;
    _update(const EpisodeState());
  }

  /// Auth step's back action — the person changed their mind for now.
  void backToReview() =>
      _update(_episode.copyWith(step: const Step(StepKind.review)));

  /// Test seam only — widget tests need to place the flow on a given step
  /// without a Firestore backend.
  @visibleForTesting
  void debugSetEpisode(EpisodeState e) => _update(e);
}
