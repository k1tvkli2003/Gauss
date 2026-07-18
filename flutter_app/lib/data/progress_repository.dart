import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../domain/gamification_catalog.dart';
import '../domain/models.dart';
import 'local/gauss_database.dart';

class ProgressRepository {
  ProgressRepository(this.database, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final GaussDatabase database;
  final DateTime Function() _clock;

  static const dailyQuestTitle = GaussGamificationCatalog.dailyQuestTitle;
  static const dailyQuestTarget = GaussGamificationCatalog.dailyQuestTarget;
  static const dailyQuestXp = GaussGamificationCatalog.dailyQuestRewardXp;
  static const _practice = 'practice';
  static const _correction = 'correction';
  static const _bonus = 'bonus';
  static const _mastery = 'mastery';
  static const _syntheticTopicKeys = {'revenge', 'review'};

  Future<void> initialize() async {
    await database.customSelect('SELECT 1').getSingle();
  }

  Future<List<StudyRecord>> studyRecords({String? topicKey}) async {
    final query = database.select(database.studyRecords);
    if (topicKey != null) {
      query.where((row) => row.topicKey.equals(topicKey));
    }
    query.orderBy([(row) => OrderingTerm.asc(row.firstReflectedAt)]);
    return (await query.get()).map(_studyRecordFromRow).toList(growable: false);
  }

  Future<StudyRecord> saveStudyReflection({
    required String questionId,
    required String topicKey,
    required String shelfKey,
    required int? hypothesisChoiceIndex,
    required StudyReflection reflection,
  }) => database.transaction(() async {
    if (hypothesisChoiceIndex != null &&
        (hypothesisChoiceIndex < 0 || hypothesisChoiceIndex > 3)) {
      throw ArgumentError.value(
        hypothesisChoiceIndex,
        'hypothesisChoiceIndex',
        'must use the zero-based four-choice contract',
      );
    }
    final now = _clock().millisecondsSinceEpoch;
    final existing = await (database.select(
      database.studyRecords,
    )..where((row) => row.questionId.equals(questionId))).getSingleOrNull();
    if (existing != null &&
        existing.topicKey == topicKey &&
        existing.shelfKey == shelfKey &&
        existing.hypothesisChoiceIndex == hypothesisChoiceIndex &&
        existing.reflection == reflection.key) {
      return _studyRecordFromRow(existing);
    }
    if (existing == null) {
      await database
          .into(database.studyRecords)
          .insert(
            StudyRecordsCompanion.insert(
              questionId: questionId,
              topicKey: topicKey,
              shelfKey: shelfKey,
              hypothesisChoiceIndex: Value(hypothesisChoiceIndex),
              reflection: reflection.key,
              firstReflectedAt: now,
              updatedAt: now,
            ),
          );
    } else {
      if (existing.topicKey != topicKey) {
        throw StateError('A study record cannot move between chapters.');
      }
      await (database.update(
        database.studyRecords,
      )..where((row) => row.questionId.equals(questionId))).write(
        StudyRecordsCompanion(
          hypothesisChoiceIndex: Value(hypothesisChoiceIndex),
          shelfKey: Value(shelfKey),
          reflection: Value(reflection.key),
          updatedAt: Value(now),
        ),
      );
    }
    final saved = await (database.select(
      database.studyRecords,
    )..where((row) => row.questionId.equals(questionId))).getSingle();
    return _studyRecordFromRow(saved);
  });

  Future<void> saveStudyPosition({
    required String shelfKey,
    required String questionId,
    required int position,
  }) async {
    if (position < 0) {
      throw ArgumentError.value(position, 'position', 'cannot be negative');
    }
    await database
        .into(database.studyPositions)
        .insertOnConflictUpdate(
          StudyPositionsCompanion.insert(
            shelfKey: shelfKey,
            questionId: questionId,
            position: position,
            updatedAt: _clock().millisecondsSinceEpoch,
          ),
        );
  }

  Future<int?> studyPosition(String shelfKey) async {
    final row = await (database.select(
      database.studyPositions,
    )..where((item) => item.shelfKey.equals(shelfKey))).getSingleOrNull();
    return row?.position;
  }

  Future<List<String>> revisitStudyIds() async {
    final query = database.select(database.studyRecords)
      ..where((row) => row.reflection.equals(StudyReflection.revisit.key))
      ..orderBy([(row) => OrderingTerm.asc(row.updatedAt)]);
    return (await query.get())
        .map((row) => row.questionId)
        .toList(growable: false);
  }

  Future<StudySummary> studySummary() async {
    final records = await studyRecords();
    final byTopic = <String, List<StudyRecord>>{};
    final byShelf = <String, List<StudyRecord>>{};
    final heatmap = <String, int>{};
    var clearCount = 0;
    var revisitCount = 0;
    for (final record in records) {
      byTopic.putIfAbsent(record.topicKey, () => []).add(record);
      byShelf.putIfAbsent(record.shelfKey, () => []).add(record);
      if (record.reflection == StudyReflection.clear) {
        clearCount++;
      } else {
        revisitCount++;
      }
      final day = _dayKey(record.firstReflectedAt);
      heatmap[day] = (heatmap[day] ?? 0) + 1;
    }
    return StudySummary(
      totalReflected: records.length,
      clearCount: clearCount,
      revisitCount: revisitCount,
      touchedTopics: byTopic.length,
      byTopic: {
        for (final entry in byTopic.entries)
          entry.key: StudyTopicSnapshot(
            reflected: entry.value.length,
            clear: entry.value
                .where((record) => record.reflection == StudyReflection.clear)
                .length,
            revisit: entry.value
                .where((record) => record.reflection == StudyReflection.revisit)
                .length,
          ),
      },
      byShelf: {
        for (final entry in byShelf.entries)
          entry.key: StudyTopicSnapshot(
            reflected: entry.value.length,
            clear: entry.value
                .where((record) => record.reflection == StudyReflection.clear)
                .length,
            revisit: entry.value
                .where((record) => record.reflection == StudyReflection.revisit)
                .length,
          ),
      },
      heatmap: heatmap,
    );
  }

  Future<List<AttemptRecord>> loadAttempts() async {
    final query = database.select(database.attempts)
      ..where((row) => row.examId.isNotNull())
      ..orderBy([(row) => OrderingTerm.asc(row.solvedAt)]);
    return (await query.get()).map(_attemptFromRow).toList(growable: false);
  }

  Future<void> startMission({
    required String sessionId,
    required Subject subject,
    required String topicKey,
    required int createdAt,
    required List<String> questionIds,
  }) => database.transaction(() async {
    if (questionIds.isEmpty ||
        questionIds.toSet().length != questionIds.length) {
      throw StateError('A mission queue must contain unique question ids.');
    }

    await (database.update(database.exams)..where(
          (row) =>
              row.status.equals('active') &
              row.sessionId.equals(sessionId).not(),
        ))
        .write(const ExamsCompanion(status: Value('abandoned')));

    await database
        .into(database.exams)
        .insert(
          ExamsCompanion.insert(
            sessionId: sessionId,
            subject: subject.key,
            topicKey: Value(topicKey),
            createdAt: createdAt,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final exam = await (database.select(
      database.exams,
    )..where((row) => row.sessionId.equals(sessionId))).getSingle();
    final existing =
        await (database.select(database.missionQueueItems)
              ..where((row) => row.examId.equals(exam.id))
              ..orderBy([(row) => OrderingTerm.asc(row.position)]))
            .get();
    if (existing.isNotEmpty) {
      final stored = existing.map((row) => row.questionId).toList();
      if (!_sameQueue(stored, questionIds)) {
        throw StateError(
          'The persisted mission queue does not match its session.',
        );
      }
      return;
    }
    await database.batch((batch) {
      batch.insertAll(database.missionQueueItems, [
        for (var index = 0; index < questionIds.length; index++)
          MissionQueueItemsCompanion.insert(
            examId: exam.id,
            position: index,
            questionId: questionIds[index],
          ),
      ]);
    });
  });

  Future<ActiveMissionRecord?> activeMission() async {
    final examQuery = database.select(database.exams)
      ..where((row) => row.status.equals('active'))
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
      ..limit(1);
    final exam = await examQuery.getSingleOrNull();
    if (exam == null) return null;

    final queue =
        await (database.select(database.missionQueueItems)
              ..where((row) => row.examId.equals(exam.id))
              ..orderBy([(row) => OrderingTerm.asc(row.position)]))
            .get();
    if (queue.isEmpty) {
      throw StateError('The active mission has no persisted queue.');
    }
    final attempts =
        await (database.select(database.attempts)
              ..where((row) => row.sessionId.equals(exam.sessionId))
              ..orderBy([(row) => OrderingTerm.asc(row.missionIndex)]))
            .get();
    return ActiveMissionRecord(
      sessionId: exam.sessionId,
      subject: Subject.fromKey(exam.subject),
      topicKey: exam.topicKey ?? 'unknown',
      createdAt: DateTime.fromMillisecondsSinceEpoch(exam.createdAt),
      questionIds: queue.map((row) => row.questionId).toList(growable: false),
      attempts: attempts.map(_attemptFromRow).toList(growable: false),
    );
  }

  Future<void> saveDraftAttempt(AttemptRecord attempt) async {
    await database.transaction(() async {
      final existing =
          await (database.select(database.attempts)..where(
                (row) =>
                    row.sessionId.equals(attempt.sessionId) &
                    row.questionId.equals(attempt.questionId),
              ))
              .getSingleOrNull();
      final status = attempt.skipped
          ? 'skipped'
          : (attempt.correct ? 'correct' : 'wrong');
      if (existing == null) {
        await database
            .into(database.attempts)
            .insert(
              AttemptsCompanion.insert(
                examId: const Value.absent(),
                sessionId: attempt.sessionId,
                missionIndex: attempt.missionIndex,
                questionId: attempt.questionId,
                subject: attempt.subject.key,
                topicKey: attempt.topicKey,
                status: status,
                selectedChoiceIndex: Value(attempt.selectedChoiceIndex),
                timeTakenSeconds: attempt.elapsedSeconds,
                solvedAt: attempt.at.millisecondsSinceEpoch,
                errorTag: Value(attempt.errorTag),
              ),
            );
      } else {
        await (database.update(
          database.attempts,
        )..where((row) => row.id.equals(existing.id))).write(
          AttemptsCompanion(
            missionIndex: Value(attempt.missionIndex),
            status: Value(status),
            selectedChoiceIndex: Value(attempt.selectedChoiceIndex),
            timeTakenSeconds: Value(attempt.elapsedSeconds),
            solvedAt: Value(attempt.at.millisecondsSinceEpoch),
            errorTag: Value(attempt.errorTag),
          ),
        );
      }
    });
  }

  /// Attaches (or clears) a self-reported miss reason on a recorded attempt.
  /// Purely descriptive: it never changes status, scoring, SRS, or XP.
  Future<void> tagAttempt({
    required String sessionId,
    required String questionId,
    required String? errorTag,
  }) async {
    await (database.update(database.attempts)..where(
          (row) =>
              row.sessionId.equals(sessionId) &
              row.questionId.equals(questionId),
        ))
        .write(AttemptsCompanion(errorTag: Value(errorTag)));
  }

  Future<MissionCompletion> finalizeMission({
    required String sessionId,
    required int durationSeconds,
  }) => database.transaction(() async {
    final exam = await (database.select(
      database.exams,
    )..where((row) => row.sessionId.equals(sessionId))).getSingle();
    if (exam.status == 'completed') {
      return _completionForExam(exam.id);
    }

    final draftQuery = database.select(database.attempts)
      ..where((row) => row.sessionId.equals(sessionId))
      ..orderBy([(row) => OrderingTerm.asc(row.missionIndex)]);
    final drafts = await draftQuery.get();
    if (drafts.isEmpty) {
      throw StateError('A mission cannot be completed without attempts.');
    }

    final correct = drafts.where((row) => row.status == 'correct').length;
    final wrong = drafts.where((row) => row.status == 'wrong').length;
    final skipped = drafts.where((row) => row.status == 'skipped').length;
    final total = drafts.length;
    final completedAt = _clock().millisecondsSinceEpoch;
    final score = correct / total * 100;

    await (database.update(
      database.exams,
    )..where((row) => row.id.equals(exam.id))).write(
      ExamsCompanion(
        totalQuestions: Value(total),
        correctCount: Value(correct),
        wrongCount: Value(wrong),
        skippedCount: Value(skipped),
        scorePercentage: Value((score * 100).truncate() / 100),
        durationSeconds: Value(durationSeconds),
        status: const Value('completed'),
        completedAt: Value(completedAt),
      ),
    );
    await (database.update(database.attempts)
          ..where((row) => row.sessionId.equals(sessionId)))
        .write(AttemptsCompanion(examId: Value(exam.id)));

    for (final attempt in drafts) {
      await _updateSrs(
        attempt.questionId,
        correct: attempt.status == 'correct',
        now: completedAt,
      );
    }

    final dayKey = _dayKey(DateTime.fromMillisecondsSinceEpoch(completedAt));
    final before = await _totalXp();
    final lines = <RewardLine>[];

    for (final attempt in drafts.where((row) => row.status == 'correct')) {
      await _award(
        eventId: 'question_answered:$sessionId:${attempt.questionId}',
        type: 'question_answered',
        requested: 5,
        category: _practice,
        reason: 'Correct answer',
        dayKey: dayKey,
        createdAt: completedAt,
        examId: exam.id,
        subject: attempt.subject,
        topicKey: attempt.topicKey,
        questionId: attempt.questionId,
        lines: lines,
      );
      final previousWrong = await _previousWrongAttempts(
        attempt.questionId,
        excludingExamId: exam.id,
      );
      if (previousWrong > 0) {
        await _award(
          eventId: 'mistake_corrected:$sessionId:${attempt.questionId}',
          type: 'mistake_corrected',
          requested: 15,
          category: _correction,
          reason: 'Mistake corrected',
          dayKey: dayKey,
          createdAt: completedAt,
          examId: exam.id,
          subject: attempt.subject,
          topicKey: attempt.topicKey,
          questionId: attempt.questionId,
          lines: lines,
        );
      }
    }

    await _award(
      eventId: 'exam_completed:$sessionId',
      type: 'exam_completed',
      requested: 20,
      category: _practice,
      reason: 'Mission complete',
      dayKey: dayKey,
      createdAt: completedAt,
      examId: exam.id,
      subject: exam.subject,
      topicKey: exam.topicKey,
      lines: lines,
    );

    if (total >= 20 && score >= 85 && durationSeconds > 0) {
      await _award(
        eventId: 'boss_pass:$sessionId',
        type: 'boss_pass',
        requested: 120,
        category: _mastery,
        reason: 'Gold challenge',
        dayKey: dayKey,
        createdAt: completedAt,
        examId: exam.id,
        subject: exam.subject,
        topicKey: exam.topicKey,
        lines: lines,
      );
    }

    final questProgress = math.min(
      dailyQuestTarget,
      await _answeredOnDay(dayKey),
    );
    final questCompleted = questProgress >= dailyQuestTarget;
    await database
        .into(database.questProgress)
        .insertOnConflictUpdate(
          QuestProgressCompanion.insert(
            questId: 'daily_practice:$dayKey',
            dayKey: dayKey,
            title: dailyQuestTitle,
            progress: questProgress,
            target: dailyQuestTarget,
            completed: questCompleted,
            rewardXp: dailyQuestXp,
            updatedAt: completedAt,
          ),
        );
    if (questCompleted) {
      await _award(
        eventId: 'daily_practice_completed:$dayKey',
        type: 'daily_practice_completed',
        requested: dailyQuestXp,
        category: _bonus,
        reason: 'Daily quest',
        dayKey: dayKey,
        createdAt: completedAt,
        examId: exam.id,
        subject: exam.subject,
        topicKey: exam.topicKey,
        lines: lines,
      );
    }

    // Mixed-topic sessions (revenge, review) are not chapters; letting them
    // mint `topic_mastered:<mode>` would inflate the orbit-atlas achievement.
    if (total >= 5 &&
        score >= 80 &&
        exam.topicKey != null &&
        !_syntheticTopicKeys.contains(exam.topicKey)) {
      await _award(
        eventId: 'topic_mastered:${exam.topicKey}',
        type: 'topic_mastered',
        requested: 80,
        category: _mastery,
        reason: 'Topic mastery',
        dayKey: dayKey,
        createdAt: completedAt,
        examId: exam.id,
        subject: exam.subject,
        topicKey: exam.topicKey,
        lines: lines,
      );
    }

    final after = await _totalXp();
    return MissionCompletion(
      examId: exam.id,
      xpEarned: after - before,
      totalXp: after,
      levelBefore: levelFor(before),
      levelAfter: levelFor(after),
      lines: List.unmodifiable(lines),
    );
  });

  Future<List<String>> revengeIds({DateTime? now}) async {
    final at = (now ?? _clock()).millisecondsSinceEpoch;
    final query = database.select(database.srsStates)
      ..where(
        (row) =>
            row.lapses.isBiggerThanValue(0) &
            row.dueAt.isSmallerOrEqualValue(at),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.dueAt)])
      ..limit(300);
    return (await query.get()).map((row) => row.questionId).toList();
  }

  /// Every question whose spaced-repetition timer has elapsed — correct
  /// answers approaching the forgetting curve as well as lapsed mistakes.
  /// This is the full review orbit; [revengeIds] remains the lapse-only view.
  Future<List<String>> reviewDueIds({DateTime? now, int limit = 300}) async {
    final at = (now ?? _clock()).millisecondsSinceEpoch;
    final query = database.select(database.srsStates)
      ..where((row) => row.dueAt.isSmallerOrEqualValue(at))
      ..orderBy([(row) => OrderingTerm.asc(row.dueAt)])
      ..limit(limit);
    return (await query.get()).map((row) => row.questionId).toList();
  }

  Future<List<RecentExamSummary>> recentExams({int limit = 5}) async {
    final query = database.select(database.exams)
      ..where((row) => row.status.equals('completed'))
      ..orderBy([(row) => OrderingTerm.desc(row.completedAt)])
      ..limit(limit);
    return (await query.get())
        .map(
          (row) => RecentExamSummary(
            id: row.id,
            subject: Subject.fromKey(row.subject),
            topicKey: row.topicKey,
            totalQuestions: row.totalQuestions,
            correctCount: row.correctCount,
            scorePercentage: row.scorePercentage,
            completedAt: DateTime.fromMillisecondsSinceEpoch(
              row.completedAt ?? row.createdAt,
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<AnalyticsSnapshot> analytics() async {
    final rows = await (database.select(
      database.attempts,
    )..where((row) => row.examId.isNotNull())).get();
    final correctRows = rows.where((row) => row.status == 'correct').toList();
    final timed = rows.where((row) => row.timeTakenSeconds > 0).toList();
    final topicBuckets = <String, List<AttemptRow>>{};
    for (final row in rows) {
      topicBuckets.putIfAbsent(row.topicKey, () => []).add(row);
    }
    final weak = topicBuckets.entries.map((entry) {
      final items = entry.value;
      final correct = items.where((row) => row.status == 'correct').length;
      return TopicInsight(
        topicKey: entry.key,
        subject: Subject.fromKey(items.first.subject),
        total: items.length,
        correct: correct,
        accuracy: items.isEmpty ? 0 : correct / items.length * 100,
        averageSeconds: items.isEmpty
            ? 0
            : items.fold<int>(0, (sum, row) => sum + row.timeTakenSeconds) /
                  items.length,
      );
    }).toList()..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    final trapCounts = <String, int>{};
    for (final row in rows.where(
      (item) => item.status == 'wrong' && item.selectedChoiceIndex != null,
    )) {
      final key = '${row.subject}|${row.topicKey}|${row.selectedChoiceIndex}';
      trapCounts[key] = (trapCounts[key] ?? 0) + 1;
    }
    final distractors =
        trapCounts.entries.where((entry) => entry.value >= 2).map((entry) {
          final parts = entry.key.split('|');
          return DistractorInsight(
            subject: Subject.fromKey(parts[0]),
            topicKey: parts[1],
            choiceIndex: int.parse(parts[2]),
            count: entry.value,
          );
        }).toList()..sort((a, b) => b.count.compareTo(a.count));

    final heatmap = <String, int>{};
    for (final row in rows) {
      final day = _dayKey(DateTime.fromMillisecondsSinceEpoch(row.solvedAt));
      heatmap[day] = (heatmap[day] ?? 0) + 1;
    }
    final errorBreakdown = <String, int>{};
    for (final row in rows) {
      final tag = row.errorTag;
      if (row.status != 'wrong' || tag == null) continue;
      errorBreakdown[tag] = (errorBreakdown[tag] ?? 0) + 1;
    }
    return AnalyticsSnapshot(
      totalAnswered: rows.length,
      totalCorrect: correctRows.length,
      accuracy: rows.isEmpty ? 0 : correctRows.length / rows.length * 100,
      averageSeconds: timed.isEmpty
          ? 0
          : timed.fold<int>(0, (sum, row) => sum + row.timeTakenSeconds) /
                timed.length,
      weakTopics: List.unmodifiable(weak),
      distractors: List.unmodifiable(distractors.take(6)),
      heatmap: Map.unmodifiable(heatmap),
      streak: _streakFromDays(heatmap.keys.toSet(), now: _clock()),
      errorBreakdown: Map.unmodifiable(errorBreakdown),
    );
  }

  Future<GamificationSummary> gamificationSummary() async {
    final now = _clock();
    final today = _dayKey(now);
    final total = await _totalXp();
    final level = levelFor(total);
    final questRow = await (database.select(
      database.questProgress,
    )..where((row) => row.dayKey.equals(today))).getSingleOrNull();
    final dayQuery = database.selectOnly(database.xpTransactions)
      ..addColumns([database.xpTransactions.dayKey])
      ..groupBy([database.xpTransactions.dayKey]);
    final days = (await dayQuery.get())
        .map((row) => row.read(database.xpTransactions.dayKey))
        .whereType<String>()
        .toSet();
    final streak = _streakFromDays(days, now: now);
    return GamificationSummary(
      totalXp: total,
      todayXp: await _xpForDay(today),
      level: level,
      levelProgress: levelProgress(total, level),
      streak: streak,
      quest: questRow == null
          ? const DailyQuest(
              title: dailyQuestTitle,
              progress: 0,
              target: dailyQuestTarget,
              rewardXp: dailyQuestXp,
              completed: false,
            )
          : DailyQuest(
              title: questRow.title,
              progress: questRow.progress,
              target: questRow.target,
              rewardXp: questRow.rewardXp,
              completed: questRow.completed,
            ),
      achievements: await _achievementSnapshots(streak: streak),
    );
  }

  Future<List<AchievementSnapshot>> _achievementSnapshots({
    required int streak,
  }) async {
    final values = await Future.wait<int>([
      _countAttemptsWithStatus('correct'),
      _countEvents('mistake_corrected'),
      _countEvents('topic_mastered'),
      _countEvents('boss_pass'),
      _countCompletedMissions(),
      _countPracticedSubjects(),
    ]);
    return GaussGamificationCatalog.evaluate({
      AchievementMetric.correctAnswers: values[0],
      AchievementMetric.correctedMistakes: values[1],
      AchievementMetric.masteredTopics: values[2],
      AchievementMetric.goldChallenges: values[3],
      AchievementMetric.studyRhythm: streak,
      AchievementMetric.completedMissions: values[4],
      AchievementMetric.practicedSubjects: values[5],
    });
  }

  Future<int> _countAttemptsWithStatus(String status) async {
    final count = database.attempts.id.count();
    final query = database.selectOnly(database.attempts)
      ..addColumns([count])
      ..where(
        database.attempts.examId.isNotNull() &
            database.attempts.status.equals(status),
      );
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> _countEvents(String type) async {
    final count = database.gamificationEvents.id.count();
    final query = database.selectOnly(database.gamificationEvents)
      ..addColumns([count])
      ..where(database.gamificationEvents.type.equals(type));
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> _countCompletedMissions() async {
    final count = database.exams.id.count();
    final query = database.selectOnly(database.exams)
      ..addColumns([count])
      ..where(database.exams.status.equals('completed'));
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> _countPracticedSubjects() async {
    final subject = database.attempts.subject;
    final query = database.selectOnly(database.attempts)
      ..addColumns([subject])
      ..where(
        database.attempts.examId.isNotNull() &
            database.attempts.status.isNotValue('skipped'),
      )
      ..groupBy([subject]);
    return (await query.get()).length;
  }

  Future<void> _updateSrs(
    String questionId, {
    required bool correct,
    required int now,
  }) async {
    final previous = await (database.select(
      database.srsStates,
    )..where((row) => row.questionId.equals(questionId))).getSingleOrNull();
    var ease = previous?.ease ?? 2.5;
    var reps = previous?.reps ?? 0;
    var lapses = previous?.lapses ?? 0;
    var interval = previous?.intervalDays ?? 0;
    late final int dueAt;
    if (correct) {
      reps += 1;
      interval = switch (reps) {
        1 => 1,
        2 => 3,
        _ => (interval * ease).ceil(),
      };
      ease = math.min(2.8, ease + .1);
      dueAt = now + interval * Duration.millisecondsPerDay;
    } else {
      lapses += 1;
      reps = 0;
      interval = 0;
      ease = math.max(1.3, ease - .2);
      dueAt = now;
    }
    await database
        .into(database.srsStates)
        .insertOnConflictUpdate(
          SrsStatesCompanion.insert(
            questionId: questionId,
            ease: Value(ease),
            intervalDays: Value(interval),
            reps: Value(reps),
            lapses: Value(lapses),
            dueAt: dueAt,
            updatedAt: now,
          ),
        );
  }

  Future<void> _award({
    required String eventId,
    required String type,
    required int requested,
    required String category,
    required String reason,
    required String dayKey,
    required int createdAt,
    required int examId,
    required String subject,
    required String? topicKey,
    required List<RewardLine> lines,
    String? questionId,
  }) async {
    final existing = await (database.select(
      database.gamificationEvents,
    )..where((row) => row.id.equals(eventId))).getSingleOrNull();
    if (existing != null) return;
    await database
        .into(database.gamificationEvents)
        .insert(
          GamificationEventsCompanion.insert(
            id: eventId,
            type: type,
            subject: Value(subject),
            topicKey: Value(topicKey),
            examId: Value(examId),
            questionId: Value(questionId),
            dayKey: dayKey,
            createdAt: createdAt,
          ),
        );
    final amount = await _cappedAmount(dayKey, category, requested);
    if (amount <= 0) return;
    await database
        .into(database.xpTransactions)
        .insert(
          XpTransactionsCompanion.insert(
            id: 'xp:$eventId',
            eventId: eventId,
            amount: amount,
            category: category,
            reason: reason,
            dayKey: dayKey,
            createdAt: createdAt,
          ),
        );
    lines.add(RewardLine(reason: reason, amount: amount, category: category));
  }

  Future<int> _cappedAmount(
    String dayKey,
    String category,
    int requested,
  ) async {
    final cap = switch (category) {
      _practice => 200,
      _correction => 120,
      _ => null,
    };
    if (cap == null) return requested;
    final sum = database.xpTransactions.amount.sum();
    final query = database.selectOnly(database.xpTransactions)
      ..addColumns([sum])
      ..where(
        database.xpTransactions.dayKey.equals(dayKey) &
            database.xpTransactions.category.equals(category),
      );
    final used = (await query.getSingle()).read(sum) ?? 0;
    return math.min(requested, math.max(0, cap - used));
  }

  Future<int> _totalXp() async {
    final sum = database.xpTransactions.amount.sum();
    final query = database.selectOnly(database.xpTransactions)
      ..addColumns([sum]);
    return (await query.getSingle()).read(sum) ?? 0;
  }

  Future<int> _xpForDay(String dayKey) async {
    final sum = database.xpTransactions.amount.sum();
    final query = database.selectOnly(database.xpTransactions)
      ..addColumns([sum])
      ..where(database.xpTransactions.dayKey.equals(dayKey));
    return (await query.getSingle()).read(sum) ?? 0;
  }

  Future<int> _answeredOnDay(String dayKey) async {
    final start = DateTime.parse(dayKey).millisecondsSinceEpoch;
    final end = start + Duration.millisecondsPerDay;
    final count = database.attempts.id.count();
    final query = database.selectOnly(database.attempts)
      ..addColumns([count])
      ..where(
        database.attempts.examId.isNotNull() &
            database.attempts.solvedAt.isBiggerOrEqualValue(start) &
            database.attempts.solvedAt.isSmallerThanValue(end) &
            database.attempts.status.isNotValue('skipped'),
      );
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> _previousWrongAttempts(
    String questionId, {
    required int excludingExamId,
  }) async {
    final count = database.attempts.id.count();
    final query = database.selectOnly(database.attempts)
      ..addColumns([count])
      ..where(
        database.attempts.questionId.equals(questionId) &
            database.attempts.status.equals('wrong') &
            database.attempts.examId.isNotNull() &
            database.attempts.examId.isNotValue(excludingExamId),
      );
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<MissionCompletion> _completionForExam(int examId) async {
    final totalAfter = await _totalXp();
    final joined = database.select(database.xpTransactions).join([
      innerJoin(
        database.gamificationEvents,
        database.gamificationEvents.id.equalsExp(
          database.xpTransactions.eventId,
        ),
      ),
    ])..where(database.gamificationEvents.examId.equals(examId));
    final rows = await joined.get();
    final lines = rows
        .map((row) => row.readTable(database.xpTransactions))
        .map(
          (row) => RewardLine(
            reason: row.reason,
            amount: row.amount,
            category: row.category,
          ),
        )
        .toList(growable: false);
    final earned = lines.fold<int>(0, (sum, line) => sum + line.amount);
    return MissionCompletion(
      examId: examId,
      xpEarned: earned,
      totalXp: totalAfter,
      levelBefore: levelFor(totalAfter - earned),
      levelAfter: levelFor(totalAfter),
      lines: lines,
    );
  }

  AttemptRecord _attemptFromRow(AttemptRow row) => AttemptRecord(
    sessionId: row.sessionId,
    missionIndex: row.missionIndex,
    questionId: row.questionId,
    subject: Subject.fromKey(row.subject),
    topicKey: row.topicKey,
    selectedChoiceIndex: row.selectedChoiceIndex,
    correct: row.status == 'correct',
    elapsedSeconds: row.timeTakenSeconds,
    at: DateTime.fromMillisecondsSinceEpoch(row.solvedAt),
    examId: row.examId,
    finalized: row.examId != null,
    errorTag: row.errorTag,
  );

  StudyRecord _studyRecordFromRow(StudyRecordRow row) => StudyRecord(
    questionId: row.questionId,
    topicKey: row.topicKey,
    shelfKey: row.shelfKey,
    hypothesisChoiceIndex: row.hypothesisChoiceIndex,
    reflection: StudyReflection.fromKey(row.reflection),
    firstReflectedAt: DateTime.fromMillisecondsSinceEpoch(row.firstReflectedAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
  );

  static int levelFor(int xp) => math.sqrt(math.max(0, xp) / 160).floor() + 1;

  static double levelProgress(int xp, [int? currentLevel]) {
    final level = currentLevel ?? levelFor(xp);
    final start = (level - 1) * (level - 1) * 160;
    final end = level * level * 160;
    return ((xp - start) / (end - start)).clamp(0, 1);
  }

  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static bool _sameQueue(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static int _streakFromDays(Set<String> days, {DateTime? now}) {
    if (days.isEmpty) return 0;
    var day = now ?? DateTime.now();
    if (!days.contains(_dayKey(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (days.contains(_dayKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
