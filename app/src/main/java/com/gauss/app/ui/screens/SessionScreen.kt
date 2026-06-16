package com.gauss.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateMapOf
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
import com.gauss.app.data.AttemptStatus
import com.gauss.app.data.Categories
import com.gauss.app.ui.components.DifficultyBadge
import com.gauss.app.ui.components.DrawingCanvas
import com.gauss.app.ui.components.GeniusKey
import com.gauss.app.ui.components.MathText
import com.gauss.app.ui.components.OptionButton
import com.gauss.app.ui.components.Timer
import com.gauss.app.ui.components.clickableNoRipple
import com.gauss.app.ui.exam.ExamViewModel
import com.gauss.app.ui.nav.Routes
import com.gauss.app.ui.theme.GaussColors
import com.gauss.app.ui.theme.soft
import com.gauss.app.ui.toFa

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun SessionScreen(nav: NavController, vm: ExamViewModel) {
    val q = vm.current
    val config = vm.config
    if (q == null || config == null) {
        EmptyState("آزمونی فعال نیست.") {
            nav.navigate(Routes.HOME) { popUpTo(Routes.HOME) { inclusive = true } }
        }
        return
    }

    val revealed = remember { mutableStateMapOf<Int, Boolean>() }
    var showFinish by remember { mutableStateOf(false) }
    var showAbandon by remember { mutableStateOf(false) }
    var showScratch by remember { mutableStateOf(false) }

    val isRevealed = revealed[vm.index] == true

    fun goResults() {
        vm.finishAndSave {
            nav.navigate(Routes.RESULTS) { popUpTo(Routes.SESSION) { inclusive = true } }
        }
    }

    Column(
        Modifier
            .fillMaxSize()
            .background(GaussColors.Bg)
            .systemBarsPadding(),
    ) {
        // Top bar
        Row(
            Modifier
                .fillMaxWidth()
                .border(width = 0.dp, color = Color.Transparent)
                .padding(horizontal = 16.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Timer(resetKey = vm.index)
                Spacer(Modifier.size(10.dp))
                SmallTag("✕ خروج") { showAbandon = true }
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "سؤال ${toFa(vm.index + 1)} / ${toFa(vm.questions.size)}",
                    color = GaussColors.Muted,
                    fontSize = 14.sp,
                )
                Text(
                    "  ${config.subject.faLabel}",
                    color = config.subject.color,
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                )
            }
        }

        BoxWithConstraints(Modifier.weight(1f)) {
            val wide = maxWidth > 720.dp

            val questionPane: @Composable (Modifier) -> Unit = { mod ->
                QuestionPane(
                    vm = vm,
                    isRevealed = isRevealed,
                    onToggleReveal = { revealed[vm.index] = !(revealed[vm.index] ?: false) },
                    onFinish = { showFinish = true },
                    modifier = mod,
                )
            }
            val scratchPane: @Composable (Modifier) -> Unit = { mod ->
                Column(mod.padding(12.dp)) {
                    Text(
                        "دفتر طراحی · با قلم بنویس ✍️",
                        color = GaussColors.Muted,
                        fontSize = 12.sp,
                        textAlign = TextAlign.End,
                        modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
                    )
                    DrawingCanvas(
                        strokes = vm.scratch[vm.index] ?: emptyList(),
                        onChange = { vm.setScratch(vm.index, it) },
                        modifier = Modifier.fillMaxSize(),
                    )
                }
            }

            if (wide) {
                Row(Modifier.fillMaxSize()) {
                    questionPane(Modifier.weight(1f).fillMaxHeight())
                    Box(Modifier.weight(1f).fillMaxHeight()) { scratchPane(Modifier.fillMaxSize()) }
                }
            } else {
                Column(Modifier.fillMaxSize()) {
                    // Tab switch (portrait): question vs scratchpad
                    Row(
                        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        TabToggle("سؤال", !showScratch, Modifier.weight(1f)) { showScratch = false }
                        TabToggle("دفتر طراحی ✍️", showScratch, Modifier.weight(1f)) { showScratch = true }
                    }
                    if (showScratch) scratchPane(Modifier.fillMaxSize())
                    else questionPane(Modifier.fillMaxSize())
                }
            }
        }
    }

    if (showFinish) {
        ConfirmDialog(
            title = "پایان آزمون",
            body = "${toFa(vm.recordedCount())} از ${toFa(vm.questions.size)} سؤال ثبت شده. مطمئنی؟",
            confirm = "تمام",
            onConfirm = { showFinish = false; goResults() },
            onDismiss = { showFinish = false },
        )
    }
    if (showAbandon) {
        ConfirmDialog(
            title = "خروج از آزمون",
            body = "پیشرفت این آزمون ذخیره نمی‌شه. مطمئنی می‌خوای بیرون بری؟",
            confirm = "خروج",
            onConfirm = {
                showAbandon = false
                vm.reset()
                nav.navigate(Routes.HOME) { popUpTo(Routes.HOME) { inclusive = true } }
            },
            onDismiss = { showAbandon = false },
        )
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun QuestionPane(
    vm: ExamViewModel,
    isRevealed: Boolean,
    onToggleReveal: () -> Unit,
    onFinish: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val q = vm.current ?: return
    val config = vm.config ?: return
    val attempt = vm.attempts[vm.index]
    val selected = attempt?.selectedOption
    val isLast = vm.isLast

    Column(modifier) {
        Column(
            Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
        ) {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    Categories.label(config.subject, q.category) +
                        (q.subCategory?.let { " · $it" } ?: ""),
                    color = GaussColors.Muted,
                    fontSize = 12.sp,
                )
                DifficultyBadge(q.difficulty)
            }

            Box(
                Modifier
                    .padding(top = 12.dp, bottom = 16.dp)
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(GaussColors.Surface)
                    .border(1.dp, GaussColors.Border, RoundedCornerShape(16.dp))
                    .padding(16.dp),
            ) {
                MathText(q.questionText, fontSize = 18.sp)
            }

            q.options.forEachIndexed { i, opt ->
                OptionButton(
                    index = i + 1,
                    text = opt,
                    selected = selected == i + 1,
                    onClick = { vm.answer(i + 1) },
                )
            }

            if (isRevealed) {
                GeniusKey(q.classicSolution, q.smartShortcut, Modifier.padding(top = 8.dp))
            }
        }

        // Reveal bar
        Box(Modifier.padding(horizontal = 20.dp, vertical = 6.dp)) {
            val canReveal = attempt != null
            val accent = if (isRevealed) GaussColors.NeonPurple else GaussColors.NeonGreen
            Box(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(if (canReveal) accent.soft(0.10f) else GaussColors.Card)
                    .border(1.dp, if (canReveal) accent else GaussColors.Border, RoundedCornerShape(12.dp))
                    .clickableNoRipple(canReveal) { onToggleReveal() }
                    .padding(vertical = 10.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    when {
                        isRevealed -> "بستن حل"
                        canReveal -> "نمایش حل ✨"
                        else -> "اول جواب بده، بعد حل ✍️"
                    },
                    color = if (canReveal) accent else GaussColors.Muted,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                )
            }
        }

        // Question dots
        FlowRow(
            Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.Center,
        ) {
            vm.questions.forEachIndexed { i, _ ->
                val a = vm.attempts[i]
                val bg = when {
                    i == vm.index -> GaussColors.NeonBlue
                    a?.status == AttemptStatus.SKIPPED -> GaussColors.NeonAmber
                    a != null -> GaussColors.NeonPurple
                    else -> GaussColors.Raised
                }
                Box(
                    Modifier
                        .padding(3.dp)
                        .size(40.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(bg)
                        .clickableNoRipple { vm.goTo(i) },
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        toFa(i + 1),
                        color = if (i == vm.index) GaussColors.Bg else GaussColors.Text,
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp,
                    )
                }
            }
        }

        // Nav row
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            NavBtn("‹ قبلی", enabled = vm.index > 0) { vm.prev() }
            SmallTag("رد کردن") { vm.skip(); if (!isLast) vm.next() }
            NavBtn("بعدی ›", enabled = !isLast, primary = true) { vm.next() }
        }

        // Finish
        Box(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 10.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(GaussColors.NeonGreen)
                .clickableNoRipple { onFinish() }
                .padding(vertical = 14.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text("پایان و دیدن کارنامه", color = GaussColors.Bg, fontWeight = FontWeight.Bold, fontSize = 15.sp)
        }
    }
}

