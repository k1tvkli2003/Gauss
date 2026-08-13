import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../data/backup_service.dart';
import '../data/progress_repository.dart';
import '../data/question_bank_repository.dart';
import '../data/status_widget_bridge.dart';
import '../domain/failures.dart';
import '../domain/models.dart';
import '../domain/study_curriculum.dart';

class GaussController extends ChangeNotifier {
  GaussController(
    this._questionBank,
    this._progress, {
    BackupService? backups,
    StatusWidgetBridge? statusWidget,
  }) : _backups = backups ?? BackupService(),
       _statusWidget = statusWidget ?? const StatusWidgetBridge();

  final QuestionBankRepository _questionBank;
  final ProgressRepository _progress;
  final BackupService _backups;
  final StatusWidgetBridge _statusWidget;

  BackupService get backups => _backups;
  final List<AttemptRecord> _attempts = [];
  final Map<String, int> _completedByTopic = {};
  String? _selectedTopicKey;
  bool _ready = false;
  GaussFailure? _fatalError;
  // These secondary queue counters stay lazy so Android bootstrap does not
  // decode or query surfaces the learner has not opened yet.
  final int _revengeCount = 0;
  final int _reviewDueCount = 0;
  int _studyDueCount = 0;
  bool _needsTour = false;
  final List<RecentExamSummary> _recentExams = const [];
  ResumableMission? _resumableMission;
  StudySummary _study = const StudySummary.empty();
  final AnalyticsSnapshot _analytics = const AnalyticsSnapshot(
    totalAnswered: 0,
    totalCorrect: 0,
    accuracy: 0,
    averageSeconds: 0,
    weakTopics: [],
    distractors: [],
    heatmap: {},
    streak: 0,
  );
  GamificationSummary _gamification = const GamificationSummary(
    totalXp: 0,
    todayXp: 0,
    level: 1,
    levelProgress: 0,
    streak: 0,
    quest: DailyQuest(
      title: ProgressRepository.dailyQuestTitle,
      progress: 0,
      target: ProgressRepository.dailyQuestTarget,
      rewardXp: ProgressRepository.dailyQuestXp,
      completed: false,
    ),
    achievements: [],
  );

  bool get ready => _ready;
  GaussFailure? get fatalError => _fatalError;
  UnmodifiableListView<TopicDescriptor> get topics =>
      UnmodifiableListView(_questionBank.topics);
  UnmodifiableListView<AttemptRecord> get attempts =>
      UnmodifiableListView(_attempts);
  AnalyticsSnapshot get analytics => _analytics;
  GamificationSummary get gamification => _gamification;
  StudySummary get study => _study;
  int get revengeCount => _revengeCount;
  int get reviewDueCount => _reviewDueCount;

  /// Revisit-marked questions whose spacing timer has elapsed.
  int get studyDueCount => _studyDueCount;

  /// True until the learner has seen (or dismissed) the first-run tour.
  bool get needsTour => _needsTour;

  Future<void> markTourSeen() async {
    if (!_needsTour) return;
    _needsTour = false;
    notifyListeners();
    try {
      await _progress.writeFlag(ProgressRepository.tourSeenFlag, value: true);
    } catch (_) {
      // A tour that cannot be recorded is a cosmetic loss, not a failure
      // worth interrupting the learner for; it simply shows again.
    }
  }

  UnmodifiableListView<RecentExamSummary> get recentExams =>
      UnmodifiableListView(_recentExams);
  ResumableMission? get resumableMission => _resumableMission;
  int get totalQuestions => _questionBank.declaredTotal;
  int get missionReadyQuestions => _questionBank.topics.fold(
    0,
    (total, topic) => total + topic.missionReadyCount,
  );
  int get runtimeUsableQuestions => totalQuestions;
  int get preservedArchiveQuestions => totalQuestions - missionReadyQuestions;
  String get selectedTopicKey =>
      _selectedTopicKey ?? _questionBank.topics.first.key;
  TopicDescriptor get selectedTopic =>
      _questionBank.topicByKey(selectedTopicKey);
  int get correctAnswers => _analytics.totalCorrect;
  int get xp => _gamification.totalXp;
  double get accuracy =>
      _analytics.totalAnswered == 0 ? 0 : _analytics.accuracy / 100;
  int completedInTopic(String key) => _completedByTopic[key] ?? 0;
  int studiedInTopic(String key) => _study.topic(key).reflected;
  int revisitInTopic(String key) => _study.topic(key).revisit;

