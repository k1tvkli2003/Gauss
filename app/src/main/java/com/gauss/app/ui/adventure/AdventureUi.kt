package com.gauss.app.ui.adventure

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.LocalIndication
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AutoAwesome
import androidx.compose.material.icons.rounded.Bolt
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Map
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material.icons.rounded.Redeem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gauss.app.R
import com.gauss.app.data.Subject
import androidx.compose.material.icons.automirrored.rounded.Assignment

object AdventureColors {
    val Night = Color(0xFF061C24)
    val Deep = Color(0xFF082B35)
    val Reef = Color(0xFF064E56)
    val Panel = Color(0xFF0A3643)
    val PanelDark = Color(0xFF08242F)
    val PanelLight = Color(0xFF0E4B58)
    val Border = Color(0xFF9E846E)
    val BorderSoft = Color(0x669E846E)
    val Text = Color(0xFFF6F3EA)
    val Muted = Color(0xFFB8C8C8)
    val Gold = Color(0xFFFFB422)
    val GoldBright = Color(0xFFFFD75E)
    val AmberDark = Color(0xFFB86D0A)
    val Mint = Color(0xFF78DD92)
    val MintDark = Color(0xFF1B8D48)
    val Coral = Color(0xFFFF6D76)
    val CoralDark = Color(0xFFB73D4B)
    val Lavender = Color(0xFFAC74F1)
    val Physics = Color(0xFF4DB7F7)
    val Math = Color(0xFF8B67F4)
    val Cream = Color(0xFFF9F2E6)
    val Ink = Color(0xFF172127)
}

enum class AdventureTab(val label: String, val icon: ImageVector) {
    MAP("Map", Icons.Rounded.Map),
    MISSIONS("Missions", Icons.AutoMirrored.Rounded.Assignment),
    REWARDS("Rewards", Icons.Rounded.Redeem),
    PROFILE("Profile", Icons.Rounded.Person),
}

fun Modifier.adventurePress(enabled: Boolean = true, onClick: () -> Unit): Modifier = composed {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed && enabled) 0.965f else 1f, label = "adventurePress")
    graphicsLayer(scaleX = scale, scaleY = scale)
        .clickable(
            interactionSource = source,
            indication = LocalIndication.current,
            enabled = enabled,
            role = Role.Button,
            onClick = onClick,
        )
}

@Composable
fun AdventureScreen(
    modifier: Modifier = Modifier,
    includeBottomPadding: Boolean = true,
    content: @Composable BoxScope.() -> Unit,
) {
    val top = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
    val bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
    Box(
        modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(AdventureColors.Night, AdventureColors.Deep, AdventureColors.Reef),
                ),
            )
            .drawBehind {
                val stars = listOf(
                    Offset(size.width * .08f, size.height * .12f),
                    Offset(size.width * .22f, size.height * .26f),
                    Offset(size.width * .75f, size.height * .18f),
                    Offset(size.width * .90f, size.height * .34f),
                    Offset(size.width * .62f, size.height * .58f),
                    Offset(size.width * .14f, size.height * .72f),
                )
                drawCircle(AdventureColors.Physics.copy(alpha = .18f), size.minDimension * .42f, Offset(size.width * .92f, 0f))
                drawCircle(AdventureColors.Gold.copy(alpha = .10f), size.minDimension * .34f, Offset(size.width * .05f, size.height * .35f))
                stars.forEachIndexed { index, offset ->
                    drawCircle(
                        color = if (index % 2 == 0) AdventureColors.GoldBright else AdventureColors.Mint,
                        radius = 1.6.dp.toPx(),
                        center = offset,
                        alpha = .68f,
                    )
                }
            }
            .padding(top = top + 8.dp, bottom = if (includeBottomPadding) bottom else 0.dp),
        content = content,
    )
}

@Composable
fun AdventurePanel(
    modifier: Modifier = Modifier,
    shape: RoundedCornerShape = RoundedCornerShape(20.dp),
    borderColor: Color = AdventureColors.BorderSoft,
    content: @Composable () -> Unit,
) {
    Surface(
        modifier = modifier,
        shape = shape,
        color = AdventureColors.Panel.copy(alpha = .82f),
        border = BorderStroke(1.dp, borderColor),
        shadowElevation = 8.dp,
    ) {
        Box(
            Modifier
                .background(
                    Brush.verticalGradient(
                        listOf(AdventureColors.PanelLight.copy(alpha = .42f), AdventureColors.PanelDark.copy(alpha = .62f)),
                    ),
                )
                .padding(14.dp),
        ) {
            content()
        }
    }
}

