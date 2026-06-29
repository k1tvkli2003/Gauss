package com.gauss.app.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.compose.ui.unit.em
import com.gauss.app.R

/** Vazirmatn — the Persian face shipped with the app, mapped across weights. */
val Vazirmatn = FontFamily(
    Font(R.font.vazirmatn_regular, FontWeight.Normal),
    Font(R.font.vazirmatn_semibold, FontWeight.SemiBold),
    Font(R.font.vazirmatn_bold, FontWeight.Bold),
    Font(R.font.vazirmatn_extrabold, FontWeight.ExtraBold),
    Font(R.font.vazirmatn_black, FontWeight.Black),
)

private val base = Typography()

val GaussTypography = Typography(
    displayLarge = base.displayLarge.copy(fontFamily = Vazirmatn),
    displayMedium = base.displayMedium.copy(fontFamily = Vazirmatn),
    displaySmall = base.displaySmall.copy(fontFamily = Vazirmatn),
    headlineLarge = base.headlineLarge.copy(fontFamily = Vazirmatn, fontWeight = FontWeight.Black, letterSpacing = 0.sp),
    headlineMedium = base.headlineMedium.copy(fontFamily = Vazirmatn, fontWeight = FontWeight.ExtraBold, letterSpacing = 0.sp),
    headlineSmall = base.headlineSmall.copy(fontFamily = Vazirmatn, fontWeight = FontWeight.Bold, letterSpacing = 0.sp),
    titleLarge = TextStyle(fontFamily = Vazirmatn, fontWeight = FontWeight.Black, fontSize = 23.sp, lineHeight = 1.35.em),
    titleMedium = TextStyle(fontFamily = Vazirmatn, fontWeight = FontWeight.Bold, fontSize = 17.sp, lineHeight = 1.45.em),
    titleSmall = base.titleSmall.copy(fontFamily = Vazirmatn, fontWeight = FontWeight.SemiBold),
    bodyLarge = base.bodyLarge.copy(fontFamily = Vazirmatn, lineHeight = 1.65.em, letterSpacing = 0.sp),
    bodyMedium = base.bodyMedium.copy(fontFamily = Vazirmatn, lineHeight = 1.65.em, letterSpacing = 0.sp),
    bodySmall = base.bodySmall.copy(fontFamily = Vazirmatn, lineHeight = 1.55.em, letterSpacing = 0.sp),
    labelLarge = base.labelLarge.copy(fontFamily = Vazirmatn, fontWeight = FontWeight.Bold, letterSpacing = 0.sp),
    labelMedium = base.labelMedium.copy(fontFamily = Vazirmatn, fontWeight = FontWeight.SemiBold, letterSpacing = 0.sp),
    labelSmall = base.labelSmall.copy(fontFamily = Vazirmatn, letterSpacing = 0.sp),
)
