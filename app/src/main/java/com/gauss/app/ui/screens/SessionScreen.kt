package com.gauss.app.ui.screens

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
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
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Cancel
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.HourglassEmpty
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameMillis
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.gauss.app.data.AttemptStatus
import com.gauss.app.data.ComprehensiveTaxonomy
import com.gauss.app.data.Question
import com.gauss.app.ui.components.DifficultyBadge
import com.gauss.app.ui.components.DrawingCanvas
import com.gauss.app.ui.components.GeniusKey
import com.gauss.app.ui.components.GaussMentorAvatar
import com.gauss.app.ui.components.OptionButton
import com.gauss.app.ui.components.RichContent
import com.gauss.app.ui.components.Stroke
import com.gauss.app.ui.components.Timer
import com.gauss.app.ui.components.clickableNoRipple
import com.gauss.app.ui.exam.ExamViewModel
import com.gauss.app.ui.nav.Routes
import com.gauss.app.ui.theme.GaussColors
import com.gauss.app.ui.theme.soft
import com.gauss.app.ui.toFa
import kotlin.random.Random

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

    val isRevealed = revealed[vm.index] == true
    val scheme = MaterialTheme.colorScheme

    fun goResults() {
        vm.finishAndSave {
            nav.navigate(Routes.RESULTS) { popUpTo(Routes.SESSION) { inclusive = true } }
        }
    }

    Column(
        Modifier
            .fillMaxSize()
            .background(scheme.background)
            .systemBarsPadding(),
    ) {
        SessionTopBar(
            subjectLabel = config.subject.faLabel,
            subjectColor = config.subject.color,
            current = vm.index + 1,
            total = vm.questions.size,
            onExit = { showAbandon = true },
        )

        QuestionPane(
            vm = vm,
            isRevealed = isRevealed,
            onToggleReveal = { revealed[vm.index] = !(revealed[vm.index] ?: false) },
            onFinish = { showFinish = true },
            modifier = Modifier.weight(1f),
        )
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

@Composable
private fun SessionTopBar(
    subjectLabel: String,
    subjectColor: Color,
    current: Int,
    total: Int,
    onExit: () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    val progress = (current.toFloat() / total.coerceAtLeast(1).toFloat()).coerceIn(0f, 1f)
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 10.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        SmallTag("خروج", Icons.Rounded.Close) { onExit() }
        Column(Modifier.weight(1f), horizontalAlignment = Alignment.End) {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(subjectLabel, color = subjectColor, fontWeight = FontWeight.Black, fontSize = 14.sp)
                Text(
                    "سؤال ${toFa(current)} از ${toFa(total)}",
                    color = scheme.onSurfaceVariant,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                )
            }
            Box(
                Modifier
                    .padding(top = 7.dp)
                    .fillMaxWidth()
                    .height(12.dp)
                    .clip(RoundedCornerShape(50))
                    .background(scheme.surfaceVariant),
            ) {
                Box(
                    Modifier
                        .fillMaxWidth(progress)
                        .height(12.dp)
                        .clip(RoundedCornerShape(50))
                        .background(subjectColor),
                )
            }
        }
        Timer(resetKey = current)
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
    val attempt = vm.attempts[vm.index]
    val selected = attempt?.selectedOption
    val isLast = vm.isLast
    val scheme = MaterialTheme.colorScheme
    var scratchMode by remember(q.id) { mutableStateOf(false) }
    var scratchStrokes by remember(q.id) { mutableStateOf<List<Stroke>>(emptyList()) }
    var celebrationKey by remember { mutableIntStateOf(0) }

    LaunchedEffect(q.id, attempt?.status) {
        if (attempt?.status == AttemptStatus.CORRECT) celebrationKey += 1
    }

    Box(modifier) {
        Column(
            Modifier.fillMaxSize(),
        ) {
            AnimatedContent(
                targetState = vm.index,
                transitionSpec = {
                    val forward = targetState > initialState
                    val direction = if (forward) -1 else 1
                    (slideInHorizontally(
                        animationSpec = spring(
                            dampingRatio = Spring.DampingRatioNoBouncy,
                            stiffness = Spring.StiffnessMediumLow,
                        ),
                        initialOffsetX = { direction * it / 3 },
                    ) + fadeIn(tween(180)))
                        .togetherWith(
                            slideOutHorizontally(
                                animationSpec = tween(180),
                                targetOffsetX = { -direction * it / 5 },
                            ) + fadeOut(tween(140)),
                        )
                },
                label = "questionPage",
                modifier = Modifier.weight(1f),
            ) { page ->
                val pageQuestion = vm.questions.getOrNull(page) ?: q
                QuestionContent(
                    q = pageQuestion,
                    selected = if (page == vm.index) selected else vm.attempts[page]?.selectedOption,
                    isRevealed = page == vm.index && isRevealed,
                    onAnswer = { option -> if (page == vm.index) vm.answer(option) },
                )
            }

            AnimatedVisibility(
                visible = attempt != null,
                enter = slideInVertically(
                    initialOffsetY = { it / 2 },
                    animationSpec = spring(Spring.DampingRatioMediumBouncy, Spring.StiffnessMediumLow),
                ) + fadeIn(tween(180)),
                exit = slideOutVertically(targetOffsetY = { it / 3 }) + fadeOut(tween(140)),
            ) {
                attempt?.let { AnswerFeedback(it.status, Modifier.padding(horizontal = 20.dp, vertical = 6.dp)) }
            }

            // Reveal bar
            Box(Modifier.padding(horizontal = 20.dp, vertical = 6.dp)) {
                val canReveal = attempt != null
                val accent = if (isRevealed) scheme.secondary else scheme.primary
                Box(
                    Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(if (canReveal) accent.soft(0.12f) else scheme.surfaceVariant)
                        .border(1.dp, if (canReveal) accent else scheme.outline, RoundedCornerShape(12.dp))
                        .clickableNoRipple(canReveal) { onToggleReveal() }
                        .padding(vertical = 10.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        when {
                            isRevealed -> "بستن حل"
                            canReveal -> "نمایش حل"
                            else -> "اول پاسخ بده، بعد حل را ببین"
                        },
                        color = if (canReveal) accent else scheme.onSurfaceVariant,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp,
                    )
                }
            }

            QuestionTrail(vm)

            // Nav row
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                NavBtn("قبلی", enabled = vm.index > 0) { vm.prev() }
                SmallTag("رد کردن", enabled = attempt == null) { vm.skip(); if (!isLast) vm.next() }
                NavBtn("ادامه", enabled = attempt != null && !isLast, primary = true) { vm.next() }
            }

            // Finish
            Box(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 10.dp)
                    .clip(RoundedCornerShape(16.dp))
                    .background(if (isLast) scheme.primary else scheme.primaryContainer)
                    .clickableNoRipple { onFinish() }
                    .padding(vertical = 14.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    "پایان و دیدن کارنامه",
                    color = if (isLast) scheme.onPrimary else scheme.primary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                )
            }
        }

        AnimatedVisibility(
            visible = !scratchMode,
            enter = scaleIn(
                initialScale = 0.8f,
                animationSpec = spring(Spring.DampingRatioLowBouncy, Spring.StiffnessMediumLow),
            ) + fadeIn(),
            exit = scaleOut(targetScale = 0.82f) + fadeOut(),
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(end = 20.dp, bottom = 176.dp),
        ) {
            ScratchFab(
                count = scratchStrokes.size,
                onClick = { scratchMode = true },
            )
        }

        AnimatedVisibility(
            visible = scratchMode,
            enter = fadeIn(tween(160)) + scaleIn(
                initialScale = 0.98f,
                animationSpec = spring(Spring.DampingRatioNoBouncy, Spring.StiffnessMediumLow),
            ),
            exit = fadeOut(tween(140)) + scaleOut(targetScale = 0.98f),
        ) {
            DrawingCanvas(
                strokes = scratchStrokes,
                onChange = { scratchStrokes = it },
                onClose = { scratchMode = false },
                clearKey = q.id,
                modifier = Modifier.fillMaxSize(),
            )
        }
        CorrectCelebrationOverlay(triggerKey = celebrationKey)
    }
}

