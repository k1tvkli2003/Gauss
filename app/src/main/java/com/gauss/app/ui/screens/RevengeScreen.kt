package com.gauss.app.ui.screens

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
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
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
import com.gauss.app.data.ExamConfig
import com.gauss.app.ui.components.clickableNoRipple
import com.gauss.app.ui.exam.ExamViewModel
import com.gauss.app.ui.nav.Routes
import com.gauss.app.ui.toFa
import kotlinx.coroutines.launch

@Composable
fun RevengeScreen(nav: NavController, vm: ExamViewModel) {
    val app = LocalContext.current.applicationContext as GaussApp
    val scope = rememberCoroutineScope()
    var count by remember { mutableStateOf<Int?>(null) }
    var busy by remember { mutableStateOf(false) }
    val scheme = MaterialTheme.colorScheme

    LaunchedEffect(Unit) { count = app.history.revengeIds().size }

    fun start(limit: Int) {
        if (busy) return
        busy = true
        scope.launch {
            val ids = app.history.revengeIds().take(limit)
            val questions = app.questionBank().byIds(ids)
            if (questions.isNotEmpty()) {
                vm.startExam(
                    ExamConfig(questions.first().subject, emptyList(), emptyList(), emptyList(), questions.size),
                    questions,
                )
                nav.navigate(Routes.SESSION) { popUpTo(Routes.REVENGE) { inclusive = true } }
            }
            busy = false
        }
    }

    Column(
        Modifier.fillMaxSize().background(scheme.background).systemBarsPadding().padding(24.dp),
    ) {
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                Modifier.clip(RoundedCornerShape(10.dp)).background(scheme.surfaceVariant)
                    .clickableNoRipple { nav.popBackStack() }.padding(horizontal = 16.dp, vertical = 8.dp),
            ) { Text("بازگشت", color = scheme.onSurface, fontSize = 14.sp) }
            Text("مرور خطاها", color = scheme.error, fontSize = 22.sp, fontWeight = FontWeight.Bold)
        }

        Spacer(Modifier.height(28.dp))

        Column(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(scheme.surface)
                .border(1.dp, scheme.outline, RoundedCornerShape(16.dp))
                .padding(28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                "اینجا همهٔ سؤال‌هایی که غلط زدی یا رد کردی جمع شده.",
                color = scheme.onSurface,
                fontSize = 16.sp,
                textAlign = TextAlign.Center,
            )
            Text(
                "تا وقتی یه سؤال رو چند بار درست نزنی، از این لیست بیرون نمی‌ره.",
                color = scheme.onSurfaceVariant,
                fontSize = 13.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 8.dp, bottom = 24.dp),
            )
            Text(
                if (count == null) "…" else toFa(count!!),
                color = scheme.error,
                fontSize = 52.sp,
                fontWeight = FontWeight.Black,
            )
            Spacer(Modifier.height(24.dp))

            val c = count
            if (c != null && c > 0) {
                listOf(10, 20).forEach { n ->
                    if (c >= n || n == 10) {
                        Box(
                            Modifier
                                .fillMaxWidth()
                                .padding(bottom = 12.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .background(scheme.error)
                                .clickableNoRipple(!busy) { start(n) }
                                .padding(vertical = 13.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                "تمرین ${toFa(minOf(n, c))} سؤال",
                                color = scheme.onError,
                                fontWeight = FontWeight.Bold,
                            )
                        }
                    }
                }
                Box(
                    Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .border(1.dp, scheme.outline, RoundedCornerShape(12.dp))
                        .clickableNoRipple(!busy) { start(c) }
                        .padding(vertical = 13.dp),
                    contentAlignment = Alignment.Center,
                ) { Text("همهٔ ${toFa(c)} سؤال", color = scheme.onSurface, fontWeight = FontWeight.Bold) }
            } else if (c != null) {
                Text(
                    "فعلاً چیزی برای مرور نیست. یک آزمون جدید بزن.",
                    color = scheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}
