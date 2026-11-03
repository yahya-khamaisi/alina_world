package app.jannat.alinaworld.game

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.view.Choreographer
import android.view.View

/** Hosts one [GameWorld]: steps it on every display frame and draws it with [GameRenderer]. */
@SuppressLint("ViewConstructor")
class GameView(context: Context, val world: GameWorld, private val onHud: (HudSnapshot) -> Unit) : View(context), Choreographer.FrameCallback {
    private val renderer = GameRenderer(world)
    private var lastFrame = 0L
    private var lastHud: HudSnapshot? = null
    private var running = false

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        running = true
        lastFrame = 0L
        Choreographer.getInstance().postFrameCallback(this)
    }

    override fun onDetachedFromWindow() {
        running = false
        Choreographer.getInstance().removeFrameCallback(this)
        super.onDetachedFromWindow()
    }

    override fun doFrame(frameTimeNanos: Long) {
        if (!running) return
        val dt = if (lastFrame == 0L) 1f / 60f else (frameTimeNanos - lastFrame) / 1_000_000_000f
        lastFrame = frameTimeNanos
        world.update(dt)
        val hud = world.hud()
        if (hud != lastHud) { lastHud = hud; onHud(hud) }
        invalidate()
        Choreographer.getInstance().postFrameCallback(this)
    }

    /** Called after resuming so the pause doesn't count as one long frame. */
    fun resetClock() { lastFrame = 0L }

    override fun onDraw(canvas: Canvas) {
        renderer.draw(canvas, width, height)
    }
}