@Composable
private fun QuestionContent(
    q: Question,
    selected: Int?,
    isRevealed: Boolean,
    onAnswer: (Int) -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    val locked = selected != null
    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
    ) {
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                ComprehensiveTaxonomy.label(q.topicKey),
                color = scheme.onSurfaceVariant,
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
            )
            DifficultyBadge(q.difficulty)
        }

        LessonCoachBubble(locked = locked)

        Box(
            Modifier
                .padding(top = 12.dp, bottom = 16.dp)
                .fillMaxWidth()
                .clip(RoundedCornerShape(20.dp))
                .background(scheme.surface)
                .border(1.dp, scheme.outline, RoundedCornerShape(20.dp))
                .padding(18.dp),
        ) {
            RichContent(q.stem, fontSize = 18.sp)
        }

        q.options.forEachIndexed { i, opt ->
            val optionIndex = i + 1
            OptionButton(
                index = optionIndex,
                text = opt,
                blocks = q.optionBlocks[i],
                selected = selected == optionIndex,
                reveal = isRevealed && locked,
                correct = q.correctOptionIndex == optionIndex,
                onClick = if (locked) null else ({ onAnswer(optionIndex) }),
            )
        }

        if (isRevealed) {
            GeniusKey(q.solution, q.shortcut, Modifier.padding(top = 8.dp))
        }
    }
}

