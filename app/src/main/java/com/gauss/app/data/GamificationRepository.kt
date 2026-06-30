package com.gauss.app.data

import androidx.room.withTransaction
import com.gauss.app.data.db.AchievementProgressEntity
import com.gauss.app.data.db.GamificationEventEntity
import com.gauss.app.data.db.GaussDatabase
import com.gauss.app.data.db.QuestProgressEntity
import com.gauss.app.data.db.XpTransactionEntity
import java.time.LocalDate
import java.time.ZoneId
import kotlin.math.floor
import kotlin.math.sqrt

data class RewardLine(
    val reason: String,
    val amount: Int,
    val category: String,
)

data class RewardSummary(
    val xpEarned: Int,
    val levelBefore: Int,
    val levelAfter: Int,
    val totalXp: Int,
    val lines: List<RewardLine>,
)

data class DailyQuest(
    val title: String,
    val progress: Int,
    val target: Int,
    val rewardXp: Int,
    val completed: Boolean,
)

data class GamificationSummary(
    val totalXp: Int,
    val todayXp: Int,
    val level: Int,
    val levelProgress: Float,
    val streak: Int,
    val quest: DailyQuest,
)

class GamificationRepository(private val db: GaussDatabase) {

    private val dao get() = db.dao()
    private val zone: ZoneId = ZoneId.systemDefault()

    suspend fun summary(): GamificationSummary {
        val today = todayKey()
        val total = dao.totalXp()
        val level = levelFor(total)
        val quest = dao.questForDay(today)?.toQuest() ?: DailyQuest(
            title = "Beat 10 useful questions",
            progress = 0,
            target = DAILY_QUEST_TARGET,
            rewardXp = DAILY_QUEST_XP,
            completed = false,
        )
        return GamificationSummary(
            totalXp = total,
            todayXp = dao.xpForDay(today),
            level = level,
            levelProgress = levelProgress(total, level),
            streak = streakFromDays(dao.xpDays().toSet()),
            quest = quest,
        )
    }

