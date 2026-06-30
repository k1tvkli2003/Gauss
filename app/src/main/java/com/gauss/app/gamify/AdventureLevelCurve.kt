package com.gauss.app.gamify

import kotlin.math.roundToInt

data class AdventureLevelProgress(
    val level: Int,
    val xpIntoLevel: Int,
    val xpForNextLevel: Int,
    val progress: Float,
) {
    val display: String = "%,d / %,d XP".format(xpIntoLevel, xpForNextLevel)
}

object AdventureLevelCurve {
    const val PREVIEW_LEVEL = 18
    const val PREVIEW_XP_INTO_LEVEL = 2_460
    const val PREVIEW_XP_FOR_NEXT_LEVEL = 3_200

    fun xpTargetForLevel(level: Int): Int {
        require(level >= 1) { "Level must be positive." }
        return 320 + (level * 160)
    }

    fun snapshot(level: Int, xpIntoLevel: Int): AdventureLevelProgress {
        val target = xpTargetForLevel(level)
        return AdventureLevelProgress(
            level = level,
            xpIntoLevel = xpIntoLevel.coerceIn(0, target),
            xpForNextLevel = target,
            progress = (xpIntoLevel.toFloat() / target.toFloat()).coerceIn(0f, 1f),
        )
    }

    fun previewSnapshot(): AdventureLevelProgress =
        snapshot(PREVIEW_LEVEL, PREVIEW_XP_INTO_LEVEL)

    fun fromLifetimeXp(totalXp: Int): AdventureLevelProgress {
        var remaining = totalXp.coerceAtLeast(0)
        var level = 1
        while (remaining >= xpTargetForLevel(level)) {
            remaining -= xpTargetForLevel(level)
            level += 1
        }
        return snapshot(level, remaining)
    }

    fun xpPercent(level: Int, xpIntoLevel: Int): Int =
        (snapshot(level, xpIntoLevel).progress * 100).roundToInt()
}
