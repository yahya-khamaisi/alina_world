package app.jannat.alinaworld.ui

import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import app.jannat.alinaworld.audio.Chiptune
import app.jannat.alinaworld.audio.SoundEffect
import app.jannat.alinaworld.audio.Songs
import app.jannat.alinaworld.data.GameProgress
import app.jannat.alinaworld.data.MissionResult
import app.jannat.alinaworld.data.Missions
import app.jannat.alinaworld.data.Objective
import app.jannat.alinaworld.game.Input
import app.jannat.alinaworld.game.WorldThemes

private val LocalActiveRoute = compositionLocalOf { true }

sealed interface Route {
    data object Menu : Route
    data object Map : Route
    data class Settings(val back: Route) : Route
    data class Briefing(val id: Int) : Route
    data class Playing(val id: Int, val attempt: Int) : Route
    class Won(val result: MissionResult) : Route
    data class Lost(val id: Int, val reason: String) : Route
}

/** App navigation plus the active screen's key handler, which runs after every remote press. */
object Router {
    var route by mutableStateOf<Route>(Route.Menu)
    var mapIndex by mutableIntStateOf(0)
    private var attempt = 0
    private var handler: (() -> Unit)? = null
    var onExit: () -> Unit = {}

    fun play(id: Int) { attempt++; route = Route.Playing(id, attempt) }

    fun openMap() {
        mapIndex = (minOf(GameProgress.MISSION_COUNT, GameProgress.unlockedMission) - 1).coerceAtLeast(0)
        route = Route.Map
    }

    /** Called by the activity after [Input] records a key. */
    fun dispatchKeys() { handler?.invoke() }

    /** Registers the screen's key handler; a screen fading out during a transition never takes over. */
    @Composable
    fun Keys(onKeys: () -> Unit) {
        val active = LocalActiveRoute.current
        LaunchedEffect(active) { if (active) Input.clearPresses() }
        if (active) handler = onKeys
    }

    fun select() = Chiptune.play(SoundEffect.Select)
}

@Composable
fun AlinaWorldApp() {
    val route = Router.route
    LaunchedEffect(route) {
        when (route) {
            Route.Menu, Route.Map, is Route.Settings, is Route.Briefing -> Chiptune.play(Songs.title)
            is Route.Playing -> Missions.byId(route.id)?.let {
                Chiptune.play(Songs.level(WorldThemes.index(it.world), it.objective == Objective.DefeatBoss))
            }
            is Route.Won -> Chiptune.play(Songs.victory)
            is Route.Lost -> Chiptune.play(Songs.defeat)
        }
        Chiptune.setDucked(false)
    }

    Box(Modifier.fillMaxSize().background(Palette.cream)) {
        Crossfade(route, animationSpec = tween(250), label = "route") { current ->
            CompositionLocalProvider(LocalActiveRoute provides (current === route)) { DesignCanvas {
                when (current) {
                    Route.Menu -> MainMenuScreen()
                    Route.Map -> MissionMapScreen()
                    is Route.Settings -> SettingsScreen(current.back)
                    is Route.Briefing -> Missions.byId(current.id)?.let { BriefingScreen(it) }
                    is Route.Playing -> Missions.byId(current.id)?.let { GameScreen(it, current.attempt) }
                    is Route.Won -> MissionCompleteScreen(current.result)
                    is Route.Lost -> DefeatScreen(current.id, current.reason)
                }
            } }
        }
    }
}
