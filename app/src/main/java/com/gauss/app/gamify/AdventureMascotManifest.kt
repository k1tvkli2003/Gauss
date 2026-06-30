package com.gauss.app.gamify

enum class MascotRole {
    Companion,
    Coach,
    CelebrationLead,
    Shopkeeper,
    ComebackGuide,
}

data class MascotFamilyDirection(
    val id: String,
    val name: String,
    val silhouette: String,
    val personality: String,
    val roleFit: Set<MascotRole>,
    val productionRisk: String,
    val noCopyNote: String,
)

data class MascotStateSpec(
    val stateId: String,
    val triggerEvent: String,
    val emotionAndPose: String,
    val uiConsumers: List<String>,
    val reducedMotionFallback: String,
    val contentDescription: String,
)

object AdventureMascotManifest {
    val familyDirections = listOf(
        MascotFamilyDirection(
            id = "explorer_gauss",
            name = "Explorer Gauss",
            silhouette = "Small wizard explorer with a crown-hat, cloak, compass/star motif, and rounded friendly proportions.",
            personality = "Curious, proud, warm, and clever without becoming childish.",
            roleFit = setOf(MascotRole.Companion, MascotRole.Coach, MascotRole.CelebrationLead, MascotRole.Shopkeeper, MascotRole.ComebackGuide),
            productionRisk = "Medium: many poses need strict costume and face consistency.",
            noCopyNote = "Avoid Duolingo/Lingo silhouettes, owl cues, green-first palette, copied expressions, or protected character poses.",
        ),
        MascotFamilyDirection(
            id = "astro_scholar",
            name = "Astro Scholar",
            silhouette = "Tiny astronaut mathematician with a star satchel, floating chalk, and simple helmet rim.",
            personality = "Futuristic, playful, science-forward, and precise.",
            roleFit = setOf(MascotRole.Companion, MascotRole.Coach, MascotRole.CelebrationLead),
            productionRisk = "Medium/high: helmet reflections can make repeated expressions harder.",
            noCopyNote = "No NASA marks, no logos, no generic space-IP costume copying.",
        ),
        MascotFamilyDirection(
            id = "clockwork_mentor",
            name = "Clockwork Mentor",
            silhouette = "Toy-like brass automaton tutor with a gem core, soft hands, and a rounded hood.",
            personality = "Puzzle-minded, patient, precise, and reward-machine friendly.",
            roleFit = setOf(MascotRole.Coach, MascotRole.CelebrationLead, MascotRole.Shopkeeper),
            productionRisk = "Medium: metal must stay warm and not feel cold or corporate.",
            noCopyNote = "No copied robot silhouettes, no branded sci-fi props, no borrowed iconography.",
        ),
    )

    val recommendedFamilyId = "explorer_gauss"

    val states = listOf(
        MascotStateSpec(
            stateId = "neutral_hud",
            triggerEvent = "AppLoaded",
            emotionAndPose = "Calm smile with a small wave.",
            uiConsumers = listOf("Map HUD", "Profile hero"),
            reducedMotionFallback = "Static avatar.",
            contentDescription = "Explorer Gauss avatar",
        ),
        MascotStateSpec(
            stateId = "map_current",
            triggerEvent = "RoadNodeSelected",
            emotionAndPose = "Pointing toward the glowing path.",
            uiConsumers = listOf("Map"),
            reducedMotionFallback = "Static pointer with node glow.",
            contentDescription = "Explorer Gauss points to the current mission",
        ),
        MascotStateSpec(
            stateId = "coach_hint",
            triggerEvent = "TrapHintAvailable",
            emotionAndPose = "Leaning forward with a raised wand.",
            uiConsumers = listOf("Arena"),
            reducedMotionFallback = "Static coach bubble.",
            contentDescription = "Explorer Gauss gives a hint",
        ),
        MascotStateSpec(
            stateId = "answer_correct",
            triggerEvent = "CorrectAnswer",
            emotionAndPose = "Excited check gesture and bright eyes.",
            uiConsumers = listOf("Arena"),
            reducedMotionFallback = "Static smile plus check icon.",
            contentDescription = "Explorer Gauss celebrates a correct answer",
        ),
        MascotStateSpec(
            stateId = "answer_wrong",
            triggerEvent = "WrongAnswer",
            emotionAndPose = "Gentle thinking pose, no shame.",
            uiConsumers = listOf("Arena"),
            reducedMotionFallback = "Static thinking pose.",
            contentDescription = "Explorer Gauss suggests trying again",
        ),
        MascotStateSpec(
            stateId = "combo",
            triggerEvent = "ComboReached",
            emotionAndPose = "Sparkling wand and proud grin.",
            uiConsumers = listOf("Arena combo ribbon"),
            reducedMotionFallback = "Static wand sparkle.",
            contentDescription = "Explorer Gauss celebrates the combo",
        ),
        MascotStateSpec(
            stateId = "low_focus",
            triggerEvent = "LowFocus",
            emotionAndPose = "Tired but encouraging with a tiny lantern.",
            uiConsumers = listOf("HUD", "Arena"),
            reducedMotionFallback = "Static low-focus badge.",
            contentDescription = "Explorer Gauss warns that focus is low",
        ),
        MascotStateSpec(
            stateId = "mission_complete",
            triggerEvent = "MissionCompleted",
            emotionAndPose = "Full-body celebration beside the vault.",
            uiConsumers = listOf("Reward Vault"),
            reducedMotionFallback = "Static reward hero.",
            contentDescription = "Explorer Gauss celebrates mission completion",
        ),
        MascotStateSpec(
            stateId = "quest_complete",
            triggerEvent = "QuestCompleted",
            emotionAndPose = "Thumbs-up and wand star.",
            uiConsumers = listOf("Reward quest row"),
            reducedMotionFallback = "Quest checkmark only.",
            contentDescription = "Explorer Gauss marks the quest complete",
        ),
        MascotStateSpec(
            stateId = "gear_shop",
            triggerEvent = "CosmeticsShopOpened",
            emotionAndPose = "Holding a wand and showing a small gear chest.",
            uiConsumers = listOf("Profile shop"),
            reducedMotionFallback = "Static shopkeeper pose.",
            contentDescription = "Explorer Gauss shows new gear",
        ),
        MascotStateSpec(
            stateId = "comeback",
            triggerEvent = "ComebackMissionStarted",
            emotionAndPose = "Welcoming pose with a warm lantern.",
            uiConsumers = listOf("Map", "Profile", "Revenge"),
            reducedMotionFallback = "Static welcome pose.",
            contentDescription = "Explorer Gauss welcomes the user back",
        ),
        MascotStateSpec(
            stateId = "offline_safe",
            triggerEvent = "OfflineProgressSaved",
            emotionAndPose = "Calm shield pose.",
            uiConsumers = listOf("Profile offline panel"),
            reducedMotionFallback = "Static shield icon.",
            contentDescription = "Explorer Gauss says progress is saved locally",
        ),
    )
}