@Composable
fun AdventureButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    enabled: Boolean = true,
    colors: List<Color> = listOf(AdventureColors.GoldBright, AdventureColors.Gold),
    contentColor: Color = AdventureColors.Ink,
) {
    val shape = RoundedCornerShape(16.dp)
    Box(
        modifier
            .defaultMinSize(minHeight = 54.dp)
            .shadow(if (enabled) 10.dp else 0.dp, shape, clip = false)
            .clip(shape)
            .background(if (enabled) Brush.verticalGradient(colors) else Brush.verticalGradient(listOf(Color(0xFF53636A), Color(0xFF33434B))))
            .border(1.dp, if (enabled) AdventureColors.GoldBright else AdventureColors.BorderSoft, shape)
            .adventurePress(enabled, onClick)
            .padding(horizontal = 18.dp, vertical = 14.dp),
        contentAlignment = Alignment.Center,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
            if (icon != null) {
                Icon(icon, contentDescription = null, tint = contentColor, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(8.dp))
            }
            Text(text, color = contentColor, fontWeight = FontWeight.Black, fontSize = 18.sp)
        }
    }
}

@Composable
fun AdventureGhostButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    enabled: Boolean = true,
) {
    val shape = RoundedCornerShape(15.dp)
    Box(
        modifier
            .defaultMinSize(minHeight = 50.dp)
            .clip(shape)
            .background(AdventureColors.PanelLight.copy(alpha = .68f))
            .border(1.dp, AdventureColors.BorderSoft, shape)
            .adventurePress(enabled, onClick)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
            if (icon != null) {
                Icon(icon, contentDescription = null, tint = AdventureColors.Text, modifier = Modifier.size(19.dp))
                Spacer(Modifier.width(8.dp))
            }
            Text(text, color = AdventureColors.Text, fontWeight = FontWeight.Bold, fontSize = 15.sp)
        }
    }
}

@Composable
fun AdventureProgress(
    progress: Float,
    modifier: Modifier = Modifier,
    track: Color = Color(0xFF0A2630),
    fill: Color = AdventureColors.Gold,
    height: Dp = 8.dp,
) {
    val shape = RoundedCornerShape(99.dp)
    Box(
        modifier
            .height(height)
            .clip(shape)
            .background(track),
    ) {
        Box(
            Modifier
                .fillMaxHeight()
                .fillMaxWidth(progress.coerceIn(0f, 1f))
                .clip(shape)
                .background(Brush.horizontalGradient(listOf(fill, AdventureColors.GoldBright))),
        )
    }
}

