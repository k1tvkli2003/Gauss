package com.gauss.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.gauss.app.GaussApp
import com.gauss.app.data.ComprehensiveTaxonomy
import com.gauss.app.data.Difficulty
import com.gauss.app.data.ExamConfig
import com.gauss.app.data.QuestionBank
import com.gauss.app.data.SourceBank
import com.gauss.app.data.Subject
import com.gauss.app.data.TopicDef
import com.gauss.app.ui.exam.ExamViewModel
import com.gauss.app.ui.components.GaussButton
import com.gauss.app.ui.components.GaussMentorAvatar
import com.gauss.app.ui.components.clickableNoRipple
import com.gauss.app.ui.nav.Routes
import com.gauss.app.ui.theme.GaussColors
import com.gauss.app.ui.theme.soft
import com.gauss.app.ui.toFa
import kotlinx.coroutines.launch

@Composable
fun SetupScreen(
    nav: NavController,
    examVm: ExamViewModel,
    presetSubject: String?,
    presetTopic: String?,
) {
    val app = GaussApp.from(androidx.compose.ui.platform.LocalContext.current)
    val scope = rememberCoroutineScope()
    var subject by remember { mutableStateOf(Subject.from(presetSubject)) }
    val selectedTopics = remember { mutableStateListOf<String>().also { presetTopic?.let(it::add) } }
    val selectedDifficulties = remember { mutableStateListOf<Difficulty>() }
    var sourceMode by remember { mutableStateOf("all") }
    var questionCount by remember { mutableIntStateOf(20) }
    var bank by remember { mutableStateOf<QuestionBank?>(null) }
    var loadError by remember { mutableStateOf<String?>(null) }
    var loadAttempt by remember { mutableIntStateOf(0) }
    var availability by remember { mutableStateOf<Map<String, Int>>(emptyMap()) }
    var busy by remember { mutableStateOf(false) }
    val scheme = MaterialTheme.colorScheme
    val topics = remember(subject) { ComprehensiveTaxonomy.topicsFor(subject) }

    LaunchedEffect(loadAttempt) {
        loadError = null
        runCatching { app.questionBank() }
            .onSuccess { loaded ->
                bank = loaded
                loadError = null
            }
            .onFailure { loadError = "بانک سؤال آماده نشد. فایل‌های سؤال را چک کن و دوباره تلاش کن." }
    }
    LaunchedEffect(bank, subject) {
        availability = bank?.topicAvailability(subject).orEmpty()
        selectedTopics.retainAll(topics.map { it.key }.toSet())
    }

    val available = if (selectedTopics.isEmpty()) availability.values.sum() else selectedTopics.sumOf { availability[it] ?: 0 }
    val sources = when (sourceMode) {
        "nardebam" -> listOf(SourceBank.NARDEBAM)
        "gauss" -> listOf(SourceBank.GAUSS)
        else -> emptyList()
    }

    Box(Modifier.fillMaxSize().background(scheme.background)) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = 20.dp, bottom = 112.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            item {
                PathHero(
                    subject = subject,
                    available = available,
                    selectedCount = selectedTopics.size,
                )
                SegmentedSubject(subject) { next ->
                    subject = next
                    selectedTopics.clear()
                }
                SectionLabel("بانک سؤال")
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("all" to "همه", "nardebam" to "نردبام", "gauss" to "Gauss").forEach { (key, label) ->
                        FilterChip(selected = sourceMode == key, onClick = { sourceMode = key }, label = { Text(label) })
                    }
                }
                Row(
                    Modifier.fillMaxWidth().padding(top = 14.dp, bottom = 2.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("${toFa(available)} سؤال در دسترس", color = scheme.primary, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                    Text("مسیر فصل‌ها", color = scheme.onSurface, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                }
                if (loadError != null) {
                    LoadErrorCard(loadError.orEmpty()) { loadAttempt += 1 }
                } else if (bank == null) {
                    LoadingBankCard()
                }
            }

            itemsIndexed(topics, key = { _, topic -> topic.key }) { index, topic ->
                TopicPathNode(
                    topic = topic,
                    count = availability[topic.key] ?: 0,
                    selected = topic.key in selectedTopics,
                    isFirst = index == 0,
                    isLast = index == topics.lastIndex,
                    onClick = {
                        if (topic.key in selectedTopics) selectedTopics.remove(topic.key) else selectedTopics.add(topic.key)
                    },
                )
            }

            item {
                SectionLabel("سختی")
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Difficulty.entries.forEach { difficulty ->
                        FilterChip(
                            selected = difficulty in selectedDifficulties,
                            onClick = {
                                if (difficulty in selectedDifficulties) selectedDifficulties.remove(difficulty) else selectedDifficulties.add(difficulty)
                            },
                            label = { Text(difficulty.faLabel, fontSize = 11.sp) },
                        )
                    }
                }
                SectionLabel("تعداد سؤال")
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf(10, 20, 30, 50).forEach { count ->
                        FilterChip(
                            selected = questionCount == count,
                            onClick = { questionCount = count },
                            label = { Text(toFa(count)) },
                        )
                    }
                }
            }
        }

        Surface(
            modifier = Modifier.align(Alignment.BottomCenter).fillMaxWidth(),
            color = scheme.surface,
            shadowElevation = 8.dp,
        ) {
            val startText = when {
                busy -> "داریم درس را می‌سازیم…"
                bank == null && loadError == null -> "در حال آماده‌سازی بانک سؤال…"
                available == 0 -> "برای این مسیر سؤال آماده نیست"
                else -> "شروع درس ${toFa(minOf(questionCount, available))} سؤالی"
            }
            GaussButton(
                text = startText,
                onClick = start@{
                    val currentBank = bank ?: return@start
                    if (busy || available == 0) return@start
                    busy = true
                    scope.launch {
                        val config = ExamConfig(
                            subject = subject,
                            topicKeys = selectedTopics.toList(),
                            sourceBanks = sources,
                            difficulties = selectedDifficulties.toList(),
                            count = minOf(questionCount, available),
                        )
                        val questions = currentBank.selectExam(config)
                        if (questions.isNotEmpty()) {
                            examVm.startExam(config.copy(count = questions.size), questions)
                            nav.navigate(Routes.SESSION)
                        }
                        busy = false
                    }
                },
                enabled = bank != null && available > 0 && !busy,
                loading = busy,
                icon = Icons.Rounded.PlayArrow,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 14.dp).height(52.dp),
            )
        }
    }
}

