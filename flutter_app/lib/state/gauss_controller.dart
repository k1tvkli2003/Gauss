import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../data/progress_repository.dart';
import '../data/question_bank_repository.dart';
import '../domain/failures.dart';
import '../domain/models.dart';

class GaussController extends ChangeNotifier {
  GaussController(this._questionBank, this._progress);

  final QuestionBankRepository _questionBank;
  final ProgressRepository _progress;
  final List<AttemptRecord> _attempts = [];
  final Map<String, int> _completedByTopic = {};
  String? _selectedTopicKey;
  bool _ready = false;
  GaussFailure? _fatalError;
  int _revengeCount = 0;
  int _reviewDueCount = 0;
  List<RecentExamSummary> _recentExams = const [];
  ResumableMission? _resumableMission;
  AnalyticsSnapshot _analytics = const AnalyticsSnapshot(
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
  int get revengeCount => _revengeCount;
  int get reviewDueCount => _reviewDueCount;
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
    final values = await Future.wait<Object?>([
      _progress.loadAttempts(),
      _progress.analytics(),
      _progress.gamificationSummary(),
      _progress.revengeIds(),
      _progress.recentExams(),
      _progress.activeMission(),
      _progress.reviewDueIds(),
    ]);
    _attempts
      ..clear()
      ..addAll(values[0] as List<AttemptRecord>);
    final solvedByTopic = <String, Set<String>>{};
    for (final attempt in _attempts) {
      if (!attempt.correct) continue;
      solvedByTopic
          .putIfAbsent(attempt.topicKey, () => <String>{})
          .add(attempt.questionId);
    }
    _completedByTopic
      ..clear()
      ..addEntries(
        solvedByTopic.entries.map(
          (entry) => MapEntry(entry.key, entry.value.length),
        ),
      );
    _analytics = values[1] as AnalyticsSnapshot;
    _gamification = values[2] as GamificationSummary;
    _revengeCount = (values[3] as List<String>).length;
    _recentExams = values[4] as List<RecentExamSummary>;
    _reviewDueCount = (values[6] as List<String>).length;
    await _hydrateActiveMission(values[5] as ActiveMissionRecord?);
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
      throw StateError('The active mission references unavailable questions.');
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
