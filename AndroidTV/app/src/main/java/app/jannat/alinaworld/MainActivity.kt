package app.jannat.alinaworld

import android.os.Bundle
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import app.jannat.alinaworld.audio.Chiptune
import app.jannat.alinaworld.data.GameProgress
import app.jannat.alinaworld.data.Missions
import app.jannat.alinaworld.data.Settings
import app.jannat.alinaworld.game.Input
import app.jannat.alinaworld.ui.AlinaWorldApp
import app.jannat.alinaworld.ui.Route
import app.jannat.alinaworld.ui.Router

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GameProgress.init(this)
        Settings.init(this)
        Missions.load(this)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        WindowInsetsControllerCompat(window, window.decorView).apply {
            hide(WindowInsetsCompat.Type.systemBars())
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
        Router.onExit = { finish() }
        // Dev shortcut, like ALINA_START_ROUTE on the Mac: adb shell am start -e route play:8 ...
        intent.getStringExtra("route")?.let { applyRoute(it) }
        setContent { AlinaWorldApp() }
    }

    private fun applyRoute(spec: String) {
        val parts = spec.split(":")
        val id = parts.getOrNull(1)?.toIntOrNull() ?: 1
        Router.route = when (parts[0]) {
            "map" -> { Router.openMap(); Route.Map }
            "story" -> Route.Briefing(id)
            "play" -> { Router.play(id); Router.route }
            "settings" -> Route.Settings(Route.Menu)
            else -> Route.Menu
        }
    }

    override fun onResume() {
        super.onResume()
        Chiptune.start()
    }

    override fun onPause() {
        Chiptune.stop()
        Input.releaseAll()
        super.onPause()
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (Input.handle(event)) {
            Router.dispatchKeys()
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
        if (Input.handle(event)) {
            Router.dispatchKeys()
            return true
        }
        return super.dispatchGenericMotionEvent(event)
    }
}
