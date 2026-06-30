package com.gauss.app.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AutoAwesome
import androidx.compose.material.icons.rounded.Bolt
import androidx.compose.material.icons.rounded.Calculate
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.Diamond
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.Inventory2
import androidx.compose.material.icons.rounded.LocalFireDepartment
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.MilitaryTech
import androidx.compose.material.icons.rounded.Paid
import androidx.compose.material.icons.rounded.Psychology
import androidx.compose.material.icons.rounded.Radar
import androidx.compose.material.icons.rounded.Redeem
import androidx.compose.material.icons.rounded.Science
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material.icons.rounded.Shield
import androidx.compose.material.icons.rounded.ShoppingBag
import androidx.compose.material.icons.rounded.Star
import androidx.compose.material.icons.rounded.TrackChanges
import androidx.compose.material.icons.rounded.Wifi
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.gauss.app.GaussApp
import com.gauss.app.data.Analytics
import com.gauss.app.data.AttemptStatus
import com.gauss.app.data.ComprehensiveTaxonomy
import com.gauss.app.data.Difficulty
import com.gauss.app.data.ExamConfig
import com.gauss.app.data.GamificationSummary
import com.gauss.app.data.Question
import com.gauss.app.data.SourceBank
import com.gauss.app.data.Subject
import com.gauss.app.data.TopicDef
import com.gauss.app.gamify.AdventureAchievementCatalog
import com.gauss.app.gamify.AdventureDisplayLabels
import com.gauss.app.gamify.AdventureLevelCurve
import com.gauss.app.gamify.AdventureRewardRules
import com.gauss.app.ui.adventure.AdventureBottomNav
import com.gauss.app.ui.adventure.AdventureButton
import com.gauss.app.ui.adventure.AdventureColors
import com.gauss.app.ui.adventure.AdventureGhostButton
import com.gauss.app.ui.adventure.AdventurePanel
import com.gauss.app.ui.adventure.AdventureProgress
import com.gauss.app.ui.adventure.AdventureScreen
import com.gauss.app.ui.adventure.AdventureTab
import com.gauss.app.ui.adventure.AnswerTileFrame
import com.gauss.app.ui.adventure.BrainNebula
import com.gauss.app.ui.adventure.ComboRibbon
import com.gauss.app.ui.adventure.ConfettiLayer
import com.gauss.app.ui.adventure.MascotPortrait
import com.gauss.app.ui.adventure.MetricTile
import com.gauss.app.ui.adventure.MiniCoin
import com.gauss.app.ui.adventure.SubjectRoadSwitch
import com.gauss.app.ui.adventure.TileState
import com.gauss.app.ui.adventure.VaultDoor
import com.gauss.app.ui.adventure.adventurePress
import com.gauss.app.ui.adventure.adventureSubjectColor
import com.gauss.app.ui.components.DrawingCanvas
import com.gauss.app.ui.components.RichContent
import com.gauss.app.ui.components.Stroke as ScratchStroke
import com.gauss.app.ui.exam.ExamViewModel
import com.gauss.app.ui.nav.Routes
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin

private data class RoadNode(
    val title: String,
    val subtitle: String,
    val topicKey: String?,
    val x: Float,
    val y: Float,
    val icon: ImageVector,
    val locked: Boolean = false,
    val boss: Boolean = false,
)

private class MissionLauncher(
    val launching: Boolean,
    val error: String?,
    val start: (Subject, List<String>, Int) -> Unit,
    val startRevenge: () -> Unit,
)

@Composable
private fun rememberMissionLauncher(nav: NavController, examVm: ExamViewModel): MissionLauncher {
    val context = LocalContext.current
    val app = remember(context) { GaussApp.from(context) }
    val scope = rememberCoroutineScope()
    var launching by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    fun launchQuestions(subject: Subject, topics: List<String>, count: Int) {
        if (launching) return
        launching = true
        error = null
        scope.launch {
            val bank = app.questionBank()
            val config = ExamConfig(
                subject = subject,
                topicKeys = topics,
                sourceBanks = SourceBank.entries.toList(),
                difficulties = Difficulty.entries.toList(),
                count = count,
            )
            val questions = bank.selectExam(config)
            if (questions.isEmpty()) {
                error = "No questions are available for this mission yet."
                launching = false
                return@launch
            }
            examVm.startExam(config.copy(count = questions.size), questions)
            launching = false
            nav.navigate(Routes.ARENA)
        }
    }

    fun launchRevenge() {
        if (launching) return
        launching = true
        error = null
        scope.launch {
            val ids = app.history.revengeIds().take(8)
            val bank = app.questionBank()
            val questions = bank.byIds(ids)
            if (questions.isEmpty()) {
                error = "Your revenge queue is clear."
                launching = false
                return@launch
            }
            val subject = questions.first().subject
            val config = ExamConfig(
                subject = subject,
                topicKeys = questions.map { it.topicKey }.distinct(),
                sourceBanks = SourceBank.entries.toList(),
                difficulties = Difficulty.entries.toList(),
                count = questions.size,
            )
            examVm.startExam(config, questions)
            launching = false
            nav.navigate(Routes.ARENA)
        }
    }

    return MissionLauncher(launching, error, ::launchQuestions, ::launchRevenge)
}

@Composable
fun AdventureMapScreen(nav: NavController, examVm: ExamViewModel) {
    val context = LocalContext.current
    val app = remember(context) { GaussApp.from(context) }
    var subject by remember { mutableStateOf(Subject.MATH) }
    var summary by remember { mutableStateOf<GamificationSummary?>(null) }
    var availability by remember { mutableStateOf<Map<String, Int>>(emptyMap()) }
    var selectedTopic by remember { mutableStateOf<String?>(null) }
    val launcher = rememberMissionLauncher(nav, examVm)

    LaunchedEffect(subject) {
        summary = app.gamification.summary()
        availability = app.questionBank().topicAvailability(subject)
        selectedTopic = roadNodes(subject, availability).firstOrNull { !it.boss && !it.locked && it.topicKey != null }?.topicKey
    }

    AdventureScreen {
        Column(
            Modifier
                .fillMaxSize()
                .padding(horizontal = 14.dp)
                .padding(bottom = 92.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            TopHud(summary)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                MetricTile("Focus", "7/10", Icons.Rounded.Bolt, AdventureColors.Gold, modifier = Modifier.weight(1f))
                MetricTile("Streak", "12 days", Icons.Rounded.LocalFireDepartment, Color(0xFFFF8A3D), modifier = Modifier.weight(1f))
            }
            SubjectRoadSwitch(
                subject = subject,
                onSubjectChange = { subject = it },
                modifier = Modifier.fillMaxWidth(),
            )
            MissionMapCard(
                subject = subject,
                nodes = roadNodes(subject, availability),
                selectedTopic = selectedTopic,
                onNodeSelect = { node ->
                    when {
                        node.locked -> Unit
                        node.topicKey != null -> selectedTopic = node.topicKey
                        node.title.contains("Chest") || node.title.contains("Vault") -> nav.openTab(AdventureTab.REWARDS)
                    }
                },
                onStart = {
                    val topic = selectedTopic
                    launcher.start(subject, if (topic == null) emptyList() else listOf(topic), 12)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
            )
            DailyQuestDock(summary, launcher.error, launcher.launching)
        }
        AdventureBottomNav(AdventureTab.MAP, { nav.openTab(it) }, Modifier.align(Alignment.BottomCenter))
    }
}

@Composable
private fun TopHud(summary: GamificationSummary?) {
    val level = AdventureLevelCurve.previewSnapshot()
    AdventurePanel(shape = RoundedCornerShape(20.dp), modifier = Modifier.fillMaxWidth()) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            MascotPortrait(size = 56.dp, badge = true)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text("Level ${level.level}", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 18.sp)
                Text("Explorer", color = AdventureColors.Muted, fontWeight = FontWeight.SemiBold, fontSize = 12.sp)
                Spacer(Modifier.height(8.dp))
                AdventureProgress(progress = level.progress)
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(level.display, color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 12.sp)
                Text("${summary?.todayXp ?: 0} today", color = AdventureColors.Muted, fontWeight = FontWeight.SemiBold, fontSize = 10.sp)
            }
        }
    }
}