  /// Human-readable identity for one logical five-question Map node, derived
  /// from the screened concepts in the generated plan rather than source order.
  String studySetLabel(StudyPathNode node) =>
      _questionBank.studyPlan.session(node.topic.key, node.offset).displayLabel;

  bool isStudySessionMissionReady(StudyPathNode node) => _questionBank
      .isStudySessionMissionReady(node.topic.key, offset: node.offset);

  bool isStudySessionPlayable(StudyPathNode node) =>
      _questionBank.isStudySessionPlayable(node.topic.key, offset: node.offset);

  Future<void> initialize() async {
    _fatalError = null;
    _ready = false;
    try {
      await _questionBank.initialize();
      await _progress.initialize();
      await _progress.migrateStudyPlan(_questionBank.studyPlan);
      await _refreshProgress();
      await _restoreLearningContext();
      _ready = true;
    } catch (error, stackTrace) {
      _fatalError = StartupFailure(error);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'gauss bootstrap',
        ),
      );
    }
    notifyListeners();
  }

  Future<void> retryInitialize() => initialize();

  Future<void> selectTopic(String key) async {
    if (_selectedTopicKey == key) return;
    _questionBank.topicByKey(key);
    _selectedTopicKey = key;
    notifyListeners();
    await _persistLearningContext(key);
  }

  /// Moves Study to the current incomplete chapter for [subject].
  ///
  /// The selected topic is the shared learning context used by both Map and
  /// Study. Switching subjects therefore changes the real destination instead
  /// of only changing a local visual filter.
  Future<void> selectStudySubject(Subject subject) async {
    if (selectedTopic.subject == subject) return;
    await selectTopic(_nextStudyTopicForSubject(subject).key);
  }

  TopicDescriptor _nextStudyTopicForSubject(Subject subject) {
    final subjectTopics = _questionBank.topics
        .where((topic) => topic.subject == subject)
        .toList(growable: false);
    if (subjectTopics.isEmpty) {
      throw StateError('No study topics exist for ${subject.key}.');
    }
    for (final section in GaussStudyCurriculum.forSubject(subject)) {
      for (final node in GaussStudyCurriculum.nodesFor(
        section,
        _questionBank.topics,
      )) {
        if (_study.shelf(node.key).reflected < node.questionCount) {
          return node.topic;
        }
      }
    }
    return subjectTopics.last;
  }

  Future<void> _restoreLearningContext() async {
    final fallback = _questionBank.topics.first.key;
    _selectedTopicKey = fallback;
    String? saved;
    try {
      saved = await _progress.readLearningContextTopic();
    } catch (_) {
      // Learning context is a convenience. A damaged optional flag must never
      // prevent the offline question library from opening.
      return;
    }
    if (saved == null) return;
    if (_questionBank.topics.any((topic) => topic.key == saved)) {
      _selectedTopicKey = saved;
      return;
    }
    // Heal a key left behind by a renamed or removed chapter. This write is
    // best-effort for the same reason as every later context update.
    await _persistLearningContext(fallback);
  }

  Future<void> _persistLearningContext(String topicKey) async {
    try {
      await _progress.writeLearningContextTopic(topicKey);
    } catch (_) {
      // The in-memory selection remains truthful and usable even if local
      // persistence is temporarily unavailable. A future selection can retry.
    }
  }

  Future<List<Question>> createMission(
    String topicKey, {
    int count = GaussStudyCurriculum.batchSize,
    Set<Difficulty> difficulties = const {},
    Set<String> sourceBanks = const {},
  }) async {
    try {
      return await _questionBank.createMission(
        topicKey,
        count: count,
        difficulties: difficulties,
        sourceBanks: sourceBanks,
      );
    } catch (error) {
      throw MissionLoadFailure(error);
    }
  }

  Future<List<Question>> createStudySessionMission(
    String topicKey, {
    required int offset,
  }) async {
    try {
      return await _questionBank.createStudySessionMission(
        topicKey,
        offset: offset,
      );
    } catch (error) {
      throw MissionLoadFailure(error);
    }
  }

  Future<void> startMission({
    required String sessionId,
    required String topicKey,
    required DateTime createdAt,
    required List<Question> questions,
    Subject? subject,
  }) async {
    try {
      await _progress.startMission(
        sessionId: sessionId,
        subject: subject ?? _questionBank.topicByKey(topicKey).subject,
        topicKey: topicKey,
        createdAt: createdAt.millisecondsSinceEpoch,
        questionIds: questions.map((question) => question.id).toList(),
      );
      await _refreshActiveMission();
      notifyListeners();
    } catch (error) {
      throw MissionWriteFailure(error, operation: 'start_mission');
    }
  }

  Future<void> recordAttempt(AttemptRecord attempt) async {
    try {
      await _progress.saveDraftAttempt(attempt);
      await _refreshActiveMission();
      notifyListeners();
    } catch (error) {
      throw MissionWriteFailure(error, operation: 'save_attempt');
    }
  }

  /// Records a self-reported miss reason on an already-saved attempt.
  /// Descriptive only — never touches scoring, SRS, or rewards.
  Future<void> tagAttempt({
    required String sessionId,
    required String questionId,
    required String? errorTag,
  }) async {
    try {
      await _progress.tagAttempt(
        sessionId: sessionId,
        questionId: questionId,
        errorTag: errorTag,
      );
    } catch (error) {
      throw MissionWriteFailure(error, operation: 'tag_attempt');
    }
  }

  /// Saves a private, offline repair signal without hiding or mutating the
  /// source question. Reporting is intentionally independent from scoring.
  Future<void> reportQuestionIssue(QuestionIssueReport report) async {
    try {
      await _progress.saveQuestionIssueReport(report);
    } catch (error) {
      throw MissionWriteFailure(error, operation: 'report_question_issue');
    }
  }

  Future<MissionCompletion> completeMission({
    required String sessionId,
    required int durationSeconds,
  }) async {
    try {
      final completion = await _progress.finalizeMission(
        sessionId: sessionId,
        durationSeconds: durationSeconds,
      );
      await _refreshProgress();
      notifyListeners();
      return completion;
    } catch (error) {
      if (error is GaussFailure) rethrow;
      throw MissionWriteFailure(error, operation: 'finalize_mission');
    }
  }

  Future<void> _refreshProgress() async {
    // Startup loads only what live surfaces consume: the study summary, the
    // spaced-revisit due queue, and the ledger-backed gamification summary.
    // Mission-era queries (attempts, analytics, revenge, recent exams,
    // active-mission hydration) return with their surfaces, not before.
    final values = await Future.wait<Object?>([
      _progress.gamificationSummary(),
      _progress.studySummary(),
      _progress.studyDueIds(),
      _progress.readFlag(ProgressRepository.tourSeenFlag),
    ]);
    _gamification = values[0] as GamificationSummary;
    _study = values[1] as StudySummary;
    _studyDueCount = (values[2] as List<String>).length;
    _needsTour = !(values[3] as bool);
    await _publishStatusWidget();
  }

  /// Mirrors today's charted count and the due queue onto the home screen.
  Future<void> _publishStatusWidget() async {
    final today = DateTime.now();
    final dayKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    await _statusWidget.publish(
      chartedToday: _study.heatmap[dayKey] ?? 0,
      due: _studyDueCount,
    );
  }

  Future<ResumableMission?> loadResumableMission() async {
    await _refreshActiveMission();
    return _resumableMission;
  }

  Future<void> _refreshActiveMission() async {
    await _hydrateActiveMission(await _progress.activeMission());
  }

  Future<void> _hydrateActiveMission(ActiveMissionRecord? record) async {
    if (record == null) {
      _resumableMission = null;
      return;
    }
    final questions = await _questionBank.questionsByIds(record.questionIds);
    if (questions.length != record.questionIds.length) {
      // The bank changed underneath this draft — a corpus migration removed
      // some of its question ids. Preserve the recorded rows, but a stale
      // draft must retire quietly instead of bricking startup forever.
      _resumableMission = null;
      return;
    }
    if (questions.any((question) => !question.runtimeUsable)) {
      // Preserve the draft rows, but do not resume a structurally damaged
      // queue. Certification status alone never retires a private mission.
      _resumableMission = null;
      return;
    }
    _resumableMission = ResumableMission(
      sessionId: record.sessionId,
      subject: record.subject,
      topicKey: record.topicKey,
      createdAt: record.createdAt,
      questions: questions,
      attempts: record.attempts,
    );
  }

  Future<List<Question>> createRevengeMission({
    int count = GaussStudyCurriculum.batchSize,
  }) async {
    try {
      final ids = await _progress.revengeIds();
      final questions = await _questionBank.questionsByIds(ids);
      return questions
          .where((question) => question.runtimeUsable)
          .take(count)
          .toList(growable: false);
    } catch (error) {
      throw MissionLoadFailure(error);
    }
  }

  /// Draws the review orbit: every question whose spaced-repetition timer has
  /// elapsed, oldest due first — remembered proofs near the forgetting curve
  /// alongside lapsed mistakes.
  Future<List<Question>> createReviewMission({
    int count = GaussStudyCurriculum.batchSize,
  }) async {
    try {
      final ids = await _progress.reviewDueIds();
      final questions = await _questionBank.questionsByIds(ids);
      return questions
          .where((question) => question.runtimeUsable)
          .take(count)
          .toList(growable: false);
    } catch (error) {
      throw MissionLoadFailure(error);
    }
  }

  /// Loads the read-only preserved archive of a chapter for the reading room.
  Future<List<Question>> loadArchive(String topicKey) async {
    try {
      return await _questionBank.archiveQuestions(topicKey);
    } catch (error) {
      throw MissionLoadFailure(error);
    }
  }

  Future<StudyShelf> loadStudyShelf(
    String topicKey, {
    int offset = 0,
    int? count,
    int? shuffleSeed,
  }) async {
    try {
      final session = _questionBank.studySession(topicKey, offset);
      final questions = List<Question>.of(
        await _questionBank.loadStudySession(topicKey, offset: offset),
      );
      final slots = [
        for (final slot in session.slots)
          StudyShelfSlot(
            id: slot.id,
            questionId: slot.questionId,
            kind: slot.kind.key,
            primaryShelfKey: slot.primarySessionKey,
            planned: true,
          ),
      ];
      if (shuffleSeed != null) {
        // A deliberate second pass over the same set: the order changes, the
        // membership and its shelf key do not, so progress stays attached.
        final order = List<int>.generate(questions.length, (index) => index)
          ..shuffle(math.Random(shuffleSeed));
        final shuffledQuestions = [for (final index in order) questions[index]];
        final shuffledSlots = [for (final index in order) slots[index]];
        questions
          ..clear()
          ..addAll(shuffledQuestions);
        slots
          ..clear()
          ..addAll(shuffledSlots);
      }
      final shelfKey = session.key;
      // These first-use statements share one local Drift executor. Sequential
      // reads are effectively free beside shard decoding and avoid a native
      // sqlite initialization race observed on Windows test/runtime hosts.
      final storedRecords = await _progress.studyRecords(topicKey: topicKey);
      final storedPosition = await _progress.studyPosition(shelfKey);
      final encounteredSlotIds = await _progress.studyEncounteredSlotIds(
        shelfKey,
      );
      final questionIds = questions.map((question) => question.id).toSet();
      final records = {
        for (final record in storedRecords)
          if (questionIds.contains(record.questionId))
            record.questionId: record,
      };
      // A reshuffled pass starts at its own beginning: the stored position
      // refers to the canonical order, not this one.
      var initialIndex = shuffleSeed == null ? (storedPosition ?? -1) : -1;
      if (initialIndex < 0 || initialIndex >= questions.length) {
        initialIndex = slots.indexWhere(
          (slot) => !encounteredSlotIds.contains(slot.id),
        );
        if (initialIndex < 0) initialIndex = 0;
      }
      return StudyShelf(
        key: shelfKey,
        questions: questions,
        slots: slots,
        records: records,
        encounteredSlotIds: encounteredSlotIds,
        initialIndex: initialIndex,
        revisitOnly: false,
      );
    } catch (error) {
      throw StudyLoadFailure(error);
    }
  }

  Future<StudyShelf> loadGemShelf() =>
      _loadCuratedShelf(key: 'gems', loadIds: _progress.gemStudyIds);

  Future<StudyShelf> loadRevisitShelf() =>
      _loadCuratedShelf(key: 'revisit', loadIds: _progress.revisitStudyIds);

  Future<StudyShelf> _loadCuratedShelf({
    required String key,
    required Future<List<String>> Function() loadIds,
  }) async {
    try {
      final ids = await loadIds();
      final storedRecords = await _progress.studyRecords();
      final records = {
        for (final record in storedRecords)
          if (ids.contains(record.questionId)) record.questionId: record,
      };
      // The records already know where each question lives, so only those
      // shards are opened instead of scanning the whole library.
      final questions = await _questionBank.questionsByIds(
        ids,
        topicByQuestionId: {
          for (final record in records.values)
            record.questionId: record.topicKey,
        },
      );
      final slots = [
        for (var index = 0; index < questions.length; index++)
          StudyShelfSlot(
            id: '$key:$index:${questions[index].id}',
            questionId: questions[index].id,
            kind: StudySlotKind.curated.key,
            primaryShelfKey: records[questions[index].id]?.shelfKey ?? key,
            planned: false,
          ),
      ];
      return StudyShelf(
        key: key,
        questions: questions,
        slots: slots,
        records: records,
        encounteredSlotIds: const {},
        initialIndex: 0,
        revisitOnly: true,
      );
    } catch (error) {
      throw StudyLoadFailure(error);
    }
  }

  Future<StudyReflectionOutcome> saveStudyReflection({
    required Question question,
    required String shelfKey,
    required int? hypothesisChoiceIndex,
    required StudyReflection reflection,
    StudyShelfSlot? slot,
  }) async {
    try {
      final topicQuestions = await _questionBank.loadTopic(question.topicKey);
      final primary = _questionBank.primaryStudySlot(question.id);
      StudySessionSlot? encounter;
      if (slot?.planned ?? false) {
        final session = _questionBank.studyPlan
            .topic(question.topicKey)
            .sessions
            .firstWhere((candidate) => candidate.key == shelfKey);
        encounter = session.slots.firstWhere(
          (candidate) => candidate.id == slot!.id,
        );
        if (encounter.questionId != question.id ||
            slot!.questionId != question.id) {
          throw StateError('Study slot does not match the displayed question.');
        }
      }
      final topicPlan = _questionBank.studyPlan.topic(question.topicKey);
      final outcome = await _progress.saveStudyReflection(
        questionId: question.id,
        topicKey: question.topicKey,
        subjectKey: question.subject.key,
        shelfKey: primary.sessionKey,
        setSize: GaussStudyCurriculum.batchSize,
        topicQuestionCount: topicQuestions.length,
        hypothesisChoiceIndex: hypothesisChoiceIndex,
        // Study reflection is a private learning note, independent from the
        // scored mission ledger. For an archive item this only means agreement
        // with the preserved source claim; for a certified item it means
        // alignment with the verified mapping. Neither path grants mission XP.
        hypothesisMatched: hypothesisChoiceIndex == null
            ? null
            : hypothesisChoiceIndex == question.correctChoiceIndex,
        reflection: reflection,
        encounterSlotId: encounter?.id,
        encounterShelfKey: encounter?.sessionKey,
        encounterSlotKind: encounter?.kind,
        topicSlotCount: encounter == null ? null : topicPlan.slotCount,
      );
      _study = await _progress.studySummary();
      _studyDueCount = (await _progress.studyDueIds()).length;
      if (outcome.unitCompleted) {
        await _maybeAwardSectionCompletion(question.topicKey);
      }
      _gamification = await _progress.gamificationSummary();
      await _publishStatusWidget();
      notifyListeners();
      return outcome;
    } catch (error) {
      if (error is GaussFailure) rethrow;
      throw StudyWriteFailure(error, operation: 'save_study_reflection');
    }
  }

  Future<void> _maybeAwardSectionCompletion(String topicKey) async {
    StudySectionDefinition? section;
    for (final item in GaussStudyCurriculum.sections) {
      if (item.topicKeys.contains(topicKey)) {
        section = item;
        break;
      }
    }
    if (section == null) return;
    for (final key in section.topicKeys) {
      final nodes = GaussStudyCurriculum.nodesFor(
        section,
        _questionBank.topics,
      ).where((node) => node.topic.key == key);
      if (nodes.any(
        (node) => _study.shelf(node.key).reflected < node.questionCount,
      )) {
        return;
      }
    }
    await _progress.awardSectionCompleted(
      sectionId: section.id,
      subjectKey: section.subject.key,
    );
  }

  Future<void> saveStudyPosition({
    required String shelfKey,
    required Question question,
    required int position,
  }) async {
    try {
      await _progress.saveStudyPosition(
        shelfKey: shelfKey,
        questionId: question.id,
        position: position,
      );
    } catch (error) {
      throw StudyWriteFailure(error, operation: 'save_study_position');
    }
  }

  Future<void> validateDataset() => _questionBank.validateAllShards();
}

class GaussScope extends InheritedNotifier<GaussController> {
  const GaussScope({
    required GaussController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static GaussController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GaussScope>();
    assert(scope != null, 'No GaussScope found in the widget tree.');
    return scope!.notifier!;
  }
}
