import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/domain/models.dart';

void main() {
  late GaussDatabase database;
  late ProgressRepository repository;
  late DateTime clockNow;
  late bool databaseIsOpen;

  setUp(() async {
    database = GaussDatabase(NativeDatabase.memory());
    clockNow = DateTime(2026, 12, 31, 23, 59);
    repository = ProgressRepository(database, clock: () => clockNow);
    await repository.initialize();
    databaseIsOpen = true;
  });

  tearDown(() async {
    if (databaseIsOpen) await database.close();
  });

  test(
    'reward receipts expose stable event identity and rule version',
    () async {
      final first = await _reflect(repository, 'identity-q1');
      final replay = await _reflect(repository, 'identity-q1');

      expect(first.xpEarned, 12);
      expect(first.lines.map((line) => line.eventId).toSet(), {
        'study_reflected:identity-q1',
        'unit_touched:sets',
      });
      expect(first.lines.map((line) => line.ruleVersion).toSet(), {
        ProgressRepository.currentGamificationRuleVersion,
      });
      expect(replay.xpEarned, 0);
      expect(replay.lines, isEmpty);

      final events = await database.select(database.gamificationEvents).get();
      final transactions = await database.select(database.xpTransactions).get();
      expect(events, hasLength(2));
      expect(transactions, hasLength(2));
      expect(events.map((event) => event.ruleVersion).toSet(), {
        ProgressRepository.currentGamificationRuleVersion,
      });
    },
  );

  test('local midnight starts a fresh quest without breaking rhythm', () async {
    await _reflect(repository, 'midnight-q1');
    final before = await repository.gamificationSummary();
    expect(before.effectiveDayKey, '2026-12-31');
    expect(before.quest.progress, 1);
    expect(before.streak, 1);

    clockNow = DateTime(2027, 1, 1, 0, 1);
    await _reflect(repository, 'midnight-q2');
    final after = await repository.gamificationSummary();
    expect(after.effectiveDayKey, '2027-01-01');
    expect(after.quest.progress, 1);
    expect(after.todayXp, ProgressRepository.studyReflectXp);
    expect(after.streak, 2);
    expect(after.streakGraceUsed, isFalse);
    expect(await database.select(database.questProgress).get(), hasLength(2));
  });

  test('daily quest completion event and XP are granted only once', () async {
    StudyReflectionOutcome? completing;
    for (var index = 0; index < ProgressRepository.dailyQuestTarget; index++) {
      completing = await _reflect(repository, 'quest-q$index');
    }
    expect(completing!.dailyQuestCompleted, isTrue);
    expect(
      completing.lines.map((line) => line.eventId),
      contains('daily_study_completed:2026-12-31'),
    );

    final beyondTarget = await _reflect(repository, 'quest-extra');
    final duplicate = await _reflect(repository, 'quest-q9');
    expect(beyondTarget.dailyQuestCompleted, isFalse);
    expect(duplicate.xpEarned, 0);
    final questEvents = await (database.select(
      database.gamificationEvents,
    )..where((row) => row.type.equals('daily_study_completed'))).get();
    final questTransactions =
        await (database.select(database.xpTransactions)..where(
              (row) => row.eventId.equals('daily_study_completed:2026-12-31'),
            ))
            .get();
    expect(questEvents, hasLength(1));
    expect(questTransactions, hasLength(1));
  });

  test(
    'backwards clock travel cannot reopen a quest or daily XP cap',
    () async {
      clockNow = DateTime(2027, 1, 2, 12);
      for (var index = 0; index < 30; index++) {
        await _reflect(repository, 'cap-q$index');
      }
      final cappedDay = await repository.gamificationSummary();
      expect(cappedDay.totalXp, 168);
      expect(cappedDay.quest.completed, isTrue);

      clockNow = DateTime(2027, 1, 1, 12);
      final rolledBack = await _reflect(repository, 'cap-q30');
      final protected = await repository.gamificationSummary();
      expect(rolledBack.xpEarned, 0);
      expect(protected.effectiveDayKey, '2027-01-02');
      expect(protected.clockAdjusted, isTrue);
      expect(protected.totalXp, 168);
      expect(protected.quest.progress, ProgressRepository.dailyQuestTarget);

      final cappedEvent = await (database.select(
        database.gamificationEvents,
      )..where((row) => row.id.equals('study_reflected:cap-q30'))).getSingle();
      expect(cappedEvent.dayKey, '2027-01-02');
      expect(
        await (database.select(database.xpTransactions)
              ..where((row) => row.eventId.equals(cappedEvent.id)))
            .getSingleOrNull(),
        isNull,
      );

      clockNow = DateTime(2027, 1, 3, 8);
      final nextRealDay = await _reflect(repository, 'cap-q31');
      final advanced = await repository.gamificationSummary();
      expect(nextRealDay.xpEarned, ProgressRepository.studyReflectXp);
      expect(advanced.effectiveDayKey, '2027-01-03');
      expect(advanced.clockAdjusted, isFalse);
      expect(advanced.quest.progress, 1);
    },
  );

  test(
    'one missed day gets humane grace without inflating active days',
    () async {
      clockNow = DateTime(2027, 1, 1, 9);
      await _reflect(repository, 'rhythm-q1');
      clockNow = DateTime(2027, 1, 3, 9);
      await _reflect(repository, 'rhythm-q3');

      final protected = await repository.gamificationSummary();
      expect(protected.streak, 2);
      expect(protected.streakGraceUsed, isTrue);

      // A second gap starts a new protected run; the older day is not counted.
      clockNow = DateTime(2027, 1, 5, 9);
      await _reflect(repository, 'rhythm-q5');
      final restarted = await repository.gamificationSummary();
      expect(restarted.streak, 2);
      expect(restarted.streakGraceUsed, isTrue);
    },
  );

  test('ledger, quest, watermark, and XP survive a database reopen', () async {
    await database.close();
    databaseIsOpen = false;
    final directory = await Directory.systemTemp.createTemp(
      'gauss-gamification-',
    );
    final file = File('${directory.path}${Platform.pathSeparator}gauss.sqlite');
    addTearDown(() async {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    final firstDatabase = GaussDatabase(NativeDatabase(file));
    final firstRepository = ProgressRepository(
      firstDatabase,
      clock: () => clockNow,
    );
    await firstRepository.initialize();
    await _reflect(firstRepository, 'persisted-q1');
    await firstDatabase.close();

    clockNow = DateTime(2026, 12, 30, 12);
    final reopenedDatabase = GaussDatabase(NativeDatabase(file));
    final reopenedRepository = ProgressRepository(
      reopenedDatabase,
      clock: () => clockNow,
    );
    await reopenedRepository.initialize();
    final restored = await reopenedRepository.gamificationSummary();
    final duplicate = await _reflect(reopenedRepository, 'persisted-q1');
    expect(restored.totalXp, 12);
    expect(restored.quest.progress, 1);
    expect(restored.streak, 1);
    expect(restored.effectiveDayKey, '2026-12-31');
    expect(restored.clockAdjusted, isTrue);
    expect(duplicate.xpEarned, 0);
    expect(
      await reopenedDatabase.select(reopenedDatabase.gamificationEvents).get(),
      hasLength(2),
    );
    await reopenedDatabase.close();
  });
}

Future<StudyReflectionOutcome> _reflect(
  ProgressRepository repository,
  String questionId,
) => repository.saveStudyReflection(
  questionId: questionId,
  topicKey: 'sets',
  subjectKey: 'math',
  shelfKey: 'sets:0:100',
  setSize: 100,
  topicQuestionCount: 100,
  hypothesisChoiceIndex: null,
  hypothesisMatched: null,
  reflection: StudyReflection.clear,
);