@Composable
private fun MissionMapCard(
    subject: Subject,
    nodes: List<RoadNode>,
    selectedTopic: String?,
    onNodeSelect: (RoadNode) -> Unit,
    onStart: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val shape = RoundedCornerShape(18.dp)
    BoxWithConstraints(
        modifier
            .clip(shape)
            .clipToBounds()
            .background(
                Brush.verticalGradient(
                    listOf(Color(0xFF08313B), Color(0xFF0A5860), Color(0xFF09313C)),
                ),
            )
            .border(1.dp, AdventureColors.BorderSoft, shape)
    ) {
        val routeNodes = nodes.filterNot { it.locked }.sortedByDescending { it.y }
        val subjectColor = adventureSubjectColor(subject)
        Canvas(Modifier.matchParentSize()) {
            drawCircle(AdventureColors.Physics.copy(alpha = .18f), size.minDimension * .48f, Offset(size.width * .95f, size.height * .03f))
            drawCircle(AdventureColors.Gold.copy(alpha = .10f), size.minDimension * .35f, Offset(size.width * .05f, size.height * .36f))
            repeat(18) { index ->
                val x = ((index * 37) % 100) / 100f * size.width
                val y = ((index * 61) % 100) / 100f * size.height
                drawCircle(
                    color = if (index % 2 == 0) AdventureColors.GoldBright else AdventureColors.Physics,
                    radius = if (index % 5 == 0) 2.2.dp.toPx() else 1.35.dp.toPx(),
                    center = Offset(x, y),
                    alpha = .42f,
                )
            }
            routeNodes.zipWithNext().forEach { (from, to) ->
                val start = Offset(size.width * from.x + 42.dp.toPx(), size.height * from.y + 28.dp.toPx())
                val end = Offset(size.width * to.x + 42.dp.toPx(), size.height * to.y + 28.dp.toPx())
                drawLine(AdventureColors.AmberDark.copy(alpha = .74f), start, end, strokeWidth = 13.dp.toPx(), cap = StrokeCap.Round)
                drawLine(AdventureColors.Cream.copy(alpha = .88f), start, end, strokeWidth = 5.dp.toPx(), cap = StrokeCap.Round)
                repeat(4) { step ->
                    val t = (step + 1) / 5f
                    drawCircle(
                        color = AdventureColors.GoldBright,
                        radius = 3.3.dp.toPx(),
                        center = Offset(start.x + (end.x - start.x) * t, start.y + (end.y - start.y) * t),
                    )
                }
            }
            nodes.forEach { node ->
                val center = Offset(size.width * node.x + 48.dp.toPx(), size.height * node.y + 44.dp.toPx())
                val islandColor = when {
                    node.locked -> Color(0xFF40505A)
                    node.boss -> AdventureColors.Lavender
                    node.title.contains("Chest") || node.title.contains("Vault") -> AdventureColors.Gold
                    else -> subjectColor
                }
                drawOval(
                    color = Color.Black.copy(alpha = .26f),
                    topLeft = Offset(center.x - 62.dp.toPx(), center.y + 8.dp.toPx()),
                    size = Size(124.dp.toPx(), 34.dp.toPx()),
                )
                drawOval(
                    brush = Brush.radialGradient(
                        listOf(islandColor.copy(alpha = .72f), Color(0xFF143D35).copy(alpha = .82f)),
                        center = center,
                        radius = 78.dp.toPx(),
                    ),
                    topLeft = Offset(center.x - 62.dp.toPx(), center.y - 22.dp.toPx()),
                    size = Size(124.dp.toPx(), 64.dp.toPx()),
                )
                drawOval(
                    color = AdventureColors.Cream.copy(alpha = .16f),
                    topLeft = Offset(center.x - 34.dp.toPx(), center.y - 14.dp.toPx()),
                    size = Size(70.dp.toPx(), 24.dp.toPx()),
                )
            }
        }

        Column(
            Modifier
                .align(Alignment.TopCenter)
                .padding(top = 12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text("Gauss Adventure Academy", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 14.sp)
            Text(AdventureDisplayLabels.roadName(subject), color = subjectColor, fontWeight = FontWeight.Bold, fontSize = 11.sp)
        }

        val currentStage = AdventureDisplayLabels.stageName(subject, selectedTopic)
        nodes.forEach { node ->
            val currentMissionNode = node.topicKey != null && node.topicKey == selectedTopic && !node.boss
            if (currentMissionNode) return@forEach
            val chipWidth = if (node.boss) 118.dp else 108.dp
            MissionNodeChip(
                node = node,
                selected = node.topicKey != null && node.topicKey == selectedTopic,
                subject = subject,
                onClick = { onNodeSelect(node) },
                modifier = Modifier.offset(
                    x = (maxWidth - chipWidth) * node.x,
                    y = (maxHeight - 84.dp) * node.y,
                ),
            )
        }

        Column(
            Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 14.dp)
                .width(174.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .background(AdventureColors.PanelDark.copy(alpha = .88f))
                    .border(1.dp, AdventureColors.Gold.copy(alpha = .62f), RoundedCornerShape(10.dp))
                    .padding(horizontal = 10.dp, vertical = 5.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text("Current Mission", color = AdventureColors.Text, fontWeight = FontWeight.Bold, fontSize = 10.sp)
            }
            Text(currentStage, color = AdventureColors.GoldBright, fontWeight = FontWeight.Black, fontSize = 12.sp, textAlign = TextAlign.Center, maxLines = 1)
            Spacer(Modifier.height(5.dp))
            AdventureButton("Start Mission", onStart, modifier = Modifier.fillMaxWidth())
        }

        MascotPortrait(
            size = 70.dp,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .offset(y = (-77).dp),
        )
    }
}

@Composable
private fun MissionNodeChip(
    node: RoadNode,
    selected: Boolean,
    subject: Subject,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val color = when {
        node.locked -> Color(0xFF4B5960)
        node.boss -> AdventureColors.Lavender
        else -> adventureSubjectColor(subject)
    }
    Column(
        modifier
            .width(if (node.boss) 118.dp else 106.dp)
            .clip(RoundedCornerShape(18.dp))
            .background(Brush.verticalGradient(listOf(color.copy(alpha = .42f), AdventureColors.PanelDark.copy(alpha = .88f))))
            .border(if (selected) 2.dp else 1.dp, if (selected) AdventureColors.GoldBright else color.copy(alpha = .65f), RoundedCornerShape(18.dp))
            .adventurePress(!node.locked, onClick)
            .padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            Modifier
                .size(42.dp)
                .clip(CircleShape)
                .background(color.copy(alpha = .25f))
                .border(1.dp, color.copy(alpha = .65f), CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(if (node.locked) Icons.Rounded.Lock else node.icon, contentDescription = null, tint = AdventureColors.Text, modifier = Modifier.size(24.dp))
        }
        Spacer(Modifier.height(5.dp))
        Text(node.title, color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 11.sp, textAlign = TextAlign.Center, maxLines = 2)
        Text(node.subtitle, color = AdventureColors.Muted, fontSize = 9.sp, textAlign = TextAlign.Center, maxLines = 1)
        if (selected || (!node.locked && !node.boss && node.topicKey != null)) {
            Spacer(Modifier.height(5.dp))
            Box(
                Modifier
                    .size(22.dp)
                    .clip(CircleShape)
                    .background(if (selected) AdventureColors.Lavender else AdventureColors.Mint)
                    .border(1.dp, AdventureColors.Text.copy(alpha = .34f), CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Rounded.Check, contentDescription = null, tint = AdventureColors.Text, modifier = Modifier.size(15.dp))
            }
        }
    }
}

@Composable
private fun DailyQuestDock(summary: GamificationSummary?, error: String?, launching: Boolean) {
    val quest = AdventureAchievementCatalog.quests.first { it.id == "daily_trap_spotter" }
    val progress = if (summary?.quest?.target == quest.target) summary.quest.progress else 0
    AdventurePanel(shape = RoundedCornerShape(18.dp), modifier = Modifier.fillMaxWidth()) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.TrackChanges, contentDescription = null, tint = AdventureColors.Coral, modifier = Modifier.size(38.dp))
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(if (launching) "Opening arena..." else error ?: "Daily Quest", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 13.sp)
                Text("Beat 2 trap questions", color = AdventureColors.Muted, fontSize = 12.sp)
                Spacer(Modifier.height(7.dp))
                AdventureProgress(
                    progress = progress / quest.target.toFloat(),
                    fill = AdventureColors.Mint,
                    height = 7.dp,
                )
            }
            Spacer(Modifier.width(10.dp))
            Column(horizontalAlignment = Alignment.End) {
                Text("$progress/${quest.target}", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 12.sp)
                Text("+${AdventureRewardRules.DAILY_TRAP_REWARD_XP} XP", color = AdventureColors.GoldBright, fontWeight = FontWeight.Black, fontSize = 12.sp)
            }
        }
    }
}

