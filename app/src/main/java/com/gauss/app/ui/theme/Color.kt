package com.gauss.app.ui.theme

import androidx.compose.ui.graphics.Color

object GaussColors {
    val Primary = Color(0xFF4DB9A7)
    val PrimaryContainer = Color(0xFFE4F7F2)
    val Secondary = Color(0xFFF2A66B)
    val SecondaryContainer = Color(0xFFFFEADB)
    val Tertiary = Color(0xFF7B9DCD)
    val TertiaryContainer = Color(0xFFE7EEF9)
    val Lavender = Color(0xFFB9ADE7)
    val Peach = Color(0xFFF7D8CB)
    val BackgroundLight = Color(0xFFF9FBF8)
    val SurfaceLight = Color(0xFFFFFCFA)
    val SurfaceVariantLight = Color(0xFFF0F4F1)
    val TextLight = Color(0xFF17211F)
    val MutedLight = Color(0xFF65746F)
    val OutlineLight = Color(0xFFD8E2DD)

    val BackgroundDark = Color(0xFF0A0F0D)
    val SurfaceDark = Color(0xFF111714)
    val SurfaceVariantDark = Color(0xFF18211D)
    val TextDark = Color(0xFFEAF3EF)
    val MutedDark = Color(0xFF95A39D)
    val OutlineDark = Color(0xFF2A3933)

    val Success = Color(0xFF42B980)
    val Warning = Color(0xFFF2B84F)
    val Error = Color(0xFFE56F7B)
    val Math = Lavender
    val Physics = Tertiary

    // Heatmap ramp.
    val HeatLow = Color(0xFFD7EEE7)
    val HeatMid = Color(0xFF78CDBA)

    // Compatibility aliases for legacy custom components.
    val Bg = BackgroundDark
    val Surface = SurfaceDark
    val Card = SurfaceVariantDark
    val Raised = Color(0xFF203029)
    val Border = OutlineDark
    val Text = TextDark
    val Muted = MutedDark
    val NeonBlue = Primary
    val NeonPurple = Math
    val NeonGreen = Success
    val NeonAmber = Warning
    val NeonRed = Error
}

/** Translucent accent fill used for chips / selected states (~10% alpha). */
fun Color.soft(alpha: Float = 0.10f): Color = copy(alpha = alpha)
