package com.gauss.app.ui.nav

import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.runtime.Composable
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.gauss.app.ui.exam.sharedExamViewModel
import com.gauss.app.ui.screens.AnalyticsScreen
import com.gauss.app.ui.screens.HomeScreen
import com.gauss.app.ui.screens.ResultsScreen
import com.gauss.app.ui.screens.RevengeScreen
import com.gauss.app.ui.screens.SessionScreen
import com.gauss.app.ui.screens.SetupScreen

object Routes {
    const val HOME = "home"
    const val SETUP = "setup"
    const val SESSION = "session"
    const val RESULTS = "results"
    const val REVENGE = "revenge"
    const val ANALYTICS = "analytics"

    fun setup(subject: String? = null, category: String? = null): String {
        val s = subject ?: "none"
        val c = category ?: "none"
        return "setup?subject=$s&category=$c"
    }
}

@Composable
fun GaussNavHost() {
    val nav = rememberNavController()
    val fade = tween<Float>(220)

    NavHost(
        navController = nav,
        startDestination = Routes.HOME,
        enterTransition = { fadeIn(fade) },
        exitTransition = { fadeOut(fade) },
        popEnterTransition = { fadeIn(fade) },
        popExitTransition = { fadeOut(fade) },
    ) {
        composable(Routes.HOME) { HomeScreen(nav) }

        composable(
            route = "${Routes.SETUP}?subject={subject}&category={category}",
            arguments = listOf(
                navArgument("subject") { type = NavType.StringType; defaultValue = "none" },
                navArgument("category") { type = NavType.StringType; defaultValue = "none" },
            ),
        ) { entry ->
            val examVm = sharedExamViewModel()
            SetupScreen(
                nav = nav,
                examVm = examVm,
                presetSubject = entry.arguments?.getString("subject")?.takeIf { it != "none" },
                presetCategory = entry.arguments?.getString("category")?.takeIf { it != "none" },
            )
        }

        composable(Routes.SESSION) { SessionScreen(nav, sharedExamViewModel()) }
        composable(Routes.RESULTS) { ResultsScreen(nav, sharedExamViewModel()) }
        composable(Routes.REVENGE) { RevengeScreen(nav, sharedExamViewModel()) }
        composable(Routes.ANALYTICS) { AnalyticsScreen(nav) }
    }
}