private fun roadNodes(subject: Subject, availability: Map<String, Int>): List<RoadNode> {
    val topics = ComprehensiveTaxonomy.topicsFor(subject).filter { availability[it.key] != 0 }
    return if (subject == Subject.MATH) {
        listOf(
            RoadNode("Treasure Chest", "Coins", null, .07f, .82f, Icons.Rounded.Inventory2),
            RoadNode("Algebra Grove", labelFor(topics.getOrNull(2)), topics.getOrNull(2)?.key, .44f, .75f, Icons.Rounded.Calculate),
            RoadNode("Calculus Cliffs", labelFor(topics.getOrNull(8)), topics.getOrNull(8)?.key, .09f, .46f, Icons.Rounded.AutoAwesome),
            RoadNode("Reward Vault", "Open soon", null, .73f, .31f, Icons.Rounded.Redeem),
            RoadNode("Boss Arena", "Gold pass", topics.firstOrNull()?.key, .22f, .14f, Icons.Rounded.EmojiEvents, boss = true),
            RoadNode("Quantum Lab", "Locked", null, .82f, .84f, Icons.Rounded.Lock, locked = true),
        )
    } else {
        listOf(
            RoadNode("Supply Chest", "Coins", null, .08f, .82f, Icons.Rounded.Inventory2),
            RoadNode("Motion Pier", labelFor(topics.getOrNull(7)), topics.getOrNull(7)?.key, .45f, .74f, Icons.Rounded.Radar),
            RoadNode("Force Forge", labelFor(topics.getOrNull(8)), topics.getOrNull(8)?.key, .13f, .47f, Icons.Rounded.Bolt),
            RoadNode("Circuit Vault", labelFor(topics.getOrNull(5)), topics.getOrNull(5)?.key, .74f, .30f, Icons.Rounded.Science),
            RoadNode("Boss Arena", "Gold pass", topics.firstOrNull()?.key, .22f, .14f, Icons.Rounded.EmojiEvents, boss = true),
            RoadNode("Relativity Lab", "Locked", null, .82f, .84f, Icons.Rounded.Lock, locked = true),
        )
    }
}

private fun labelFor(topic: TopicDef?): String = topic?.let(::englishTopicLabel) ?: "Ready"

private fun englishTopicLabel(topic: TopicDef): String = AdventureDisplayLabels.topicLabelOrFallback(topic.key)

@Composable
fun AdventureMissionsScreen(nav: NavController, examVm: ExamViewModel) {
    val context = LocalContext.current
    val app = remember(context) { GaussApp.from(context) }
    val launcher = rememberMissionLauncher(nav, examVm)
    var subject by remember { mutableStateOf(Subject.MATH) }
    var topics by remember { mutableStateOf<List<TopicDef>>(emptyList()) }
    var availability by remember { mutableStateOf<Map<String, Int>>(emptyMap()) }
    var summary by remember { mutableStateOf<GamificationSummary?>(null) }

    LaunchedEffect(subject) {
        summary = app.gamification.summary()
        availability = app.questionBank().topicAvailability(subject)
        topics = ComprehensiveTaxonomy.topicsFor(subject).filter { availability[it.key] != 0 }.take(6)
    }

    AdventureScreen {
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 14.dp)
                .padding(bottom = 92.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            ScreenTitle("Challenge Arena", "Choose one clean road. No mixed subjects.")
            SubjectRoadSwitch(subject, onSubjectChange = { subject = it }, modifier = Modifier.fillMaxWidth())
            AdventurePanel(modifier = Modifier.fillMaxWidth()) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    MascotPortrait(size = 68.dp)
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text("Daily Quest", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 18.sp)
                        Text("Beat 2 trap questions and keep your focus alive.", color = AdventureColors.Muted, fontSize = 13.sp)
                        Spacer(Modifier.height(10.dp))
                        AdventureProgress((summary?.quest?.progress ?: 0) / (summary?.quest?.target ?: 10).toFloat(), fill = AdventureColors.Mint)
                    }
                }
            }
            topics.forEachIndexed { index, topic ->
                MissionRow(
                    title = missionName(subject, index),
                    subtitle = englishTopicLabel(topic),
                    questions = availability[topic.key] ?: 0,
                    color = adventureSubjectColor(subject),
                    onClick = { launcher.start(subject, listOf(topic.key), 12) },
                )
            }
            MissionRow(
                title = "Boss Arena",
                subtitle = "A longer streak challenge for ${if (subject == Subject.MATH) "Math" else "Physics"}.",
                questions = availability.values.sum(),
                color = AdventureColors.Lavender,
                boss = true,
                onClick = { launcher.start(subject, emptyList(), 20) },
            )
            if (launcher.error != null) {
                Text(launcher.error, color = AdventureColors.Coral, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 4.dp))
            }
        }
        AdventureBottomNav(AdventureTab.MISSIONS, { nav.openTab(it) }, Modifier.align(Alignment.BottomCenter))
    }
}

