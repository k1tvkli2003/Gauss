package com.gauss.app.gamify

import com.gauss.app.data.AttemptResult
import com.gauss.app.data.AttemptStatus
import com.gauss.app.data.ContentBlock
import com.gauss.app.data.Difficulty
import com.gauss.app.data.ExamConfig
import com.gauss.app.data.Question
import com.gauss.app.data.QuestionProvenance
import com.gauss.app.data.SourceBank
import com.gauss.app.data.Subject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AdventureGamifyContractsTest {
    @Test
    fun levelCurveMatchesPreviewTarget() {
        val preview = AdventureLevelCurve.previewSnapshot()

        assertEquals(18, preview.level)
        assertEquals(2_460, preview.xpIntoLevel)
        assertEquals(3_200, preview.xpForNextLevel)
        assertEquals("2,460 / 3,200 XP", preview.display)
        assertEquals(77, AdventureLevelCurve.xpPercent(preview.level, preview.xpIntoLevel))
    }

    @Test
    fun displayLabelsKeepMathAndPhysicsRoadsSeparate() {
        assertEquals("Math Road", AdventureDisplayLabels.roadName(Subject.MATH))
        assertEquals("Physics Road", AdventureDisplayLabels.roadName(Subject.PHYSICS))
        assertEquals("Algebra Grove", AdventureDisplayLabels.topicLabel("quadratic_equations_functions"))
        assertEquals("Physics Workshop", AdventureDisplayLabels.stageName(Subject.PHYSICS, null))
        assertFalse(AdventureDisplayLabels.labelsFor(Subject.MATH).containsKey("dynamics"))
        assertFalse(AdventureDisplayLabels.labelsFor(Subject.PHYSICS).containsKey("quadratic_equations_functions"))
    }

    @Test
    fun previewRewardSummaryMatchesVaultNumbers() {
        val summary = AdventureRewardRules.summarize(AdventureRewardRules.previewRewardEvents())

        assertEquals("adventure_rewards_v1", summary.rulesVersion)
        assertEquals(Subject.MATH, summary.subject)
        assertEquals("mission-preview", summary.missionId)
        assertEquals(520, summary.xpTotal)
        assertEquals(120, summary.coins)
        assertEquals(2, summary.gems)
        assertEquals(2, summary.focusDelta)
        assertEquals(listOf("gear.common.explorer_wand"), summary.gearDrops)
        assertEquals("mission_complete", summary.mascotState)
        assertEquals("claimable", summary.claimState)
    }

    @Test
    fun liveMissionRewardEventsUseExamResults() {
        val config = ExamConfig(
            subject = Subject.MATH,
            topicKeys = listOf("quadratic_equations_functions"),
            sourceBanks = SourceBank.entries.toList(),
            difficulties = Difficulty.entries.toList(),
            count = 3,
        )
        val results = listOf(
            AttemptResult(sampleQuestion("q1", hasShortcut = true), AttemptStatus.CORRECT, selectedOption = 0, timeTakenSeconds = 21),
            AttemptResult(sampleQuestion("q2"), AttemptStatus.CORRECT, selectedOption = 1, timeTakenSeconds = 18),
            AttemptResult(sampleQuestion("q3"), AttemptStatus.WRONG, selectedOption = 2, timeTakenSeconds = 33),
        )

        val events = AdventureRewardEventMapper.fromMission(config, results, dayKey = "2026-07-03")
        val mission = events.first { it.type == AdventureEventType.MissionCompleted }
        val summary = AdventureRewardRules.summarize(events)

        assertEquals("2", mission.metadata["combo"])
        assertEquals("66", mission.metadata["accuracy"])
        assertEquals("1", mission.metadata["focusLeft"])
        assertEquals(140, summary.xpTotal)
        assertEquals(120, summary.coins)
        assertEquals(2, summary.gems)
        assertEquals(1, summary.focusDelta)
        assertFalse(events.any { it.type == AdventureEventType.QuestCompleted })
    }

    @Test
    fun liveMissionRewardEventsUnlockDailyTrapQuestAtTarget() {
        val config = ExamConfig(
            subject = Subject.MATH,
            topicKeys = listOf("quadratic_equations_functions"),
            sourceBanks = SourceBank.entries.toList(),
            difficulties = Difficulty.entries.toList(),
            count = 2,
        )
        val results = listOf(
            AttemptResult(sampleQuestion("q1", hasShortcut = true), AttemptStatus.CORRECT, selectedOption = 0, timeTakenSeconds = 12),
            AttemptResult(sampleQuestion("q2", hasShortcut = true), AttemptStatus.CORRECT, selectedOption = 0, timeTakenSeconds = 11),
        )

        val events = AdventureRewardEventMapper.fromMission(config, results, dayKey = "2026-07-03")

        assertEquals(AdventureRewardRules.DAILY_TRAP_TARGET, events.count { it.type == AdventureEventType.TrapSolved })
        assertTrue(events.any { it.type == AdventureEventType.QuestCompleted })
    }

    @Test
    fun rewardEventsAreIdempotentByEventId() {
        val events = AdventureRewardRules.previewRewardEvents()
        val duplicated = events + events.first()

        assertEquals(
            AdventureRewardRules.summarize(events).xpTotal,
            AdventureRewardRules.summarize(duplicated).xpTotal,
        )
    }

    @Test
    fun achievementCatalogHasExpectedFirstPassShape() {
        val achievements = AdventureAchievementCatalog.achievements
        val ids = achievements.map { it.id }

        assertEquals(71, achievements.size)
        assertEquals(ids.size, ids.toSet().size)
        assertEquals(24, AdventureAchievementCatalog.totalFeaturedBadgeCount())
        assertEquals(12, AdventureAchievementCatalog.unlockedPreviewCount())
        assertEquals(
            18,
            achievements.count { it.family == AchievementFamily.Mastery && it.subject == Subject.MATH },
        )
        assertEquals(
            11,
            achievements.count { it.family == AchievementFamily.Mastery && it.subject == Subject.PHYSICS },
        )
        assertTrue(achievements.all { it.titleKey.startsWith("achievement.") })
        assertTrue(achievements.all { it.iconAsset.startsWith("badge_") })
        assertTrue(achievements.any { it.hidden && it.rarity == BadgeRarity.Legendary })
    }

    @Test
    fun questCatalogCoversPreviewSurfaces() {
        val quests = AdventureAchievementCatalog.quests.associateBy { it.id }

        assertEquals(8, quests.size)
        assertEquals(2, quests.getValue("daily_trap_spotter").target)
        assertEquals(200, quests.getValue("daily_trap_spotter").rewardXp)
        assertEquals(8, quests.getValue("weekly_review_rescue").target)
        assertEquals("comeback", quests.getValue("weekly_review_rescue").linkedMascotState)
    }

    @Test
    fun mascotManifestHasOriginalDirectionsAndRequiredStates() {
        assertEquals(3, AdventureMascotManifest.familyDirections.size)
        assertEquals("explorer_gauss", AdventureMascotManifest.recommendedFamilyId)
        assertEquals(12, AdventureMascotManifest.states.size)

        val stateIds = AdventureMascotManifest.states.map { it.stateId }
        assertEquals(stateIds.size, stateIds.toSet().size)
        assertTrue("mission_complete" in stateIds)
        assertTrue("coach_hint" in stateIds)
        assertTrue("offline_safe" in stateIds)
        assertTrue(AdventureMascotManifest.states.all { it.contentDescription.isNotBlank() })
        assertNotNull(AdventureMascotManifest.familyDirections.firstOrNull { it.id == "explorer_gauss" })
    }

    private fun sampleQuestion(id: String, hasShortcut: Boolean = false): Question =
        Question(
            id = id,
            subject = Subject.MATH,
            topicKey = "quadratic_equations_functions",
            difficulty = Difficulty.HARD,
            stem = listOf(ContentBlock.Text("Find the shortcut.")),
            optionBlocks = List(4) { index -> listOf(ContentBlock.Text("${index + 1}")) },
            correctOptionIndex = 0,
            solution = listOf(ContentBlock.Text("Use the factor shortcut.")),
            shortcut = if (hasShortcut) listOf(ContentBlock.Text("Avoid expansion.")) else null,
            sourceBank = SourceBank.GAUSS,
            provenance = QuestionProvenance(
                kind = "fixture",
                edition = "adventure",
                questionNumber = null,
                questionPdf = null,
                questionPage = null,
                solutionPage = null,
                solutionOrigin = "unit-test",
            ),
        )
}