@Composable
private fun NavBtn(label: String, enabled: Boolean, primary: Boolean = false, onClick: () -> Unit) {
    val bg = when {
        !enabled -> GaussColors.Card
        primary -> GaussColors.NeonBlue
        else -> GaussColors.Raised
    }
    Box(
        Modifier
            .clip(RoundedCornerShape(10.dp))
            .background(bg)
            .clickableNoRipple(enabled) { onClick() }
            .padding(horizontal = 20.dp, vertical = 9.dp),
    ) {
        Text(
            label,
            color = if (primary && enabled) GaussColors.Bg else GaussColors.Text,
            fontWeight = FontWeight.SemiBold,
            fontSize = 14.sp,
        )
    }
}

@Composable
private fun SmallTag(label: String, onClick: () -> Unit) {
    Box(
        Modifier
            .clip(RoundedCornerShape(10.dp))
            .background(GaussColors.Card)
            .border(1.dp, GaussColors.Border, RoundedCornerShape(10.dp))
            .clickableNoRipple { onClick() }
            .padding(horizontal = 14.dp, vertical = 8.dp),
    ) {
        Text(label, color = GaussColors.Muted, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
private fun TabToggle(label: String, active: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Box(
        modifier
            .clip(RoundedCornerShape(10.dp))
            .background(if (active) GaussColors.NeonBlue.soft(0.12f) else GaussColors.Card)
            .border(1.dp, if (active) GaussColors.NeonBlue else GaussColors.Border, RoundedCornerShape(10.dp))
            .clickableNoRipple { onClick() }
            .padding(vertical = 9.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            label,
            color = if (active) GaussColors.NeonBlue else GaussColors.Muted,
            fontWeight = FontWeight.SemiBold,
            fontSize = 14.sp,
        )
    }
}

@Composable
private fun ConfirmDialog(
    title: String,
    body: String,
    confirm: String,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = GaussColors.Surface,
        titleContentColor = GaussColors.Text,
        textContentColor = GaussColors.Muted,
        title = { Text(title, fontWeight = FontWeight.Bold) },
        text = { Text(body) },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(confirm, color = GaussColors.NeonRed, fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("ادامه می‌دم", color = GaussColors.Muted) }
        },
    )
}

@Composable
private fun EmptyState(message: String, onHome: () -> Unit) {
    Column(
        Modifier.fillMaxSize().background(GaussColors.Bg).systemBarsPadding(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(message, color = GaussColors.Muted)
        Spacer(Modifier.height(16.dp))
        Box(
            Modifier
                .clip(RoundedCornerShape(10.dp))
                .background(GaussColors.Card)
                .clickableNoRipple { onHome() }
                .padding(horizontal = 20.dp, vertical = 12.dp),
        ) {
            Text("خانه", color = GaussColors.Text)
        }
    }
}