@Composable
private fun MissionRow(
    title: String,
    subtitle: String,
    questions: Int,
    color: Color,
    boss: Boolean = false,
    onClick: () -> Unit,
) {
    AdventurePanel(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(18.dp), borderColor = color.copy(alpha = .42f)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier
                    .size(54.dp)
                    .clip(RoundedCornerShape(17.dp))
                    .background(color.copy(alpha = .22f))
                    .border(1.dp, color.copy(alpha = .62f), RoundedCornerShape(17.dp)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(if (boss) Icons.Rounded.EmojiEvents else Icons.Rounded.Star, contentDescription = null, tint = color, modifier = Modifier.size(30.dp))
            }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 16.sp)
                Text(subtitle, color = AdventureColors.Muted, fontSize = 12.sp, maxLines = 1)
                Text("$questions questions ready", color = color, fontWeight = FontWeight.Bold, fontSize = 11.sp)
            }
            AdventureGhostButton("Start", onClick, modifier = Modifier.width(92.dp))
        }
    }
}

private fun missionName(subject: Subject, index: Int): String {
    val math = listOf("Algebra Grove", "Calculus Cliffs", "Function Forest", "Geometry Gate", "Probability Pier", "Statistics Harbor")
    val physics = listOf("Motion Pier", "Force Forge", "Energy Mine", "Circuit Vault", "Magnet Dock", "Wave Tower")
    return (if (subject == Subject.MATH) math else physics).getOrElse(index) { "Mission ${index + 1}" }
}

@Composable
private fun ScreenTitle(title: String, subtitle: String, trailing: (@Composable () -> Unit)? = null) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f)) {
            Text(title, color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 22.sp)
            Text(subtitle, color = AdventureColors.Muted, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
        }
        trailing?.invoke()
    }
}

@Composable
fun AdventureArenaScreen(nav: NavController, examVm: ExamViewModel) {
    val question = examVm.current
    if (question == null) {
        AdventureEmptyState(
            selected = AdventureTab.MISSIONS,
            nav = nav,
            title = "No mission running",
            body = "Pick a Math Road or Physics Road mission to open the arena.",
            action = "Open Missions",
        ) { nav.openTab(AdventureTab.MISSIONS) }
        return
    }

    var pendingOption by remember(question.id) { mutableStateOf<Int?>(null) }
    var scratchpadOpen by remember(question.id) { mutableStateOf(false) }
    var optionsOpen by remember { mutableStateOf(false) }
    val strokes = remember(question.id) { mutableStateListOf<ScratchStroke>() }
    val attempt = examVm.attempts[examVm.index]
    val combo = comboCount(examVm)
    val progress = (examVm.index + if (attempt != null) 1 else 0).toFloat() / examVm.questions.size.coerceAtLeast(1)
    val actionEnabled = !examVm.saving && (attempt != null || pendingOption != null)

    val advanceArena = {
        when {
            attempt == null && pendingOption != null -> examVm.answer(pendingOption!!)
            attempt == null -> Unit
            examVm.isLast -> examVm.finishAndSave { nav.navigate(Routes.REWARD) }
            else -> {
                examVm.next()
                pendingOption = null
            }
        }
    }

    AdventureScreen(includeBottomPadding = false) {
        Column(
            Modifier
                .fillMaxSize()
                .padding(horizontal = 14.dp)
                .padding(bottom = 14.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            ArenaHeader(
                title = "Challenge Arena",
                subtitle = "${AdventureDisplayLabels.stageName(question.subject, question.topicKey)} - Question ${examVm.index + 1} of ${examVm.questions.size}",
                onBack = { nav.openTab(AdventureTab.MAP) },
                onSettings = { optionsOpen = true },
            )
            ArenaStatusBar(
                progress = progress,
                combo = combo,
                resetKey = question.id,
            )
            Box(
                Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
            ) {
                Column(
                    Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    ComboRibbon(combo = combo, modifier = Modifier.align(Alignment.CenterHorizontally))
                    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Bottom) {
                        MascotPortrait(size = 70.dp)
                        Spacer(Modifier.width(8.dp))
                        CoachBubble(coachTextFor(question, attempt))
                    }
                    QuestionCard(question)
                    TrapHint(question)
                    AnswerGrid(
                        question = question,
                        attempt = attempt,
                        pendingOption = pendingOption,
                        onPick = { pendingOption = it },
                    )
                    ArenaFeedback(attempt)
                    if (examVm.saveError != null) {
                        Text(
                            examVm.saveError.orEmpty(),
                            color = AdventureColors.Coral,
                            fontWeight = FontWeight.Bold,
                            fontSize = 12.sp,
                        )
                    }
                }
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                AdventureGhostButton(
                    text = "Scratchpad",
                    onClick = { scratchpadOpen = true },
                    icon = Icons.Rounded.Edit,
                    modifier = Modifier.weight(.84f),
                )
                AdventureButton(
                    text = arenaActionText(examVm, attempt),
                    onClick = advanceArena,
                    enabled = actionEnabled,
                    modifier = Modifier.weight(1.36f),
                )
            }
        }
        if (scratchpadOpen) {
            Box(
                Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = .60f)),
            ) {
                DrawingCanvas(
                    strokes = strokes,
                    onChange = { changed ->
                        strokes.clear()
                        strokes.addAll(changed)
                    },
                    modifier = Modifier.fillMaxSize(),
                    onClose = { scratchpadOpen = false },
                    clearKey = question.id,
                )
            }
        }
        if (optionsOpen) {
            ArenaOptionsOverlay(
                progress = progress,
                combo = combo,
                onClose = { optionsOpen = false },
            )
        }
    }
}

@Composable
private fun ArenaHeader(
    title: String,
    subtitle: String,
    onBack: () -> Unit,
    onSettings: () -> Unit,
) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        IconButton(onClick = onBack, modifier = Modifier.size(48.dp)) {
            Icon(Icons.AutoMirrored.Rounded.ArrowBack, contentDescription = "Back to map", tint = AdventureColors.Text)
        }
        Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
            Text(title, color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 18.sp, textAlign = TextAlign.Center)
            Text(subtitle, color = AdventureColors.Muted, fontWeight = FontWeight.SemiBold, fontSize = 11.sp, textAlign = TextAlign.Center, maxLines = 1)
        }
        IconButton(onClick = onSettings, modifier = Modifier.size(48.dp)) {
            Icon(Icons.Rounded.Settings, contentDescription = "Arena settings", tint = AdventureColors.Text)
        }
    }
}

@Composable
private fun ArenaStatusBar(
    progress: Float,
    combo: Int,
    resetKey: Any,
) {
    AdventurePanel(shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth()) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("Mission Progress", color = AdventureColors.Muted, fontWeight = FontWeight.SemiBold, fontSize = 11.sp)
                    AdventureProgress(progress = progress, fill = AdventureColors.Mint, height = 7.dp)
                }
                Spacer(Modifier.width(12.dp))
                Box(
                    Modifier
                        .clip(RoundedCornerShape(14.dp))
                        .background(AdventureColors.PanelDark.copy(alpha = .74f))
                        .border(1.dp, AdventureColors.Gold.copy(alpha = .48f), RoundedCornerShape(14.dp))
                        .padding(horizontal = 10.dp, vertical = 8.dp),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Rounded.Bolt, contentDescription = null, tint = AdventureColors.GoldBright, modifier = Modifier.size(22.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("Focus\n7/10", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 12.sp, lineHeight = 14.sp)
                    }
                }
                Spacer(Modifier.width(8.dp))
                Column(horizontalAlignment = Alignment.End) {
                    Text(if (combo > 1) "Combo x$combo" else "Focus Mode", color = AdventureColors.GoldBright, fontWeight = FontWeight.Black, fontSize = 12.sp)
                    ArenaTimer(resetKey)
                }
            }
        }
    }
}

