package com.gauss.app.gamify

import com.gauss.app.data.AttemptResult
import com.gauss.app.data.AttemptStatus
import com.gauss.app.data.ExamConfig
import com.gauss.app.data.Subject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object AdventureRewardEventMapper {
    fun fromMission(
        config: ExamConfig,
        results: List<AttemptResult>,
        dayKey: String = todayKey(),
    ): List<AdventureRewardEvent> {
        if (results.isEmpty()) return AdventureRewardRules.previewRewardEvents(dayKey)

        val subject = config.subject
        val missionId = missionId(config, results)
        val topicKey = config.topicKeys.firstOrNull() ?: results.firstOrNull()?.question?.topicKey
        val correct = results.count { it.status == AttemptStatus.CORRECT }
        val attempted = results.count { it.status != AttemptStatus.SKIPPED }.coerceAtLeast(1)
        val wrongOrSkipped = results.count { it.status != AttemptStatus.CORRECT }
        val accuracy = ((correct.toFloat() / attempted) * 100).toInt().coerceIn(0, 100)
        val combo = longestCorrectStreak(results)
        val focusLeft = (2 - wrongOrSkipped).coerceIn(0, 2)

        val events = mutableListOf<AdventureRewardEvent>()
        results
            .filter { it.status == AttemptStatus.CORRECT && it.question.shortcut != null }
            .take(AdventureRewardRules.DAILY_TRAP_TARGET)
            .forEachIndexed { index, result ->
                events += AdventureRewardEvent(
                    id = "trap_solved:$missionId:${result.question.id}:$index",
                    type = AdventureEventType.TrapSolved,
                    dayKey = dayKey,
                    subject = result.question.subject,
                    topicKey = result.question.topicKey,
                    missionId = missionId,
                )
            }

        events += AdventureRewardEvent(
            id = "mission_completed:$missionId",
            type = AdventureEventType.MissionCompleted,
            dayKey = dayKey,
            subject = subject,
            topicKey = topicKey,
            missionId = missionId,
            metadata = mapOf(
                "combo" to combo.toString(),
                "accuracy" to accuracy.toString(),
                "focusLeft" to focusLeft.toString(),
            ),
        )

        if (events.count { it.type == AdventureEventType.TrapSolved } >= AdventureRewardRules.DAILY_TRAP_TARGET) {
            events += AdventureRewardEvent(
                id = "quest_completed:daily_trap_spotter:$dayKey:$missionId",
                type = AdventureEventType.QuestCompleted,
                dayKey = dayKey,
                subject = subject,
                topicKey = topicKey,
                missionId = missionId,
            )
        }

        if (correct > 0) {
            events += AdventureRewardEvent(
                id = "chest_opened:$missionId:common",
                type = AdventureEventType.ChestOpened,
                dayKey = dayKey,
                subject = subject,
                topicKey = topicKey,
                missionId = missionId,
            )
        }

        return events
    }

    private fun missionId(config: ExamConfig, results: List<AttemptResult>): String {
        val topic = config.topicKeys.firstOrNull()
            ?: results.firstOrNull()?.question?.topicKey
            ?: "mixed"
        val firstQuestion = results.firstOrNull()?.question?.id ?: config.count.toString()
        return "mission:${config.subject.raw}:$topic:$firstQuestion"
    }

    private fun longestCorrectStreak(results: List<AttemptResult>): Int {
        var current = 0
        var best = 0
        results.forEach { result ->
            if (result.status == AttemptStatus.CORRECT) {
                current += 1
                best = maxOf(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    private fun todayKey(): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
}
