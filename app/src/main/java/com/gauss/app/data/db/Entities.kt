package com.gauss.app.data.db

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/** One finished exam. */
@Entity(tableName = "exams")
data class ExamEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val subject: String,
    val totalQuestions: Int,
    val correctCount: Int,
    val wrongCount: Int,
    val skippedCount: Int,
    val scorePercentage: Double,
    val durationSeconds: Int,
    val createdAt: Long,
)

/** One per-question attempt. Subject/category are denormalized for fast analytics. */
@Entity(
    tableName = "attempts",
    indices = [Index("questionId"), Index("status"), Index("solvedAt")],
)
data class AttemptEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val examId: Long?,
    val questionId: String,
    val subject: String,
    val category: String,
    val chapter: String?,
    val topic: String?,
    val status: String,
    val selectedOption: Int?,
    val timeTakenSeconds: Int,
    val solvedAt: Long,
)

/** SM-2 lite spaced-repetition state, one row per question. */
@Entity(tableName = "srs", indices = [Index("dueAt")])
data class SrsEntity(
    @PrimaryKey val questionId: String,
    val ease: Double = 2.5,
    val intervalDays: Int = 0,
    val reps: Int = 0,
    val lapses: Int = 0,
    val dueAt: Long,
    val updatedAt: Long,
)

@Entity(
    tableName = "gamification_events",
    indices = [Index("type"), Index("dayKey"), Index("createdAt")],
)
data class GamificationEventEntity(
    @PrimaryKey val id: String,
    val type: String,
    val subject: String?,
    val topic: String?,
    val examId: Long?,
    val questionId: String?,
    val dayKey: String,
    val createdAt: Long,
    val ruleVersion: Int = 1,
)

@Entity(
    tableName = "xp_transactions",
    indices = [Index("eventId"), Index("dayKey"), Index("category")],
)
data class XpTransactionEntity(
    @PrimaryKey val id: String,
    val eventId: String,
    val amount: Int,
    val category: String,
    val reason: String,
    val dayKey: String,
    val createdAt: Long,
)

@Entity(tableName = "quest_progress")
data class QuestProgressEntity(
    @PrimaryKey val questId: String,
    val dayKey: String,
    val title: String,
    val progress: Int,
    val target: Int,
    val completed: Boolean,
    val rewardXp: Int,
    val updatedAt: Long,
)

@Entity(tableName = "achievement_progress")
data class AchievementProgressEntity(
    @PrimaryKey val achievementId: String,
    val title: String,
    val current: Int,
    val target: Int,
    val completedAt: Long?,
    val updatedAt: Long,
)
