package com.gauss.app.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface GaussDao {

    @Insert
    suspend fun insertExam(exam: ExamEntity): Long

    @Insert
    suspend fun insertAttempts(rows: List<AttemptEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertSrs(state: SrsEntity)

    @Query("SELECT * FROM srs WHERE questionId = :id")
    suspend fun srsFor(id: String): SrsEntity?

    @Query("SELECT * FROM exams ORDER BY createdAt DESC LIMIT :limit")
    suspend fun recentExams(limit: Int): List<ExamEntity>

    @Query("SELECT * FROM attempts")
    suspend fun allAttempts(): List<AttemptEntity>

    /** Revenge queue: lapsed questions that are due, soonest first. */
    @Query(
        "SELECT questionId FROM srs WHERE lapses > 0 AND dueAt <= :now ORDER BY dueAt ASC LIMIT 300",
    )
    suspend fun dueRevengeIds(now: Long): List<String>
}