private fun coachTextFor(question: Question, attempt: com.gauss.app.data.AttemptResult?): String =
    when {
        attempt?.status == AttemptStatus.CORRECT -> "Great shortcut. Keep the combo alive."
        attempt?.status == AttemptStatus.WRONG -> "Not that path yet. Read the structure again."
        question.shortcut != null -> "Find the shortcut."
        else -> "Solve it cleanly."
    }

@Composable
private fun ArenaFeedback(attempt: com.gauss.app.data.AttemptResult?) {
    if (attempt == null) return
    val correct = attempt.status == AttemptStatus.CORRECT
    AdventurePanel(
        shape = RoundedCornerShape(14.dp),
        modifier = Modifier.fillMaxWidth(),
        borderColor = if (correct) AdventureColors.Mint.copy(alpha = .48f) else AdventureColors.Coral.copy(alpha = .48f),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                if (correct) Icons.Rounded.Check else Icons.Rounded.AutoAwesome,
                contentDescription = null,
                tint = if (correct) AdventureColors.Mint else AdventureColors.Coral,
                modifier = Modifier.size(24.dp),
            )
            Spacer(Modifier.width(8.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    if (correct) "Correct" else "Review the trap",
                    color = AdventureColors.Text,
                    fontWeight = FontWeight.Black,
                    fontSize = 13.sp,
                )
                Text(
                    if (correct) "The vault will count this toward your combo." else "The correct answer is highlighted. Continue when you are ready.",
                    color = AdventureColors.Muted,
                    fontSize = 12.sp,
                )
            }
        }
    }
}

@Composable
private fun ArenaOptionsOverlay(
    progress: Float,
    combo: Int,
    onClose: () -> Unit,
) {
    Box(
        Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = .56f))
            .padding(24.dp),
        contentAlignment = Alignment.Center,
    ) {
        AdventurePanel(shape = RoundedCornerShape(20.dp), modifier = Modifier.fillMaxWidth()) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Rounded.Settings, contentDescription = null, tint = AdventureColors.GoldBright, modifier = Modifier.size(28.dp))
                    Spacer(Modifier.width(10.dp))
                    Column(Modifier.weight(1f)) {
                        Text("Arena Options", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 18.sp)
                        Text("Mission state stays local until rewards are claimed.", color = AdventureColors.Muted, fontSize = 12.sp)
                    }
                }
                AdventureProgress(progress = progress, fill = AdventureColors.Mint)
                Text(
                    if (combo > 1) "Current combo: x$combo" else "Build a combo by answering correctly.",
                    color = AdventureColors.Text,
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp,
                )
                AdventureGhostButton("Close", onClick = onClose, modifier = Modifier.fillMaxWidth())
            }
        }
    }
}

@Composable
private fun ArenaTimer(resetKey: Any) {
    var seconds by remember(resetKey) { mutableIntStateOf(0) }
    LaunchedEffect(resetKey) {
        seconds = 0
        while (true) {
            delay(1000)
            seconds += 1
        }
    }
    val mm = (seconds / 60).toString().padStart(2, '0')
    val ss = (seconds % 60).toString().padStart(2, '0')
    Text("$mm:$ss", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 13.sp)
}

@Composable
private fun CoachBubble(text: String) {
    Box(
        Modifier
            .clip(RoundedCornerShape(18.dp))
            .background(AdventureColors.Cream)
            .border(1.dp, Color(0xFFD5C4AD), RoundedCornerShape(18.dp))
            .padding(horizontal = 18.dp, vertical = 12.dp),
    ) {
        Text(text, color = AdventureColors.Ink, fontWeight = FontWeight.Bold, fontSize = 15.sp)
    }
}

@Composable
private fun QuestionCard(question: Question) {
    Box(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(AdventureColors.Cream)
            .border(2.dp, Color(0xFFE0D1BE), RoundedCornerShape(20.dp))
            .padding(18.dp),
    ) {
        Box(
            Modifier
                .align(Alignment.TopEnd)
                .clip(RoundedCornerShape(9.dp))
                .background(AdventureColors.Coral)
                .padding(horizontal = 10.dp, vertical = 5.dp),
        ) {
            Text("Trap", color = Color.White, fontWeight = FontWeight.Black, fontSize = 12.sp)
        }
        CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
            RichContent(
                blocks = question.stem,
                fontSize = 19.sp,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 30.dp),
            )
        }
    }
}

@Composable
private fun TrapHint(question: Question) {
    AdventurePanel(shape = RoundedCornerShape(14.dp), modifier = Modifier.fillMaxWidth(), borderColor = AdventureColors.Coral.copy(alpha = .38f)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.AutoAwesome, contentDescription = null, tint = AdventureColors.Coral, modifier = Modifier.size(24.dp))
            Spacer(Modifier.width(8.dp))
            Text(
                text = if (question.shortcut != null) "Trap Hint: A shortcut exists here." else "Trap Hint: Check the structure before expanding.",
                color = AdventureColors.Text,
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp,
                modifier = Modifier.weight(1f),
            )
        }
    }
}

@Composable
private fun AnswerGrid(
    question: Question,
    attempt: com.gauss.app.data.AttemptResult?,
    pendingOption: Int?,
    onPick: (Int) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        question.optionBlocks.withIndex().chunked(2).forEach { row ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                row.forEach { (index, blocks) ->
                    val state = when {
                        attempt != null && index == question.correctOptionIndex -> TileState.Correct
                        attempt != null && attempt.selectedOption == index && attempt.status == AttemptStatus.WRONG -> TileState.Wrong
                        attempt == null && pendingOption == index -> TileState.Selected
                        else -> TileState.Idle
                    }
                    AnswerTileFrame(
                        label = ('A' + index).toString(),
                        state = state,
                        onClick = { onPick(index) },
                        enabled = attempt == null,
                        modifier = Modifier.weight(1f),
                    ) {
                        CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
                            RichContent(blocks = blocks, fontSize = 17.sp)
                        }
                    }
                }
                if (row.size == 1) Spacer(Modifier.weight(1f))
            }
        }
    }
}

private fun arenaActionText(examVm: ExamViewModel, attempt: com.gauss.app.data.AttemptResult?): String =
    when {
        examVm.saving -> "Saving..."
        attempt == null -> "Check Answer"
        examVm.isLast -> "Claim Rewards"
        else -> "Next"
    }

private fun comboCount(examVm: ExamViewModel): Int {
    var combo = 0
    for (i in 0..examVm.index) {
        val attempt = examVm.attempts[i] ?: continue
        if (attempt.status == AttemptStatus.CORRECT) combo += 1 else combo = 0
    }
    return combo
}

private fun roadTitle(subject: Subject): String = if (subject == Subject.MATH) "Algebra Grove" else "Physics Workshop"

