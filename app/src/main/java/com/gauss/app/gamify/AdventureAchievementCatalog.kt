package com.gauss.app.gamify

import com.gauss.app.data.ComprehensiveTaxonomy
import com.gauss.app.data.Subject

enum class AchievementFamily {
    Mastery,
    Consistency,
    Correction,
    Exploration,
    Challenge,
    Quest,
    Collection,
    Comeback,
    Secret,
}

enum class BadgeRarity {
    Common,
    Rare,
    Epic,
    Legendary,
}

data class AchievementDefinition(
    val id: String,
    val version: Int,
    val family: AchievementFamily,
    val titleKey: String,
    val descriptionKey: String,
    val criteriaType: String,
    val subject: Subject? = null,
    val topicKey: String? = null,
    val threshold: Int,
    val rarity: BadgeRarity,
    val iconAsset: String,
    val hidden: Boolean = false,
)

data class QuestDefinition(
    val id: String,
    val cadence: String,
    val criteriaType: String,
    val target: Int,
    val rewardXp: Int,
    val rewardCurrency: String? = null,
    val linkedMascotState: String,
)

object AdventureAchievementCatalog {
    private val mastery = ComprehensiveTaxonomy.topics.map { topic ->
        AchievementDefinition(
            id = "mastery_${topic.subject.raw}_${topic.key}",
            version = 1,
            family = AchievementFamily.Mastery,
            titleKey = "achievement.mastery.${topic.subject.raw}.${topic.key}.title",
            descriptionKey = "achievement.mastery.${topic.subject.raw}.${topic.key}.description",
            criteriaType = "topic_mastery_percent",
            subject = topic.subject,
            topicKey = topic.key,
            threshold = 70,
            rarity = BadgeRarity.Common,
            iconAsset = "badge_mastery_${topic.subject.raw}_${topic.key}",
        )
    }

    private val consistency = listOf(3, 7, 14, 30, 60, 100).map { days ->
        AchievementDefinition(
            id = "streak_$days",
            version = 1,
            family = AchievementFamily.Consistency,
            titleKey = "achievement.streak_$days.title",
            descriptionKey = "achievement.streak_$days.description",
            criteriaType = "streak_days",
            threshold = days,
            rarity = if (days >= 60) BadgeRarity.Epic else BadgeRarity.Rare,
            iconAsset = "badge_streak_$days",
        )
    }

    private val correction = listOf(1, 5, 10, 25).map { count ->
        AchievementDefinition(
            id = "mistake_mender_$count",
            version = 1,
            family = AchievementFamily.Correction,
            titleKey = "achievement.mistake_mender_$count.title",
            descriptionKey = "achievement.mistake_mender_$count.description",
            criteriaType = "mistakes_corrected",
            threshold = count,
            rarity = if (count >= 25) BadgeRarity.Epic else BadgeRarity.Common,
            iconAsset = "badge_mistake_mender_$count",
        )
    }

    private val exploration = listOf(
        "math_trailblazer" to Subject.MATH,
        "physics_trailblazer" to Subject.PHYSICS,
        "dual_road_scout" to null,
        "map_vault_finder" to null,
    ).map { (id, subject) ->
        AchievementDefinition(
            id = id,
            version = 1,
            family = AchievementFamily.Exploration,
            titleKey = "achievement.$id.title",
            descriptionKey = "achievement.$id.description",
            criteriaType = "road_exploration",
            subject = subject,
            threshold = 1,
            rarity = BadgeRarity.Common,
            iconAsset = "badge_$id",
        )
    }

    private val challenge = listOf(
        "boss_algebra_grove",
        "boss_calculus_cliffs",
        "boss_geometry_gate",
        "boss_statistics_tower",
        "boss_physics_workshop",
        "boss_mechanics_engine",
        "boss_electromagnetism_core",
        "boss_quantum_lab",
    ).mapIndexed { index, id ->
        AchievementDefinition(
            id = id,
            version = 1,
            family = AchievementFamily.Challenge,
            titleKey = "achievement.$id.title",
            descriptionKey = "achievement.$id.description",
            criteriaType = "boss_completed",
            subject = if (index < 4) Subject.MATH else Subject.PHYSICS,
            threshold = 1,
            rarity = BadgeRarity.Rare,
            iconAsset = "badge_$id",
        )
    }

    val quests = listOf(
        QuestDefinition("daily_trap_spotter", "daily", "trap_solved", 2, 200, linkedMascotState = "quest_complete"),
        QuestDefinition("daily_focus_keeper", "daily", "mission_focus_left", 2, 40, "focus", "low_focus"),
        QuestDefinition("weekly_review_rescue", "weekly", "revenge_questions_completed", 8, 160, "gems", "comeback"),
        QuestDefinition("weekend_boss_run", "weekend", "boss_accuracy", 85, 220, "chest", "mission_complete"),
        QuestDefinition("comeback_warmup", "comeback", "comeback_mission_completed", 1, 60, null, "comeback"),
        QuestDefinition("mastery_push", "weekly", "topic_mastery_delta", 10, 120, null, "answer_correct"),
        QuestDefinition("physics_spark", "weekly", "physics_missions_completed", 3, 120, "coins", "map_current"),
        QuestDefinition("algebra_sprint", "weekly", "math_missions_completed", 3, 120, "coins", "map_current"),
    )

    private val questAchievements = quests.map { quest ->
        AchievementDefinition(
            id = "quest_${quest.id}",
            version = 1,
            family = AchievementFamily.Quest,
            titleKey = "achievement.quest.${quest.id}.title",
            descriptionKey = "achievement.quest.${quest.id}.description",
            criteriaType = quest.criteriaType,
            threshold = quest.target,
            rarity = BadgeRarity.Rare,
            iconAsset = "badge_quest_${quest.id}",
        )
    }

    private val collection = listOf(
        "first_common_gear",
        "wand_collector",
        "cloak_collector",
        "crest_collector",
        "full_apprentice_set",
        "gem_saver",
        "coin_stash",
        "shop_regular",
    ).map { id ->
        AchievementDefinition(
            id = id,
            version = 1,
            family = AchievementFamily.Collection,
            titleKey = "achievement.$id.title",
            descriptionKey = "achievement.$id.description",
            criteriaType = "collection_progress",
            threshold = 1,
            rarity = BadgeRarity.Common,
            iconAsset = "badge_$id",
        )
    }

    private val secrets = listOf(
        "secret_shortcut_whisper",
        "secret_perfect_focus",
        "secret_vault_listener",
        "secret_midnight_scholar",
    ).map { id ->
        AchievementDefinition(
            id = id,
            version = 1,
            family = AchievementFamily.Secret,
            titleKey = "achievement.$id.title",
            descriptionKey = "achievement.$id.description",
            criteriaType = "secret_condition",
            threshold = 1,
            rarity = BadgeRarity.Legendary,
            iconAsset = "badge_$id",
            hidden = true,
        )
    }

    val achievements: List<AchievementDefinition> =
        mastery + consistency + correction + exploration + challenge + questAchievements + collection + secrets

    val featuredBadgeWall: List<AchievementDefinition> = achievements.take(24)

    fun unlockedPreviewCount(): Int = 12

    fun totalFeaturedBadgeCount(): Int = featuredBadgeWall.size
}
