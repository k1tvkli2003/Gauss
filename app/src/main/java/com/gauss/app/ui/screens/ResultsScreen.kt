package com.gauss.app.ui.screens

import androidx.compose.animation.core.animateIntAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import com.gauss.app.ui.components.SolutionCard
import com.gauss.app.ui.components.clickableNoRipple
import com.gauss.app.ui.exam.ExamViewModel
import com.gauss.app.ui.nav.Routes
import com.gauss.app.ui.theme.GaussColors
import com.gauss.app.ui.toFa

@Composable
fun ResultsScreen(nav: NavController, vm: ExamViewModel) {
    val results = remember(vm.questions) { vm.results() }

    fun home() {
        vm.reset()
        nav.navigate(Routes.HOME) { popUpTo(Routes.HOME) { inclusive = true } }
    }

    if (results.isEmpty()) {
        Column(
            Modifier.fillMaxSize().background(GaussColors.Bg).systemBarsPadding(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text("نتیجه‌ای برای نمایش نیست.", color = GaussColors.Muted)
            Spacer(Modifier.height(16.dp))
            Box(
                Modifier.clip(RoundedCornerShape(10.dp)).background(GaussColors.Card)
                    .clickableNoRipple { home() }.padding(horizontal = 20.dp, vertical = 12.dp),
            ) { Text("خانه", color = GaussColors.Text) }
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
        score >= 70 -> GaussColors.NeonGreen
        score >= 40 -> GaussColors.NeonAmber
        else -> GaussColors.NeonRed
    }

    var started by remember { mutableStateOf(false) }
    val shownScore by animateIntAsState(
        targetValue = if (started) score else 0,
        animationSpec = tween(durationMillis = 800),
        label = "score",
    )
    LaunchedEffect(Unit) { started = true }

    Column(
        Modifier
            .fillMaxSize()
            .background(GaussColors.Bg)
            .systemBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
    ) {
        Text(
            "کارنامه",
            color = GaussColors.Text,
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.End,
            modifier = Modifier.fillMaxWidth(),
        )
        Text(
            if (avg > KONKUR_SECONDS_PER_QUESTION) "سرعتت رو ببر بالا رفیق — از زمان کنکور عقبی."
            else "ایول، سرعتت توی استاندارد کنکوره. 🔥",
            color = GaussColors.Muted,
            fontSize = 13.sp,
            textAlign = TextAlign.End,
            modifier = Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 20.dp),
        )

        // Score ring + breakdown
        Row(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(GaussColors.Surface)
                .border(1.dp, GaussColors.Border, RoundedCornerShape(16.dp))
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            ScoreRing(shownScore, scoreColor)
            Column(Modifier.weight(1f).padding(start = 20.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                BreakdownRow("درست", toFa(correct), GaussColors.NeonGreen)
                BreakdownRow("غلط", toFa(wrong), GaussColors.NeonRed)
                BreakdownRow("نزده", toFa(skipped), GaussColors.NeonAmber)
                BreakdownRow("میانگین زمان", "${toFa(avg)}s", GaussColors.NeonBlue)
            }
        }

        Spacer(Modifier.height(16.dp))

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Box(
                Modifier.weight(1f).clip(RoundedCornerShape(12.dp)).background(GaussColors.NeonBlue)
                    .clickableNoRipple {
                        vm.reset()
                        nav.navigate(Routes.setup()) { popUpTo(Routes.HOME) }
                    }
                    .padding(vertical = 12.dp),
                contentAlignment = Alignment.Center,
            ) { Text("آزمون دوباره", color = GaussColors.Bg, fontWeight = FontWeight.Bold) }
            Box(
                Modifier.weight(1f).clip(RoundedCornerShape(12.dp)).background(GaussColors.Card)
                    .clickableNoRipple { home() }.padding(vertical = 12.dp),
                contentAlignment = Alignment.Center,
            ) { Text("خانه", color = GaussColors.Text, fontWeight = FontWeight.Bold) }
        }

        Spacer(Modifier.height(20.dp))
        Text(
            "پاسخنامهٔ تشریحی",
            color = GaussColors.Text,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.End,
            modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp),
        )
        results.forEachIndexed { i, r -> SolutionCard(r, i + 1) }
    }
}

@Composable
private fun ScoreRing(score: Int, color: Color) {
    Box(Modifier.size(96.dp), contentAlignment = Alignment.Center) {
        Canvas(Modifier.size(96.dp)) {
            val stroke = 8.dp.toPx()
            val inset = stroke / 2
            drawArc(
                color = GaussColors.Raised,
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
    Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(value, color = color, fontWeight = FontWeight.Bold, fontSize = 16.sp)
        Text(label, color = GaussColors.Muted, fontSize = 14.sp)
    }
}
