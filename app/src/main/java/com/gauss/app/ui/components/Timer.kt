package com.gauss.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gauss.app.data.KONKUR_SECONDS_PER_QUESTION
import com.gauss.app.ui.toFa
import com.gauss.app.ui.theme.GaussColors
import kotlinx.coroutines.delay

/** Per-question stopwatch. Amber past the 70s Konkur budget, red at 2×. */
@Composable
fun Timer(resetKey: Any, modifier: Modifier = Modifier) {
    var seconds by remember { mutableIntStateOf(0) }
    LaunchedEffect(resetKey) {
        seconds = 0
        while (true) {
            delay(1000)
            seconds += 1
        }
    }

    val color = when {
        seconds > KONKUR_SECONDS_PER_QUESTION * 2 -> MaterialTheme.colorScheme.error
        seconds > KONKUR_SECONDS_PER_QUESTION -> GaussColors.Warning
        else -> GaussColors.Success
    }
    val mm = (seconds / 60).toString().padStart(2, '0')
    val ss = (seconds % 60).toString().padStart(2, '0')

    Row(
        modifier
            .clip(RoundedCornerShape(10.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(horizontal = 12.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(7.dp).clip(CircleShape).background(color))
        Text(
            "  ${toFa("$mm:$ss")}",
            color = color,
            fontWeight = FontWeight.SemiBold,
            fontSize = 14.sp,
        )
        Text("  / ${toFa(KONKUR_SECONDS_PER_QUESTION)}s", color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
    }
}