@Composable
private fun LessonCoachBubble(locked: Boolean) {
    val scheme = MaterialTheme.colorScheme
    Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier
                .weight(1f)
                .clip(RoundedCornerShape(18.dp))
                .background(scheme.primaryContainer)
                .border(1.dp, scheme.primary.soft(0.38f), RoundedCornerShape(18.dp))
                .padding(horizontal = 14.dp, vertical = 12.dp),
        ) {
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    if (locked) "حرکت ثبت شد" else "نوبت توئه",
                    color = scheme.onSurface,
                    fontWeight = FontWeight.Black,
                    textAlign = TextAlign.End,
                    modifier = Modifier.fillMaxWidth(),
                )
                Text(
                    if (locked) "دام گزینه‌ها روشن شد؛ اگر لازم داری، حل را باز کن."
                    else "با یک انتخاب دقیق جلو برو؛ زمان استاندارد کنکور بالا سرته.",
                    color = scheme.onSurfaceVariant,
                    fontSize = 12.sp,
                    textAlign = TextAlign.End,
                    modifier = Modifier.fillMaxWidth().padding(top = 3.dp),
                )
            }
        }
        GaussMentorAvatar(size = 56.dp)
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun QuestionTrail(vm: ExamViewModel) {
    val scheme = MaterialTheme.colorScheme
    FlowRow(
        Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.Center,
    ) {
        vm.questions.forEachIndexed { i, _ ->
            val a = vm.attempts[i]
            val bg = when {
                i == vm.index -> scheme.primary
                a?.status == AttemptStatus.SKIPPED -> GaussColors.Warning.soft(0.22f)
                a?.status == AttemptStatus.WRONG -> scheme.error.soft(0.18f)
                a?.status == AttemptStatus.CORRECT -> GaussColors.Success.soft(0.20f)
                else -> scheme.surfaceVariant
            }
            val fg = when {
                i == vm.index -> scheme.onPrimary
                a?.status == AttemptStatus.SKIPPED -> GaussColors.Warning
                a?.status == AttemptStatus.WRONG -> scheme.error
                a?.status == AttemptStatus.CORRECT -> GaussColors.Success
                else -> scheme.onSurfaceVariant
            }
            Box(
                Modifier
                    .padding(3.dp)
                    .size(30.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(bg)
                    .border(1.dp, if (i == vm.index) scheme.primary else scheme.outline, RoundedCornerShape(10.dp))
                    .clickableNoRipple { vm.goTo(i) },
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    toFa(i + 1),
                    color = fg,
                    fontWeight = FontWeight.Black,
                    fontSize = 11.sp,
                )
            }
        }
    }
}

@Composable
private fun ScratchFab(count: Int, onClick: () -> Unit) {
    val scheme = MaterialTheme.colorScheme
    Row(
        Modifier
            .clip(RoundedCornerShape(18.dp))
            .background(scheme.primary)
            .border(1.dp, scheme.primary, RoundedCornerShape(18.dp))
            .clickableNoRipple { onClick() }
            .padding(horizontal = 14.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            if (count > 0) "قلم ${toFa(count)}" else "قلم",
            color = scheme.onPrimary,
            fontWeight = FontWeight.Black,
            fontSize = 13.sp,
        )
        Icon(Icons.Rounded.Edit, contentDescription = null, tint = scheme.onPrimary, modifier = Modifier.size(19.dp))
    }
}

private data class CelebrationDot(
    val x: Float,
    val y: Float,
    val vx: Float,
    val vy: Float,
    val radius: Float,
    val color: Color,
)

