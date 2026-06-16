package com.gauss.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.gauss.app.GaussApp
import com.gauss.app.data.Categories
import com.gauss.app.data.RecentExam
import com.gauss.app.data.TopicStat
import com.gauss.app.ui.components.clickableNoRipple
import com.gauss.app.ui.nav.Routes
import com.gauss.app.ui.theme.GaussColors
import com.gauss.app.ui.theme.soft
import com.gauss.app.ui.toFa

private data class HomeState(
    val answered: Int = 0,
    val accuracy: Int = 0,
    val streak: Int = 0,
    val revenge: Int = 0,
    val recent: List<RecentExam> = emptyList(),
    val weak: List<TopicStat> = emptyList(),
)

@Composable
fun HomeScreen(nav: NavController) {
    val app = LocalContext.current.applicationContext as GaussApp
    var state by remember { mutableStateOf(HomeState()) }

    LaunchedEffect(Unit) {
        val a = app.history.analytics()
        val revenge = app.history.revengeIds().size
        val recent = app.history.recentExams(5)
        state = HomeState(
            answered = a.totalAnswered,
            accuracy = Math.round(a.accuracy).toInt(),
            streak = a.streak,
            revenge = revenge,
            recent = recent,
            weak = a.weakTopics.filter { it.total >= 3 }.take(3),
        )
    }

    Column(
        Modifier
            .fillMaxSize()
            .background(GaussColors.Bg)
            .systemBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
    ) {
        // Header
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                Modifier
                    .size(56.dp)
                    .clip(RoundedCornerShape(18.dp))
                    .border(1.dp, GaussColors.NeonPurple, RoundedCornerShape(18.dp)),
                contentAlignment = Alignment.Center,
            ) {
                Text("∑", color = GaussColors.NeonPurple, fontSize = 26.sp, fontWeight = FontWeight.Bold)
            }
            Column(horizontalAlignment = Alignment.End) {
                Text("گائوس", color = GaussColors.Text, fontSize = 30.sp, fontWeight = FontWeight.Black)
                Text("ذهن رو تیز نگه دار، رفیق.", color = GaussColors.Muted, fontSize = 13.sp)
            }
        }

        Spacer(Modifier.height(28.dp))

        // Stat strip
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatCard("پاسخ‌داده", toFa(state.answered), GaussColors.NeonBlue, Modifier.weight(1f))
            StatCard("دقت", "${toFa(state.accuracy)}٪", GaussColors.NeonGreen, Modifier.weight(1f))
            StatCard("روزهای پیاپی", toFa(state.streak), GaussColors.NeonAmber, Modifier.weight(1f))
        }

        Spacer(Modifier.height(22.dp))

        BigButton(
            title = "آزمون جدید",
            subtitle = "ساخت آزمون سفارشی — ریاضی یا فیزیک",
            glyph = "⚡",
            color = GaussColors.NeonBlue,
        ) { nav.navigate(Routes.setup()) }

        Spacer(Modifier.height(12.dp))

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            SmallButton(
                "حالت انتقام", "${toFa(state.revenge)} سؤال", "🔁",
                GaussColors.NeonRed, Modifier.weight(1f), enabled = state.revenge > 0,
            ) { nav.navigate(Routes.REVENGE) }
            SmallButton(
                "تحلیل و آمار", "نقشه حرارتی مغز", "📊",
                GaussColors.NeonPurple, Modifier.weight(1f),
            ) { nav.navigate(Routes.ANALYTICS) }
        }

        if (state.weak.isNotEmpty()) {
            Spacer(Modifier.height(28.dp))
            Text(
                "ضعف امروز — بزن تو هدف 🎯",
                color = GaussColors.Text,
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.End,
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(12.dp))
            state.weak.forEach { t ->
                Row(
                    Modifier
                        .padding(bottom = 8.dp)
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(GaussColors.Card)
                        .border(1.dp, GaussColors.Border, RoundedCornerShape(12.dp))
                        .clickableNoRipple {
                            nav.navigate(Routes.setup(subject = t.subject.raw, category = t.category))
                        }
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("تمرین ›", color = GaussColors.NeonBlue, fontSize = 12.sp)
                        Text(
                            "  ${toFa(Math.round(t.accuracy))}٪",
                            color = scoreColor(t.accuracy),
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                        )
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("(${t.subject.faLabel}) ", color = GaussColors.Muted, fontSize = 12.sp)
                        Text(
                            Categories.label(t.subject, t.category),
                            color = GaussColors.Text,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 14.sp,
                        )
                    }
                }
            }
        }

        if (state.recent.isNotEmpty()) {
            Spacer(Modifier.height(28.dp))
            Text(
                "آزمون‌های اخیر",
                color = GaussColors.Text,
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.End,
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(12.dp))
            state.recent.forEach { e ->
                Row(
                    Modifier
                        .padding(bottom = 8.dp)
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(GaussColors.Card)
                        .border(1.dp, GaussColors.Border, RoundedCornerShape(12.dp))
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            "${toFa(Math.round(e.scorePercentage))}٪",
                            color = scoreColor(e.scorePercentage),
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp,
                        )
                        Text(
                            "   ${toFa(e.correctCount)}/${toFa(e.totalQuestions)}",
                            color = GaussColors.Muted,
                            fontSize = 12.sp,
                        )
                    }
                    Text(faDate(e.createdAt), color = GaussColors.Muted, fontSize = 12.sp)
                }
            }
        }

        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun StatCard(label: String, value: String, color: Color, modifier: Modifier = Modifier) {
    Column(
        modifier
            .clip(RoundedCornerShape(18.dp))
            .background(GaussColors.Card)
            .border(1.dp, GaussColors.Border, RoundedCornerShape(18.dp))
            .padding(vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(value, color = color, fontSize = 24.sp, fontWeight = FontWeight.Black)
        Text(label, color = GaussColors.Muted, fontSize = 12.sp, modifier = Modifier.padding(top = 4.dp))
    }
}

@Composable
private fun BigButton(
    title: String,
    subtitle: String,
    glyph: String,
    color: Color,
    onClick: () -> Unit,
) {
    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(color.soft(0.06f))
            .border(1.dp, color, RoundedCornerShape(18.dp))
            .clickableNoRipple { onClick() }
            .padding(20.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(glyph, fontSize = 30.sp)
        Column(horizontalAlignment = Alignment.End) {
            Text(title, color = GaussColors.Text, fontSize = 20.sp, fontWeight = FontWeight.Bold)
            Text(subtitle, color = GaussColors.Muted, fontSize = 13.sp, modifier = Modifier.padding(top = 4.dp))
        }
    }
}

@Composable
private fun SmallButton(
    title: String,
    subtitle: String,
    glyph: String,
    color: Color,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    Row(
        modifier
            .clip(RoundedCornerShape(18.dp))
            .background(if (enabled) color.soft(0.06f) else GaussColors.Card)
            .border(1.dp, if (enabled) color else GaussColors.Border, RoundedCornerShape(18.dp))
            .clickableNoRipple(enabled) { onClick() }
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(glyph, fontSize = 22.sp)
        Column(horizontalAlignment = Alignment.End) {
            Text(
                title,
                color = if (enabled) GaussColors.Text else GaussColors.Muted,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
            )
            Text(subtitle, color = GaussColors.Muted, fontSize = 12.sp, modifier = Modifier.padding(top = 2.dp))
        }
    }
}

private fun scoreColor(p: Double): Color = when {
    p >= 70 -> GaussColors.NeonGreen
    p >= 40 -> GaussColors.NeonAmber
    else -> GaussColors.NeonRed
}

private fun faDate(epochMillis: Long): String {
    val d = java.time.Instant.ofEpochMilli(epochMillis)
        .atZone(java.time.ZoneId.systemDefault()).toLocalDate()
    return toFa("${d.year}/${d.monthValue}/${d.dayOfMonth}")
}
