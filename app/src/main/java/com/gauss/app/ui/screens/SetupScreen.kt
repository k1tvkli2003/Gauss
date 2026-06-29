package com.gauss.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.EmojiEvents
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
    var availability by remember { mutableStateOf<Map<String, Int>>(emptyMap()) }
    var busy by remember { mutableStateOf(false) }
    val scheme = MaterialTheme.colorScheme

    LaunchedEffect(Unit) {
        runCatching { app.questionBank() }
            .onSuccess { loaded ->
                bank = loaded
                loadError = null
            }
            .onFailure { loadError = "بانک سؤال آماده نشد. دوباره وارد این صفحه شو." }
    }
    LaunchedEffect(bank, subject) {
        availability = bank?.topicAvailability(subject).orEmpty()
        selectedTopics.retainAll(ComprehensiveTaxonomy.topicsFor(subject).map { it.key }.toSet())
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
                Text("مسیر تمرین", fontSize = 25.sp, fontWeight = FontWeight.Black, color = scheme.onBackground, modifier = Modifier.fillMaxWidth())
                Text(
                    "اول درس را انتخاب کن، بعد از nodeهای مسیر یک یا چند مبحث را روشن کن.",
                    color = scheme.onSurfaceVariant,
                    fontSize = 13.sp,
                    modifier = Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 12.dp),
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
                    Text("مباحث جامع", color = scheme.onSurface, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                }
                if (loadError != null) {
                    Box(
                        Modifier
                            .fillMaxWidth()
                            .padding(top = 8.dp)
                            .clip(RoundedCornerShape(16.dp))
                            .background(scheme.error.soft(0.10f))
                            .border(1.dp, scheme.error.soft(0.55f), RoundedCornerShape(16.dp))
                            .padding(14.dp),
                    ) {
                        Text(loadError.orEmpty(), color = scheme.error, fontWeight = FontWeight.Bold, textAlign = TextAlign.End)
                    }
                }
            }

            items(ComprehensiveTaxonomy.topicsFor(subject), key = { it.key }) { topic ->
                TopicPathNode(
                    topic = topic,
                    count = availability[topic.key] ?: 0,
                    selected = topic.key in selectedTopics,
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
            GaussButton(
                text = if (busy) "در حال ساخت…" else "شروع تمرین ${toFa(minOf(questionCount, available))} سؤالی",
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
private fun SegmentedSubject(selected: Subject, onSelect: (Subject) -> Unit) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Subject.entries.forEach { subject ->
            val active = selected == subject
            Box(
                Modifier.weight(1f).height(48.dp).clip(RoundedCornerShape(12.dp))
                    .background(if (active) subject.color.copy(alpha = 0.16f) else MaterialTheme.colorScheme.surface)
                    .border(1.dp, if (active) subject.color else MaterialTheme.colorScheme.outline, RoundedCornerShape(12.dp))
                    .clickable { onSelect(subject) },
                contentAlignment = Alignment.Center,
            ) { Text(subject.faLabel, color = if (active) subject.color else MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold) }
        }
    }
}

@Composable
private fun TopicPathNode(topic: TopicDef, count: Int, selected: Boolean, onClick: () -> Unit) {
    val scheme = MaterialTheme.colorScheme
    val accent = if (topic.subject == Subject.MATH) GaussColors.Math else GaussColors.Physics
    val ready = count > 0
    val nodeColor = when {
        selected -> accent
        ready -> scheme.surface
        else -> scheme.surfaceVariant
    }
    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(22.dp))
            .background(if (selected) accent.soft(0.12f) else scheme.surface)
            .border(1.dp, if (selected) accent else scheme.outline, RoundedCornerShape(22.dp))
            .clickable(enabled = ready, onClick = onClick)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Column(horizontalAlignment = Alignment.Start) {
            Text("${toFa(count)} سؤال", color = if (ready) accent else scheme.onSurfaceVariant, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            Text(if (selected) "فعال" else if (ready) "آماده" else "خالی", color = scheme.onSurfaceVariant, fontSize = 11.sp)
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Column(horizontalAlignment = Alignment.End) {
                Text(topic.faLabel, color = scheme.onSurface, fontWeight = FontWeight.Bold, textAlign = TextAlign.End)
                Text("مرحله ${toFa(topic.order)}", color = scheme.onSurfaceVariant, fontSize = 11.sp)
            }
            Box(
                Modifier.size(46.dp).clip(CircleShape)
                    .background(nodeColor)
                    .border(2.dp, if (selected) accent else scheme.outline, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                if (selected) {
                    Icon(Icons.Rounded.Check, contentDescription = null, tint = scheme.onPrimary, modifier = Modifier.size(22.dp))
                } else if (topic.order % 5 == 0) {
                    Icon(Icons.Rounded.EmojiEvents, contentDescription = null, tint = accent, modifier = Modifier.size(22.dp))
                } else {
                    Text(toFa(topic.order), color = if (ready) accent else scheme.onSurfaceVariant, fontWeight = FontWeight.Black)
                }
            }
        }
    }
}

@Composable
private fun SectionLabel(text: String) {
    Text(text, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold, fontSize = 15.sp, modifier = Modifier.fillMaxWidth().padding(top = 18.dp, bottom = 6.dp))
}
