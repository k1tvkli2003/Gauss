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
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
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
import com.gauss.app.data.Analytics
import com.gauss.app.data.Categories
import com.gauss.app.data.KONKUR_SECONDS_PER_QUESTION
import com.gauss.app.ui.components.Heatmap
import com.gauss.app.ui.components.clickableNoRipple
import com.gauss.app.ui.theme.GaussColors
import com.gauss.app.ui.theme.soft
import com.gauss.app.ui.toFa

private val OPTION_FA = listOf("", "۱", "۲", "۳", "۴")

@Composable
fun AnalyticsScreen(nav: NavController) {
    val app = LocalContext.current.applicationContext as GaussApp
    var data by remember { mutableStateOf<Analytics?>(null) }
    LaunchedEffect(Unit) { data = app.history.analytics() }

    Column(
        Modifier
            .fillMaxSize()
            .background(GaussColors.Bg)
            .systemBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
    ) {
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                Modifier.clip(RoundedCornerShape(10.dp)).background(GaussColors.Card)
                    .clickableNoRipple { nav.popBackStack() }.padding(horizontal = 16.dp, vertical = 8.dp),
            ) { Text("بازگشت ›", color = GaussColors.Text, fontSize = 14.sp) }
            Text("تحلیل عملکرد", color = GaussColors.Text, fontSize = 22.sp, fontWeight = FontWeight.Bold)
        }

        Spacer(Modifier.height(24.dp))

        val d = data
        if (d == null || d.totalAnswered == 0) {
            Box(Modifier.fillMaxWidth().padding(top = 80.dp), contentAlignment = Alignment.Center) {
                Text("هنوز داده‌ای ثبت نشده. یه آزمون بزن!", color = GaussColors.Muted)
            }
            return@Column
        }

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Kpi("کل پاسخ‌ها", toFa(d.totalAnswered), GaussColors.NeonBlue, Modifier.weight(1f))
            Kpi("دقت کلی", "${toFa(Math.round(d.accuracy))}٪", GaussColors.NeonGreen, Modifier.weight(1f))
            Kpi(
                "میانگین زمان",
                "${toFa(Math.round(d.avgTime))}s",
                if (d.avgTime > KONKUR_SECONDS_PER_QUESTION) GaussColors.NeonAmber else GaussColors.NeonGreen,
                Modifier.weight(1f),
            )
        }

        Spacer(Modifier.height(20.dp))

        Card("نقشهٔ حرارتی مغز") { Heatmap(d.heatmap) }

        Card("نقاط ضعف (به ترتیب اولویت تمرین)") {
            d.weakTopics.forEach { t ->
                Column(Modifier.padding(bottom = 12.dp)) {
                    Row(
                        Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            "${toFa(Math.round(t.accuracy))}٪ · ${toFa(t.correct)}/${toFa(t.total)}",
                            color = barColor(t.accuracy),
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                        )
                        Text(Categories.label(t.subject, t.category), color = GaussColors.Text, fontSize = 14.sp)
                    }
                    Box(
                        Modifier
                            .padding(top = 6.dp)
                            .fillMaxWidth()
                            .height(8.dp)
                            .clip(RoundedCornerShape(4.dp))
                            .background(GaussColors.Raised),
                    ) {
                        Box(
                            Modifier
                                .fillMaxWidth(fraction = (maxOf(4.0, t.accuracy) / 100).toFloat())
                                .height(8.dp)
                                .clip(RoundedCornerShape(4.dp))
                                .background(barColor(t.accuracy)),
                        )
                    }
                }
            }
        }

        if (d.distractors.isNotEmpty()) {
            Card("تله‌های پرتکرار (گزینهٔ غلطی که زیاد می‌زنی)") {
                d.distractors.forEach { dd ->
                    Row(
                        Modifier
                            .padding(bottom = 8.dp)
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(GaussColors.Bg)
                            .border(1.dp, GaussColors.Border, RoundedCornerShape(12.dp))
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("${toFa(dd.count)} بار", color = GaussColors.Muted, fontSize = 12.sp)
                            Spacer(Modifier.size(10.dp))
                            Box(
                                Modifier.size(28.dp).clip(CircleShape).background(GaussColors.NeonRed.soft())
                                    .border(1.dp, GaussColors.NeonRed, CircleShape),
                                contentAlignment = Alignment.Center,
                            ) {
                                Text(OPTION_FA[dd.option], color = GaussColors.NeonRed, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                            }
                        }
                        Text(Categories.label(dd.subject, dd.category), color = GaussColors.Text, fontSize = 14.sp)
                    }
                }
            }
        }

        Spacer(Modifier.height(20.dp))
    }
}

@Composable
private fun Kpi(label: String, value: String, color: Color, modifier: Modifier = Modifier) {
    Column(
        modifier
            .clip(RoundedCornerShape(16.dp))
            .background(GaussColors.Card)
            .border(1.dp, GaussColors.Border, RoundedCornerShape(16.dp))
            .padding(vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(value, color = color, fontSize = 22.sp, fontWeight = FontWeight.Black)
        Text(label, color = GaussColors.Muted, fontSize = 11.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(top = 4.dp))
    }
}

@Composable
private fun Card(title: String, content: @Composable () -> Unit) {
    Column(
        Modifier
            .padding(bottom = 20.dp)
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(GaussColors.Surface)
            .border(1.dp, GaussColors.Border, RoundedCornerShape(16.dp))
            .padding(16.dp),
    ) {
        Text(
            title,
            color = GaussColors.Muted,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.End,
            modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp),
        )
        content()
    }
}

private fun barColor(acc: Double): Color = when {
    acc >= 70 -> GaussColors.NeonGreen
    acc >= 40 -> GaussColors.NeonAmber
    else -> GaussColors.NeonRed
}
