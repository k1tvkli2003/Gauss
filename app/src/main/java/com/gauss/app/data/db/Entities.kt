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