@Composable
private fun CorrectCelebrationOverlay(triggerKey: Int) {
    var progress by remember { mutableFloatStateOf(1f) }
    val dots = remember { mutableStateListOf<CelebrationDot>() }
    val colors = listOf(
        MaterialTheme.colorScheme.primary,
        MaterialTheme.colorScheme.secondary,
        GaussColors.Success,
        GaussColors.Warning,
        GaussColors.Math,
    )

    LaunchedEffect(triggerKey) {
        if (triggerKey == 0) return@LaunchedEffect
        progress = 0f
        dots.clear()
        repeat(48) {
            dots += CelebrationDot(
                x = 0.5f + Random.nextFloat() * 0.22f - 0.11f,
                y = 0.74f + Random.nextFloat() * 0.08f,
                vx = Random.nextFloat() * 0.76f - 0.38f,
                vy = -(Random.nextFloat() * 0.42f + 0.18f),
                radius = Random.nextFloat() * 5f + 3f,
                color = colors.random(),
            )
        }
        val start = withFrameMillis { it }
        while (progress < 1f) {
            val elapsed = withFrameMillis { it } - start
            progress = (elapsed / 1100f).coerceIn(0f, 1f)
        }
        dots.clear()
    }

    if (dots.isNotEmpty()) {
        Canvas(Modifier.fillMaxSize()) {
            dots.forEach { dot ->
                val p = progress
                drawCircle(
                    color = dot.color.copy(alpha = 1f - p),
                    radius = dot.radius,
                    center = Offset(
                        x = size.width * (dot.x + dot.vx * p),
                        y = size.height * (dot.y + dot.vy * p + 0.26f * p * p),
                    ),
                )
            }
        }
    }
}

@Composable
private fun AnswerFeedback(status: AttemptStatus, modifier: Modifier = Modifier) {
    val scheme = MaterialTheme.colorScheme
    val label: String
    val detail: String
    val color: Color
    val icon: ImageVector
    when (status) {
        AttemptStatus.CORRECT -> {
            label = "درست بود"
            detail = "+۵ XP احتمالی بعد از پایان آزمون"
            color = GaussColors.Success
            icon = Icons.Rounded.CheckCircle
        }
        AttemptStatus.WRONG -> {
            label = "غلط ثبت شد"
            detail = "بعداً از Revenge برش می‌گردونیم"
            color = scheme.error
            icon = Icons.Rounded.Cancel
        }
        AttemptStatus.SKIPPED -> {
            label = "نزده ماند"
            detail = "می‌تونی برگردی و جواب بدی"
            color = GaussColors.Warning
            icon = Icons.Rounded.HourglassEmpty
        }
    }
    Row(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(color.soft(0.12f))
            .border(1.dp, color.soft(0.55f), RoundedCornerShape(16.dp))
            .padding(14.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(detail, color = scheme.onSurfaceVariant, fontSize = 12.sp)
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(label, color = color, fontWeight = FontWeight.Black)
            Icon(icon, contentDescription = null, tint = color)
        }
    }
}

@Composable
private fun NavBtn(label: String, enabled: Boolean, primary: Boolean = false, onClick: () -> Unit) {
    val scheme = MaterialTheme.colorScheme
    val bg = when {
        !enabled -> scheme.surfaceVariant.copy(alpha = 0.55f)
        primary -> scheme.primary
        else -> scheme.surfaceVariant
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
            color = if (primary && enabled) scheme.onPrimary else scheme.onSurface,
            fontWeight = FontWeight.SemiBold,
            fontSize = 14.sp,
        )
    }
}

@Composable
private fun SmallTag(label: String, icon: ImageVector? = null, enabled: Boolean = true, onClick: () -> Unit) {
    val scheme = MaterialTheme.colorScheme
    Row(
        Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(if (enabled) scheme.surfaceVariant else scheme.surfaceVariant.copy(alpha = 0.55f))
            .border(1.dp, scheme.outline, RoundedCornerShape(12.dp))
            .clickableNoRipple(enabled) { onClick() }
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        icon?.let {
            Icon(it, contentDescription = null, tint = scheme.onSurfaceVariant, modifier = Modifier.size(16.dp))
        }
        Text(label, color = scheme.onSurfaceVariant, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
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
    val scheme = MaterialTheme.colorScheme
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = scheme.surface,
        titleContentColor = scheme.onSurface,
        textContentColor = scheme.onSurfaceVariant,
        title = { Text(title, fontWeight = FontWeight.Bold) },
        text = { Text(body) },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(confirm, color = scheme.error, fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("ادامه می‌دم", color = scheme.onSurfaceVariant) }
        },
    )
}

@Composable
private fun EmptyState(message: String, onHome: () -> Unit) {
    val scheme = MaterialTheme.colorScheme
    Column(
        Modifier.fillMaxSize().background(scheme.background).systemBarsPadding(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(message, color = scheme.onSurfaceVariant)
        Spacer(Modifier.height(16.dp))
        Box(
            Modifier
                .clip(RoundedCornerShape(10.dp))
                .background(scheme.surfaceVariant)
                .clickableNoRipple { onHome() }
                .padding(horizontal = 20.dp, vertical = 12.dp),
        ) {
            Text("خانه", color = scheme.onSurface)
        }
    }
}
