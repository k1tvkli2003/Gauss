import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../data/progress_repository.dart';
import '../data/question_bank_repository.dart';
import '../domain/failures.dart';
import '../domain/models.dart';
import '../domain/study_curriculum.dart';

class GaussController extends ChangeNotifier {
  GaussController(this._questionBank, this._progress);

  final QuestionBankRepository _questionBank;
  final ProgressRepository _progress;
  final List<AttemptRecord> _attempts = [];
  final Map<String, int> _completedByTopic = {};
  String? _selectedTopicKey;
  bool _ready = false;
  GaussFailure? _fatalError;
  // Mission-era state, dormant while the corpus has no scored items: nothing
  // writes these anymore, so they are final defaults rather than live queries.
  final int _revengeCount = 0;
  final int _reviewDueCount = 0;
  int _studyDueCount = 0;
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
  UnmodifiableListView<RecentExamSummary> get recentExams =>
      UnmodifiableListView(_recentExams);
  ResumableMission? get resumableMission => _resumableMission;
  int get totalQuestions => _questionBank.declaredTotal;
  int get missionReadyQuestions => _questionBank.topics.fold(
    0,
    (total, topic) => total + topic.missionReadyCount,
  );
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

  Future<void> initialize() async {
    _fatalError = null;
    _ready = false;
    try {
      await _questionBank.initialize();
      await _progress.initialize();
      await _refreshProgress();
      _selectedTopicKey = _questionBank.topics.first.key;
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

  void selectTopic(String key) {
    if (_selectedTopicKey == key) return;
    _questionBank.topicByKey(key);
    _selectedTopicKey = key;
    notifyListeners();
  }

  Future<List<Question>> createMission(
    String topicKey, {
    int count = 10,
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
    ]);
    _gamification = values[0] as GamificationSummary;
    _study = values[1] as StudySummary;
    _studyDueCount = (values[2] as List<String>).length;
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
    if (questions.any((question) => !question.missionReady)) {
      // Preserve the draft rows but never resume a source item whose answer
      // contract is quarantined. Starting a new mission retires the draft.
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

  Future<List<Question>> createRevengeMission({int count = 10}) async {
    try {
      final ids = await _progress.revengeIds();
      final questions = await _questionBank.questionsByIds(ids);
      return questions
          .where((question) => question.missionReady)
          .take(count)
          .toList(growable: false);
    } catch (error) {
      throw MissionLoadFailure(error);
    }
  }

  /// Draws the review orbit: every question whose spaced-repetition timer has
  /// elapsed, oldest due first — remembered proofs near the forgetting curve
  /// alongside lapsed mistakes.
  Future<List<Question>> createReviewMission({int count = 10}) async {
    try {
      final ids = await _progress.reviewDueIds();
      final questions = await _questionBank.questionsByIds(ids);
      return questions
          .where((question) => question.missionReady)
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
      final allQuestions = await _questionBank.archiveQuestions(topicKey);
      final safeOffset = offset.clamp(0, allQuestions.length);
      final limit = (count ?? allQuestions.length).clamp(
        1,
        allQuestions.length,
      );
      final questions = allQuestions.skip(safeOffset).take(limit).toList();
      if (shuffleSeed != null) {
        // A deliberate second pass over the same set: the order changes, the
        // membership and its shelf key do not, so progress stays attached.
        questions.shuffle(math.Random(shuffleSeed));
      }
      final shelfKey = '$topicKey:$safeOffset:$limit';
      // These first-use statements share one local Drift executor. Sequential
      // reads are effectively free beside shard decoding and avoid a native
      // sqlite initialization race observed on Windows test/runtime hosts.
      final storedRecords = await _progress.studyRecords(topicKey: topicKey);
      final storedPosition = await _progress.studyPosition(shelfKey);
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
        initialIndex = questions.indexWhere(
          (question) => !records.containsKey(question.id),
        );
        if (initialIndex < 0) initialIndex = 0;
      }
      return StudyShelf(
        key: shelfKey,
        questions: questions,
        records: records,
        initialIndex: initialIndex,
        revisitOnly: false,
      );
    } catch (error) {
      throw StudyLoadFailure(error);
    }
  }

  Future<StudyShelf> loadGemShelf() => _loadCuratedShelf(
    key: 'gems',
    loadIds: _progress.gemStudyIds,
  );

  Future<StudyShelf> loadRevisitShelf() => _loadCuratedShelf(
    key: 'revisit',
    loadIds: _progress.revisitStudyIds,
  );

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
      return StudyShelf(
        key: key,
        questions: questions,
        records: records,
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
  }) async {
    if (question.missionReady) {
      throw ArgumentError(
        'Verified mission items do not use source reflection.',
      );
    }
    try {
      // Attribution always uses the canonical curriculum slice of the
      // question, regardless of which surface (chapter shelf, revisit orbit,
      // filtered browse, deep link) the reflection came from. This keeps
      // set-completion counting stable.
      final topicQuestions = await _questionBank.loadTopic(question.topicKey);
      final index = topicQuestions.indexWhere(
        (item) => item.id == question.id,
      );
      const batch = GaussStudyCurriculum.batchSize;
      final offset = index < 0 ? 0 : (index ~/ batch) * batch;
      final canonicalShelfKey = '${question.topicKey}:$offset:$batch';
      final setSize = math.min(batch, topicQuestions.length - offset);
      final outcome = await _progress.saveStudyReflection(
        questionId: question.id,
        topicKey: question.topicKey,
        subjectKey: question.subject.key,
        shelfKey: canonicalShelfKey,
        setSize: setSize,
        topicQuestionCount: topicQuestions.length,
        hypothesisChoiceIndex: hypothesisChoiceIndex,
        // Alignment with the source-claimed key, recorded only when a
        // hypothesis existed. The source is unverified, so this is a private
        // note about agreement — never a correctness score.
        hypothesisMatched: hypothesisChoiceIndex == null
            ? null
            : hypothesisChoiceIndex == question.correctChoiceIndex,
        reflection: reflection,
      );
      _study = await _progress.studySummary();
      _studyDueCount = (await _progress.studyDueIds()).length;
      if (outcome.unitCompleted) {
        await _maybeAwardSectionCompletion(question.topicKey);
      }
      _gamification = await _progress.gamificationSummary();
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
      final topic = _questionBank.topicByKey(key);
      if (_study.topic(key).reflected < topic.questionCount) return;
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