@Composable
fun AdventureRewardScreen(nav: NavController, examVm: ExamViewModel) {
    val events = remember { AdventureRewardRules.previewRewardEvents() }
    val reward = remember { AdventureRewardRules.summarize(events) }
    val missionMeta = remember { events.firstOrNull { it.missionId != null && it.metadata.isNotEmpty() }?.metadata.orEmpty() }
    var claimed by remember(reward.id) { mutableStateOf(false) }
    val backToMap = {
        examVm.reset()
        nav.openTab(AdventureTab.MAP)
    }

    AdventureScreen(includeBottomPadding = false) {
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 14.dp)
                .padding(bottom = 14.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            ScreenTitle("Reward Vault", "Claim your mission haul before returning to the map.")
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(250.dp)
                    .clip(RoundedCornerShape(22.dp))
                    .background(Brush.verticalGradient(listOf(Color(0xFF08313B), Color(0xFF0D4C55))))
                    .border(1.dp, AdventureColors.BorderSoft, RoundedCornerShape(22.dp)),
            ) {
                ConfettiLayer(Modifier.matchParentSize())
                Box(
                    Modifier
                        .align(Alignment.TopCenter)
                        .padding(top = 14.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(Brush.horizontalGradient(listOf(Color(0xFF5C3216), Color(0xFFB66C24), Color(0xFF5C3216))))
                        .border(1.dp, AdventureColors.GoldBright.copy(alpha = .65f), RoundedCornerShape(12.dp))
                        .padding(horizontal = 18.dp, vertical = 8.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Text("Mission Complete!", color = AdventureColors.GoldBright, fontWeight = FontWeight.Black, fontSize = 22.sp)
                }
                VaultDoor(
                    modifier = Modifier
                        .align(Alignment.CenterEnd)
                        .padding(top = 28.dp, end = 8.dp)
                        .fillMaxWidth(.68f)
                        .fillMaxHeight(.78f),
                    open = true,
                )
                MascotPortrait(
                    size = 112.dp,
                    modifier = Modifier
                        .align(Alignment.BottomStart)
                        .padding(start = 24.dp, bottom = 12.dp),
                )
            }

            AdventurePanel(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(20.dp), borderColor = AdventureColors.Gold.copy(alpha = .55f)) {
                Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("XP Earned", color = AdventureColors.GoldBright, fontWeight = FontWeight.Black, fontSize = 13.sp)
                    Text("+${reward.xpTotal} XP", color = AdventureColors.GoldBright, fontWeight = FontWeight.Black, fontSize = 30.sp)
                    Spacer(Modifier.height(10.dp))
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        RewardStat("Combo Bonus", "x${missionMeta["combo"] ?: "4"}", AdventureColors.Lavender, Modifier.weight(1f))
                        RewardStat("Accuracy", "${missionMeta["accuracy"] ?: "93"}%", AdventureColors.Mint, Modifier.weight(1f))
                        RewardStat("Focus Left", "+${reward.focusDelta}", AdventureColors.GoldBright, Modifier.weight(1f))
                    }
                }
            }

            RewardQuestRow()
            RewardFoundPanel(
                coins = reward.coins,
                gems = reward.gems,
                gearCount = reward.gearDrops.size,
            )

            AdventureButton(
                text = if (claimed) "Rewards Claimed" else "Claim Rewards",
                onClick = { claimed = true },
                enabled = !claimed,
                modifier = Modifier.fillMaxWidth(),
            )
            AdventureGhostButton("Back to Map", onClick = backToMap, modifier = Modifier.fillMaxWidth())
        }
    }
}

@Composable
private fun RewardVaultHub(nav: NavController) {
    AdventureScreen {
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 14.dp)
                .padding(bottom = 92.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text("Reward Vault", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 22.sp)
            Box(Modifier.fillMaxWidth().height(250.dp)) {
                VaultDoor(Modifier.align(Alignment.Center).fillMaxWidth(.88f).fillMaxHeight(), open = false)
                MascotPortrait(Modifier.align(Alignment.BottomStart).offset(x = 18.dp), size = 98.dp)
            }
            AdventurePanel(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(20.dp), borderColor = AdventureColors.Gold.copy(alpha = .44f)) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                    Text("No rewards waiting", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 20.sp)
                    Text("Clear an arena mission to open the vault.", color = AdventureColors.Muted, fontSize = 13.sp, textAlign = TextAlign.Center)
                }
            }
            AdventureButton("Start a Mission", onClick = { nav.openTab(AdventureTab.MISSIONS) }, icon = Icons.Rounded.Star, modifier = Modifier.fillMaxWidth())
        }
        AdventureBottomNav(AdventureTab.REWARDS, { nav.openTab(it) }, Modifier.align(Alignment.BottomCenter))
    }
}

@Composable
private fun RewardStat(label: String, value: String, color: Color, modifier: Modifier = Modifier) {
    Column(
        modifier
            .clip(RoundedCornerShape(14.dp))
            .background(color.copy(alpha = .14f))
            .border(1.dp, color.copy(alpha = .45f), RoundedCornerShape(14.dp))
            .padding(vertical = 12.dp, horizontal = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(label, color = AdventureColors.Muted, fontSize = 11.sp, textAlign = TextAlign.Center)
        Text(value, color = color, fontWeight = FontWeight.Black, fontSize = 22.sp, textAlign = TextAlign.Center)
    }
}

@Composable
private fun RewardQuestRow() {
    AdventurePanel(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(18.dp), borderColor = AdventureColors.Mint.copy(alpha = .42f)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.TrackChanges, contentDescription = null, tint = AdventureColors.Coral, modifier = Modifier.size(38.dp))
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text("Daily Quest", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 14.sp)
                Text("Beat 2 trap questions", color = AdventureColors.Muted, fontSize = 12.sp)
                Spacer(Modifier.height(7.dp))
                AdventureProgress(progress = 1f, fill = AdventureColors.Mint, height = 7.dp)
            }
            Spacer(Modifier.width(10.dp))
            Column(horizontalAlignment = Alignment.End) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Rounded.Check, contentDescription = null, tint = AdventureColors.Mint, modifier = Modifier.size(24.dp))
                    Spacer(Modifier.width(5.dp))
                    Text("+${AdventureRewardRules.DAILY_TRAP_REWARD_XP} XP", color = AdventureColors.GoldBright, fontWeight = FontWeight.Black, fontSize = 14.sp)
                }
                Text("${AdventureRewardRules.DAILY_TRAP_TARGET}/${AdventureRewardRules.DAILY_TRAP_TARGET}", color = AdventureColors.Muted, fontSize = 11.sp)
            }
        }
    }
}

@Composable
private fun RewardFoundPanel(
    coins: Int,
    gems: Int,
    gearCount: Int,
) {
    AdventurePanel(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(18.dp), borderColor = AdventureColors.Gold.copy(alpha = .42f)) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("You Found", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 14.sp)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                MiniCoin(Icons.Rounded.Paid, "Coins", "+$coins", AdventureColors.GoldBright, Modifier.weight(1f))
                MiniCoin(Icons.Rounded.Diamond, "Gems", "+$gems", AdventureColors.Physics, Modifier.weight(1f))
                Column(
                    Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(15.dp))
                        .background(AdventureColors.PanelDark.copy(alpha = .72f))
                        .border(1.dp, AdventureColors.Gold.copy(alpha = .50f), RoundedCornerShape(15.dp))
                        .padding(10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Icon(Icons.Rounded.Inventory2, contentDescription = null, tint = AdventureColors.GoldBright, modifier = Modifier.size(42.dp))
                    Text("Common", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 12.sp)
                    Text("$gearCount Gear", color = AdventureColors.Muted, fontSize = 11.sp)
                }
            }
        }
    }
}

