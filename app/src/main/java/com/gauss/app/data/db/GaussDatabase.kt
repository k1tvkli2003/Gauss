package com.gauss.app.data.db

import android.content.Context
import androidx.room.Database
import androidx.room.migration.Migration
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(
    entities = [
        ExamEntity::class,
        AttemptEntity::class,
        SrsEntity::class,
        GamificationEventEntity::class,
        XpTransactionEntity::class,
        QuestProgressEntity::class,
        AchievementProgressEntity::class,
    ],
    version = 4,
    exportSchema = false,
)
abstract class GaussDatabase : RoomDatabase() {
    abstract fun dao(): GaussDao

    companion object {
        @Volatile
        private var instance: GaussDatabase? = null

        fun get(context: Context): GaussDatabase =
            instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    GaussDatabase::class.java,
                    "gauss.db",
                )
                    .addMigrations(MIGRATION_1_2, MIGRATION_2_3, MIGRATION_3_4)
                    .build()
                    .also { instance = it }
            }

        fun allMigrations(): Array<Migration> =
            arrayOf(MIGRATION_1_2, MIGRATION_2_3, MIGRATION_3_4)

        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE attempts ADD COLUMN chapter TEXT")
            }
        }

        private val MIGRATION_2_3 = object : Migration(2, 3) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE attempts ADD COLUMN topic TEXT")
                db.execSQL(
                    """
                    UPDATE attempts SET topic = CASE chapter
                        WHEN 'sets_patterns_sequences' THEN 'patterns_sequences'
                        WHEN 'rational_powers_algebraic_expressions' THEN 'radicals_algebraic_expressions'
                        WHEN 'equations_inequalities' THEN 'rational_inequalities_sign'
                        WHEN 'functions_domain_range' THEN 'functions'
                        WHEN 'counting_without_counting' THEN 'combinatorics'
                        WHEN 'statistics_probability' THEN 'probability'
                        WHEN 'analytic_geometry_algebra' THEN 'analytic_geometry'
                        WHEN 'functions_inverse_operations' THEN 'functions'
                        WHEN 'trigonometry_advanced' THEN 'trigonometry'
                        WHEN 'functions_monotonic_composition' THEN 'functions'
                        WHEN 'trigonometry_period_equations' THEN 'trigonometry'
                        WHEN 'infinite_limits' THEN 'limits_continuity'
                        WHEN 'geometry_conics_circle' THEN 'visual_thinking_conics'
                        WHEN 'total_probability' THEN 'probability'
                        WHEN 'kinematics' THEN 'one_dimensional_motion'
                        WHEN 'dynamics_circular_motion' THEN 'dynamics'
                        ELSE chapter
                    END
                    """.trimIndent(),
                )
            }
        }

        private val MIGRATION_3_4 = object : Migration(3, 4) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS gamification_events (
                        id TEXT NOT NULL PRIMARY KEY,
                        type TEXT NOT NULL,
                        subject TEXT,
                        topic TEXT,
                        examId INTEGER,
                        questionId TEXT,
                        dayKey TEXT NOT NULL,
                        createdAt INTEGER NOT NULL,
                        ruleVersion INTEGER NOT NULL
                    )
                    """.trimIndent(),
                )
                db.execSQL("CREATE INDEX IF NOT EXISTS index_gamification_events_type ON gamification_events(type)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_gamification_events_dayKey ON gamification_events(dayKey)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_gamification_events_createdAt ON gamification_events(createdAt)")
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS xp_transactions (
                        id TEXT NOT NULL PRIMARY KEY,
                        eventId TEXT NOT NULL,
                        amount INTEGER NOT NULL,
                        category TEXT NOT NULL,
                        reason TEXT NOT NULL,
                        dayKey TEXT NOT NULL,
                        createdAt INTEGER NOT NULL
                    )
                    """.trimIndent(),
                )
                db.execSQL("CREATE INDEX IF NOT EXISTS index_xp_transactions_eventId ON xp_transactions(eventId)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_xp_transactions_dayKey ON xp_transactions(dayKey)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_xp_transactions_category ON xp_transactions(category)")
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS quest_progress (
                        questId TEXT NOT NULL PRIMARY KEY,
                        dayKey TEXT NOT NULL,
                        title TEXT NOT NULL,
                        progress INTEGER NOT NULL,
                        target INTEGER NOT NULL,
                        completed INTEGER NOT NULL,
                        rewardXp INTEGER NOT NULL,
                        updatedAt INTEGER NOT NULL
                    )
                    """.trimIndent(),
                )
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS achievement_progress (
                        achievementId TEXT NOT NULL PRIMARY KEY,
                        title TEXT NOT NULL,
                        current INTEGER NOT NULL,
                        target INTEGER NOT NULL,
                        completedAt INTEGER,
                        updatedAt INTEGER NOT NULL
                    )
                    """.trimIndent(),
                )
            }
        }
    }
}
