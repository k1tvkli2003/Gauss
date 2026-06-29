package com.gauss.app.ui.screens

import androidx.compose.foundation.BorderStroke
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
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Analytics
import androidx.compose.material.icons.rounded.Bolt
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.School
import androidx.compose.material.icons.rounded.Whatshot
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.gauss.app.GaussApp
import com.gauss.app.data.ComprehensiveTaxonomy
import com.gauss.app.data.DailyQuest
import com.gauss.app.data.GamificationSummary
import com.gauss.app.data.RecentExam
import com.gauss.app.data.TopicStat
import com.gauss.app.ui.components.GaussButton
import com.gauss.app.ui.components.GaussCard
import com.gauss.app.ui.components.PressableSurface
import com.gauss.app.ui.components.StatPill
import com.gauss.app.ui.nav.Routes
import com.gauss.app.ui.theme.GaussColors
import com.gauss.app.ui.theme.soft
import com.gauss.app.ui.toFa
import java.time.Instant
import java.time.ZoneId

private data class HomeState(
    val answered: Int = 0,
    val accuracy: Int = 0,
    val streak: Int = 0,
    val revenge: Int = 0,
    val recent: List<RecentExam> = emptyList(),
    val weak: List<TopicStat> = emptyList(),
    val game: GamificationSummary? = null,
)

@Composable
fun HomeScreen(nav: NavController) {
    val app = androidx.compose.ui.platform.LocalContext.current.applicationContext as GaussApp
    var state by remember { mutableStateOf(HomeState()) }

    LaunchedEffect(Unit) {
        val analytics = app.history.analytics()
        val game = app.gamification.summary()
        state = HomeState(
            answered = analytics.totalAnswered,
            accuracy = Math.round(analytics.accuracy).toInt(),
            streak = maxOf(analytics.streak, game.streak),
            revenge = app.history.revengeIds().size,
            recent = app.history.recentExams(4),
            weak = analytics.weakTopics.filter { it.total >= 3 }.take(3),
            game = game,
        )
    }

    Column(
        Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .systemBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Header(state)
        HeroCard(nav, state)
        DailyQuestCard(state.game?.quest)
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            StatPill("پاسخ‌ها", toFa(state.answered), MaterialTheme.colorScheme.primary, Modifier.weight(1f))
            StatPill("دقت", "${toFa(state.accuracy)}٪", GaussColors.Success, Modifier.weight(1f))
            StatPill("امروز", toFa(state.game?.todayXp ?: 0) + " XP", GaussColors.Secondary, Modifier.weight(1f))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            ActionCard(
                title = "حالت انتقام",
                subtitle = "${toFa(state.revenge)} سؤال برای برگشت",
                icon = Icons.Rounded.Refresh,
                color = GaussColors.Error,
                enabled = state.revenge > 0,
                modifier = Modifier.weight(1f),
            ) { nav.navigate(Routes.REVENGE) }
            ActionCard(
                title = "تحلیل",
                subtitle = "نقشه ضعف و دام‌ها",
                icon = Icons.Rounded.Analytics,
                color = GaussColors.Math,
                modifier = Modifier.weight(1f),
            ) { nav.navigate(Routes.ANALYTICS) }
        }

        if (state.weak.isNotEmpty()) {
            SectionTitle("مسیر پیشنهادی امروز")
            state.weak.forEach { topic ->
                WeakTopicRow(topic) {
                    nav.navigate(Routes.setup(subject = topic.subject.raw, topic = topic.chapter))
                }
            }
        }

        if (state.recent.isNotEmpty()) {
            SectionTitle("آخرین کارنامه‌ها")
            state.recent.forEach { exam -> RecentRow(exam) }
        }

        Spacer(Modifier.height(8.dp))
    }
}

