package com.gauss.app.ui.theme

import android.app.Activity
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val GaussScheme = darkColorScheme(
    primary = GaussColors.NeonBlue,
    onPrimary = GaussColors.Bg,
    secondary = GaussColors.NeonPurple,
    onSecondary = GaussColors.Bg,
    tertiary = GaussColors.NeonGreen,
    background = GaussColors.Bg,
    onBackground = GaussColors.Text,
    surface = GaussColors.Surface,
    onSurface = GaussColors.Text,
    surfaceVariant = GaussColors.Card,
    onSurfaceVariant = GaussColors.Muted,
    outline = GaussColors.Border,
    error = GaussColors.NeonRed,
)

@Composable
fun GaussTheme(content: @Composable () -> Unit) {
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            WindowCompat.setDecorFitsSystemWindows(window, false)
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false
        }
    }
    MaterialTheme(
        colorScheme = GaussScheme,
        typography = GaussTypography,
        content = content,
    )
}
