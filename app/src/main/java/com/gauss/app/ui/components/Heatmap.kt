package com.gauss.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gauss.app.ui.theme.GaussColors
import java.time.LocalDate

/** GitHub-style "Brain Heatmap" of daily activity for the last ~17 weeks. */
@Composable
fun Heatmap(data: Map<String, Int>, modifier: Modifier = Modifier) {
    val weeks = 17
    val days = remember(data) {
        val start = LocalDate.now().minusDays((weeks * 7 - 1).toLong())
        (0 until weeks * 7).map { i ->
            val d = start.plusDays(i.toLong())
            d.toString() to (data[d.toString()] ?: 0)
        }
    }
    val max = remember(days) { maxOf(1, days.maxOf { it.second }) }
    fun level(c: Int): Color = when {
        c == 0 -> GaussColors.Raised
        c.toFloat() / max > 0.66f -> GaussColors.NeonGreen
        c.toFloat() / max > 0.33f -> GaussColors.HeatMid
        else -> GaussColors.HeatLow
    }
    val columns = days.chunked(7)

    Column(modifier) {
        Row(Modifier.horizontalScroll(rememberScrollState())) {
            columns.forEach { col ->
                Column {
                    col.forEach { (_, count) ->
                        Box(
                            Modifier
                                .padding(1.5.dp)
                                .size(14.dp)
                                .clip(RoundedCornerShape(3.dp))
                                .background(level(count)),
                        )
                    }
                }
            }
        }
        Row(
            Modifier.padding(top = 8.dp),
            horizontalArrangement = Arrangement.End,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("کمتر ", color = GaussColors.Muted, fontSize = 11.sp)
            listOf(GaussColors.Raised, GaussColors.HeatLow, GaussColors.HeatMid, GaussColors.NeonGreen).forEach {
                Box(
                    Modifier
                        .padding(horizontal = 1.dp)
                        .size(12.dp)
                        .clip(RoundedCornerShape(3.dp))
                        .background(it),
                )
            }
            Text(" بیشتر", color = GaussColors.Muted, fontSize = 11.sp)
        }
    }
}
