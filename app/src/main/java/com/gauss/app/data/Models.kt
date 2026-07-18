package com.gauss.app.data

import androidx.compose.ui.graphics.Color
import com.gauss.app.ui.theme.GaussColors

const val KONKUR_SECONDS_PER_QUESTION = 70

enum class Subject(val raw: String, val faLabel: String, val color: Color) {
    MATH("math", "ریاضی", GaussColors.Math),
    PHYSICS("physics", "فیزیک", GaussColors.Physics);

    companion object {
        fun from(raw: String?): Subject = entries.firstOrNull { it.raw == raw } ?: MATH
    }
}

enum class Difficulty(val raw: String, val faLabel: String, val color: Color) {
    ABOVE_AVERAGE("above_average", "بالاتر از متوسط", GaussColors.Success),
    HARD("hard", "سخت", GaussColors.Primary),
    VERY_HARD("very_hard", "خیلی سخت", GaussColors.Warning),
    OLYMPIAD("olympiad", "المپیادی", GaussColors.Error);

    companion object {
        fun from(raw: String?): Difficulty = entries.firstOrNull { it.raw == raw } ?: HARD
    }
}

enum class SourceBank(val raw: String, val faLabel: String) {
    NARDEBAM("nardebam", "آرشیو منبع"),
    GAUSS("gauss", "Gauss");

    companion object {
        fun from(raw: String?): SourceBank = entries.firstOrNull { it.raw == raw } ?: GAUSS
    }
}

enum class AttemptStatus(val raw: String) {
    CORRECT("correct"), WRONG("wrong"), SKIPPED("skipped");

    companion object {
        fun from(raw: String?): AttemptStatus = entries.firstOrNull { it.raw == raw } ?: SKIPPED
    }
}

sealed interface ContentBlock {
    data class Text(val text: String) : ContentBlock
    data class Image(
        val asset: String,
        val alt: String,
        val aspectRatio: Float? = null,
    ) : ContentBlock
}

data class QuestionProvenance(
    val kind: String,
    val edition: String,
    val questionNumber: Int?,
    val questionPdf: String?,
    val questionPage: Int?,
    val solutionPage: Int?,
    val solutionOrigin: String,
)

data class Question(
    val id: String,
    val subject: Subject,
    val topicKey: String,
    val difficulty: Difficulty,
    val stem: List<ContentBlock>,
    val optionBlocks: List<List<ContentBlock>>,
    val correctOptionIndex: Int,
    val solution: List<ContentBlock>,
    val shortcut: List<ContentBlock>?,
    val sourceBank: SourceBank,
    val provenance: QuestionProvenance,
) {
    val questionText: String get() = stem.plainText()
    val options: List<String> get() = optionBlocks.map { it.plainText() }
    val classicSolution: String get() = solution.plainText()
    val smartShortcut: String? get() = shortcut?.plainText()
    val imageUrl: String? get() = stem.filterIsInstance<ContentBlock.Image>().firstOrNull()?.asset
    val category: String get() = subject.raw
    val subCategory: String get() = topicKey
    val source: String get() = "${sourceBank.raw}:${provenance.edition}"
}

fun List<ContentBlock>.plainText(): String =
    filterIsInstance<ContentBlock.Text>().joinToString("\n") { it.text }.trim()

data class ExamConfig(
    val subject: Subject,
    val topicKeys: List<String>,
    val sourceBanks: List<SourceBank>,
    val difficulties: List<Difficulty>,
    val count: Int,
)

data class AttemptResult(
    val question: Question,
    val status: AttemptStatus,
    val selectedOption: Int?,
    val timeTakenSeconds: Int,
)