    suspend fun rewardExam(
        examId: Long,
        config: ExamConfig,
        results: List<AttemptResult>,
        durationSeconds: Int,
    ): RewardSummary = db.withTransaction {
        val before = dao.totalXp()
        val levelBefore = levelFor(before)
        val now = System.currentTimeMillis()
        val today = todayKey(now)
        val lines = mutableListOf<RewardLine>()

        suspend fun award(
            eventId: String,
            type: String,
            amount: Int,
            category: String,
            reason: String,
            question: Question? = null,
            topic: String? = question?.topicKey,
        ) {
            val inserted = dao.insertGamificationEvent(
                GamificationEventEntity(
                    id = eventId,
                    type = type,
                    subject = question?.subject?.raw ?: config.subject.raw,
                    topic = topic,
                    examId = examId,
                    questionId = question?.id,
                    dayKey = today,
                    createdAt = now,
                ),
            )
            if (inserted == -1L) return
            val grant = cappedAmount(today, category, amount)
            if (grant <= 0) return
            dao.insertXpTransaction(
                XpTransactionEntity(
                    id = "xp:$eventId",
                    eventId = eventId,
                    amount = grant,
                    category = category,
                    reason = reason,
                    dayKey = today,
                    createdAt = now,
                ),
            )
            lines += RewardLine(reason, grant, category)
        }

        results.forEach { result ->
            if (result.status == AttemptStatus.CORRECT) {
                award(
                    eventId = "question_answered:$examId:${result.question.id}",
                    type = "question_answered",
                    amount = 5,
                    category = CATEGORY_PRACTICE,
                    reason = "Correct answer",
                    question = result.question,
                )
                if (dao.previousWrongAttempts(result.question.id, examId) > 0) {
                    award(
                        eventId = "mistake_corrected:$examId:${result.question.id}",
                        type = "mistake_corrected",
                        amount = 15,
                        category = CATEGORY_CORRECTION,
                        reason = "Mistake corrected",
                        question = result.question,
                    )
                }
            }
        }

        if (results.isNotEmpty()) {
            award(
                eventId = "exam_completed:$examId",
                type = "exam_completed",
                amount = 20,
                category = CATEGORY_PRACTICE,
                reason = "Mission complete",
            )
        }

        val answered = results.count { it.status != AttemptStatus.SKIPPED }
        val quest = QuestProgressEntity(
            questId = "daily_practice:$today",
            dayKey = today,
            title = "Beat 10 useful questions",
            progress = minOf(DAILY_QUEST_TARGET, answered),
            target = DAILY_QUEST_TARGET,
            completed = answered >= DAILY_QUEST_TARGET,
            rewardXp = DAILY_QUEST_XP,
            updatedAt = now,
        )
        dao.upsertQuestProgress(quest)
        if (quest.completed) {
            award(
                eventId = "daily_practice_completed:$today",
                type = "daily_practice_completed",
                amount = DAILY_QUEST_XP,
                category = CATEGORY_BONUS,
                reason = "Daily quest",
            )
        }

        val score = results.count { it.status == AttemptStatus.CORRECT }.toDouble() / results.size.coerceAtLeast(1) * 100.0
        if (results.size >= 20 && score >= 85.0 && durationSeconds > 0) {
            award(
                eventId = "boss_pass:$examId",
                type = "boss_pass",
                amount = 120,
                category = CATEGORY_MASTERY,
                reason = "Gold challenge",
            )
        }

        results.groupBy { it.question.topicKey }.forEach { (topic, topicResults) ->
            val topicScore = topicResults.count { it.status == AttemptStatus.CORRECT }.toDouble() /
                topicResults.size.coerceAtLeast(1) * 100.0
            if (topicResults.size >= 5 && topicScore >= 80.0) {
                val label = ComprehensiveTaxonomy.label(topic)
                award(
                    eventId = "topic_mastered:$topic",
                    type = "topic_mastered",
                    amount = 80,
                    category = CATEGORY_MASTERY,
                    reason = "Mastered $label",
                    topic = topic,
                )
                dao.upsertAchievementProgress(
                    AchievementProgressEntity(
                        achievementId = "topic_mastered:$topic",
                        title = "Mastery: $label",
                        current = 1,
                        target = 1,
                        completedAt = now,
                        updatedAt = now,
                    ),
                )
            }
        }

        val earned = lines.sumOf { it.amount }
        val after = before + earned
        RewardSummary(
            xpEarned = earned,
            levelBefore = levelBefore,
            levelAfter = levelFor(after),
            totalXp = after,
            lines = lines,
        )
    }

    private suspend fun cappedAmount(dayKey: String, category: String, requested: Int): Int {
        val cap = when (category) {
            CATEGORY_PRACTICE -> 200
            CATEGORY_CORRECTION -> 120
            else -> return requested
        }
        val used = dao.xpForDayCategory(dayKey, category)
        return (cap - used).coerceAtLeast(0).coerceAtMost(requested)
    }

    private fun todayKey(now: Long = System.currentTimeMillis()): String =
        java.time.Instant.ofEpochMilli(now).atZone(zone).toLocalDate().toString()

    private fun streakFromDays(days: Set<String>): Int {
        if (days.isEmpty()) return 0
        var day = LocalDate.now(zone)
        if (day.toString() !in days) day = day.minusDays(1)
        var streak = 0
        var graceUsed = false
        while (streak < 365) {
            if (day.toString() in days) {
                streak += 1
                day = day.minusDays(1)
            } else if (!graceUsed && streak > 0) {
                graceUsed = true
                day = day.minusDays(1)
            } else {
                break
            }
        }
        return streak
    }

    private fun QuestProgressEntity.toQuest(): DailyQuest =
        DailyQuest(title, progress, target, rewardXp, completed)

    companion object {
        private const val DAILY_QUEST_TARGET = 10
        private const val DAILY_QUEST_XP = 40
        private const val CATEGORY_PRACTICE = "practice"
        private const val CATEGORY_CORRECTION = "correction"
        private const val CATEGORY_BONUS = "bonus"
        private const val CATEGORY_MASTERY = "mastery"

        fun levelFor(xp: Int): Int = floor(sqrt(xp.coerceAtLeast(0) / 160.0)).toInt() + 1

        fun levelProgress(xp: Int, level: Int = levelFor(xp)): Float {
            val start = (level - 1) * (level - 1) * 160
            val end = level * level * 160
            return ((xp - start).toFloat() / (end - start).toFloat()).coerceIn(0f, 1f)
        }
    }
}
