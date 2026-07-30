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
  static const _study = 'study';
  static const _syntheticTopicKeys = {'revenge', 'review'};

  static const studyReflectXp = 4;
  static const revisitClearedXp = 12;
  static const setCompletedXp = 20;
  static const unitCompletedXp = 60;
  static const unitTouchedXp = 8;
  static const sectionCompletedXp = 120;

  Future<void> initialize() async {
    await database.customSelect('SELECT 1').getSingle();
  }

  static const tourSeenFlag = 'tour_seen';

  Future<bool> readFlag(String key) async {
    final row = await (database.select(
      database.appFlags,
    )..where((item) => item.key.equals(key))).getSingleOrNull();
    return row?.value == 'true';
  }

  Future<void> writeFlag(String key, {required bool value}) async {
    await database
        .into(database.appFlags)
        .insertOnConflictUpdate(
          AppFlagsCompanion.insert(
            key: key,
            value: value ? 'true' : 'false',
            updatedAt: _clock().millisecondsSinceEpoch,
          ),
        );
  }

  Future<List<StudyRecord>> studyRecords({String? topicKey}) async {
    final query = database.select(database.studyRecords);
    if (topicKey != null) {
      query.where((row) => row.topicKey.equals(topicKey));
    }
    query.orderBy([(row) => OrderingTerm.asc(row.firstReflectedAt)]);
    return (await query.get()).map(_studyRecordFromRow).toList(growable: false);
  }

  Future<StudyReflectionOutcome> saveStudyReflection({
    required String questionId,
    required String topicKey,
    required String subjectKey,
    required String shelfKey,
    required int setSize,
    required int topicQuestionCount,
    required int? hypothesisChoiceIndex,
    required bool? hypothesisMatched,
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
    final xpBefore = await _totalXp();
    final existing = await (database.select(
      database.studyRecords,
    )..where((row) => row.questionId.equals(questionId))).getSingleOrNull();
    if (existing != null &&
        existing.topicKey == topicKey &&
        existing.shelfKey == shelfKey &&
        existing.hypothesisChoiceIndex == hypothesisChoiceIndex &&
        existing.hypothesisMatched == hypothesisMatched &&
        existing.reflection == reflection.key) {
      return StudyReflectionOutcome(
        record: _studyRecordFromRow(existing),
        lines: const [],
        setCompleted: false,
        unitCompleted: false,
        dailyQuestCompleted: false,
        xpEarned: 0,
        totalXp: xpBefore,
        levelBefore: levelFor(xpBefore),
        levelAfter: levelFor(xpBefore),
      );
    }
    final isFirst = existing == null;
    if (isFirst) {
      await database
          .into(database.studyRecords)
          .insert(
            StudyRecordsCompanion.insert(
              questionId: questionId,
              topicKey: topicKey,
              shelfKey: shelfKey,
              hypothesisChoiceIndex: Value(hypothesisChoiceIndex),
              hypothesisMatched: Value(hypothesisMatched),
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
          hypothesisMatched: Value(hypothesisMatched),
          shelfKey: Value(shelfKey),
          reflection: Value(reflection.key),
          updatedAt: Value(now),
        ),
      );
    }
    await _updateStudySrs(questionId, reflection: reflection, now: now);

    // Rule version 2: rewards for the act of studying, granted inside the
    // same transaction through the idempotent event ledger. Nothing here
    // claims the unverified source mapping is correct.
    final dayKey = _dayKey(DateTime.fromMillisecondsSinceEpoch(now));
    final lines = <RewardLine>[];
    var setCompleted = false;
    var unitCompleted = false;
    var dailyQuestCompleted = false;
    if (isFirst) {
      await _award(
        eventId: 'study_reflected:$questionId',
        type: 'study_reflected',
        requested: studyReflectXp,
        category: _study,
        reason: 'Question charted',
        dayKey: dayKey,
        createdAt: now,
        examId: null,
        subject: subjectKey,
        topicKey: topicKey,
        questionId: questionId,
        lines: lines,
      );
      final topicReflected = await _countStudyRecords(topicKey: topicKey);
      if (topicReflected == 1) {
        await _award(
          eventId: 'unit_touched:$topicKey',
          type: 'unit_touched',
          requested: unitTouchedXp,
          category: _bonus,
          reason: 'New unit reached',
          dayKey: dayKey,
          createdAt: now,
          examId: null,
          subject: subjectKey,
          topicKey: topicKey,
          lines: lines,
        );
      }
      if (setSize > 0) {
        final setReflected = await _countStudyRecords(shelfKey: shelfKey);
        if (setReflected >= setSize) {
          setCompleted = true;
          await _award(
            eventId: 'set_completed:$shelfKey',
            type: 'set_completed',
            requested: setCompletedXp,
            category: _mastery,
            reason: 'Study set complete',
            dayKey: dayKey,
            createdAt: now,
            examId: null,
            subject: subjectKey,
            topicKey: topicKey,
            lines: lines,
          );
        }
      }
      if (topicQuestionCount > 0 && topicReflected >= topicQuestionCount) {
        unitCompleted = true;
        await _award(
          eventId: 'unit_completed:$topicKey',
          type: 'unit_completed',
          requested: unitCompletedXp,
          category: _mastery,
          reason: 'Unit complete',
          dayKey: dayKey,
          createdAt: now,
          examId: null,
          subject: subjectKey,
          topicKey: topicKey,
          lines: lines,
        );
      }
      final reflectedToday = await _reflectionsOnDay(dayKey);
      final questProgressCount = math.min(dailyQuestTarget, reflectedToday);
      await database
          .into(database.questProgress)
          .insertOnConflictUpdate(
            QuestProgressCompanion.insert(
              questId: 'daily_study:$dayKey',
              dayKey: dayKey,
              title: dailyQuestTitle,
              progress: questProgressCount,
              target: dailyQuestTarget,
              completed: reflectedToday >= dailyQuestTarget,
              rewardXp: dailyQuestXp,
              updatedAt: now,
            ),
          );
      if (reflectedToday >= dailyQuestTarget) {
        dailyQuestCompleted = await _award(
          eventId: 'daily_study_completed:$dayKey',
          type: 'daily_study_completed',
          requested: dailyQuestXp,
          category: _bonus,
          reason: 'Daily observation',
          dayKey: dayKey,
          createdAt: now,
          examId: null,
          subject: subjectKey,
          topicKey: topicKey,
          lines: lines,
        );
      }
    } else if (existing.reflection == StudyReflection.revisit.key &&
        !reflection.needsAnotherPass &&
        _dayKey(DateTime.fromMillisecondsSinceEpoch(existing.updatedAt)) !=
            dayKey) {
      await _award(
        eventId: 'revisit_cleared:$questionId',
        type: 'revisit_cleared',
        requested: revisitClearedXp,
        category: _correction,
        reason: 'Revisit cleared',
        dayKey: dayKey,
        createdAt: now,
        examId: null,
        subject: subjectKey,
        topicKey: topicKey,
        questionId: questionId,
        lines: lines,
      );
    }

    final xpAfter = await _totalXp();
    final saved = await (database.select(
      database.studyRecords,
    )..where((row) => row.questionId.equals(questionId))).getSingle();
    return StudyReflectionOutcome(
      record: _studyRecordFromRow(saved),
      lines: List.unmodifiable(lines),
      setCompleted: setCompleted,
      unitCompleted: unitCompleted,
      dailyQuestCompleted: dailyQuestCompleted,
      xpEarned: xpAfter - xpBefore,
      totalXp: xpAfter,
      levelBefore: levelFor(xpBefore),
      levelAfter: levelFor(xpAfter),
    );
  });

  /// Marks a whole curriculum section complete, once, through the same
  /// idempotent ledger. The caller (controller) owns section membership.
  Future<void> awardSectionCompleted({
    required String sectionId,
    required String subjectKey,
  }) async {
    await database.transaction(() async {
      final now = _clock().millisecondsSinceEpoch;
      await _award(
        eventId: 'section_completed:$sectionId',
        type: 'section_completed',
        requested: sectionCompletedXp,
        category: _mastery,
        reason: 'Section complete',
        dayKey: _dayKey(DateTime.fromMillisecondsSinceEpoch(now)),
        createdAt: now,
        examId: null,
        subject: subjectKey,
        topicKey: null,
        lines: <RewardLine>[],
      );
    });
  }

  Future<int> _countStudyRecords({String? topicKey, String? shelfKey}) async {
    final count = database.studyRecords.questionId.count();
    final query = database.selectOnly(database.studyRecords)
      ..addColumns([count]);
    if (topicKey != null) {
      query.where(database.studyRecords.topicKey.equals(topicKey));
    }
    if (shelfKey != null) {
      query.where(database.studyRecords.shelfKey.equals(shelfKey));
    }
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<int> _reflectionsOnDay(String dayKey) async {
    final count = database.gamificationEvents.id.count();
    final query = database.selectOnly(database.gamificationEvents)
      ..addColumns([count])
      ..where(
        database.gamificationEvents.type.equals('study_reflected') &
            database.gamificationEvents.dayKey.equals(dayKey),
      );
    return (await query.getSingle()).read(count) ?? 0;
  }

  /// Spaced revisit scheduling over the shared SRS table. A `revisit`
  /// reflection comes due tomorrow (never immediately, so the study loop is
  /// not interrupted); a `clear` reflection earns a growing interval. This is
  /// a private pacing aid — it never claims correctness of source content.
  Future<void> _updateStudySrs(
    String questionId, {
    required StudyReflection reflection,
    required int now,
  }) async {
    final previous = await (database.select(
      database.srsStates,
    )..where((row) => row.questionId.equals(questionId))).getSingleOrNull();
    var ease = previous?.ease ?? 2.5;
    var reps = previous?.reps ?? 0;
    var lapses = previous?.lapses ?? 0;
    var interval = previous?.intervalDays ?? 0;
    if (reflection.needsAnotherPass) {
      lapses += 1;
      reps = 0;
      interval = 1;
      ease = math.max(1.3, ease - .2);
    } else {
      reps += 1;
      interval = switch (reps) {
        1 => 3,
        2 => 7,
        _ => (interval * ease).ceil(),
      };
      ease = math.min(2.8, ease + .1);
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
            dueAt: now + interval * Duration.millisecondsPerDay,
            updatedAt: now,
          ),
        );
  }

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
    final rows = await query.get();
    if (rows.isEmpty) return const [];
    final dueByQuestion = <String, int>{};
    for (final srs in await database.select(database.srsStates).get()) {
      dueByQuestion[srs.questionId] = srs.dueAt;
    }
    // Oldest due first; unscheduled legacy rows sort as immediately due.
    final ids = rows.map((row) => row.questionId).toList()
      ..sort(
        (a, b) => (dueByQuestion[a] ?? 0).compareTo(dueByQuestion[b] ?? 0),
      );
    return List.unmodifiable(ids);
  }

  /// Revisit-marked questions whose spacing timer has elapsed.
  Future<List<String>> studyDueIds({DateTime? now}) async {
    final at = (now ?? _clock()).millisecondsSinceEpoch;
    final revisit = await (database.select(database.studyRecords)..where(
          (row) => row.reflection.equals(StudyReflection.revisit.key),
        ))
        .get();
    if (revisit.isEmpty) return const [];
    final dueByQuestion = <String, int>{};
    for (final srs in await database.select(database.srsStates).get()) {
      dueByQuestion[srs.questionId] = srs.dueAt;
    }
    final due = [
      for (final row in revisit)
        if ((dueByQuestion[row.questionId] ?? 0) <= at) row.questionId,
    ]..sort(
      (a, b) => (dueByQuestion[a] ?? 0).compareTo(dueByQuestion[b] ?? 0),
    );
    return List.unmodifiable(due);
  }

  Future<StudySummary> studySummary() async {
    final records = await studyRecords();
    final byTopic = <String, List<StudyRecord>>{};
    final byShelf = <String, List<StudyRecord>>{};
    final heatmap = <String, int>{};
    var clearCount = 0;
    var revisitCount = 0;
    var gemCount = 0;
    var hypothesisCount = 0;
    var hypothesisMatchedCount = 0;
    for (final record in records) {
      byTopic.putIfAbsent(record.topicKey, () => []).add(record);
      byShelf.putIfAbsent(record.shelfKey, () => []).add(record);
      switch (record.reflection) {
        case StudyReflection.clear:
          clearCount++;
        case StudyReflection.revisit:
          revisitCount++;
        case StudyReflection.gem:
          gemCount++;
      }
      if (record.hypothesisMatched case final matched?) {
        hypothesisCount++;
        if (matched) hypothesisMatchedCount++;
      }
      final day = _dayKey(record.firstReflectedAt);
      heatmap[day] = (heatmap[day] ?? 0) + 1;
    }
    return StudySummary(
      totalReflected: records.length,
      clearCount: clearCount,
      revisitCount: revisitCount,
      gemCount: gemCount,
      hypothesisCount: hypothesisCount,
      hypothesisMatchedCount: hypothesisMatchedCount,
      touchedTopics: byTopic.length,
      byTopic: {
        for (final entry in byTopic.entries) entry.key: _snapshot(entry.value),
      },
      byShelf: {
        for (final entry in byShelf.entries) entry.key: _snapshot(entry.value),
      },
      heatmap: heatmap,
    );
  }

  static StudyTopicSnapshot _snapshot(List<StudyRecord> records) {
    var clear = 0;
    var revisit = 0;
    var gem = 0;
    for (final record in records) {
      switch (record.reflection) {
        case StudyReflection.clear:
          clear++;
        case StudyReflection.revisit:
          revisit++;
        case StudyReflection.gem:
          gem++;
      }
    }
    return StudyTopicSnapshot(
      reflected: records.length,
      clear: clear,
      revisit: revisit,
      gem: gem,
    );
  }

  /// The keepsake shelf: questions marked as gems, newest first.
  Future<List<String>> gemStudyIds() async {
    final query = database.select(database.studyRecords)
      ..where((row) => row.reflection.equals(StudyReflection.gem.key))
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);
    return (await query.get())
        .map((row) => row.questionId)
        .toList(growable: false);
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
    final questRow =
        await (database.select(database.questProgress)..where(
              (row) =>
                  row.dayKey.equals(today) &
                  row.questId.like('daily_study:%'),
            ))
            .getSingleOrNull();
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

  /// Catalog v2 metric sources: every achievement now derives from
  /// study-native ledger events and records. Mission-era events remain in
  /// the ledger as history but no longer feed any metric.
  Future<List<AchievementSnapshot>> _achievementSnapshots({
    required int streak,
  }) async {
    final values = await Future.wait<int>([
      _countStudyRecords(),
      _countEvents('revisit_cleared'),
      _countEvents('unit_completed'),
      _countEvents('section_completed'),
      _countEvents('set_completed'),
      _countStudySubjects(),
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

  Future<int> _countStudySubjects() async {
    final subject = database.gamificationEvents.subject;
    final query = database.selectOnly(database.gamificationEvents)
      ..addColumns([subject])
      ..where(database.gamificationEvents.type.equals('study_reflected'))
      ..groupBy([subject]);
    return (await query.get()).length;
  }

  Future<int> _countEvents(String type) async {
    final count = database.gamificationEvents.id.count();
    final query = database.selectOnly(database.gamificationEvents)
      ..addColumns([count])
      ..where(database.gamificationEvents.type.equals(type));
    return (await query.getSingle()).read(count) ?? 0;
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

  /// Returns whether an idempotent event was recorded. A reward can be
  /// recorded with zero new XP when a category cap is exhausted; callers can
  /// still present the truthful milestone without treating the presentation as
  /// a grant authority.
  Future<bool> _award({
    required String eventId,
    required String type,
    required int requested,
    required String category,
    required String reason,
    required String dayKey,
    required int createdAt,
    required int? examId,
    required String subject,
    required String? topicKey,
    required List<RewardLine> lines,
    String? questionId,
  }) async {
    final existing = await (database.select(
      database.gamificationEvents,
    )..where((row) => row.id.equals(eventId))).getSingleOrNull();
    if (existing != null) return false;
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
    if (amount <= 0) return true;
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
    return true;
  }

  Future<int> _cappedAmount(
    String dayKey,
    String category,
    int requested,
  ) async {
    final cap = switch (category) {
      _practice => 200,
      _correction => 120,
      _study => 120,
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
    hypothesisMatched: row.hypothesisMatched,
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
