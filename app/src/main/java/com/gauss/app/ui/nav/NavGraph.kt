package com.gauss.app.ui.nav

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.gauss.app.ui.exam.sharedExamViewModel
import com.gauss.app.ui.screens.AdventureArenaScreen
import com.gauss.app.ui.screens.AdventureMapScreen
import com.gauss.app.ui.screens.AdventureMissionsScreen
import com.gauss.app.ui.screens.AdventureProfileScreen
import com.gauss.app.ui.screens.AdventureRewardScreen

object Routes {
    const val MAP = "map"
    const val MISSIONS = "missions"
    const val ARENA = "arena"
    const val REWARD = "reward"
    const val PROFILE = "profile"

    // Legacy routes retained for older callers/tests that still reference setup().
    const val HOME = MAP
    const val SETUP = MISSIONS
    const val SESSION = ARENA
    const val RESULTS = REWARD
    const val REVENGE = "revenge"
    const val ANALYTICS = PROFILE

    fun setup(subject: String? = null, topic: String? = null): String = MISSIONS
}

@Composable
fun GaussNavHost() {
    val nav = rememberNavController()
    val fade = tween<Float>(180)

    NavHost(
        navController = nav,
        startDestination = Routes.MAP,
        enterTransition = {
            slideInHorizontally(
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioNoBouncy,
                    stiffness = Spring.StiffnessMediumLow,
                ),
                initialOffsetX = { it / 5 },
            ) + fadeIn(fade)
        },
        exitTransition = {
            slideOutHorizontally(
                animationSpec = tween(160),
                targetOffsetX = { -it / 8 },
            ) + fadeOut(tween(110))
        },
        popEnterTransition = {
            slideInHorizontally(
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioNoBouncy,
                    stiffness = Spring.StiffnessMediumLow,
                ),
                initialOffsetX = { -it / 5 },
            ) + fadeIn(fade)
        },
        popExitTransition = {
            slideOutHorizontally(
                animationSpec = tween(160),
                targetOffsetX = { it / 8 },
            ) + fadeOut(tween(110))
        },
    ) {
        composable(Routes.MAP) { AdventureMapScreen(nav, sharedExamViewModel()) }
        composable(Routes.MISSIONS) { AdventureMissionsScreen(nav, sharedExamViewModel()) }
        composable(Routes.ARENA) { AdventureArenaScreen(nav, sharedExamViewModel()) }
        composable(Routes.REWARD) { AdventureRewardScreen(nav, sharedExamViewModel()) }
        composable(Routes.PROFILE) { AdventureProfileScreen(nav, sharedExamViewModel()) }
    }
}
