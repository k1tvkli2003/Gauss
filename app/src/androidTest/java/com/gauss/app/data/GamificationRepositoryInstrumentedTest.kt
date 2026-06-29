package com.gauss.app.data

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.gauss.app.data.db.AttemptEntity
import com.gauss.app.data.db.GaussDatabase
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

class GamificationRepositoryInstrumentedTest {
    private lateinit var db: GaussDatabase
    private lateinit var repo: GamificationRepository

    @Before
    fun setUp() {
        db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            GaussDatabase::class.java,
        ).build()
        repo = GamificationRepository(db)
    }

    @After
    fun tearDown() {
        db.close()
    }

    @Test
    fun duplicateExamRewardDoesNotDoubleAwardXp() = runBlocking {
        val results = (1..50).map { index ->
            AttemptResult(question("q$index"), AttemptStatus.CORRECT, 1, 12)
        }
        val first = repo.rewardExam(
            examId = 42,
            config = ExamConfig(Subject.MATH, listOf("sets"), emptyList(), emptyList(), results.size),
            results = results,
            durationSeconds = 900,
        )
        val second = repo.rewardExam(
            examId = 42,
            config = ExamConfig(Subject.MATH, listOf("sets"), emptyList(), emptyList(), results.size),
            results = results,
            durationSeconds = 900,
        )

        assertEquals(440, first.xpEarned)
        assertEquals(0, second.xpEarned)
        assertEquals(440, db.dao().totalXp())
    }

    @Test
    fun correctionXpIsCappedPerDay() = runBlocking {
        val results = (1..10).map { index ->
            val q = question("fix$index")
            db.dao().insertAttempts(
                listOf(
                    AttemptEntity(
                        examId = 1,
                        questionId = q.id,
                        subject = q.subject.raw,
                        category = q.category,
                        chapter = q.topicKey,
                        topic = q.topicKey,
                        status = AttemptStatus.WRONG.raw,
                        selectedOption = 2,
                        timeTakenSeconds = 30,
                        solvedAt = System.currentTimeMillis() - 86_400_000L,
                    ),
                ),
            )
            AttemptResult(q, AttemptStatus.CORRECT, 1, 10)
        }

        val summary = repo.rewardExam(
            examId = 2,
            config = ExamConfig(Subject.MATH, listOf("sets"), emptyList(), emptyList(), results.size),
            results = results,
            durationSeconds = 400,
        )

        assertEquals(310, summary.xpEarned)
        assertEquals(120, db.dao().xpForDayCategory(summaryDay(), "correction"))
    }

    private fun question(id: String): Question =
        Question(
            id = id,
            subject = Subject.MATH,
            topicKey = "sets",
            difficulty = Difficulty.HARD,
            stem = listOf(ContentBlock.Text("صورت تست $id")),
            optionBlocks = listOf(
                listOf(ContentBlock.Text("گزینه ۱")),
                listOf(ContentBlock.Text("گزینه ۲")),
                listOf(ContentBlock.Text("گزینه ۳")),
                listOf(ContentBlock.Text("گزینه ۴")),
            ),
            correctOptionIndex = 1,
            solution = listOf(ContentBlock.Text("حل")),
            shortcut = null,
            sourceBank = SourceBank.GAUSS,
            provenance = QuestionProvenance(
                kind = "test",
                edition = "instrumented",
                questionNumber = null,
                questionPdf = null,
                questionPage = null,
                solutionPage = null,
                solutionOrigin = "test",
            ),
        )

    private fun summaryDay(): String =
        java.time.LocalDate.now(java.time.ZoneId.systemDefault()).toString()
}
