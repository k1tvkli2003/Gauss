package com.gauss.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.gauss.app.GaussApp
import com.gauss.app.data.Categories
import com.gauss.app.data.Difficulty
import com.gauss.app.data.ExamConfig
import com.gauss.app.data.QuestionBank
import com.gauss.app.data.Subject
import com.gauss.app.ui.components.Chip
import com.gauss.app.ui.components.clickableNoRipple
import com.gauss.app.ui.exam.ExamViewModel
import com.gauss.app.ui.nav.Routes
import com.gauss.app.ui.theme.GaussColors
import com.gauss.app.ui.toFa
import kotlinx.coroutines.launch

private val COUNTS = listOf(5, 10, 15, 20)

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun SetupScreen(
    nav: NavController,
    examVm: ExamViewModel,
    presetSubject: String?,
    presetCategory: String?,
) {
    val app = LocalContext.current.applicationContext as GaussApp
    val scope = rememberCoroutineScope()

    var bank by remember { mutableStateOf<QuestionBank?>(null) }
    var subject by remember { mutableStateOf(Subject.from(presetSubject)) }
    val categories = remember { mutableStateListOf<String>().also { presetCategory?.let { c -> it.add(c) } } }
    val subCategories = remember { mutableStateListOf<String>() }
    val difficulties = remember { mutableStateListOf(Difficulty.HARD, Difficulty.VERY_HARD) }
    var count by remember { mutableStateOf(10) }
    var availability by remember { mutableStateOf<Map<String, Int>>(emptyMap()) }
    var loading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) { bank = app.questionBank() }
    LaunchedEffect(bank, subject) {
        bank?.let { availability = it.availability(subject) }
    }

    // Drop sub-categories no longer valid for the selected categories.
    val subCatOptions = remember(subject, categories.toList()) {
        Categories.tree[subject].orEmpty()
            .filter { it.key in categories }
            .flatMap { it.subCategories }
    }
    LaunchedEffect(subCatOptions) {
        subCategories.retainAll { key -> subCatOptions.any { it.key == key } }
    }

    val available = bank?.totalFor(subject) ?: 0
    val startEnabled = !loading && difficulties.isNotEmpty() && bank != null

    fun start() {
        val b = bank ?: return
        error = null
        loading = true
        scope.launch {
            val config = ExamConfig(subject, categories.toList(), subCategories.toList(), difficulties.toList(), count)
            val questions = b.selectExam(config)
            if (questions.isEmpty()) {
                error = "هیچ سؤالی با این فیلترها پیدا نشد. فیلترها رو بازتر کن رفیق."
                loading = false
            } else {
                examVm.startExam(config, questions)
                nav.navigate(Routes.SESSION) {
                    popUpTo("${Routes.SETUP}?subject={subject}&category={category}") { inclusive = true }
                }
            }
        }
    }

    Column(
        Modifier
            .fillMaxSize()
            .background(GaussColors.Bg)
            .systemBarsPadding(),
    ) {
        // Header
        Row(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp, vertical = 16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            BackChip { nav.popBackStack() }
            Text("آزمون سفارشی", color = GaussColors.Text, fontSize = 22.sp, fontWeight = FontWeight.Bold)
        }

        BoxWithConstraints(Modifier.weight(1f)) {
            val wide = maxWidth > 640.dp

            @Composable
            fun leftPane(mod: Modifier) = Column(mod) {
                Section("درس") {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Subject.entries.forEach { s ->
                            Chip(s.faLabel, subject == s, s.color, Modifier.weight(1f)) {
                                subject = s; categories.clear(); subCategories.clear()
                            }
                        }
                    }
                }
                Section("سطح دشواری") {
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        listOf(Difficulty.ABOVE_AVERAGE, Difficulty.HARD, Difficulty.VERY_HARD, Difficulty.OLYMPIAD)
                            .forEach { d ->
                                Chip(d.faLabel, difficulties.contains(d), d.color) { toggle(difficulties, d) }
                            }
                    }
                }
                Section("تعداد سؤال") {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        COUNTS.forEach { n ->
                            Chip(toFa(n), count == n, GaussColors.NeonPurple, Modifier.weight(1f)) { count = n }
                        }
                    }
                }
            }

            @Composable
            fun rightPane(mod: Modifier) = Column(mod) {
                Section("مبحث (خالی = همه)") {
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Categories.tree[subject].orEmpty().forEach { c ->
                            val n = availability[c.key] ?: 0
                            Chip(
                                "${c.faLabel} (${toFa(n)})",
                                categories.contains(c.key),
                                GaussColors.NeonBlue,
                                enabled = n > 0,
                            ) { toggle(categories, c.key) }
                        }
                    }
                }
                if (subCatOptions.isNotEmpty()) {
                    Section("زیرمبحث (خالی = همهٔ مبحث)") {
                        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            subCatOptions.forEach { sc ->
                                Chip(sc.faLabel, subCategories.contains(sc.key), GaussColors.NeonGreen) {
                                    toggle(subCategories, sc.key)
                                }
                            }
                        }
                    }
                }
            }

            if (wide) {
                Row(
                    Modifier
                        .fillMaxSize()
                        .padding(horizontal = 24.dp),
                    horizontalArrangement = Arrangement.spacedBy(24.dp),
                ) {
                    leftPane(Modifier.weight(1f).verticalScroll(rememberScrollState()))
                    rightPane(Modifier.weight(1f).verticalScroll(rememberScrollState()))
                }
            } else {
                Column(
                    Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(horizontal = 24.dp),
                ) {
                    leftPane(Modifier.fillMaxWidth())
                    rightPane(Modifier.fillMaxWidth())
                }
            }
        }

        // Sticky start CTA
        Column(
            Modifier
                .fillMaxWidth()
                .background(GaussColors.Bg)
                .padding(horizontal = 24.dp, vertical = 12.dp),
        ) {
            error?.let {
                Text(
                    it,
                    color = GaussColors.NeonRed,
                    fontSize = 13.sp,
                    textAlign = TextAlign.End,
                    modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
                )
            }
            Box(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(if (startEnabled) GaussColors.NeonBlue else GaussColors.Card)
                    .clickableNoRipple(startEnabled) { start() }
                    .padding(vertical = 16.dp),
                contentAlignment = Alignment.Center,
            ) {
                if (loading) {
                    CircularProgressIndicator(color = GaussColors.NeonBlue, strokeWidth = 2.dp, modifier = Modifier.height(24.dp))
                } else {
                    Text(
                        "شروع آزمون · ${toFa(available)} سؤال آماده",
                        color = if (startEnabled) GaussColors.Bg else GaussColors.Muted,
                        fontSize = 17.sp,
                        fontWeight = FontWeight.Bold,
                    )
                }
            }
        }
    }
}

@Composable
private fun Section(title: String, content: @Composable () -> Unit) {
    Column(Modifier.padding(top = 8.dp, bottom = 16.dp)) {
        Text(
            title,
            color = GaussColors.Muted,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.End,
            modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp),
        )
        content()
    }
}

@Composable
private fun BackChip(onClick: () -> Unit) {
    Box(
        Modifier
            .clip(RoundedCornerShape(10.dp))
            .background(GaussColors.Card)
            .clickableNoRipple { onClick() }
            .padding(horizontal = 16.dp, vertical = 8.dp),
    ) {
        Text("بازگشت ›", color = GaussColors.Text, fontSize = 14.sp)
    }
}

private fun <T> toggle(list: SnapshotStateList<T>, value: T) {
    if (list.contains(value)) list.remove(value) else list.add(value)
}
