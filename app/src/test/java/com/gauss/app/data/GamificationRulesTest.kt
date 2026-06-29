package com.gauss.app.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class GamificationRulesTest {
    @Test
    fun levelCurveStartsAtOneAndProgressStaysBounded() {
        assertEquals(1, GamificationRepository.levelFor(0))
        assertEquals(1, GamificationRepository.levelFor(159))
        assertEquals(2, GamificationRepository.levelFor(160))
        assertTrue(GamificationRepository.levelProgress(0) in 0f..1f)
        assertTrue(GamificationRepository.levelProgress(10_000) in 0f..1f)
    }
}
