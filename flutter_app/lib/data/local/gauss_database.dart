import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'gauss_database.g.dart';

@DataClassName('ExamRow')
class Exams extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text().unique()();
  TextColumn get subject => text()();
  TextColumn get topicKey => text().nullable()();
  IntColumn get totalQuestions => integer().withDefault(const Constant(0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get wrongCount => integer().withDefault(const Constant(0))();
  IntColumn get skippedCount => integer().withDefault(const Constant(0))();
  RealColumn get scorePercentage => real().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get createdAt => integer()();
  IntColumn get completedAt => integer().nullable()();
}

@DataClassName('AttemptRow')
class Attempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get examId => integer().nullable().references(Exams, #id)();
  TextColumn get sessionId => text()();
  IntColumn get missionIndex => integer()();
  TextColumn get questionId => text()();
  TextColumn get subject => text()();
  TextColumn get topicKey => text()();
  TextColumn get status => text()();
  IntColumn get selectedChoiceIndex => integer().nullable()();
  IntColumn get timeTakenSeconds => integer()();
  IntColumn get solvedAt => integer()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {sessionId, questionId},
  ];
}

@DataClassName('MissionQueueRow')
class MissionQueueItems extends Table {
  IntColumn get examId => integer().references(Exams, #id)();
  IntColumn get position => integer()();
  TextColumn get questionId => text()();

  @override
  Set<Column<Object>> get primaryKey => {examId, position};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {examId, questionId},
  ];
}

@DataClassName('SrsRow')
class SrsStates extends Table {
  TextColumn get questionId => text()();
  RealColumn get ease => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get dueAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {questionId};
}

@DataClassName('GamificationEventRow')
class GamificationEvents extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get subject => text().nullable()();
  TextColumn get topicKey => text().nullable()();
  IntColumn get examId => integer().nullable().references(Exams, #id)();
  TextColumn get questionId => text().nullable()();
  TextColumn get dayKey => text()();
  IntColumn get createdAt => integer()();
  IntColumn get ruleVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('XpTransactionRow')
class XpTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text().references(GamificationEvents, #id)();
  IntColumn get amount => integer()();
  TextColumn get category => text()();
  TextColumn get reason => text()();
  TextColumn get dayKey => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('QuestProgressRow')
class QuestProgress extends Table {
  TextColumn get questId => text()();
  TextColumn get dayKey => text()();
  TextColumn get title => text()();
  IntColumn get progress => integer()();
  IntColumn get target => integer()();
  BoolColumn get completed => boolean()();
  IntColumn get rewardXp => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {questId};
}

@DataClassName('AchievementProgressRow')
/// Retained for schema and rollback compatibility. Achievement UI is derived
/// from the immutable event ledger so it cannot drift from recorded activity.
class AchievementProgress extends Table {
  TextColumn get achievementId => text()();
  TextColumn get title => text()();
  IntColumn get current => integer()();
  IntColumn get target => integer()();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {achievementId};
}

@DriftDatabase(
  tables: [
    Exams,
    Attempts,
    MissionQueueItems,
    SrsStates,
    GamificationEvents,
    XpTransactions,
    QuestProgress,
    AchievementProgress,
  ],
)
class GaussDatabase extends _$GaussDatabase {
  GaussDatabase(super.executor);

  GaussDatabase.defaults()
    : super(
        driftDatabase(
          name: 'gauss_flutter_v1',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.dart.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(missionQueueItems);
        // Version 1 never stored question order, so those local-only drafts
        // cannot be resumed safely. Preserve every row and retire only the
        // incomplete status instead of fabricating a queue.
        await customStatement(
          "UPDATE exams SET status = 'abandoned' WHERE status = 'active'",
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
