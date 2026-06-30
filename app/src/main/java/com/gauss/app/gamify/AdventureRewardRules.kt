package com.gauss.app.gamify

import com.gauss.app.data.Subject

enum class AdventureEventType {
    MissionStarted,
    AnswerSubmitted,
    CorrectAnswer,
    WrongAnswer,
    MistakeCorrected,
    TrapSolved,
    MissionCompleted,
    QuestCompleted,
    RewardClaimed,
    ChestOpened,
    FocusSpent,
    FocusRecovered,
    StreakAdvanced,
}

enum class AdventureRewardType {
    XP,
    Coins,
    Gems,
    Focus,
    Gear,
}

data class AdventureRewardEvent(
    val id: String,
    val type: AdventureEventType,
    val dayKey: String,
    val subject: Subject,
    val topicKey: String? = null,
    val missionId: String? = null,
    val metadata: Map<String, String> = emptyMap(),
)

data class AdventureRewardGrant(
    val type: AdventureRewardType,
    val amount: Int,
    val reason: String,
    val sourceEventId: String,
    val itemId: String? = null,
)

data class RewardSummaryV2(
    val id: String,
    val rulesVersion: String,
    val subject: Subject,
    val missionId: String?,
    val xpTotal: Int,
    val coins: Int,
    val gems: Int,
    val focusDelta: Int,
    val gearDrops: List<String>,
    val grants: List<AdventureRewardGrant>,
    val mascotState: String,
    val claimState: String,
)

object AdventureRewardRules {
    const val RULES_VERSION = "adventure_rewards_v1"
    const val DAILY_TRAP_TARGET = 2
    const val DAILY_TRAP_REWARD_XP = 200
    const val PREVIEW_COMMON_GEAR_ID = "gear.common.explorer_wand"

    fun summarize(
        events: List<AdventureRewardEvent>,
        alreadyAppliedEventIds: Set<String> = emptySet(),
        claimState: String = "claimable",
    ): RewardSummaryV2 {
        val eligible = events
            .filterNot { it.id in alreadyAppliedEventIds }
            .distinctBy { it.id }

        val grants = mutableListOf<AdventureRewardGrant>()

        fun grant(
            type: AdventureRewardType,
            amount: Int,
            reason: String,
            sourceEventId: String,
            itemId: String? = null,
        ) {
            grants += AdventureRewardGrant(type, amount, reason, sourceEventId, itemId)
        }

        eligible.filter { it.type == AdventureEventType.TrapSolved }
            .take(DAILY_TRAP_TARGET)
            .forEach { event ->
                grant(AdventureRewardType.XP, 20, "Trap solved", event.id)
            }

        eligible.filter { it.type == AdventureEventType.MissionCompleted }
            .distinctBy { it.missionId ?: it.id }
            .forEach { event ->
                grant(AdventureRewardType.XP, 120, "Mission complete", event.id)
                val combo = event.metadata["combo"]?.toIntOrNull() ?: 0
                val accuracy = event.metadata["accuracy"]?.toIntOrNull() ?: 0
                val focusLeft = event.metadata["focusLeft"]?.toIntOrNull() ?: 0
                if (combo >= 4) grant(AdventureRewardType.XP, 80, "Combo bonus", event.id)
                if (accuracy >= 90) grant(AdventureRewardType.XP, 100, "Accuracy bonus", event.id)
                if (focusLeft >= 2) grant(AdventureRewardType.Focus, 2, "Focus left", event.id)
            }

        eligible.filter { it.type == AdventureEventType.QuestCompleted }
            .distinctBy { it.id }
            .forEach { event ->
                grant(AdventureRewardType.XP, DAILY_TRAP_REWARD_XP, "Daily quest", event.id)
            }

        eligible.filter { it.type == AdventureEventType.ChestOpened }
            .distinctBy { it.id }
            .forEach { event ->
                grant(AdventureRewardType.Coins, 120, "Coins", event.id)
                grant(AdventureRewardType.Gems, 2, "Gems", event.id)
                grant(AdventureRewardType.Gear, 1, "Common Gear", event.id, PREVIEW_COMMON_GEAR_ID)
            }

        val subject = eligible.firstOrNull()?.subject ?: Subject.MATH
        val missionId = eligible.firstOrNull { it.missionId != null }?.missionId
        val rewardId = missionId?.let { "reward:$it" } ?: "reward:${eligible.joinToString(":") { it.id }.hashCode()}"
        return RewardSummaryV2(
            id = rewardId,
            rulesVersion = RULES_VERSION,
            subject = subject,
            missionId = missionId,
            xpTotal = grants.filter { it.type == AdventureRewardType.XP }.sumOf { it.amount },
            coins = grants.filter { it.type == AdventureRewardType.Coins }.sumOf { it.amount },
            gems = grants.filter { it.type == AdventureRewardType.Gems }.sumOf { it.amount },
            focusDelta = grants.filter { it.type == AdventureRewardType.Focus }.sumOf { it.amount },
            gearDrops = grants.filter { it.type == AdventureRewardType.Gear }.mapNotNull { it.itemId },
            grants = grants,
            mascotState = if (grants.isNotEmpty()) "mission_complete" else "neutral_hud",
            claimState = claimState,
        )
    }

    fun previewRewardEvents(dayKey: String = "2026-07-01"): List<AdventureRewardEvent> =
        listOf(
            AdventureRewardEvent(
                id = "trap_solved:mission-preview:q6",
                type = AdventureEventType.TrapSolved,
                dayKey = dayKey,
                subject = Subject.MATH,
                topicKey = "quadratic_equations_functions",
                missionId = "mission-preview",
            ),
            AdventureRewardEvent(
                id = "mission_completed:mission-preview",
                type = AdventureEventType.MissionCompleted,
                dayKey = dayKey,
                subject = Subject.MATH,
                topicKey = "quadratic_equations_functions",
                missionId = "mission-preview",
                metadata = mapOf("combo" to "4", "accuracy" to "93", "focusLeft" to "2"),
            ),
            AdventureRewardEvent(
                id = "quest_completed:daily_trap_spotter:$dayKey",
                type = AdventureEventType.QuestCompleted,
                dayKey = dayKey,
                subject = Subject.MATH,
                topicKey = "quadratic_equations_functions",
                missionId = "mission-preview",
            ),
            AdventureRewardEvent(
                id = "chest_opened:mission-preview:common",
                type = AdventureEventType.ChestOpened,
                dayKey = dayKey,
                subject = Subject.MATH,
                topicKey = "quadratic_equations_functions",
                missionId = "mission-preview",
            ),
        )
}
