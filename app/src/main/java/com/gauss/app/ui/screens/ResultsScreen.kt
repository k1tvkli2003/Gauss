package com.gauss.app.ui.screens

import androidx.compose.animation.core.animateIntAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Bolt
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.gauss.app.data.AttemptStatus
import com.gauss.app.data.KONKUR_SECONDS_PER_QUESTION
import com.gauss.app.data.RewardSummary
import com.gauss.app.ui.components.GaussButton
import com.gauss.app.ui.components.GaussCard
import com.gauss.app.ui.components.SolutionCard
import com.gauss.app.ui.components.clickableNoRipple
import com.gauss.app.ui.exam.ExamViewModel
import com.gauss.app.ui.nav.Routes
import com.gauss.app.ui.theme.GaussColors
import com.gauss.app.ui.theme.soft
import com.gauss.app.ui.toFa

@Composable
fun ResultsScreen(nav: NavController, vm: ExamViewModel) {
    val results = remember(vm.questions) { vm.results() }
    val scheme = MaterialTheme.colorScheme

    fun home() {
        vm.reset()
        nav.navigate(Routes.HOME) { popUpTo(Routes.HOME) { inclusive = true } }
    }

    if (results.isEmpty()) {
        Column(
            Modifier.fillMaxSize().background(scheme.background).systemBarsPadding(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text("نتیجه‌ای برای نمایش نیست.", color = scheme.onSurfaceVariant)
            Spacer(Modifier.height(16.dp))
            Box(
                Modifier.clip(RoundedCornerShape(10.dp)).background(scheme.surfaceVariant)
                    .clickableNoRipple { home() }.padding(horizontal = 20.dp, vertical = 12.dp),
            ) { Text("خانه", color = scheme.onSurface) }
        }
        return
    }

    val correct = results.count { it.status == AttemptStatus.CORRECT }
    val wrong = results.count { it.status == AttemptStatus.WRONG }
    val skipped = results.count { it.status == AttemptStatus.SKIPPED }
    val total = results.size
    val avg = if (total > 0) results.sumOf { it.timeTakenSeconds } / total else 0
    val score = if (total > 0) Math.round(correct.toDouble() / total * 100).toInt() else 0
    val scoreColor = when {
        score >= 70 -> GaussColors.Success
        score >= 40 -> GaussColors.Warning
        else -> scheme.error
    }

    var started by remember { mutableStateOf(false) }
    val shownScore by animateIntAsState(
        targetValue = if (started) score else 0,
        animationSpec = tween(durationMillis = 800),
        label = "score",
    )
    LaunchedEffect(Unit) { started = true }

    LazyColumn(
        Modifier
            .fillMaxSize()
            .background(scheme.background)
            .systemBarsPadding(),
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        item {
            Text(
                "کارنامه",
                color = scheme.onBackground,
                fontSize = 24.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.End,
                modifier = Modifier.fillMaxWidth(),
            )
            Text(
                if (avg > KONKUR_SECONDS_PER_QUESTION) "میانگین زمانت از استاندارد کنکور کندتر است؛ مرور فصل‌های ضعیف را شروع کن."
                else "میانگین زمانت در محدوده استاندارد کنکور است.",
                color = scheme.onSurfaceVariant,
                fontSize = 13.sp,
                textAlign = TextAlign.End,
                modifier = Modifier.fillMaxWidth().padding(top = 4.dp),
            )
        }

        item {
            Row(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(22.dp))
                    .background(scheme.surface)
                    .border(1.dp, scheme.outline, RoundedCornerShape(22.dp))
                    .padding(20.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                ScoreRing(shownScore, scoreColor)
                Column(Modifier.weight(1f).padding(start = 20.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    BreakdownRow("درست", toFa(correct), GaussColors.Success)
                    BreakdownRow("غلط", toFa(wrong), scheme.error)
                    BreakdownRow("نزده", toFa(skipped), GaussColors.Warning)
                    BreakdownRow("میانگین زمان", "${toFa(avg)}s", scheme.primary)
                }
            }
        }

        item { RewardCard(vm.rewardSummary) }
        if (vm.saveError != null) {
            item {
                SaveErrorCard(
                    message = vm.saveError.orEmpty(),
                    canRetry = vm.canRetrySave,
                    saving = vm.saving,
                    onRetry = { vm.finishAndSave {} },
                )
            }
        }

        item {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Box(
                    Modifier.weight(1f).clip(RoundedCornerShape(16.dp)).background(scheme.primary)
                        .clickableNoRipple {
                            vm.reset()
                            nav.navigate(Routes.setup()) { popUpTo(Routes.HOME) }
                        }
                        .padding(vertical = 13.dp),
                    contentAlignment = Alignment.Center,
                ) { Text("آزمون دوباره", color = scheme.onPrimary, fontWeight = FontWeight.Black) }
                Box(
                    Modifier.weight(1f).clip(RoundedCornerShape(16.dp)).background(scheme.surfaceVariant)
                        .clickableNoRipple { home() }.padding(vertical = 13.dp),
                    contentAlignment = Alignment.Center,
                ) { Text("خانه", color = scheme.onSurface, fontWeight = FontWeight.Black) }
            }
        }

        item {
            Text(
                "پاسخنامهٔ تشریحی",
                color = scheme.onBackground,
                fontSize = 18.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.End,
                modifier = Modifier.fillMaxWidth().padding(top = 4.dp),
            )
        }

        itemsIndexed(results, key = { _, r -> r.question.id }) { i, r ->
            SolutionCard(r, i + 1)
        }
    }
}

@Composable
private fun RewardCard(summary: RewardSummary?) {
    val scheme = MaterialTheme.colorScheme
    GaussCard(
        color = if ((summary?.xpEarned ?: 0) > 0) GaussColors.SecondaryContainer else scheme.surface,
        border = androidx.compose.foundation.BorderStroke(
            1.dp,
            if ((summary?.xpEarned ?: 0) > 0) GaussColors.Secondary.soft(0.55f) else scheme.outline,
        ),
    ) {
        Column(horizontalAlignment = Alignment.End) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Rounded.Bolt, contentDescription = null, tint = GaussColors.Secondary)
                Text("پاداش این تمرین", color = scheme.onSurface, fontWeight = FontWeight.Black)
            }
            Text(
                "+${toFa(summary?.xpEarned ?: 0)} XP",
                color = GaussColors.Secondary,
                fontSize = 30.sp,
                fontWeight = FontWeight.Black,
                modifier = Modifier.padding(top = 8.dp),
            )
            if (summary != null && summary.lines.isNotEmpty()) {
                summary.lines.take(4).forEach { line ->
                    BreakdownRow(line.reason, "+${toFa(line.amount)}", GaussColors.Secondary)
                }
                if (summary.levelAfter > summary.levelBefore) {
                    Text(
                        "سطح جدید: ${toFa(summary.levelAfter)}",
                        color = GaussColors.Success,
                        fontWeight = FontWeight.Black,
                        modifier = Modifier.padding(top = 6.dp),
                    )
                }
            } else {
                Text("اگر آزمون ذخیره نشده باشد، XP بعد از retry ثبت می‌شود.", color = scheme.onSurfaceVariant, textAlign = TextAlign.End)
            }
        }
    }
}

