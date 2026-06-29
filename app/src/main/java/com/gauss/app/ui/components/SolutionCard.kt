package com.gauss.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gauss.app.data.AttemptResult
import com.gauss.app.data.AttemptStatus
import com.gauss.app.data.ComprehensiveTaxonomy
import com.gauss.app.data.KONKUR_SECONDS_PER_QUESTION
import com.gauss.app.ui.theme.GaussColors
import com.gauss.app.ui.theme.soft
import com.gauss.app.ui.toFa

private data class StatusMeta(val label: String, val color: Color, val glyph: String)

private fun metaFor(status: AttemptStatus) = when (status) {
    AttemptStatus.CORRECT -> StatusMeta("درست", GaussColors.Success, "✓")
    AttemptStatus.WRONG -> StatusMeta("غلط", GaussColors.Error, "✕")
    AttemptStatus.SKIPPED -> StatusMeta("نزده", GaussColors.Warning, "–")
}

/** One reviewed question: verdict, options revealed, classic solution + shortcut. */
@Composable
fun SolutionCard(result: AttemptResult, number: Int, modifier: Modifier = Modifier) {
    val q = result.question
    val meta = metaFor(result.status)
    val overTime = result.timeTakenSeconds > KONKUR_SECONDS_PER_QUESTION
    val scheme = MaterialTheme.colorScheme

    Column(
        modifier
            .padding(bottom = 16.dp)
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(scheme.surface)
            .border(1.dp, scheme.outline, RoundedCornerShape(16.dp))
            .padding(16.dp),
    ) {
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                DifficultyBadge(q.difficulty)
                Text(
                    "  سؤال ${toFa(number)}",
                    color = scheme.onSurfaceVariant,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                )
            }
            Box(
                Modifier
                    .clip(CircleShape)
                    .background(meta.color.soft())
                    .border(1.dp, meta.color, CircleShape)
                    .padding(horizontal = 12.dp, vertical = 5.dp),
            ) {
                Text("${meta.glyph} ${meta.label}", color = meta.color, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            }
        }

        Text(
            ComprehensiveTaxonomy.label(q.topicKey),
            color = scheme.onSurfaceVariant,
            fontSize = 12.sp,
            modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
        )

        Row(Modifier.padding(top = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(
                "زمان: ${toFa(result.timeTakenSeconds)}s",
                color = if (overTime) GaussColors.Warning else GaussColors.Success,
                fontSize = 12.sp,
            )
            Text(
                "  (استاندارد: ${toFa(KONKUR_SECONDS_PER_QUESTION)}s)" +
                    if (overTime) " — کندتر از حد مجاز" else " — در زمان مجاز",
                color = scheme.onSurfaceVariant,
                fontSize = 12.sp,
            )
        }

        Box(
            Modifier
                .padding(top = 12.dp)
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(scheme.surfaceVariant)
                .border(1.dp, scheme.outline, RoundedCornerShape(12.dp))
                .padding(12.dp),
        ) {
            RichContent(q.stem, fontSize = 16.sp)
        }

        Column(Modifier.padding(top = 12.dp)) {
            q.options.forEachIndexed { i, opt ->
                OptionButton(
                    index = i + 1,
                    text = opt,
                    blocks = q.optionBlocks[i],
                    selected = result.selectedOption == i + 1,
                    reveal = true,
                    correct = q.correctOptionIndex == i + 1,
                )
            }
        }

        GeniusKey(q.solution, q.shortcut, Modifier.padding(top = 4.dp))
    }
}