@Composable
fun AdventureProfileScreen(nav: NavController, examVm: ExamViewModel) {
    val context = LocalContext.current
    val app = remember(context) { GaussApp.from(context) }
    val launcher = rememberMissionLauncher(nav, examVm)
    var summary by remember { mutableStateOf<GamificationSummary?>(null) }
    var analytics by remember { mutableStateOf<Analytics?>(null) }
    var revengeCount by remember { mutableIntStateOf(8) }
    var selectedTab by remember { mutableStateOf("Mastery") }
    var shopOpen by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        summary = app.gamification.summary()
        analytics = app.history.analytics()
        revengeCount = app.history.revengeIds().size.takeIf { it > 0 } ?: 8
    }

    AdventureScreen {
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 14.dp)
                .padding(bottom = 92.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            ScreenTitle("My Profile", "Explorer progress, mastery, badges, and league.")
            ProfileHeader(summary)
            ProfileTabs(selectedTab, onSelect = { selectedTab = it })
            when (selectedTab) {
                "Stats" -> ProfileStatsPanel(analytics)
                "Badges" -> ProfileBadgesDetailPanel()
                "League" -> ProfileLeaguePanel()
                else -> {
                    BrainMapPanel(analytics)
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        WeakTopicsPanel(analytics, Modifier.weight(1f))
                        RevengeQueuePanel(revengeCount, launcher, Modifier.weight(1f))
                    }
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        BadgeWallPanel(Modifier.weight(1f), onViewAll = { selectedTab = "Badges" })
                        CosmeticsPanel(Modifier.weight(1f), onShop = { shopOpen = true })
                    }
                }
            }
            OfflineStatusPanel()
        }
        AdventureBottomNav(AdventureTab.PROFILE, { nav.openTab(it) }, Modifier.align(Alignment.BottomCenter))
        if (shopOpen) {
            CosmeticsShopOverlay(onClose = { shopOpen = false })
        }
    }
}

@Composable
private fun ProfileHeader(summary: GamificationSummary?) {
    val level = AdventureLevelCurve.previewSnapshot()
    AdventurePanel(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(20.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            MascotPortrait(size = 78.dp, badge = true)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text("Explorer Gauss", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 17.sp)
                Text("Level ${level.level}", color = AdventureColors.Text, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                Spacer(Modifier.height(8.dp))
                AdventureProgress(level.progress)
                Text(level.display, color = AdventureColors.Muted, fontSize = 11.sp)
                if (summary != null) {
                    Text("${summary.todayXp} XP today", color = AdventureColors.Mint, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                }
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(Icons.Rounded.Shield, contentDescription = null, tint = Color(0xFFC8D2DB), modifier = Modifier.size(56.dp))
                Text("Silver I", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 13.sp)
                Text("Top 48%", color = AdventureColors.Muted, fontSize = 11.sp)
            }
        }
    }
}

@Composable
private fun ProfileTabs(selected: String, onSelect: (String) -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(AdventureColors.PanelDark.copy(alpha = .88f))
            .border(1.dp, AdventureColors.BorderSoft, RoundedCornerShape(16.dp))
            .padding(4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        listOf("Mastery", "Stats", "Badges", "League").forEach { tab ->
            val active = selected == tab
            Box(
                Modifier
                    .weight(1f)
                    .height(36.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(if (active) AdventureColors.Reef.copy(alpha = .95f) else Color.Transparent)
                    .border(if (active) 1.dp else 0.dp, if (active) AdventureColors.Physics.copy(alpha = .58f) else Color.Transparent, RoundedCornerShape(12.dp))
                    .adventurePress { onSelect(tab) },
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    tab,
                    color = if (active) AdventureColors.Text else AdventureColors.Muted,
                    fontWeight = FontWeight.Black,
                    fontSize = 12.sp,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}

@Composable
private fun BrainMapPanel(analytics: Analytics?) {
    AdventurePanel(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(18.dp)) {
        Column {
            Text("Brain Map", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 15.sp)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(.82f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    BrainStat("Algebra", scoreFor(analytics, Subject.MATH, 78), AdventureColors.Math)
                    BrainStat("Calculus", scoreFor(analytics, Subject.MATH, 72), AdventureColors.Lavender)
                    BrainStat("Geometry", scoreFor(analytics, Subject.MATH, 64), AdventureColors.Mint)
                }
                BrainNebula(Modifier.weight(1f).aspectRatio(1.12f))
                Column(Modifier.weight(.95f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    BrainStat("Physics", scoreFor(analytics, Subject.PHYSICS, 69), AdventureColors.Physics)
                    BrainStat("Mechanics", scoreFor(analytics, Subject.PHYSICS, 62), AdventureColors.Mint)
                    BrainStat("Electromag.", scoreFor(analytics, Subject.PHYSICS, 55), AdventureColors.Gold)
                }
            }
        }
    }
}

@Composable
private fun BrainStat(label: String, score: Int, color: Color) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(28.dp).clip(CircleShape).background(color.copy(alpha = .18f)), contentAlignment = Alignment.Center) {
            Icon(Icons.Rounded.AutoAwesome, contentDescription = null, tint = color, modifier = Modifier.size(17.dp))
        }
        Spacer(Modifier.width(7.dp))
        Column {
            Text(label, color = AdventureColors.Text, fontWeight = FontWeight.Bold, fontSize = 11.sp)
            Text("$score%", color = AdventureColors.Mint, fontWeight = FontWeight.Black, fontSize = 11.sp)
        }
    }
}

private fun scoreFor(analytics: Analytics?, subject: Subject, fallback: Int): Int {
    val matching = analytics?.weakTopics?.filter { it.subject == subject }
    val value = matching?.takeIf { it.isNotEmpty() }?.map { it.accuracy }?.average()
    return value?.roundToInt()?.coerceIn(0, 100) ?: fallback
}

@Composable
private fun WeakTopicsPanel(analytics: Analytics?, modifier: Modifier = Modifier) {
    val weak = analytics?.weakTopics?.take(3).orEmpty()
    AdventurePanel(modifier = modifier.heightIn(min = 138.dp), shape = RoundedCornerShape(16.dp)) {
        Column {
            Text("Weak Topics", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 14.sp)
            val rows = if (weak.isEmpty()) {
                listOf("Sequences & Series" to 28, "Limits" to 34, "Rotational Dynamics" to 42)
            } else {
                weak.map { ComprehensiveTaxonomy.label(it.chapter) to it.accuracy.roundToInt() }
            }
            rows.forEach { (label, value) ->
                Spacer(Modifier.height(7.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text(label, color = AdventureColors.Muted, fontSize = 11.sp, maxLines = 1)
                    Text("$value%", color = AdventureColors.Muted, fontSize = 11.sp)
                }
                AdventureProgress(value / 100f, fill = AdventureColors.Coral, height = 5.dp)
            }
        }
    }
}

@Composable
private fun RevengeQueuePanel(count: Int, launcher: MissionLauncher, modifier: Modifier = Modifier) {
    AdventurePanel(modifier = modifier.heightIn(min = 138.dp), shape = RoundedCornerShape(16.dp)) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("Revenge Queue", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 14.sp, modifier = Modifier.align(Alignment.Start))
            Text("$count questions", color = AdventureColors.Muted, fontSize = 12.sp, modifier = Modifier.align(Alignment.Start))
            Spacer(Modifier.height(10.dp))
            Icon(Icons.Rounded.TrackChanges, contentDescription = null, tint = AdventureColors.Coral, modifier = Modifier.size(46.dp))
            Spacer(Modifier.height(10.dp))
            AdventureGhostButton("Go Revive", onClick = launcher.startRevenge, modifier = Modifier.fillMaxWidth())
        }
    }
}

@Composable
private fun BadgeWallPanel(modifier: Modifier = Modifier, onViewAll: () -> Unit = {}) {
    val badges = AdventureAchievementCatalog.featuredBadgeWall.take(5)
    AdventurePanel(modifier = modifier.heightIn(min = 142.dp), shape = RoundedCornerShape(16.dp)) {
        Column {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("Badge Wall", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 14.sp)
                Text("${AdventureAchievementCatalog.unlockedPreviewCount()} / ${AdventureAchievementCatalog.totalFeaturedBadgeCount()}", color = AdventureColors.Muted, fontSize = 11.sp)
            }
            Spacer(Modifier.height(12.dp))
            Row(
                Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                badges.forEachIndexed { index, badge ->
                    BadgeIcon(index, badgeColor(index))
                }
            }
            Spacer(Modifier.height(10.dp))
            AdventureGhostButton("View all", onClick = onViewAll, modifier = Modifier.fillMaxWidth())
        }
    }
}