@Composable
private fun SaveErrorCard(message: String, canRetry: Boolean, saving: Boolean, onRetry: () -> Unit) {
    val scheme = MaterialTheme.colorScheme
    val isRewardError = message.contains("XP") || message.contains("پاداش")
    GaussCard(
        color = scheme.error.soft(0.10f),
        border = androidx.compose.foundation.BorderStroke(1.dp, scheme.error.soft(0.55f)),
    ) {
        Column(horizontalAlignment = Alignment.End) {
            Text(message, color = scheme.error, fontWeight = FontWeight.Bold, textAlign = TextAlign.End)
            if (canRetry) {
                Spacer(Modifier.height(10.dp))
                GaussButton(
                    text = when {
                        saving -> "در حال ثبت…"
                        isRewardError -> "تلاش دوباره برای ثبت XP"
                        else -> "تلاش دوباره برای ذخیره"
                    },
                    onClick = onRetry,
                    loading = saving,
                    containerColor = scheme.error,
                    contentColor = scheme.onError,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
    }
}

@Composable
private fun ScoreRing(score: Int, color: Color) {
    val scheme = MaterialTheme.colorScheme
    Box(Modifier.size(96.dp), contentAlignment = Alignment.Center) {
        Canvas(Modifier.size(96.dp)) {
            val stroke = 8.dp.toPx()
            val inset = stroke / 2
            drawArc(
                color = scheme.surfaceVariant,
                startAngle = 0f,
                sweepAngle = 360f,
                useCenter = false,
                topLeft = androidx.compose.ui.geometry.Offset(inset, inset),
                size = Size(size.width - stroke, size.height - stroke),
                style = Stroke(width = stroke, cap = StrokeCap.Round),
            )
            drawArc(
                color = color,
                startAngle = -90f,
                sweepAngle = 360f * (score / 100f),
                useCenter = false,
                topLeft = androidx.compose.ui.geometry.Offset(inset, inset),
                size = Size(size.width - stroke, size.height - stroke),
                style = Stroke(width = stroke, cap = StrokeCap.Round),
            )
        }
        Text("${toFa(score)}٪", color = color, fontSize = 26.sp, fontWeight = FontWeight.Black)
    }
}

@Composable
private fun BreakdownRow(label: String, value: String, color: Color) {
    val scheme = MaterialTheme.colorScheme
    Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(value, color = color, fontWeight = FontWeight.Bold, fontSize = 16.sp)
        Text(label, color = scheme.onSurfaceVariant, fontSize = 14.sp)
    }
}