@Composable
private fun Header(state: HomeState) {
    Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            HeaderBadge(Icons.Rounded.Whatshot, "${toFa(state.streak)} روز", GaussColors.Warning)
            HeaderBadge(Icons.Rounded.Bolt, "LV ${toFa(state.game?.level ?: 1)}", MaterialTheme.colorScheme.primary)
        }
        Column(horizontalAlignment = Alignment.End) {
            Text("Gauss", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)
            Text("تمرین شخصی، تیز و بازی‌وار", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun HeaderBadge(icon: ImageVector, label: String, color: Color) {
    Surface(shape = CircleShape, color = color.soft(0.13f), border = BorderStroke(1.dp, color.soft(0.55f))) {
        Row(
            Modifier.padding(horizontal = 11.dp, vertical = 7.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(5.dp),
        ) {
            Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(17.dp))
            Text(label, color = color, fontWeight = FontWeight.Black)
        }
    }
}

@Composable
private fun HeroCard(nav: NavController, state: HomeState) {
    val game = state.game
    GaussCard(
        color = MaterialTheme.colorScheme.primaryContainer,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.soft(0.45f)),
    ) {
        Column(horizontalAlignment = Alignment.End) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Column(Modifier.weight(1f), horizontalAlignment = Alignment.End) {
                    Text(
                        "مسیر امروز آماده‌ست",
                        color = MaterialTheme.colorScheme.onSurface,
                        style = MaterialTheme.typography.titleLarge,
                        textAlign = TextAlign.End,
                    )
                    Text(
                        if (state.weak.isEmpty()) "یک آزمون سریع بزن تا Gauss مسیر بعدی را بسازد."
                        else "از ضعیف‌ترین مبحث شروع کن و XP بگیر.",
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.End,
                        modifier = Modifier.padding(top = 4.dp),
                    )
                }
                Box(Modifier.size(58.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primary), contentAlignment = Alignment.Center) {
                    Icon(Icons.Rounded.EmojiEvents, contentDescription = null, tint = MaterialTheme.colorScheme.onPrimary, modifier = Modifier.size(30.dp))
                }
            }
            Spacer(Modifier.height(16.dp))
            XpProgress(game?.levelProgress ?: 0f, game?.totalXp ?: 0)
            Spacer(Modifier.height(16.dp))
            GaussButton(
                text = "شروع تمرین",
                icon = Icons.Rounded.PlayArrow,
                onClick = { nav.navigate(Routes.setup()) },
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}

@Composable
private fun XpProgress(progress: Float, totalXp: Int) {
    Column {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text("${toFa(totalXp)} XP", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Black)
            Text("پیشرفت سطح", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Box(
            Modifier
                .padding(top = 7.dp)
                .fillMaxWidth()
                .height(12.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.8f)),
        ) {
            Box(
                Modifier
                    .fillMaxWidth(progress.coerceIn(0.04f, 1f))
                    .height(12.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary),
            )
        }
    }
}

@Composable
private fun DailyQuestCard(quest: DailyQuest?) {
    val q = quest ?: DailyQuest("۱۰ سؤال مفید حل کن", 0, 10, 40, false)
    PressableSurface(onClick = {}, enabled = false, color = MaterialTheme.colorScheme.surface) {
        Column(Modifier.padding(16.dp), horizontalAlignment = Alignment.End) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text("+${toFa(q.rewardXp)} XP", color = GaussColors.Secondary, fontWeight = FontWeight.Black)
                Text("ماموریت امروز", color = MaterialTheme.colorScheme.onSurfaceVariant, fontWeight = FontWeight.Bold)
            }
            Text(q.title, style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(top = 6.dp))
            Box(
                Modifier
                    .padding(top = 10.dp)
                    .fillMaxWidth()
                    .height(10.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.surfaceVariant),
            ) {
                Box(
                    Modifier
                        .fillMaxWidth((q.progress.toFloat() / q.target.toFloat()).coerceIn(0f, 1f))
                        .height(10.dp)
                        .clip(CircleShape)
                        .background(if (q.completed) GaussColors.Success else GaussColors.Secondary),
                )
            }
            Text("${toFa(q.progress)}/${toFa(q.target)}", color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 5.dp))
        }
    }
}

@Composable
private fun ActionCard(
    title: String,
    subtitle: String,
    icon: ImageVector,
    color: Color,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    PressableSurface(onClick = onClick, enabled = enabled, modifier = modifier, color = MaterialTheme.colorScheme.surface) {
        Column(Modifier.padding(16.dp), horizontalAlignment = Alignment.End) {
            Box(Modifier.size(38.dp).clip(CircleShape).background(color.soft(0.14f)), contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = if (enabled) color else MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Text(title, fontWeight = FontWeight.Black, modifier = Modifier.padding(top = 10.dp))
            Text(subtitle, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.labelMedium, textAlign = TextAlign.End)
        }
    }
}

@Composable
private fun SectionTitle(title: String) {
    Text(
        title,
        style = MaterialTheme.typography.titleMedium,
        fontWeight = FontWeight.Black,
        modifier = Modifier.fillMaxWidth().padding(top = 6.dp),
        textAlign = TextAlign.Start,
    )
}

@Composable
private fun WeakTopicRow(topic: TopicStat, onClick: () -> Unit) {
    val label = ComprehensiveTaxonomy.label(topic.chapter)
    PressableSurface(onClick = onClick, modifier = Modifier.fillMaxWidth()) {
        Row(
            Modifier.padding(14.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("${toFa(Math.round(topic.accuracy))}٪", color = scoreColor(topic.accuracy), fontWeight = FontWeight.Black)
            Column(horizontalAlignment = Alignment.End, modifier = Modifier.weight(1f).padding(horizontal = 12.dp)) {
                Text(label, fontWeight = FontWeight.Black, textAlign = TextAlign.End)
                Text("${toFa(topic.correct)}/${toFa(topic.total)} درست", color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.labelMedium)
            }
            Icon(Icons.Rounded.School, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
        }
    }
}

@Composable
private fun RecentRow(exam: RecentExam) {
    Surface(shape = RoundedCornerShape(16.dp), color = MaterialTheme.colorScheme.surface, border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline)) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("${toFa(Math.round(exam.scorePercentage))}٪", color = scoreColor(exam.scorePercentage), fontWeight = FontWeight.Black)
            Text("${toFa(exam.correctCount)}/${toFa(exam.totalQuestions)}", color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(faDate(exam.createdAt), color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

private fun scoreColor(p: Double): Color = when {
    p >= 70 -> GaussColors.Success
    p >= 40 -> GaussColors.Warning
    else -> GaussColors.Error
}

private fun faDate(epochMillis: Long): String {
    val date = Instant.ofEpochMilli(epochMillis)
        .atZone(ZoneId.systemDefault())
        .toLocalDate()
    return toFa("${date.year}/${date.monthValue}/${date.dayOfMonth}")
}
