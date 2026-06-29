package com.gauss.app.ui.nav

import androidx.compose.animation.core.tween
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Analytics
import androidx.compose.material.icons.rounded.Home
import androidx.compose.material.icons.rounded.School
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import androidx.navigation.NavController
import androidx.navigation.NavGraph.Companion.findStartDestination
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

    fun setup(subject: String? = null, topic: String? = null): String {
        val s = subject ?: "none"
        val t = topic ?: "none"
        return "setup?subject=$s&topic=$t"
    }
}

private data class TopLevelDestination(
    val route: String,
    val label: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
)

private val topLevelDestinations = listOf(
    TopLevelDestination(Routes.HOME, "خانه", Icons.Rounded.Home),
    TopLevelDestination(Routes.SETUP, "تمرین", Icons.Rounded.School),
    TopLevelDestination(Routes.ANALYTICS, "تحلیل", Icons.Rounded.Analytics),
)

@Composable
fun GaussNavHost() {
    val nav = rememberNavController()
    val fade = tween<Float>(180)
    val isRtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    val direction = if (isRtl) -1 else 1

    NavHost(
        navController = nav,
        startDestination = Routes.HOME,
        enterTransition = {
            slideInHorizontally(
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioNoBouncy,
                    stiffness = Spring.StiffnessMediumLow,
                ),
                initialOffsetX = { direction * it / 5 },
            ) + fadeIn(fade)
        },
        exitTransition = {
            slideOutHorizontally(
                animationSpec = tween(180),
                targetOffsetX = { -direction * it / 8 },
            ) + fadeOut(tween(120))
        },
        popEnterTransition = {
            slideInHorizontally(
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioNoBouncy,
                    stiffness = Spring.StiffnessMediumLow,
                ),
                initialOffsetX = { -direction * it / 5 },
            ) + fadeIn(fade)
        },
        popExitTransition = {
            slideOutHorizontally(
                animationSpec = tween(180),
                targetOffsetX = { direction * it / 8 },
            ) + fadeOut(tween(120))
        },
    ) {
        composable(Routes.HOME) {
            TopLevelScaffold(nav, Routes.HOME) { HomeScreen(nav) }
        }

        composable(
            route = "${Routes.SETUP}?subject={subject}&topic={topic}",
            arguments = listOf(
                navArgument("subject") { type = NavType.StringType; defaultValue = "none" },
                navArgument("topic") { type = NavType.StringType; defaultValue = "none" },
            ),
        ) { entry ->
            val examVm = sharedExamViewModel()
            TopLevelScaffold(nav, Routes.SETUP) {
                SetupScreen(
                    nav = nav,
                    examVm = examVm,
                    presetSubject = entry.arguments?.getString("subject")?.takeIf { it != "none" },
                    presetTopic = entry.arguments?.getString("topic")?.takeIf { it != "none" },
                )
            }
        }

        composable(Routes.SESSION) { SessionScreen(nav, sharedExamViewModel()) }
        composable(Routes.RESULTS) { ResultsScreen(nav, sharedExamViewModel()) }
        composable(Routes.REVENGE) { RevengeScreen(nav, sharedExamViewModel()) }
        composable(Routes.ANALYTICS) {
            TopLevelScaffold(nav, Routes.ANALYTICS) { AnalyticsScreen(nav) }
        }
    }
}

@Composable
private fun TopLevelScaffold(
    nav: NavController,
    selectedRoute: String,
    content: @Composable () -> Unit,
) {
    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        bottomBar = {
            NavigationBar(modifier = Modifier.navigationBarsPadding()) {
                topLevelDestinations.forEach { item ->
                    NavigationBarItem(
                        selected = item.route == selectedRoute,
                        onClick = {
                            val target = if (item.route == Routes.SETUP) Routes.setup() else item.route
                            nav.navigate(target) {
                                popUpTo(nav.graph.findStartDestination().id) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(item.icon, contentDescription = item.label) },
                        label = { Text(item.label) },
                    )
                }
            }
        },
    ) { innerPadding ->
        Box(Modifier.padding(innerPadding)) {
            content()
        }
    }
}
