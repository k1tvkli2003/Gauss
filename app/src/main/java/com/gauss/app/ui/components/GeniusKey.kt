package com.gauss.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.unit.TextUnit
import com.gauss.app.ui.theme.soft
import com.gauss.app.data.ContentBlock

/**
 * The "Genius key": the classic worked solution and the ⚡ smart shortcut as
 * switchable tabs. Shared by the in-session reveal and the results review.
 */
@Composable
fun GeniusKey(
    classic: String,
    shortcut: String?,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = 15.sp,
) {
    var showShortcut by remember { mutableStateOf(false) }
    val active = showShortcut && shortcut != null
    val scheme = MaterialTheme.colorScheme

    Column(modifier) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Tab("حل تشریحی", !active, scheme.primary, Modifier.weight(1f)) { showShortcut = false }
            if (shortcut != null) {
                Tab("راه تستی", active, scheme.secondary, Modifier.weight(1f)) { showShortcut = true }
            }
        }
        Box(
            Modifier
                .padding(top = 12.dp)
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(scheme.surfaceVariant)
                .border(
                    1.dp,
                    if (active) scheme.secondary else scheme.primary,
                    RoundedCornerShape(12.dp),
                )
                .padding(16.dp),
        ) {
            MathText(if (active) shortcut!! else classic, fontSize = fontSize)
        }
    }
}

@Composable
fun GeniusKey(
    classic: List<ContentBlock>,
    shortcut: List<ContentBlock>?,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = 15.sp,
) {
    var showShortcut by remember { mutableStateOf(false) }
    val active = showShortcut && shortcut != null
    val scheme = MaterialTheme.colorScheme
    Column(modifier) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Tab("حل تشریحی", !active, scheme.primary, Modifier.weight(1f)) { showShortcut = false }
            if (shortcut != null) {
                Tab("راه تستی", active, scheme.secondary, Modifier.weight(1f)) { showShortcut = true }
            }
        }
        Box(
            Modifier.padding(top = 12.dp).fillMaxWidth().clip(RoundedCornerShape(12.dp))
                .background(scheme.surfaceVariant)
                .border(1.dp, if (active) scheme.secondary else scheme.primary, RoundedCornerShape(12.dp))
                .padding(16.dp),
        ) {
            RichContent(if (active) shortcut!! else classic, fontSize = fontSize)
        }
    }
}

@Composable
private fun Tab(
    label: String,
    active: Boolean,
    color: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    Box(
        modifier
            .clip(RoundedCornerShape(10.dp))
            .background(if (active) color.soft(0.12f) else MaterialTheme.colorScheme.surface)
            .border(1.dp, if (active) color else MaterialTheme.colorScheme.outline, RoundedCornerShape(10.dp))
            .clickableNoRipple { onClick() }
            .padding(vertical = 9.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            label,
            color = if (active) color else MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.SemiBold,
            fontSize = 14.sp,
        )
    }
}