private fun badgeColor(index: Int): Color =
    listOf(AdventureColors.Physics, AdventureColors.Coral, AdventureColors.Math, AdventureColors.Lavender, AdventureColors.Gold)[index % 5]

@Composable
private fun BadgeIcon(index: Int, color: Color, modifier: Modifier = Modifier) {
    Box(
        modifier
            .size(44.dp)
            .clip(RoundedCornerShape(13.dp))
            .background(color.copy(alpha = .20f))
            .border(2.dp, color.copy(alpha = .82f), RoundedCornerShape(13.dp)),
        contentAlignment = Alignment.Center,
    ) {
        Icon(if (index % 2 == 0) Icons.Rounded.MilitaryTech else Icons.Rounded.AutoAwesome, contentDescription = null, tint = color, modifier = Modifier.size(27.dp))
    }
}

@Composable
private fun CosmeticsPanel(modifier: Modifier = Modifier, onShop: () -> Unit) {
    AdventurePanel(modifier = modifier.heightIn(min = 142.dp), shape = RoundedCornerShape(16.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text("Cosmetics Shop", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 14.sp)
                Text("New items!", color = AdventureColors.Muted, fontSize = 11.sp)
                Spacer(Modifier.height(18.dp))
                AdventureGhostButton("Shop", onClick = onShop, modifier = Modifier.width(88.dp), icon = Icons.Rounded.ShoppingBag)
            }
            MascotPortrait(size = 76.dp)
        }
    }
}

@Composable
private fun ProfileStatsPanel(analytics: Analytics?) {
    AdventurePanel(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(18.dp)) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("Stats", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 16.sp)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                RewardStat("Answered", "${analytics?.totalAnswered ?: 0}", AdventureColors.Physics, Modifier.weight(1f))
                RewardStat("Accuracy", "${analytics?.accuracy?.roundToInt() ?: 93}%", AdventureColors.Mint, Modifier.weight(1f))
                RewardStat("Streak", "${analytics?.streak ?: 12}d", AdventureColors.GoldBright, Modifier.weight(1f))
            }
            Text("Average time: ${analytics?.avgTime?.roundToInt() ?: 45}s", color = AdventureColors.Muted, fontWeight = FontWeight.Bold, fontSize = 12.sp)
        }
    }
}

@Composable
private fun ProfileBadgesDetailPanel() {
    AdventurePanel(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(18.dp)) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("Badges", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 16.sp)
                Text("${AdventureAchievementCatalog.achievements.size} total", color = AdventureColors.Muted, fontSize = 12.sp)
            }
            AdventureAchievementCatalog.featuredBadgeWall.chunked(4).forEach { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    row.forEachIndexed { index, _ ->
                        BadgeIcon(index, badgeColor(index), modifier = Modifier.weight(1f))
                    }
                    repeat(4 - row.size) { Spacer(Modifier.weight(1f)) }
                }
            }
        }
    }
}

@Composable
private fun ProfileLeaguePanel() {
    AdventurePanel(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(18.dp), borderColor = Color(0xFFC8D2DB).copy(alpha = .52f)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.Shield, contentDescription = null, tint = Color(0xFFC8D2DB), modifier = Modifier.size(72.dp))
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text("Silver I", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 20.sp)
                Text("Top 48%", color = AdventureColors.Muted, fontSize = 13.sp)
                Spacer(Modifier.height(10.dp))
                AdventureProgress(.48f, fill = Color(0xFFC8D2DB), height = 8.dp)
                Text("Keep climbing with clean missions.", color = AdventureColors.Mint, fontWeight = FontWeight.Bold, fontSize = 12.sp)
            }
        }
    }
}

@Composable
private fun CosmeticsShopOverlay(onClose: () -> Unit) {
    Box(
        Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = .58f))
            .padding(24.dp),
        contentAlignment = Alignment.Center,
    ) {
        AdventurePanel(shape = RoundedCornerShape(20.dp), modifier = Modifier.fillMaxWidth()) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                MascotPortrait(size = 92.dp)
                Text("Cosmetics Shop", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 20.sp)
                Text("Explorer wand, star cloak, and vault key cosmetics are preview-ready.", color = AdventureColors.Muted, fontSize = 13.sp, textAlign = TextAlign.Center)
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    RewardStat("Coins", "120", AdventureColors.GoldBright, Modifier.weight(1f))
                    RewardStat("Gems", "2", AdventureColors.Physics, Modifier.weight(1f))
                }
                AdventureGhostButton("Close", onClick = onClose, modifier = Modifier.fillMaxWidth())
            }
        }
    }
}

@Composable
private fun OfflineStatusPanel() {
    AdventurePanel(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), borderColor = AdventureColors.Mint.copy(alpha = .42f)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.Wifi, contentDescription = null, tint = AdventureColors.Mint, modifier = Modifier.size(30.dp))
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text("You're offline-ready", color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 13.sp)
                Text("All progress is saved locally.", color = AdventureColors.Muted, fontSize = 12.sp)
            }
            Box(Modifier.size(34.dp).clip(CircleShape).background(AdventureColors.MintDark), contentAlignment = Alignment.Center) {
                Icon(Icons.Rounded.Check, contentDescription = "Saved locally", tint = Color.White, modifier = Modifier.size(22.dp))
            }
        }
    }
}

@Composable
private fun AdventureEmptyState(
    selected: AdventureTab,
    nav: NavController,
    title: String,
    body: String,
    action: String,
    onAction: () -> Unit,
) {
    AdventureScreen {
        Column(
            Modifier
                .fillMaxSize()
                .padding(horizontal = 18.dp)
                .padding(bottom = 92.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            MascotPortrait(size = 110.dp, badge = true)
            Spacer(Modifier.height(18.dp))
            Text(title, color = AdventureColors.Text, fontWeight = FontWeight.Black, fontSize = 24.sp, textAlign = TextAlign.Center)
            Text(body, color = AdventureColors.Muted, fontSize = 14.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(vertical = 12.dp))
            AdventureButton(action, onAction, modifier = Modifier.fillMaxWidth())
        }
        AdventureBottomNav(selected, { nav.openTab(it) }, Modifier.align(Alignment.BottomCenter))
    }
}

private fun NavController.openTab(tab: AdventureTab) {
    val route = when (tab) {
        AdventureTab.MAP -> Routes.MAP
        AdventureTab.MISSIONS -> Routes.MISSIONS
        AdventureTab.REWARDS -> Routes.REWARD
        AdventureTab.PROFILE -> Routes.PROFILE
    }
    navigate(route) {
        popUpTo(Routes.MAP) { saveState = true }
        launchSingleTop = true
        restoreState = true
    }
}
