package com.gauss.app.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
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

/** A committed scratchpad stroke. Owned by the exam engine so it survives navigation. */
data class Stroke(val points: List<Offset>, val color: Color, val width: Float)

/**
 * Stylus-friendly scratchpad: multi-colour pen, width presets, undo/redo, clear.
 * Strokes are hoisted to the caller so they persist when navigating questions.
 */
@Composable
fun DrawingCanvas(
    strokes: List<Stroke>,
    onChange: (List<Stroke>) -> Unit,
    modifier: Modifier = Modifier,
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

    Column(
        modifier = modifier
            .border(1.dp, scheme.outline, RoundedCornerShape(16.dp))
            .background(scheme.surface, RoundedCornerShape(16.dp)),
    ) {
        // Toolbar
        Row(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 10.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                penColors.forEach { c ->
                    Box(
                        Modifier
                            .size(22.dp)
                            .background(c, CircleShape)
                            .border(
                                if (penColor == c) 2.dp else 0.dp,
                                scheme.onSurface,
                                CircleShape,
                            )
                            .clickableNoRipple { penColor = c },
                    )
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                listOf(2f, 3f, 5f, 8f).forEach { w ->
                    ToolChip("${w.toInt()}", active = penWidth == w) { penWidth = w }
                }
            }
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
                    redo.clear(); onChange(emptyList())
                }
            }
        }

        // Drawing surface
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
            .background(
                if (active) scheme.primaryContainer else scheme.surfaceVariant,
                RoundedCornerShape(8.dp),
            )
            .clickableNoRipple(enabled, onClick)
            .padding(horizontal = 10.dp, vertical = 6.dp),
    ) {
        Text(
            label,
            color = if (enabled) scheme.onSurface else scheme.onSurfaceVariant,
        )
    }
}