@Composable
fun MetricTile(
    label: String,
    value: String,
    icon: ImageVector,
    color: Color,
    modifier: Modifier = Modifier,
    supporting: String? = null,
) {
    AdventurePanel(modifier = modifier, shape = RoundedCornerShape(14.dp), borderColor = color.copy(alpha = .36f)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier
                    .size(38.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(color.copy(alpha = .18f)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(25.dp))
            }
            Spacer(Modifier.width(10.dp))
            Column {
                Text(label, color = AdventureColors.Muted, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                Text(value, color = AdventureColors.Text, fontSize = 18.sp, fontWeight = FontWeight.Black)
                if (supporting != null) {
                    Text(supporting, color = color, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
fun MascotPortrait(
    modifier: Modifier = Modifier,
    size: Dp = 74.dp,
    badge: Boolean = false,
) {
    Box(modifier.size(size), contentAlignment = Alignment.Center) {
        Box(
            Modifier
                .matchParentSize()
                .clip(if (badge) CircleShape else RoundedCornerShape(22.dp))
                .background(Brush.radialGradient(listOf(AdventureColors.Gold.copy(alpha = .50f), Color.Transparent)))
                .border(2.dp, AdventureColors.GoldBright, if (badge) CircleShape else RoundedCornerShape(22.dp)),
        )
        Image(
            painter = painterResource(R.drawable.gauss_mentor),
            contentDescription = "Gauss mentor",
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .padding(4.dp)
                .fillMaxSize()
                .clip(if (badge) CircleShape else RoundedCornerShape(19.dp)),
        )
    }
}

@Composable
fun SubjectRoadSwitch(
    subject: Subject,
    onSubjectChange: (Subject) -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier
            .clip(RoundedCornerShape(18.dp))
            .background(Color(0x66091F28))
            .border(1.dp, AdventureColors.BorderSoft, RoundedCornerShape(18.dp))
            .padding(4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Subject.entries.forEach { item ->
            val active = item == subject
            Box(
                Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(14.dp))
                    .background(
                        if (active) {
                            Brush.horizontalGradient(
                                if (item == Subject.MATH) {
                                    listOf(AdventureColors.Math, AdventureColors.Lavender)
                                } else {
                                    listOf(AdventureColors.Physics, AdventureColors.Mint)
                                },
                            )
                        } else {
                            Brush.horizontalGradient(listOf(Color.Transparent, Color.Transparent))
                        },
                    )
                    .adventurePress { onSubjectChange(item) }
                    .padding(vertical = 10.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    if (item == Subject.MATH) "Math Road" else "Physics Road",
                    color = if (active) AdventureColors.Text else AdventureColors.Muted,
                    fontWeight = FontWeight.Black,
                    fontSize = 13.sp,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}

@Composable
fun AdventureBottomNav(
    selected: AdventureTab,
    onSelect: (AdventureTab) -> Unit,
    modifier: Modifier = Modifier,
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(topStart = 22.dp, topEnd = 22.dp),
        color = AdventureColors.PanelDark.copy(alpha = .96f),
        border = BorderStroke(1.dp, AdventureColors.BorderSoft),
        shadowElevation = 14.dp,
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            AdventureTab.entries.forEach { tab ->
                val active = tab == selected
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(15.dp))
                        .background(if (active) AdventureColors.Reef.copy(alpha = .85f) else Color.Transparent)
                        .border(
                            if (active) 1.dp else 0.dp,
                            if (active) AdventureColors.Physics.copy(alpha = .58f) else Color.Transparent,
                            RoundedCornerShape(15.dp),
                        )
                        .adventurePress { onSelect(tab) }
                        .padding(vertical = 7.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(3.dp),
                ) {
                    Icon(tab.icon, contentDescription = tab.label, tint = if (active) AdventureColors.Text else AdventureColors.Muted, modifier = Modifier.size(23.dp))
                    Text(tab.label, color = if (active) AdventureColors.Text else AdventureColors.Muted, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
fun ComboRibbon(combo: Int, modifier: Modifier = Modifier) {
    AnimatedVisibility(combo > 1, modifier = modifier) {
        Box(
            Modifier
                .height(30.dp)
                .fillMaxWidth(.52f)
                .clip(RoundedCornerShape(bottomStart = 16.dp, bottomEnd = 16.dp, topStart = 4.dp, topEnd = 4.dp))
                .background(Brush.horizontalGradient(listOf(AdventureColors.Lavender, AdventureColors.Math)))
                .border(1.dp, Color.White.copy(alpha = .32f), RoundedCornerShape(bottomStart = 16.dp, bottomEnd = 16.dp, topStart = 4.dp, topEnd = 4.dp)),
            contentAlignment = Alignment.Center,
        ) {
            Text("COMBO x$combo", color = Color.White, fontWeight = FontWeight.Black, fontSize = 14.sp)
        }
    }
}

enum class TileState { Idle, Selected, Correct, Wrong }

@Composable
fun AnswerTileFrame(
    label: String,
    state: TileState,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    content: @Composable () -> Unit,
) {
    val shape = RoundedCornerShape(17.dp)
    val colors = when (state) {
        TileState.Correct -> listOf(Color(0xFF7ADD84), Color(0xFF39AD58))
        TileState.Wrong -> listOf(Color(0xFFFF7980), Color(0xFFD94C5C))
        TileState.Selected -> listOf(Color(0xFFE9F8FF), Color(0xFFD6F0FF))
        TileState.Idle -> listOf(AdventureColors.Cream, Color(0xFFF0E7DA))
    }
    val border = when (state) {
        TileState.Correct -> AdventureColors.Mint
        TileState.Wrong -> AdventureColors.Coral
        TileState.Selected -> AdventureColors.Physics
        TileState.Idle -> Color(0xFFE5D7C6)
    }
    Surface(
        modifier = modifier
            .defaultMinSize(minHeight = 92.dp)
            .shadow(7.dp, shape, clip = false)
            .clip(shape)
            .adventurePress(enabled, onClick),
        color = Color.Transparent,
        shape = shape,
    ) {
        Box(
            Modifier
                .fillMaxSize()
                .background(Brush.verticalGradient(colors))
                .border(2.dp, border.copy(alpha = .78f), shape)
                .padding(12.dp),
        ) {
            Text(label, color = when (state) {
                TileState.Correct -> Color.White
                TileState.Wrong -> Color.White
                else -> AdventureColors.Ink
            }, fontWeight = FontWeight.Black, fontSize = 16.sp)
            Box(Modifier.align(Alignment.Center).padding(top = 8.dp)) { content() }
            if (state == TileState.Correct || state == TileState.Wrong) {
                Icon(
                    if (state == TileState.Correct) Icons.Rounded.CheckCircle else Icons.Rounded.Close,
                    contentDescription = if (state == TileState.Correct) "Correct" else "Wrong",
                    tint = Color.White,
                    modifier = Modifier.align(Alignment.BottomEnd).size(30.dp),
                )
            }
        }
    }
}

@Composable
fun VaultDoor(
    modifier: Modifier = Modifier,
    open: Boolean = true,
) {
    Canvas(modifier) {
        val center = Offset(size.width * .52f, size.height * .54f)
        val radius = size.minDimension * .34f
        drawCircle(Color(0xFF4F5B5E), radius * 1.22f, center)
        drawCircle(Color(0xFFC6CED0), radius * 1.06f, center)
        drawCircle(Color(0xFF6E797B), radius * .92f, center)
        drawCircle(Color(0xFF322B21), radius * .74f, center)
        drawCircle(AdventureColors.Gold.copy(alpha = .85f), radius * .68f, center)
        repeat(9) { index ->
            val angle = (index / 9f) * Math.PI.toFloat() * 2f
            val point = Offset(
                center.x + kotlin.math.cos(angle) * radius * .99f,
                center.y + kotlin.math.sin(angle) * radius * .99f,
            )
            drawCircle(Color(0xFFE4E7E8), radius * .07f, point)
        }
        repeat(10) { index ->
            val angle = (index / 10f) * Math.PI.toFloat() * 2f
            val point = Offset(
                center.x + kotlin.math.cos(angle) * radius * .40f,
                center.y + kotlin.math.sin(angle) * radius * .40f,
            )
            drawStar(point, radius * .13f, AdventureColors.GoldBright)
        }
        if (open) {
            val doorCenter = Offset(size.width * .80f, center.y)
            drawCircle(Color(0xFF7B8586), radius * .78f, doorCenter)
            drawCircle(Color(0xFF455054), radius * .62f, doorCenter)
            drawCircle(Color(0xFFC8D0D2), radius * .11f, doorCenter)
            drawLine(Color(0xFF222C31), doorCenter, Offset(size.width * .98f, size.height * .20f), strokeWidth = 6.dp.toPx())
            drawLine(Color(0xFF222C31), doorCenter, Offset(size.width * .98f, size.height * .86f), strokeWidth = 6.dp.toPx())
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawStar(center: Offset, radius: Float, color: Color) {
    val path = Path()
    repeat(10) { i ->
        val r = if (i % 2 == 0) radius else radius * .45f
        val angle = -Math.PI.toFloat() / 2f + i * Math.PI.toFloat() / 5f
        val p = Offset(center.x + kotlin.math.cos(angle) * r, center.y + kotlin.math.sin(angle) * r)
        if (i == 0) path.moveTo(p.x, p.y) else path.lineTo(p.x, p.y)
    }
    path.close()
    drawPath(path, color)
}

@Composable
fun BrainNebula(modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val base = listOf(
            Color(0xFFFF7B7B), Color(0xFFFFA4C0), Color(0xFFA76DFF),
            Color(0xFF54BDF7), Color(0xFF29C8AA), Color(0xFF396BFF),
        )
        repeat(58) { index ->
            val col = (index % 10)
            val row = index / 10
            val x = size.width * (.18f + col * .07f + if (row % 2 == 0) .02f else -.015f)
            val y = size.height * (.18f + row * .105f)
            val radius = size.minDimension * (.105f - (row * .005f)).coerceAtLeast(.065f)
            drawCircle(
                color = base[index % base.size].copy(alpha = .88f),
                radius = radius,
                center = Offset(x, y),
            )
        }
        drawCircle(Color.White.copy(alpha = .12f), size.minDimension * .52f, Offset(size.width * .42f, size.height * .40f))
    }
}

@Composable
fun MiniCoin(icon: ImageVector, label: String, value: String, color: Color, modifier: Modifier = Modifier) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically) {
        Box(
            Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(color.copy(alpha = .20f))
                .border(1.dp, color.copy(alpha = .65f), CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(26.dp))
        }
        Spacer(Modifier.width(10.dp))
        Column {
            Text(value, color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 17.sp)
            Text(label, color = AdventureColors.Muted, fontSize = 11.sp)
        }
    }
}

fun adventureSubjectColor(subject: Subject): Color =
    if (subject == Subject.MATH) AdventureColors.Math else AdventureColors.Physics

fun DrawScopePath(points: List<Offset>): Path = Path().apply {
    points.forEachIndexed { index, offset ->
        if (index == 0) moveTo(offset.x, offset.y) else lineTo(offset.x, offset.y)
    }
}

@Composable
fun ConfettiLayer(modifier: Modifier = Modifier) {
    Canvas(modifier.fillMaxSize()) {
        val colors = listOf(AdventureColors.Gold, AdventureColors.Mint, AdventureColors.Lavender, AdventureColors.Coral)
        repeat(34) { index ->
            val x = size.width * ((index * 37 % 100) / 100f)
            val y = size.height * ((index * 19 % 86) / 100f)
            val c = colors[index % colors.size]
            drawRect(c, topLeft = Offset(x, y), size = Size(7.dp.toPx(), 4.dp.toPx()))
        }
    }
}
