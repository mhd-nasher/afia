/// The report/update flow engine (D-015 structure: a conventional app —
/// auth first, Home with one big action, tabs — with this model driving the
/// two guided flows and the safety overlay).
///
/// Unchanged safety semantics:
/// · red flags are evaluated LOCALLY after EVERY answer (§2.7 — pure Dart,
///   no network, instant, works in airplane mode); a YES shows the
///   emergency interrupt immediately, and going back un-does nothing;
/// · every mutation persists to the device BEFORE it renders (F-055) — no
///   unsaved state exists, a killed app resumes its draft from Home;
/// · "my condition has changed" APPENDS to the active case (F-056);
///   priority merges one-way (§2.1); UNKNOWN stays first-class (§2.2).
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
    if (_episode.caseId != null) {
      try {
        CaseRepo.instance.resumeAckWatch(_episode.caseId!);
      } catch (_) {
        // Firebase unavailable (offline first start): the flows and the
        // emergency path never depend on it (§2.7).
      }
    }
  }

  static final EpisodeModel instance = EpisodeModel._();

  late EpisodeState _episode;
  InterruptSource _interruptSource = InterruptSource.fixture;

  final List<RedFlagQuestion> redFlagQuestions = bundledRedFlagQuestions;
  final List<FunctionalQuestion> functionalQuestions =
      bundledFunctionalQuestions;

  EpisodeState get episode => _episode;
  InterruptSource get interruptSource => _interruptSource;

  /// One active case at a time (D-015). Null = no active report.
  String? get activeCaseId => _episode.caseId;
  bool get hasActiveCase => _episode.caseId != null;
  bool get hasDraft => _episode.hasDraft;

  /// The single write path: persist first, then render (F-055).
  void _update(EpisodeState next) {
    _episode = next;
    Prefs.instance.setEpisodeJson(next.toJson());
    notifyListeners();
  }

  void setName(String v) => _update(_episode.copyWith(name: v));

  // ── report flow (from Home's one big action) ─────────────────────────────

  /// Starts a fresh report draft. Callers must respect the active-case rule
  /// (Home routes to the update flow when a case is active).
  void startNewReport() {
    _update(_episode.copyWith(
      step: const Step(StepKind.redflag, 0),
      returnToReview: false,
      draftStarted: true,
      consentGiven: false,
      consentId: null,
      completedBy: null,
      redFlagAnswers: const {},
      transcript: '',
      audio: null,
      functionalAnswers: const {},
      update: null,
    ));
  }

  /// Resume is implicit — the draft state IS the current state. Guard only.
  void resumeDraft() {
    if (!_episode.hasDraft) startNewReport();
  }

  void discardDraft() {
    _update(_episode.copyWith(
      draftStarted: false,
      returnToReview: false,
      step: const Step(StepKind.redflag, 0),
      consentGiven: false,
      completedBy: null,
      redFlagAnswers: const {},
      transcript: '',
      audio: null,
      functionalAnswers: const {},
    ));
  }

  /// D-015 active-case rule: a NEW report while a case is active is an
  /// explicit choice ("a different, new situation"). The old case simply
  /// stops being the active one on this device — it stays in the history
  /// and with the nursing team; nothing is deleted, nothing is lowered.
  void startNewReportDespiteActive() {
    _update(_episode.copyWith(caseId: null));
    startNewReport();
  }

  // ── red flags (report + condition-changed repeat) ────────────────────────

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

    if (fired && _episode.caseId != null && isUpdateFlow) {
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
            isUpdateFlow ? StepKind.updateRedflag : StepKind.redflag,
            nextIndex);
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
          ? (_episode.update ?? const UpdateDraft())
              .copyWith(redFlagAnswers: answers)
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

  /// The fixture (top-right, EVERY screen incl. auth) opens the interrupt.
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
          update: (_episode.update ?? const UpdateDraft())
              .copyWith(transcript: t)));
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
    final answers =
        Map<String, FunctionalValue>.from(_episode.functionalAnswers);
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
        functionalAnswers: answers,
        step: step,
        returnToReview: returnToReview));
  }

  void setConsent(bool v) => _update(_episode.copyWith(consentGiven: v));

  // ── clear back affordance on every step (D-015) ──────────────────────────

  /// One step back within the current flow. Returns false when already at
  /// the first step (the flow route then pops — the draft stays saved).
  bool goBackStep() {
    final s = _episode.step;
    Step? prev;
    switch (s.kind) {
      case StepKind.redflag:
        prev = s.index > 0 ? Step(StepKind.redflag, s.index - 1) : null;
      case StepKind.who:
        prev = Step(StepKind.redflag, redFlagQuestions.length - 1);
      case StepKind.voice:
        prev = const Step(StepKind.who);
      case StepKind.functional:
        prev = s.index > 0
            ? Step(StepKind.functional, s.index - 1)
            : const Step(StepKind.voice);
      case StepKind.review:
        prev = Step(StepKind.functional, functionalQuestions.length - 1);
      case StepKind.updateRedflag:
        prev = s.index > 0 ? Step(StepKind.updateRedflag, s.index - 1) : null;
      case StepKind.updateDelta:
        prev = Step(StepKind.updateRedflag, redFlagQuestions.length - 1);
      case StepKind.updateConfirm:
        prev = null; // the update was sent — there is no back from here
    }
    if (prev == null) return false;
    _update(_episode.copyWith(step: prev, returnToReview: false));
    return true;
  }

  // ── review edits ─────────────────────────────────────────────────────────

  void editRedFlag(int index) => _update(_episode.copyWith(
      returnToReview: true, step: Step(StepKind.redflag, index)));
  void editWho() => _update(
      _episode.copyWith(returnToReview: true, step: const Step(StepKind.who)));
  void editVoice() => _update(_episode.copyWith(
      returnToReview: true, step: const Step(StepKind.voice)));
  void editFunctional(int index) => _update(_episode.copyWith(
      returnToReview: true, step: Step(StepKind.functional, index)));

  /// The patient accepted a tidied/translated version of their own words.
  void acceptDescription(String text) =>
      _update(_episode.copyWith(transcript: text));

  // ── send (the user is already signed in — the mid-flow gate is gone) ─────

  Future<void> send() async {
    final user = PatientAuthService.instance.currentUser;
    if (user == null) return;

    var consentId = _episode.consentId;
    consentId ??= await CaseRepo.instance.grantConsent(
        _episode.name.trim().isEmpty ? 'anonymous' : _episode.name.trim(),
        'symptom_submission');

    final c = CaseRepo.instance.buildCase(
      patientName:
          _episode.name.trim().isEmpty ? 'Anonymous' : _episode.name.trim(),
      completedBy: _episode.completedBy ?? 'self',
      consentId: consentId,
      accountUid: user.uid,
    );

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

    // Workflow preferences only — never anything clinical.
    PatientMemoryService.instance.rememberPreferences(
      user.uid,
      inputHabit: _episode.audio != null ? 'voice' : 'typed',
    );

    // The new case becomes the active one; the draft is done.
    _update(_episode.copyWith(
      caseId: c.id,
      consentId: consentId,
      draftStarted: false,
      returnToReview: false,
      consentGiven: false,
      completedBy: null,
      redFlagAnswers: const {},
      transcript: '',
      audio: null,
      functionalAnswers: const {},
      step: const Step(StepKind.redflag, 0),
    ));
  }

  // ── "my condition has changed" — appends to the SAME case (F-056) ────────

  void startConditionChanged() {
    if (_episode.caseId == null) return;
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

  /// Leaves the finished update flow (route pops back to where it started).
  void finishUpdateFlow() => _update(_episode.copyWith(
      step: const Step(StepKind.redflag, 0), returnToReview: false));

  // ── account ──────────────────────────────────────────────────────────────

  /// After sign-out or delete-my-data: wipe the local episode entirely.
  void resetAfterErasure() {
    Prefs.instance.clearEpisode();
    _update(const EpisodeState());
  }

  /// Test seam only — widget tests need to place the flow on a given step
  /// without a Firestore backend.
  @visibleForTesting
  void debugSetEpisode(EpisodeState e) => _update(e);
}
