package com.gauss.app.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val GaussLightScheme = lightColorScheme(
    primary = GaussColors.Primary,
    onPrimary = GaussColors.BackgroundDark,
    primaryContainer = GaussColors.PrimaryContainer,
    onPrimaryContainer = GaussColors.TextLight,
    secondary = GaussColors.Secondary,
    onSecondary = GaussColors.BackgroundDark,
    secondaryContainer = GaussColors.SecondaryContainer,
    tertiary = GaussColors.Tertiary,
    onTertiary = GaussColors.BackgroundDark,
    tertiaryContainer = GaussColors.TertiaryContainer,
    background = GaussColors.BackgroundLight,
    onBackground = GaussColors.TextLight,
    surface = GaussColors.SurfaceLight,
    onSurface = GaussColors.TextLight,
    surfaceVariant = GaussColors.SurfaceVariantLight,
    onSurfaceVariant = GaussColors.MutedLight,
    outline = GaussColors.OutlineLight,
    error = GaussColors.Error,
)

private val GaussDarkScheme = darkColorScheme(
    primary = Color(0xFF7BD8C5),
    onPrimary = GaussColors.BackgroundDark,
    primaryContainer = Color(0xFF173D35),
    onPrimaryContainer = GaussColors.TextDark,
    secondary = Color(0xFFFFBF88),
    onSecondary = GaussColors.BackgroundDark,
    secondaryContainer = Color(0xFF3D2818),
    tertiary = Color(0xFFAFCBFF),
    onTertiary = GaussColors.BackgroundDark,
    tertiaryContainer = Color(0xFF263A5A),
    background = GaussColors.BackgroundDark,
    onBackground = GaussColors.TextDark,
    surface = GaussColors.SurfaceDark,
    onSurface = GaussColors.TextDark,
    surfaceVariant = GaussColors.SurfaceVariantDark,
    onSurfaceVariant = GaussColors.MutedDark,
    outline = GaussColors.OutlineDark,
    error = GaussColors.Error,
)

@Composable
fun GaussTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            WindowCompat.setDecorFitsSystemWindows(window, false)
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }
    MaterialTheme(
        colorScheme = if (darkTheme) GaussDarkScheme else GaussLightScheme,
        typography = GaussTypography,
        content = content,
    )
}
