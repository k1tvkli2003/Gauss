package com.gauss.app.data

import androidx.room.withTransaction
import com.gauss.app.data.db.AttemptEntity
import com.gauss.app.data.db.ExamEntity
import com.gauss.app.data.db.GaussDatabase
import com.gauss.app.data.db.SrsEntity
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

data class RecentExam(
    val id: Long,
    val totalQuestions: Int,
    val correctCount: Int,
    val scorePercentage: Double,
    val createdAt: Long,
)

data class TopicStat(
    val category: String,
    val subject: Subject,
    val total: Int,
    val correct: Int,
    val accuracy: Double,
    val avgTime: Double,
)

data class DistractorStat(
    val category: String,
    val subject: Subject,
    val option: Int,
    val count: Int,
)

data class Analytics(
    val totalAnswered: Int,
    val totalCorrect: Int,
    val accuracy: Double,
    val avgTime: Double,
    val weakTopics: List<TopicStat>,
    val distractors: List<DistractorStat>,
    val heatmap: Map<String, Int>, // 'yyyy-MM-dd' -> attempts
    val streak: Int,
)

private val DAY_FMT: DateTimeFormatter =
    DateTimeFormatter.ofPattern("yyyy-MM-dd").withZone(ZoneId.systemDefault())

class HistoryRepository(private val db: GaussDatabase) {

    private val dao get() = db.dao()

    /** Persist a finished exam, its attempts, and update SRS — atomically. */
    suspend fun saveExam(
        config: ExamConfig,
        results: List<AttemptResult>,
        durationSeconds: Int,
    ): Long = db.withTransaction {
        val now = System.currentTimeMillis()
        val correct = results.count { it.status == AttemptStatus.CORRECT }
        val wrong = results.count { it.status == AttemptStatus.WRONG }
        val skipped = results.count { it.status == AttemptStatus.SKIPPED }
        val total = results.size
        val score = if (total > 0) (correct.toDouble() / total) * 100 else 0.0

        val examId = dao.insertExam(
            ExamEntity(
                subject = config.subject.raw,
                totalQuestions = total,
                correctCount = correct,
                wrongCount = wrong,
                skippedCount = skipped,
                scorePercentage = (score * 100).toInt() / 100.0,
                durationSeconds = durationSeconds,
                createdAt = now,
            ),
        )

        dao.insertAttempts(
            results.map { r ->
                AttemptEntity(
                    examId = examId,
                    questionId = r.question.id,
                    subject = r.question.subject.raw,
                    category = r.question.category,
                    status = r.status.raw,
                    selectedOption = r.selectedOption,
                    timeTakenSeconds = r.timeTakenSeconds,
                    solvedAt = now,
                )
            },
        )

        results.forEach { updateSrs(it.question.id, it.status == AttemptStatus.CORRECT, now) }
        examId
    }

    /** SM-2 lite: lucky single correct no longer redeems a question forever. */
    private suspend fun updateSrs(questionId: String, correct: Boolean, now: Long) {
        val prev = dao.srsFor(questionId)
        var ease = prev?.ease ?: 2.5
        var reps = prev?.reps ?: 0
        var lapses = prev?.lapses ?: 0
        var interval = prev?.intervalDays ?: 0
        val dueAt: Long

        if (correct) {
            reps += 1
            interval = when (reps) {
                1 -> 1
                2 -> 3
                else -> Math.ceil(interval * ease).toInt()
            }
            ease = minOf(2.8, ease + 0.1)
            dueAt = now + interval.toLong() * 86_400_000L
        } else {
            lapses += 1
            reps = 0
            interval = 0
            ease = maxOf(1.3, ease - 0.2)
            dueAt = now
        }

        dao.upsertSrs(
            SrsEntity(
                questionId = questionId,
                ease = ease,
                intervalDays = interval,
                reps = reps,
                lapses = lapses,
                dueAt = dueAt,
                updatedAt = now,
            ),
        )
    }

    suspend fun recentExams(limit: Int = 5): List<RecentExam> =
        dao.recentExams(limit).map {
            RecentExam(it.id, it.totalQuestions, it.correctCount, it.scorePercentage, it.createdAt)
        }

    suspend fun revengeIds(): List<String> = dao.dueRevengeIds(System.currentTimeMillis())

    suspend fun analytics(): Analytics {
        val rows = dao.allAttempts()
        val totalAnswered = rows.size
        val totalCorrect = rows.count { it.status == AttemptStatus.CORRECT.raw }
        val timed = rows.filter { it.timeTakenSeconds > 0 }
        val avgTime = if (timed.isNotEmpty()) timed.sumOf { it.timeTakenSeconds }.toDouble() / timed.size else 0.0

        // Weak topics by category.
        data class Agg(var subject: Subject, var total: Int = 0, var correct: Int = 0, var time: Int = 0)
        val byCat = HashMap<String, Agg>()
        rows.forEach { r ->
            val agg = byCat.getOrPut(r.category) { Agg(Subject.from(r.subject)) }
            agg.total += 1
            if (r.status == AttemptStatus.CORRECT.raw) agg.correct += 1
            agg.time += r.timeTakenSeconds
        }
        val weak = byCat.map { (cat, a) ->
            TopicStat(
                category = cat,
                subject = a.subject,
                total = a.total,
                correct = a.correct,
                accuracy = if (a.total > 0) a.correct.toDouble() / a.total * 100 else 0.0,
                avgTime = if (a.total > 0) a.time.toDouble() / a.total else 0.0,
            )
        }.sortedBy { it.accuracy }

        // Distractor traps: wrong option repeatedly chosen, per topic.
        val byTrap = HashMap<String, DistractorStat>()
        rows.forEach { r ->
            val opt = r.selectedOption
            if (r.status != AttemptStatus.WRONG.raw || opt == null) return@forEach
            val key = "${r.category}|$opt"
            val cur = byTrap[key]
            byTrap[key] = cur?.copy(count = cur.count + 1)
                ?: DistractorStat(r.category, Subject.from(r.subject), opt, 1)
        }
        val distractors = byTrap.values
            .filter { it.count >= 2 }
            .sortedByDescending { it.count }
            .take(6)

        // Daily heatmap.
        val heatmap = HashMap<String, Int>()
        rows.forEach { r ->
            val day = DAY_FMT.format(Instant.ofEpochMilli(r.solvedAt))
            heatmap[day] = (heatmap[day] ?: 0) + 1
        }

        return Analytics(
            totalAnswered = totalAnswered,
            totalCorrect = totalCorrect,
            accuracy = if (totalAnswered > 0) totalCorrect.toDouble() / totalAnswered * 100 else 0.0,
            avgTime = avgTime,
            weakTopics = weak,
            distractors = distractors,
            heatmap = heatmap,
            streak = computeStreak(heatmap),
        )
    }

    private fun computeStreak(heatmap: Map<String, Int>): Int {
        val zone = ZoneId.systemDefault()
        var day = Instant.now().atZone(zone).toLocalDate()
        if (heatmap[day.toString()] == null) day = day.minusDays(1) // today may be empty
        var streak = 0
        while (heatmap[day.toString()] != null) {
            streak += 1
            day = day.minusDays(1)
        }
        return streak
    }
}
