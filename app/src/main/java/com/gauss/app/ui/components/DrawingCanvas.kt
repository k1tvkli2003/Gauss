package com.gauss.app.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke as DrawStroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import com.gauss.app.ui.theme.GaussColors
import com.gauss.app.ui.theme.soft

/** A committed scratch stroke. The session screen owns its lifetime per visible question. */
data class Stroke(val points: List<Offset>, val color: Color, val width: Float)

/**
 * Stylus-friendly transparent scratch layer: multi-colour pen, width presets, undo/redo, clear.
 * Strokes are hoisted to the caller so the parent can clear them when the question changes.
 */
@Composable
fun DrawingCanvas(
    strokes: List<Stroke>,
    onChange: (List<Stroke>) -> Unit,
    modifier: Modifier = Modifier,
    onClose: (() -> Unit)? = null,
    clearKey: Any? = Unit,
) {
    var penColor by remember { mutableStateOf<Color>(GaussColors.Primary) }
    var penWidth by remember { mutableStateOf(3f) }
    val redo = remember { mutableStateListOf<Stroke>() }
    val live = remember { mutableStateListOf<Offset>() }
    val scheme = MaterialTheme.colorScheme
    val penColors = listOf(
        scheme.primary,
        scheme.secondary,
        GaussColors.Success,
        GaussColors.Warning,
        scheme.error,
        scheme.onSurface,
    )

    androidx.compose.runtime.LaunchedEffect(clearKey) {
        redo.clear()
        live.clear()
    }

    Box(
        modifier = modifier
            .background(scheme.background.copy(alpha = 0.08f)),
    ) {
        Box(
            Modifier
                .fillMaxSize()
                .pointerInput(penColor, penWidth, strokes) {
                    detectDragGestures(
                        onDragStart = { offset -> live.clear(); live.add(offset) },
                        onDrag = { change, _ -> live.add(change.position) },
                        onDragEnd = {
                            if (live.size > 1) {
                                onChange(strokes + Stroke(live.toList(), penColor, penWidth))
                                redo.clear()
                            }
                            live.clear()
                        },
                        onDragCancel = { live.clear() },
                    )
                },
        ) {
            Canvas(Modifier.fillMaxSize()) {
                (strokes + listOfNotNull(
                    if (live.size > 1) Stroke(live.toList(), penColor, penWidth) else null,
                )).forEach { s ->
                    if (s.points.size < 2) return@forEach
                    val path = Path().apply {
                        moveTo(s.points.first().x, s.points.first().y)
                        for (i in 1 until s.points.size) lineTo(s.points[i].x, s.points[i].y)
                    }
                    drawPath(
                        path = path,
                        color = s.color,
                        style = DrawStroke(width = s.width, cap = StrokeCap.Round, join = StrokeJoin.Round),
                    )
                }
            }
        }

        Column(
            Modifier
                .align(Alignment.TopCenter)
                .padding(12.dp)
                .fillMaxWidth()
                .background(scheme.surface.copy(alpha = 0.96f), RoundedCornerShape(18.dp))
                .border(1.dp, scheme.primary.soft(0.34f), RoundedCornerShape(18.dp))
                .padding(10.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    ToolChip("↶", enabled = strokes.isNotEmpty()) {
                        if (strokes.isNotEmpty()) {
                            redo.add(strokes.last())
                            onChange(strokes.dropLast(1))
                        }
                    }
                    ToolChip("↷", enabled = redo.isNotEmpty()) {
                        if (redo.isNotEmpty()) {
                            val last = redo.removeAt(redo.lastIndex)
                            onChange(strokes + last)
                        }
                    }
                    ToolChip("پاک", enabled = strokes.isNotEmpty()) {
                        redo.clear()
                        onChange(emptyList())
                    }
                }
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("چرک‌نویس روی سؤال", color = scheme.onSurface, style = MaterialTheme.typography.labelLarge)
                    onClose?.let { close ->
                        ToolChip("بستن") { close() }
                    }
                }
            }
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                    penColors.forEach { c ->
                        Box(
                            Modifier
                                .size(26.dp)
                                .background(c, CircleShape)
                                .border(
                                    if (penColor == c) 3.dp else 1.dp,
                                    if (penColor == c) scheme.onSurface else scheme.outline,
                                    CircleShape,
                                )
                                .clickableNoRipple { penColor = c },
                        )
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    listOf(2f, 4f, 6f, 9f).forEach { w ->
                        ToolChip("${w.toInt()}", active = penWidth == w) { penWidth = w }
                    }
                }
            }
        }
    }
}

@Composable
private fun ToolChip(
    label: String,
    active: Boolean = false,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    Box(
        Modifier
            .defaultMinSize(minWidth = 40.dp, minHeight = 36.dp)
            .background(
                if (active) scheme.primaryContainer else scheme.surfaceVariant,
                RoundedCornerShape(12.dp),
            )
            .border(1.dp, if (active) scheme.primary else scheme.outline, RoundedCornerShape(12.dp))
            .clickableNoRipple(enabled, onClick)
            .padding(horizontal = 10.dp, vertical = 7.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            label,
            color = if (enabled) scheme.onSurface else scheme.onSurfaceVariant,
            style = MaterialTheme.typography.labelMedium,
        )
    }
}