@Composable
private fun PathHero(subject: Subject, available: Int, selectedCount: Int) {
    val scheme = MaterialTheme.colorScheme
    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(26.dp))
            .background(subject.color.soft(0.12f))
            .border(1.dp, subject.color.soft(0.52f), RoundedCornerShape(26.dp))
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Column(Modifier.weight(1f), horizontalAlignment = Alignment.End) {
            Text(
                "مسیر ${subject.faLabel}",
                color = scheme.onBackground,
                fontSize = 24.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.End,
                modifier = Modifier.fillMaxWidth(),
            )
            Text(
                "هر گره یک درس کوتاه است؛ فصل‌های آماده را روشن کن و با یک درس فشرده جلو برو.",
                color = scheme.onSurfaceVariant,
                fontSize = 13.sp,
                textAlign = TextAlign.End,
                modifier = Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 12.dp),
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                PathMetric("انتخاب", toFa(selectedCount), GaussColors.Secondary)
                PathMetric("بانک", toFa(available), subject.color)
            }
        }
        GaussMentorAvatar(size = 78.dp)
    }
}

@Composable
private fun PathMetric(label: String, value: String, color: Color) {
    Column(
        Modifier
            .clip(RoundedCornerShape(14.dp))
            .background(color.soft(0.13f))
            .border(1.dp, color.soft(0.48f), RoundedCornerShape(14.dp))
            .padding(horizontal = 12.dp, vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(value, color = color, fontWeight = FontWeight.Black, fontSize = 16.sp)
        Text(label, color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 11.sp)
    }
}

@Composable
private fun LoadErrorCard(message: String, onRetry: () -> Unit) {
    val scheme = MaterialTheme.colorScheme
    Row(
        Modifier
            .fillMaxWidth()
            .padding(top = 8.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(scheme.error.soft(0.10f))
            .border(1.dp, scheme.error.soft(0.55f), RoundedCornerShape(16.dp))
            .padding(14.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier
                .clip(RoundedCornerShape(12.dp))
                .background(scheme.error)
                .clickableNoRipple { onRetry() }
                .padding(horizontal = 12.dp, vertical = 9.dp),
        ) {
            Text("تلاش دوباره", color = scheme.onError, fontWeight = FontWeight.Black, fontSize = 12.sp)
        }
        Text(
            message,
            color = scheme.error,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.End,
            modifier = Modifier.weight(1f).padding(start = 12.dp),
        )
    }
}

@Composable
private fun LoadingBankCard() {
    val scheme = MaterialTheme.colorScheme
    Box(
        Modifier
            .fillMaxWidth()
            .padding(top = 8.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(scheme.surfaceVariant)
            .border(1.dp, scheme.outline, RoundedCornerShape(16.dp))
            .padding(14.dp),
    ) {
        Text(
            "در حال آماده‌سازی بانک سؤال…",
            color = scheme.onSurfaceVariant,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.End,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

@Composable
private fun SegmentedSubject(selected: Subject, onSelect: (Subject) -> Unit) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Subject.entries.forEach { subject ->
            val active = selected == subject
            Box(
                Modifier.weight(1f).height(48.dp).clip(RoundedCornerShape(12.dp))
                    .background(if (active) subject.color.copy(alpha = 0.16f) else MaterialTheme.colorScheme.surface)
                    .border(1.dp, if (active) subject.color else MaterialTheme.colorScheme.outline, RoundedCornerShape(12.dp))
                    .clickableNoRipple { onSelect(subject) },
                contentAlignment = Alignment.Center,
            ) { Text(subject.faLabel, color = if (active) subject.color else MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold) }
        }
    }
}

@Composable
private fun TopicPathNode(
    topic: TopicDef,
    count: Int,
    selected: Boolean,
    isFirst: Boolean,
    isLast: Boolean,
    onClick: () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    val accent = if (topic.subject == Subject.MATH) GaussColors.Math else GaussColors.Physics
    val ready = count > 0
    val checkpoint = topic.order % 5 == 0
    val leansRight = topic.order % 2 == 1
    val nodeColor = when {
        selected -> accent
        ready -> scheme.surface
        else -> scheme.surfaceVariant
    }
    Row(
        Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
    ) {
        if (!leansRight) Spacer(Modifier.weight(0.14f))
        Row(
            Modifier
                .weight(0.86f)
                .clip(RoundedCornerShape(24.dp))
                .background(if (selected) accent.soft(0.13f) else scheme.surface)
                .border(1.dp, if (selected) accent else scheme.outline, RoundedCornerShape(24.dp))
                .clickableNoRipple(ready) { onClick() }
                .padding(horizontal = 14.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Column(horizontalAlignment = Alignment.Start) {
                Text("${toFa(count)} سؤال", color = if (ready) accent else scheme.onSurfaceVariant, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                Text(
                    when {
                        selected -> "روشن شد"
                        ready -> "برای تمرین آماده"
                        else -> "فعلاً قفل است"
                    },
                    color = scheme.onSurfaceVariant,
                    fontSize = 11.sp,
                )
            }
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Column(horizontalAlignment = Alignment.End) {
                    Text(topic.faLabel, color = scheme.onSurface, fontWeight = FontWeight.Black, textAlign = TextAlign.End)
                    Text(
                        if (checkpoint) "ایستگاه جایزه ${toFa(topic.order)}" else "مرحله ${toFa(topic.order)}",
                        color = scheme.onSurfaceVariant,
                        fontSize = 11.sp,
                    )
                }
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    ConnectorLine(visible = !isFirst, color = if (selected) accent else scheme.outline)
                    Box(
                        Modifier.size(if (checkpoint) 56.dp else 50.dp).clip(CircleShape)
                            .background(nodeColor)
                            .border(2.dp, if (selected) accent else scheme.outline, CircleShape),
                        contentAlignment = Alignment.Center,
                    ) {
                        when {
                            selected -> Icon(Icons.Rounded.Check, contentDescription = null, tint = scheme.onPrimary, modifier = Modifier.size(24.dp))
                            !ready -> Icon(Icons.Rounded.Lock, contentDescription = null, tint = scheme.onSurfaceVariant, modifier = Modifier.size(21.dp))
                            checkpoint -> Icon(Icons.Rounded.EmojiEvents, contentDescription = null, tint = accent, modifier = Modifier.size(24.dp))
                            else -> Text(toFa(topic.order), color = accent, fontWeight = FontWeight.Black)
                        }
                    }
                    ConnectorLine(visible = !isLast, color = scheme.outline)
                }
            }
        }
        if (leansRight) Spacer(Modifier.weight(0.14f))
    }
}

@Composable
private fun ConnectorLine(visible: Boolean, color: Color) {
    Box(
        Modifier
            .size(width = 5.dp, height = 14.dp)
            .clip(CircleShape)
            .background(if (visible) color.copy(alpha = 0.52f) else Color.Transparent),
    )
}

@Composable
private fun SectionLabel(text: String) {
    Text(text, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold, fontSize = 15.sp, modifier = Modifier.fillMaxWidth().padding(top = 18.dp, bottom = 6.dp))
}
