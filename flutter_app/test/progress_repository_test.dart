import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/domain/gamification_catalog.dart';
import 'package:gauss/domain/models.dart';

void main() {
  late GaussDatabase database;
  late ProgressRepository repository;
  late DateTime clockNow;

  setUp(() async {
    database = GaussDatabase(NativeDatabase.memory());
    clockNow = DateTime(2026, 7, 12, 10);
    repository = ProgressRepository(database, clock: () => clockNow);
    await repository.initialize();
  });

  tearDown(() => database.close());

  test('level curve starts at one and remains bounded', () {
    expect(ProgressRepository.levelFor(0), 1);
    expect(ProgressRepository.levelFor(159), 1);
    expect(ProgressRepository.levelFor(160), 2);
    expect(ProgressRepository.levelProgress(0), inInclusiveRange(0, 1));
    expect(ProgressRepository.levelProgress(10000), inInclusiveRange(0, 1));
  });

  test(
    'mission finalization atomically persists history, SRS, XP, and quest',
    () async {
      final now = clockNow;
      await repository.startMission(
        sessionId: 'mission-one',
        subject: Subject.math,
        topicKey: 'sets',
        createdAt: now.millisecondsSinceEpoch,
        questionIds: const ['q1', 'q2', 'q3'],
      );
      await repository.saveDraftAttempt(
        _attempt('mission-one', 0, 'q1', true, now),
      );
      await repository.saveDraftAttempt(
        _attempt('mission-one', 1, 'q2', false, now),
      );
      await repository.saveDraftAttempt(
        _attempt('mission-one', 2, 'q3', true, now),
      );

      final completion = await repository.finalizeMission(
        sessionId: 'mission-one',
        durationSeconds: 90,
      );

      expect(completion.xpEarned, 30);
      expect(completion.totalXp, 30);
      expect(await repository.loadAttempts(), hasLength(3));
      expect(await repository.activeMission(), isNull);
      final analytics = await repository.analytics();
      expect(analytics.totalAnswered, 3);
      expect(analytics.totalCorrect, 2);
      expect(analytics.accuracy, closeTo(66.666, .01));
      final summary = await repository.gamificationSummary();
      final quest = summary.quest;
      expect(quest.progress, 3);
      expect(quest.completed, isFalse);
      expect(
        summary.achievements
            .singleWhere((item) => item.definition.id == 'proof_ledger')
            .current,
        2,
      );
      expect(
        summary.achievements
            .singleWhere((item) => item.definition.id == 'mission_archive')
            .current,
        1,
      );

      final correctSrs = await (database.select(
        database.srsStates,
      )..where((row) => row.questionId.equals('q1'))).getSingle();
      final wrongSrs = await (database.select(
        database.srsStates,
      )..where((row) => row.questionId.equals('q2'))).getSingle();
      expect(correctSrs.reps, 1);
      expect(correctSrs.intervalDays, 1);
      expect(wrongSrs.reps, 0);
      expect(wrongSrs.lapses, 1);
    },
  );

  test('repeating finalization is idempotent', () async {
    final now = clockNow;
    await repository.startMission(
      sessionId: 'same-session',
      subject: Subject.physics,
      topicKey: 'dynamics',
      createdAt: now.millisecondsSinceEpoch,
      questionIds: const ['p1'],
    );
    await repository.saveDraftAttempt(
      _attempt(
        'same-session',
        0,
        'p1',
        true,
        now,
        subject: Subject.physics,
        topic: 'dynamics',
      ),
    );

    final first = await repository.finalizeMission(
      sessionId: 'same-session',
      durationSeconds: 20,
    );
    final second = await repository.finalizeMission(
      sessionId: 'same-session',
      durationSeconds: 20,
    );

    expect(first.totalXp, 25);
    expect(second.totalXp, 25);
    expect(
      await database.select(database.gamificationEvents).get(),
      hasLength(2),
    );
    expect(await database.select(database.xpTransactions).get(), hasLength(2));
  });

  test('draft upsert prevents duplicate rapid taps', () async {
    final now = clockNow;
    await repository.startMission(
      sessionId: 'rapid-tap',
      subject: Subject.math,
      topicKey: 'sets',
      createdAt: now.millisecondsSinceEpoch,
      questionIds: const ['q1'],
    );
    await repository.saveDraftAttempt(
      _attempt('rapid-tap', 0, 'q1', false, now),
    );
    await repository.saveDraftAttempt(
      _attempt('rapid-tap', 0, 'q1', true, now),
    );

    final rows = await database.select(database.attempts).get();
    expect(rows, hasLength(1));
    expect(rows.single.status, 'correct');
  });

  test(
    'active mission restores its exact queue and recorded attempts',
    () async {
      final now = clockNow.add(const Duration(hours: 4, minutes: 30));
      await repository.startMission(
        sessionId: 'resume-me',
        subject: Subject.math,
        topicKey: 'sets',
        createdAt: now.millisecondsSinceEpoch,
        questionIds: const ['q3', 'q1', 'q2'],
      );
      await repository.saveDraftAttempt(
        _attempt('resume-me', 0, 'q3', true, now),
      );

      final saved = await repository.activeMission();

      expect(saved, isNotNull);
      expect(saved!.sessionId, 'resume-me');
      expect(saved.topicKey, 'sets');
      expect(saved.questionIds, const ['q3', 'q1', 'q2']);
      expect(saved.attempts, hasLength(1));
      expect(saved.attempts.single.questionId, 'q3');
      expect(saved.attempts.single.finalized, isFalse);
    },
  );

  test('starting a new mission retires the previous active queue', () async {
    final now = clockNow;
    await repository.startMission(
      sessionId: 'older',
      subject: Subject.math,
      topicKey: 'sets',
      createdAt: now.millisecondsSinceEpoch,
      questionIds: const ['old-q'],
    );
    await repository.startMission(
      sessionId: 'newer',
      subject: Subject.physics,
      topicKey: 'dynamics',
      createdAt: now.add(const Duration(seconds: 1)).millisecondsSinceEpoch,
      questionIds: const ['new-q'],
    );

    expect((await repository.activeMission())!.sessionId, 'newer');
    final older = await (database.select(
      database.exams,
    )..where((row) => row.sessionId.equals('older'))).getSingle();
    expect(older.status, 'abandoned');
  });

  test(
    'a persisted session cannot be reopened with a different queue',
    () async {
      final now = clockNow;
      await repository.startMission(
        sessionId: 'stable-queue',
        subject: Subject.math,
        topicKey: 'sets',
        createdAt: now.millisecondsSinceEpoch,
        questionIds: const ['q1', 'q2'],
      );

      await expectLater(
        repository.startMission(
          sessionId: 'stable-queue',
          subject: Subject.math,
          topicKey: 'sets',
          createdAt: now.millisecondsSinceEpoch,
          questionIds: const ['q2', 'q1'],
        ),
        throwsStateError,
      );
      expect((await repository.activeMission())!.questionIds, const [
        'q1',
        'q2',
      ]);
    },
  );

  test(
    'correcting a previous mistake grants the correction event once',
    () async {
      final now = clockNow;
      await _completeSingle(repository, 'wrong-session', 'q1', false, now);
      final corrected = await _completeSingle(
        repository,
        'correct-session',
        'q1',
        true,
        now.add(const Duration(minutes: 1)),
      );

      expect(corrected.xpEarned, 40);
      final correctionEvents = await (database.select(
        database.gamificationEvents,
      )..where((row) => row.type.equals('mistake_corrected'))).get();
      expect(correctionEvents, hasLength(1));
    },
  );

  test('an empty mission cannot produce phantom success', () async {
    final now = clockNow;
    await repository.startMission(
      sessionId: 'empty',
      subject: Subject.math,
      topicKey: 'sets',
      createdAt: now.millisecondsSinceEpoch,
      questionIds: const ['q1'],
    );

    await expectLater(
      repository.finalizeMission(sessionId: 'empty', durationSeconds: 0),
      throwsStateError,
    );
    final exam = await (database.select(
      database.exams,
    )..where((row) => row.sessionId.equals('empty'))).getSingle();
    expect(exam.status, 'active');
    expect(await database.select(database.xpTransactions).get(), isEmpty);
  });

  test(
    'a qualifying long mission grants real boss, mastery, and quest rewards',
    () async {
      final now = clockNow;
      await repository.startMission(
        sessionId: 'gold-run',
        subject: Subject.math,
        topicKey: 'sets',
        createdAt: now.millisecondsSinceEpoch,
        questionIds: [for (var index = 0; index < 20; index++) 'gold-$index'],
      );
      for (var index = 0; index < 20; index++) {
        await repository.saveDraftAttempt(
          _attempt('gold-run', index, 'gold-$index', true, now),
        );
      }

      final completion = await repository.finalizeMission(
        sessionId: 'gold-run',
        durationSeconds: 600,
      );

      expect(completion.xpEarned, 360);
      expect(
        completion.lines.map((line) => line.reason),
        containsAll(['Gold challenge', 'Daily quest', 'Topic mastery']),
      );
      final summary = await repository.gamificationSummary();
      expect(summary.quest.completed, isTrue);
      expect(
        summary.achievements
            .singleWhere(
              (item) =>
                  item.definition.metric == AchievementMetric.goldChallenges,
            )
            .current,
        1,
      );
      expect(
        summary.achievements
            .singleWhere(
              (item) =>
                  item.definition.metric == AchievementMetric.masteredTopics,
            )
            .current,
        1,
      );
    },
  );

  test('revisit reflections come due tomorrow, clear ones rest longer', () async {
    await repository.saveStudyReflection(
      questionId: 'study-q1',
      topicKey: 'sets',
      shelfKey: 'sets:0:20',
      hypothesisChoiceIndex: 1,
      reflection: StudyReflection.revisit,
    );
    await repository.saveStudyReflection(
      questionId: 'study-q2',
      topicKey: 'sets',
      shelfKey: 'sets:0:20',
      hypothesisChoiceIndex: null,
      reflection: StudyReflection.clear,
    );

    // Nothing interrupts the current session: neither card is due today.
    expect(await repository.studyDueIds(), isEmpty);

    // Tomorrow the revisit card surfaces; the clear card keeps resting.
    clockNow = clockNow.add(const Duration(days: 1, minutes: 1));
    expect(await repository.studyDueIds(), const ['study-q1']);
    expect(await repository.revisitStudyIds(), const ['study-q1']);

    // Day four: the clear card's first interval (3 days) elapses, but only
    // revisit-marked cards ever enter the due queue.
    clockNow = clockNow.add(const Duration(days: 3));
    expect(await repository.studyDueIds(), const ['study-q1']);

    // Clearing the revisit empties the queue and extends its interval.
    await repository.saveStudyReflection(
      questionId: 'study-q1',
      topicKey: 'sets',
      shelfKey: 'sets:0:20',
      hypothesisChoiceIndex: 1,
      reflection: StudyReflection.clear,
    );
    expect(await repository.studyDueIds(), isEmpty);
  });

  test('review orbit surfaces every due card, not only lapses', () async {
    final now = clockNow;
    await repository.startMission(
      sessionId: 'srs-seed',
      subject: Subject.math,
      topicKey: 'sets',
      createdAt: now.millisecondsSinceEpoch,
      questionIds: const ['q-right', 'q-wrong'],
    );
    await repository.saveDraftAttempt(
      _attempt('srs-seed', 0, 'q-right', true, now),
    );
    await repository.saveDraftAttempt(
      _attempt('srs-seed', 1, 'q-wrong', false, now),
    );
    await repository.finalizeMission(
      sessionId: 'srs-seed',
      durationSeconds: 30,
    );

    // Immediately after: only the lapse is due (correct answer waits a day).
    expect(await repository.reviewDueIds(), const ['q-wrong']);
    expect(await repository.revengeIds(), const ['q-wrong']);

    // A day later the remembered proof approaches the forgetting curve and
    // enters the review orbit, while revenge still only sees the lapse.
    clockNow = clockNow.add(const Duration(days: 1, minutes: 1));
    expect(
      await repository.reviewDueIds(),
      containsAll(const ['q-right', 'q-wrong']),
    );
    expect(await repository.revengeIds(), const ['q-wrong']);
  });

  test(
    'mixed-topic review and revenge sessions never mint topic mastery',
    () async {
      final now = clockNow;
      for (final mode in const ['review', 'revenge']) {
        await repository.startMission(
          sessionId: 'synthetic-$mode',
          subject: Subject.math,
          topicKey: mode,
          createdAt: now.millisecondsSinceEpoch,
          questionIds: [for (var i = 0; i < 5; i++) '$mode-q$i'],
        );
        for (var i = 0; i < 5; i++) {
          await repository.saveDraftAttempt(
            _attempt('synthetic-$mode', i, '$mode-q$i', true, now),
          );
        }
        await repository.finalizeMission(
          sessionId: 'synthetic-$mode',
          durationSeconds: 60,
        );
      }

      final masteryEvents = await (database.select(
        database.gamificationEvents,
      )..where((row) => row.type.equals('topic_mastered'))).get();
      expect(masteryEvents, isEmpty);
    },
  );

  test('miss tags persist through finalization and feed the anatomy', () async {
    final now = clockNow;
    await repository.startMission(
      sessionId: 'tagged-miss',
      subject: Subject.math,
      topicKey: 'sets',
      createdAt: now.millisecondsSinceEpoch,
      questionIds: const ['q-miss'],
    );
    await repository.saveDraftAttempt(
      _attempt('tagged-miss', 0, 'q-miss', false, now),
    );
    await repository.tagAttempt(
      sessionId: 'tagged-miss',
      questionId: 'q-miss',
      errorTag: 'careless',
    );
    await repository.finalizeMission(
      sessionId: 'tagged-miss',
      durationSeconds: 20,
    );

    final tagged = await repository.analytics();
    expect(tagged.errorBreakdown, {'careless': 1});
    final loaded = (await repository.loadAttempts()).single;
    expect(loaded.errorTag, 'careless');

    // Clearing the tag is honored and the anatomy empties again.
    await repository.tagAttempt(
      sessionId: 'tagged-miss',
      questionId: 'q-miss',
      errorTag: null,
    );
    expect((await repository.analytics()).errorBreakdown, isEmpty);
  });

  test(
    'daily quest and streak honor the injected local-day boundary',
    () async {
      clockNow = DateTime(2026, 7, 12, 23, 59);
      await _completeSingle(
        repository,
        'before-midnight',
        'q-midnight',
        true,
        clockNow,
      );

      final before = await repository.gamificationSummary();
      expect(before.quest.progress, 1);
      expect(before.todayXp, 25);
      expect(before.streak, 1);

      clockNow = DateTime(2026, 7, 13, 0, 1);
      final after = await repository.gamificationSummary();
      expect(after.quest.progress, 0);
      expect(after.todayXp, 0);
      expect(after.streak, 1);
    },
  );

  test(
    'source reflections are idempotent and never mint scored rewards',
    () async {
      final first = await repository.saveStudyReflection(
        questionId: 'source-q1',
        topicKey: 'sets',
        shelfKey: 'sets:0:20',
        hypothesisChoiceIndex: 2,
        reflection: StudyReflection.revisit,
      );
      final repeated = await repository.saveStudyReflection(
        questionId: 'source-q1',
        topicKey: 'sets',
        shelfKey: 'sets:0:20',
        hypothesisChoiceIndex: 2,
        reflection: StudyReflection.revisit,
      );

      expect(repeated.firstReflectedAt, first.firstReflectedAt);
      expect(await database.select(database.studyRecords).get(), hasLength(1));
      expect(await database.select(database.gamificationEvents).get(), isEmpty);
      expect(await database.select(database.xpTransactions).get(), isEmpty);
      final summary = await repository.studySummary();
      expect(summary.totalReflected, 1);
      expect(summary.revisitCount, 1);
      expect(summary.clearCount, 0);
      expect(summary.topic('sets').reflected, 1);
    },
  );

  test('a clear reflection removes an item from the revisit orbit', () async {
    await repository.saveStudyReflection(
      questionId: 'source-q2',
      topicKey: 'sets',
      shelfKey: 'sets:0:20',
      hypothesisChoiceIndex: null,
      reflection: StudyReflection.revisit,
    );
    expect(await repository.revisitStudyIds(), ['source-q2']);

    clockNow = clockNow.add(const Duration(days: 1));
    await repository.saveStudyReflection(
      questionId: 'source-q2',
      topicKey: 'sets',
      shelfKey: 'sets:0:20',
      hypothesisChoiceIndex: 1,
      reflection: StudyReflection.clear,
    );

    expect(await repository.revisitStudyIds(), isEmpty);
    final summary = await repository.studySummary();
    expect(summary.totalReflected, 1);
    expect(summary.clearCount, 1);
    expect(summary.heatmap, {'2026-07-12': 1});
  });

  test('study position resumes without creating progress', () async {
    await repository.saveStudyPosition(
      shelfKey: 'sets:0:20',
      questionId: 'source-q8',
      position: 8,
    );

    expect(await repository.studyPosition('sets:0:20'), 8);
    expect((await repository.studySummary()).totalReflected, 0);
  });
}

Future<MissionCompletion> _completeSingle(
  ProgressRepository repository,
  String session,
  String question,
  bool correct,
  DateTime now,
) async {
  await repository.startMission(
    sessionId: session,
    subject: Subject.math,
    topicKey: 'sets',
    createdAt: now.millisecondsSinceEpoch,
    questionIds: [question],
  );
  await repository.saveDraftAttempt(
    _attempt(session, 0, question, correct, now),
  );
  return repository.finalizeMission(sessionId: session, durationSeconds: 15);
}

AttemptRecord _attempt(
  String session,
  int index,
  String question,
  bool correct,
  DateTime at, {
  Subject subject = Subject.math,
  String topic = 'sets',
}) => AttemptRecord(
  sessionId: session,
  missionIndex: index,
  questionId: question,
  subject: subject,
  topicKey: topic,
  selectedChoiceIndex: correct ? 0 : 1,
  correct: correct,
  elapsedSeconds: 10,
  at: at,
);
