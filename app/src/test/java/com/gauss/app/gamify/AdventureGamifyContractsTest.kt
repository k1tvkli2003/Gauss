package com.gauss.app.gamify

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
}
