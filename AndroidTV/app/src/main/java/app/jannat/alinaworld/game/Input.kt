package app.jannat.alinaworld.game

import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent

/**
 * Remote, keyboard and gamepad state. Held keys drive Alina; presses are consumed once by menus.
 *
 * A TV remote's arrows and OK share one ring under the thumb, so a direction can't be held while jumping.
 * With auto-run on, tapping ◀ or ▶ sets Alina running that way until ▼ stops her or the other arrow turns
 * her around, leaving the thumb free for OK. Holding a direction for a moment breaks into a sprint, which
 * stays on while she keeps running that way.
 */
object Input {
    var left = false; private set
    var right = false; private set
    private var upHeld = false
    private var okHeld = false
    val jumpHeld: Boolean get() = upHeld || okHeld
    /** Latched on every fresh jump press, so a quick tap that goes down and up between frames still jumps. */
    private var jumpTap = false
    fun consumeJumpTap() = jumpTap.also { jumpTap = false }
    private var sprintHeld = false
    private var stickX = 0f
    private var directionHeldFor = 0f

    /** Auto-run direction: -1 left, 1 right, 0 standing. Only set while [steering]. */
    var cruise = 0; private set
    private var sprintLatched = false
    /** True while a mission is running and unpaused, so menu presses never start Alina running. */
    var steering = false
        set(value) { field = value; stopCruise() }
    var autoRun = true

    val sprint: Boolean get() = sprintHeld || sprintLatched || directionHeldFor > AUTO_SPRINT_AFTER
    val movingLeft: Boolean get() = left || stickX < -0.4f || cruise < 0
    val movingRight: Boolean get() = right || stickX > 0.4f || cruise > 0

    fun stopCruise() { cruise = 0; sprintLatched = false }

    private fun steer(direction: Int) {
        if (!steering || !autoRun) return
        if (cruise != direction) sprintLatched = false
        cruise = direction
    }

    private var up = false
    private var down = false
    private var leftPress = false
    private var rightPress = false
    private var enter = false
    private var escape = false
    private var pause = false

    private const val AUTO_SPRINT_AFTER = 0.55f

    fun consumeUp() = up.also { up = false }
    fun consumeDown() = down.also { down = false }
    fun consumeLeft() = leftPress.also { leftPress = false }
    fun consumeRight() = rightPress.also { rightPress = false }
    fun consumeEnter() = enter.also { enter = false }
    fun consumeEscape() = escape.also { escape = false }
    fun consumePause() = pause.also { pause = false }

    fun clearPresses() {
        up = false; down = false; leftPress = false; rightPress = false
        enter = false; escape = false; pause = false
    }

    fun releaseAll() {
        left = false; right = false; upHeld = false; okHeld = false; sprintHeld = false; stickX = 0f; directionHeldFor = 0f
        stopCruise()
        jumpTap = false
        clearPresses()
    }

    /** Advances the auto-sprint timer; called once per game frame. */
    fun tick(dt: Float) {
        val held = (left || stickX < -0.4f) != (right || stickX > 0.4f)
        directionHeldFor = if (held) directionHeldFor + dt else 0f
        if (directionHeldFor > AUTO_SPRINT_AFTER && cruise != 0) sprintLatched = true
    }

    /** Returns true when the key belongs to the game. */
    fun handle(event: KeyEvent): Boolean {
        val down = event.action == KeyEvent.ACTION_DOWN
        val fresh = down && event.repeatCount == 0
        when (event.keyCode) {
            KeyEvent.KEYCODE_DPAD_LEFT, KeyEvent.KEYCODE_A -> {
                left = down; if (down) leftPress = true
                if (fresh) steer(-1)
            }
            KeyEvent.KEYCODE_DPAD_RIGHT, KeyEvent.KEYCODE_D -> {
                right = down; if (down) rightPress = true
                if (fresh) steer(1)
            }
            KeyEvent.KEYCODE_DPAD_UP, KeyEvent.KEYCODE_W -> {
                upHeld = down; if (down) up = true
                if (fresh) jumpTap = true
            }
            KeyEvent.KEYCODE_DPAD_DOWN, KeyEvent.KEYCODE_S -> if (down) { this.down = true; stopCruise() }
            KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_ENTER, KeyEvent.KEYCODE_NUMPAD_ENTER,
            KeyEvent.KEYCODE_BUTTON_A, KeyEvent.KEYCODE_SPACE -> {
                okHeld = down; if (fresh) { enter = true; jumpTap = true }
            }
            KeyEvent.KEYCODE_BUTTON_X, KeyEvent.KEYCODE_BUTTON_Y, KeyEvent.KEYCODE_BUTTON_R1,
            KeyEvent.KEYCODE_BUTTON_L1, KeyEvent.KEYCODE_SHIFT_LEFT, KeyEvent.KEYCODE_SHIFT_RIGHT -> sprintHeld = down
            KeyEvent.KEYCODE_BACK, KeyEvent.KEYCODE_ESCAPE, KeyEvent.KEYCODE_BUTTON_B -> if (fresh) escape = true
            KeyEvent.KEYCODE_MENU, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, KeyEvent.KEYCODE_BUTTON_START,
            KeyEvent.KEYCODE_P -> if (fresh) pause = true
            else -> return false
        }
        return true
    }

    /** Gamepad stick and hat; the hat also moves menu focus. */
    fun handle(event: MotionEvent): Boolean {
        if (event.source and InputDevice.SOURCE_JOYSTICK != InputDevice.SOURCE_JOYSTICK) return false
        val x = event.getAxisValue(MotionEvent.AXIS_X)
        val hatX = event.getAxisValue(MotionEvent.AXIS_HAT_X)
        val hatY = event.getAxisValue(MotionEvent.AXIS_HAT_Y)
        val previous = stickX
        stickX = if (kotlin.math.abs(hatX) > 0.5f) hatX else x
        if (previous > -0.5f && stickX <= -0.5f) leftPress = true
        if (previous < 0.5f && stickX >= 0.5f) rightPress = true
        if (hatY < -0.5f) up = true
        if (hatY > 0.5f) down = true
        return true
    }
}
