package com.gauss.app.data

import androidx.compose.ui.graphics.Color
import com.gauss.app.ui.theme.GaussColors

/** Konkur standard time budget per question, in seconds. */
const val KONKUR_SECONDS_PER_QUESTION = 70

enum class Subject(val raw: String, val faLabel: String, val color: Color) {
    MATH("math", "ریاضی", GaussColors.NeonPurple),
    PHYSICS("physics", "فیزیک", GaussColors.NeonBlue);

    companion object {
        fun from(raw: String?): Subject = entries.firstOrNull { it.raw == raw } ?: MATH
    }
}

enum class Difficulty(val raw: String, val faLabel: String, val color: Color) {
    ABOVE_AVERAGE("above_average", "بالاتر از متوسط", GaussColors.NeonGreen),
    HARD("hard", "سخت", GaussColors.NeonBlue),
    VERY_HARD("very_hard", "خیلی سخت", GaussColors.NeonAmber),
    OLYMPIAD("olympiad", "المپیادی", GaussColors.NeonRed);

    companion object {
        fun from(raw: String?): Difficulty = entries.firstOrNull { it.raw == raw } ?: HARD
    }
}

enum class AttemptStatus(val raw: String) {
    CORRECT("correct"), WRONG("wrong"), SKIPPED("skipped");

    companion object {
        fun from(raw: String?): AttemptStatus =
            entries.firstOrNull { it.raw == raw } ?: SKIPPED
    }
}

/** An immutable question from the bundled bank. */
data class Question(
    val id: String,
    val subject: Subject,
    val category: String,
    val subCategory: String?,
    val difficulty: Difficulty,
    val questionText: String,
    val imageUrl: String?,
    val options: List<String>, // exactly 4, index 0..3
    val correctOptionIndex: Int, // 1..4
    val classicSolution: String,
    val smartShortcut: String?,
    val source: String,
)

/** Filters chosen on the setup screen (empty list = "all"). */
data class ExamConfig(
    val subject: Subject,
    val categories: List<String>,
    val subCategories: List<String>,
    val difficulties: List<Difficulty>,
    val count: Int,
)

/** A single answered/skipped question inside a session. */
data class AttemptResult(
    val question: Question,
    val status: AttemptStatus,
    val selectedOption: Int?, // 1..4
    val timeTakenSeconds: Int,
)
