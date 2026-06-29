package com.gauss.app.ui.exam

import android.app.Application
import androidx.activity.ComponentActivity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.SnapshotStateMap
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.gauss.app.GaussApp
import com.gauss.app.data.AttemptResult
import com.gauss.app.data.AttemptStatus
import com.gauss.app.data.ExamConfig
import com.gauss.app.data.Question
import com.gauss.app.data.RewardSummary
import com.gauss.app.ui.components.Stroke
import kotlinx.coroutines.launch

/**
 * The exam engine — shared across the session and results screens. Mirrors the
 * original Zustand store: per-question attempts, a persistent scratchpad, and
 * an atomic finish-and-save.
 */
class ExamViewModel(app: Application) : AndroidViewModel(app) {

    var config by mutableStateOf<ExamConfig?>(null)
        private set
    var questions by mutableStateOf<List<Question>>(emptyList())
        private set
    var index by mutableIntStateOf(0)
        private set

    val attempts: SnapshotStateMap<Int, AttemptResult> = mutableStateMapOf()
    val scratch: SnapshotStateMap<Int, List<Stroke>> = mutableStateMapOf()

    var finished by mutableStateOf(false)
        private set
    var saving by mutableStateOf(false)
        private set
    var saveError by mutableStateOf<String?>(null)
        private set
    var rewardSummary by mutableStateOf<RewardSummary?>(null)
        private set

    private var questionStartedAt = 0L
    private var examStartedAt = 0L
    private var savedExamId: Long? = null

    val current: Question? get() = questions.getOrNull(index)
    val isLast: Boolean get() = index == questions.lastIndex
    val canRetrySave: Boolean get() = savedExamId == null && !saving

    fun startExam(config: ExamConfig, questions: List<Question>) {
        this.config = config
        this.questions = questions
        index = 0
        attempts.clear()
        scratch.clear()
        finished = false
        saving = false
        saveError = null
        rewardSummary = null
        savedExamId = null
        val now = System.currentTimeMillis()
        questionStartedAt = now
        examStartedAt = now
    }

    private fun record(status: AttemptStatus, selectedOption: Int?) {
        val q = questions.getOrNull(index) ?: return
        val taken = maxOf(1, ((System.currentTimeMillis() - questionStartedAt) / 1000).toInt())
        attempts[index] = AttemptResult(q, status, selectedOption, taken)
    }

    fun answer(selectedOption: Int) {
        val q = questions.getOrNull(index) ?: return
        val status = if (selectedOption == q.correctOptionIndex) AttemptStatus.CORRECT else AttemptStatus.WRONG
        record(status, selectedOption)
    }

    fun skip() {
        if (attempts[index] != null) return // don't overwrite a real answer
        record(AttemptStatus.SKIPPED, null)
    }

    fun next() {
        if (index < questions.lastIndex) {
            index += 1
            questionStartedAt = System.currentTimeMillis()
        }
    }

    fun prev() {
        if (index > 0) {
            index -= 1
            questionStartedAt = System.currentTimeMillis()
        }
    }

    fun goTo(target: Int) {
        if (target in questions.indices) {
            index = target
            questionStartedAt = System.currentTimeMillis()
        }
    }

    fun setScratch(i: Int, strokes: List<Stroke>) {
        scratch[i] = strokes
    }

    fun answeredCount(): Int = attempts.values.count { it.status != AttemptStatus.SKIPPED }

    fun recordedCount(): Int = attempts.size

    /** Ordered results, treating any untouched question as skipped. */
    fun results(): List<AttemptResult> {
        val map = HashMap(attempts)
        questions.forEachIndexed { i, q ->
            if (map[i] == null) map[i] = AttemptResult(q, AttemptStatus.SKIPPED, null, 0)
        }
        return map.entries.sortedBy { it.key }.map { it.value }
    }

    fun finishAndSave(onDone: () -> Unit) {
        if (saving || savedExamId != null) {
            onDone(); return
        }
        saving = true
        val cfg = config ?: run { saving = false; onDone(); return }
        val res = results()
        val duration = ((System.currentTimeMillis() - examStartedAt) / 1000).toInt()
        viewModelScope.launch {
            try {
                val app = GaussApp.from(getApplication())
                val examId = app.history.saveExam(cfg, res, duration)
                savedExamId = examId
                saveError = null
                rewardSummary = runCatching {
                    app.gamification.rewardExam(examId, cfg, res, duration)
                }.getOrElse {
                    saveError = "آزمون ذخیره شد، اما پاداش XP ثبت نشد."
                    null
                }
            } catch (error: Throwable) {
                saveError = error.message?.takeIf { it.isNotBlank() }
                    ?: "ذخیره آزمون کامل نشد. نتیجه را نگه داشتم تا دوباره تلاش کنی."
            } finally {
                saving = false
                finished = true
                onDone()
            }
        }
    }

    fun reset() {
        config = null
        questions = emptyList()
        index = 0
        attempts.clear()
        scratch.clear()
        finished = false
        saving = false
        saveError = null
        rewardSummary = null
        savedExamId = null
    }
}

/** Obtain the exam engine scoped to the Activity so it is shared across screens. */
@Composable
fun sharedExamViewModel(): ExamViewModel {
    val owner = LocalContext.current as ComponentActivity
    return viewModel(viewModelStoreOwner = owner)
}
