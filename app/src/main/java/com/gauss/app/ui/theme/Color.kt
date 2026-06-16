package com.gauss.app.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * Gauss "zen-hacker" palette — neon accents on near-black charcoal.
 * Lifted verbatim from the original design tokens so the look is preserved.
 */
object GaussColors {
    val Bg = Color(0xFF0B0F14)
    val Surface = Color(0xFF11161D)
    val Card = Color(0xFF171E27)
    val Raised = Color(0xFF1F2832)
    val Border = Color(0xFF2A3744)
    val Text = Color(0xFFE6EDF3)
    val Muted = Color(0xFF9AA6B2)

    val NeonBlue = Color(0xFF3DD3FF)
    val NeonPurple = Color(0xFFA06BFF)
    val NeonGreen = Color(0xFF3DFF99)
    val NeonAmber = Color(0xFFFFC23D)
    val NeonRed = Color(0xFFFF5C72)

    // Heatmap ramp.
    val HeatLow = Color(0xFF1C6B47)
    val HeatMid = Color(0xFF2BB673)
}

/** Translucent accent fill used for chips / selected states (~10% alpha). */
fun Color.soft(alpha: Float = 0.10f): Color = copy(alpha = alpha)
