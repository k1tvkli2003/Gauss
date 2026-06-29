package com.gauss.app.data.db

import androidx.room.testing.MigrationTestHelper
import androidx.sqlite.db.framework.FrameworkSQLiteOpenHelperFactory
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class GaussDatabaseMigrationInstrumentedTest {
    @get:Rule
    val helper = MigrationTestHelper(
        InstrumentationRegistry.getInstrumentation(),
        GaussDatabase::class.java,
        emptyList(),
        FrameworkSQLiteOpenHelperFactory(),
    )

    @Test
    fun migration3To4CreatesGamificationTables() {
        helper.createDatabase(TEST_DB, 3).apply {
            execSQL(
                """
                CREATE TABLE IF NOT EXISTS exams (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    subject TEXT NOT NULL,
                    totalQuestions INTEGER NOT NULL,
                    correctCount INTEGER NOT NULL,
                    wrongCount INTEGER NOT NULL,
                    skippedCount INTEGER NOT NULL,
                    scorePercentage REAL NOT NULL,
                    durationSeconds INTEGER NOT NULL,
                    createdAt INTEGER NOT NULL
                )
                """.trimIndent(),
            )
            execSQL(
                """
                CREATE TABLE IF NOT EXISTS attempts (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    examId INTEGER,
                    questionId TEXT NOT NULL,
                    subject TEXT NOT NULL,
                    category TEXT NOT NULL,
                    chapter TEXT,
                    topic TEXT,
                    status TEXT NOT NULL,
                    selectedOption INTEGER,
                    timeTakenSeconds INTEGER NOT NULL,
                    solvedAt INTEGER NOT NULL
                )
                """.trimIndent(),
            )
            execSQL("CREATE INDEX IF NOT EXISTS index_attempts_questionId ON attempts(questionId)")
            execSQL("CREATE INDEX IF NOT EXISTS index_attempts_status ON attempts(status)")
            execSQL("CREATE INDEX IF NOT EXISTS index_attempts_solvedAt ON attempts(solvedAt)")
            execSQL(
                """
                CREATE TABLE IF NOT EXISTS srs (
                    questionId TEXT NOT NULL PRIMARY KEY,
                    ease REAL NOT NULL,
                    intervalDays INTEGER NOT NULL,
                    reps INTEGER NOT NULL,
                    lapses INTEGER NOT NULL,
                    dueAt INTEGER NOT NULL,
                    updatedAt INTEGER NOT NULL
                )
                """.trimIndent(),
            )
            execSQL("CREATE INDEX IF NOT EXISTS index_srs_dueAt ON srs(dueAt)")
            close()
        }

        helper.runMigrationsAndValidate(TEST_DB, 4, true, *GaussDatabase.allMigrations())
    }

    private companion object {
        const val TEST_DB = "gauss-migration-test"
    }
}
