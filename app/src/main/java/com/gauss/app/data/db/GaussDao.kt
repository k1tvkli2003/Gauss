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

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertGamificationEvent(event: GamificationEventEntity): Long

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertXpTransaction(transaction: XpTransactionEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertQuestProgress(progress: QuestProgressEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAchievementProgress(progress: AchievementProgressEntity)

    @Query("SELECT COALESCE(SUM(amount), 0) FROM xp_transactions")
    suspend fun totalXp(): Int

    @Query("SELECT COALESCE(SUM(amount), 0) FROM xp_transactions WHERE dayKey = :dayKey")
    suspend fun xpForDay(dayKey: String): Int

    @Query("SELECT COALESCE(SUM(amount), 0) FROM xp_transactions WHERE dayKey = :dayKey AND category = :category")
    suspend fun xpForDayCategory(dayKey: String, category: String): Int

    @Query("SELECT * FROM xp_transactions ORDER BY createdAt DESC LIMIT :limit")
    suspend fun recentXpTransactions(limit: Int): List<XpTransactionEntity>

    @Query("SELECT DISTINCT dayKey FROM xp_transactions ORDER BY dayKey DESC")
    suspend fun xpDays(): List<String>

    @Query("SELECT * FROM quest_progress WHERE dayKey = :dayKey LIMIT 1")
    suspend fun questForDay(dayKey: String): QuestProgressEntity?

    @Query("SELECT * FROM achievement_progress")
    suspend fun achievementProgress(): List<AchievementProgressEntity>

    @Query("SELECT COUNT(*) FROM attempts WHERE questionId = :questionId AND status = 'wrong' AND (examId IS NULL OR examId != :examId)")
    suspend fun previousWrongAttempts(questionId: String, examId: Long): Int
}
