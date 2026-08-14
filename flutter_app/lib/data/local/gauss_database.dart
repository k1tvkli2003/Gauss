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

  /// Self-reported reason for a wrong answer (careless, gap, misread, time).
  /// Nullable: tagging is optional and only offered on non-skipped misses.
  TextColumn get errorTag => text().nullable()();

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

@DataClassName('StudyRecordRow')
class StudyRecords extends Table {
  TextColumn get questionId => text()();
  TextColumn get topicKey => text()();
  TextColumn get shelfKey => text()();
  IntColumn get hypothesisChoiceIndex => integer().nullable()();

  /// Whether the private hypothesis matched the source-claimed key. Recorded
  /// only as a personal alignment note — the source key is never verified, so
  /// this can never become a score.
  BoolColumn get hypothesisMatched => boolean().nullable()();
  TextColumn get reflection => text()();
  IntColumn get firstReflectedAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {questionId};
}

@DataClassName('AppFlagRow')
class AppFlags extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('StudyPositionRow')
class StudyPositions extends Table {
  TextColumn get shelfKey => text()();
  TextColumn get questionId => text()();
  IntColumn get position => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {shelfKey};
}

/// Actual passes through planned curriculum slots.
///
/// StudyRecords remains one row per immutable source question. This separate
/// ledger lets an explicit mastery-review duplicate count only after that
/// particular five-question session slot was encountered.
@DataClassName('StudySlotEncounterRow')
class StudySlotEncounters extends Table {
  TextColumn get slotId => text()();
  TextColumn get topicKey => text()();
  TextColumn get shelfKey => text()();
  TextColumn get questionId => text()();
  TextColumn get slotKind => text()();
  IntColumn get firstEncounteredAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {slotId};
}

/// Local-first feedback waiting for the authenticated sync lane.
///
/// Screenshot bytes live in the same SQLite transaction as their metadata so
/// a process interruption cannot leave a report pointing at a partial file.
/// The stable [id] is also the future remote idempotency key.
@DataClassName('FeedbackOutboxRow')
class FeedbackOutboxEntries extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get route => text()();
  TextColumn get note => text()();
  TextColumn get questionId => text().nullable()();
  IntColumn get questionRevision => integer().nullable()();
  TextColumn get topicKey => text().nullable()();
  TextColumn get questionIssueKind => text().nullable()();
  TextColumn get sessionId => text().nullable()();
  IntColumn get missionIndex => integer().nullable()();
  IntColumn get selectedChoiceIndex => integer().nullable()();
  BlobColumn get screenshotPng => blob().nullable()();
  IntColumn get screenshotWidthPx => integer().nullable()();
  IntColumn get screenshotHeightPx => integer().nullable()();
  IntColumn get screenshotByteLength => integer().nullable()();
  RealColumn get screenshotPixelRatio => real().nullable()();
  TextColumn get syncState => text().withDefault(const Constant('pending'))();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  TextColumn get lastSyncError => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
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
    StudyRecords,
    StudyPositions,
    StudySlotEncounters,
    FeedbackOutboxEntries,
    AppFlags,
  ],
)
class GaussDatabase extends _$GaussDatabase {
  GaussDatabase(super.executor);

  GaussDatabase.defaults({String name = 'gauss_flutter_v1'})
    : super(
        driftDatabase(
          name: name,
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.dart.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 8;

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
      if (from < 3) {
        // Additive: existing attempts simply have no self-reported miss
        // reason. No rows are rewritten.
        await migrator.addColumn(attempts, attempts.errorTag);
      }
      if (from < 4) {
        // Source-study progress is additive and separate from scored attempts.
        // Existing missions, SRS rows, rewards, and question data are kept.
        await migrator.createTable(studyRecords);
        await migrator.createTable(studyPositions);
      }
      if (from < 5) {
        // Additive: earlier reflections simply have no recorded alignment.
        await migrator.addColumn(studyRecords, studyRecords.hypothesisMatched);
      }
      if (from < 6) {
        // Small key/value store for one-time UI state. An upgrading learner
        // has already found their way around, so the tour stays dismissed.
        await migrator.createTable(appFlags);
        await customStatement(
          "INSERT OR IGNORE INTO app_flags (key, value, updated_at) "
          "VALUES ('tour_seen', 'true', 0)",
        );
      }
      if (from < 7) {
        // Reflections are unique by source question, while the new curriculum
        // may deliberately repeat a question in a mastery-review remainder.
        // Keep every old row; the controller seeds primary encounters from
        // the generated plan after the question bank is available.
        await migrator.createTable(studySlotEncounters);
      }
      if (from < 8) {
        // Additive: existing progress and legacy question reports remain
        // untouched. New reports gain atomic screenshot storage and a durable
        // pending/synced state for the forthcoming account-scoped backend.
        await migrator.createTable(feedbackOutboxEntries);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
