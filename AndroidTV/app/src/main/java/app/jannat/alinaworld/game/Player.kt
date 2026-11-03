package app.jannat.alinaworld.game

import app.jannat.alinaworld.audio.Chiptune
import app.jannat.alinaworld.audio.SoundEffect
import app.jannat.alinaworld.data.Difficulty
import app.jannat.alinaworld.pixel.PixelSprite
import kotlin.math.abs
import kotlin.math.sin
import kotlin.random.Random

enum class PlayerState { Idle, Walk, Run, Jump, Fall, Glide, Land, Skid, Hurt, Bounce }

/** Alina: the same feel as the Mac game — acceleration, sprint, variable jump, coyote time and buffering. */
class Player {
    var x = 0f
    var y = 0f
    var vx = 0f
    var vy = 0f
    var onGround = false
    var facingRight = true
    var hurtCooldown = 0f
    var stompGraceTimer = 0f
    private var coyoteTimer = 0f
    private var jumpBufferTimer = 0f
    /**
     * A remote's D-pad can't be held while OK is pressed, so ground friction waits a moment after a
     * direction is released; a run-up then carries into the jump instead of stopping dead.
     */
    private var coastTimer = 0f
    private var lastDirection = 0

    /** Sunbloom: absorbs one hit and gilds Alina's bow. */
    var bloom = false; private set
    /** Glow Ribbon: hold jump while falling to glide. */
    var hasRibbon = false; private set
    /** One extra jump in the air; refilled on landing and by stomping an enemy. */
    var airJumps = 1; private set
    /** True for the frame the air jump fires, so the world can leave a sparkle puff. */
    var didAirJump = false; private set
    /** Frostpeak ice: less grip, so Alina slides before she stops. */
    var slippery = false

    var state = PlayerState.Idle; private set
    var stateTimer = 0f; private set
    private var frameTimer = 0f
    private var frameIndex = 0
    private var blinkTimer = 2.5f
    private var wasOnGround = false
    private var lastJumpHeld = false

    // Visuals
    var sprite = PixelSprite.AlinaIdle; private set
    val bodyScaleY = Tween(1f)
    val rootScale = Tween(1f)
    var alpha = 1f
    /** Fail animation: rises 30 then fades. */
    var failT = -1f
    val gliding get() = state == PlayerState.Glide
    val rotation get() = if (state == PlayerState.Skid) (if (facingRight) -0.12f else 0.12f) else 0f
    val ribbonRotation get() = if (gliding) sin(stateTimer * 18) * 0.25f else 0f

    /** Pending dust puffs (count), drained by the world into particles. */
    var dustRequest = 0

    val box get() = Box(x - GameConstants.PLAYER_WIDTH / 2, y - GameConstants.PLAYER_HEIGHT / 2, GameConstants.PLAYER_WIDTH, GameConstants.PLAYER_HEIGHT)

    fun primeJump(held: Boolean) { lastJumpHeld = held; Input.consumeJumpTap() }

    /**
     * A remote press is short, so every jump gets this long at full strength before letting go cuts it;
     * holding longer still reaches the full height.
     */
    private var jumpBoost = 0f

    fun grantBloom() { bloom = true; flashPowerUp() }
    fun grantRibbon() { hasRibbon = true; flashPowerUp() }

    /** Spends the strongest power-up to survive a hit; returns false when Alina had none. */
    fun absorbHit(): Boolean {
        if (bloom) { bloom = false; return true }
        if (hasRibbon) { hasRibbon = false; return true }
        return false
    }

    private fun flashPowerUp() = rootScale.run(1.25f to 0.08f, 0.95f to 0.08f, 1.1f to 0.06f, 1f to 0.06f)

    fun update(dt: Float, difficulty: Difficulty) {
        wasOnGround = onGround
        val input = Input
        val walkSpeed = when (difficulty) { Difficulty.Hard -> 260f; Difficulty.Normal -> 230f; Difficulty.Easy -> 200f }
        val runSpeed = when (difficulty) { Difficulty.Hard -> 360f; Difficulty.Normal -> 320f; Difficulty.Easy -> 280f }
        val maxSpeed = if (input.sprint) runSpeed else walkSpeed
        val accel = if (onGround) (if (slippery) 900f else 1800f) else 1200f
        val friction = if (onGround) (if (slippery) 260f else 1400f) else 400f
        val jumpVelocity = if (input.sprint || abs(vx) > walkSpeed) 720f else 640f
        val gravity = GameConstants.GRAVITY

        val movingLeft = input.movingLeft && !input.movingRight
        val movingRight = input.movingRight && !input.movingLeft
        val noInput = !movingLeft && !movingRight

        if (movingLeft) { vx -= accel * dt; facingRight = false; lastDirection = -1 }
        if (movingRight) { vx += accel * dt; facingRight = true; lastDirection = 1 }
        if (noInput) {
            if (lastDirection != 0) { coastTimer = 0.22f; lastDirection = 0 } else if (coastTimer > 0) coastTimer -= dt
        }

        if (noInput && onGround && coastTimer <= 0) {
            vx = if (vx > 0) maxOf(0f, vx - friction * dt) else if (vx < 0) minOf(0f, vx + friction * dt) else 0f
        }

        val wasSkidding = (vx > 0 && movingLeft) || (vx < 0 && movingRight)
        // Keep a sprint's speed while coasting into a jump.
        val cap = if (noInput && coastTimer > 0) maxOf(maxSpeed, abs(vx)) else maxSpeed
        vx = vx.coerceIn(-cap, cap)

        // Buffer only fresh presses so holding jump (to glide) never auto-hops on landing.
        val jumpPressed = (input.jumpHeld && !lastJumpHeld) or input.consumeJumpTap()
        lastJumpHeld = input.jumpHeld
        if (jumpPressed) jumpBufferTimer = 0.15f else if (jumpBufferTimer > 0) jumpBufferTimer -= dt

        if (onGround) { coyoteTimer = 0.15f; airJumps = 1 } else if (coyoteTimer > 0) coyoteTimer -= dt

        didAirJump = false

        if (jumpBufferTimer > 0 && coyoteTimer > 0) {
            vy = jumpVelocity
            jumpBufferTimer = 0f
            coyoteTimer = 0f
            onGround = false
            jumpBoost = 0.2f
            setState(PlayerState.Jump)
            Chiptune.play(SoundEffect.Jump)
        } else if (jumpPressed && !onGround && airJumps > 0) {
            // Double jump: a fresh press in the air resets the fall into a slightly smaller hop.
            airJumps--
            vy = jumpVelocity * 0.9f
            jumpBufferTimer = 0f
            jumpBoost = 0.2f
            didAirJump = true
            state = PlayerState.Fall
            setState(PlayerState.Jump)
            Chiptune.play(SoundEffect.DoubleJump)
        }
        if (jumpBoost > 0) jumpBoost -= dt

        if (!input.jumpHeld && jumpBoost <= 0 && vy > 200) vy -= gravity * 0.45f * dt
        vy -= gravity * dt

        val gliding = hasRibbon && !onGround && input.jumpHeld && vy < -110
        if (gliding) vy = -110f

        if (hurtCooldown > 0) {
            hurtCooldown -= dt
            alpha = if ((hurtCooldown * 14).toInt() % 2 == 0) 0.35f else 1f
        } else {
            alpha = 1f
        }
        if (stompGraceTimer > 0) stompGraceTimer -= dt

        updateStateMachine(movingLeft, movingRight, wasSkidding, gliding)
        updateAnimation(dt)
    }

    private fun updateStateMachine(movingLeft: Boolean, movingRight: Boolean, wasSkidding: Boolean, gliding: Boolean) {
        val moving = (movingLeft || movingRight) && onGround
        if (hurtCooldown > 0.7f) return
        when {
            !onGround -> setState(if (gliding) PlayerState.Glide else if (vy > 50) PlayerState.Jump else PlayerState.Fall)
            wasSkidding && abs(vx) > 50 -> setState(PlayerState.Skid)
            moving -> setState(if (Input.sprint) PlayerState.Run else PlayerState.Walk)
            !wasOnGround && onGround -> setState(PlayerState.Land)
            state != PlayerState.Land || stateTimer > 0.12f -> setState(PlayerState.Idle)
        }
    }

    private fun setState(newState: PlayerState) {
        if (state == newState) return
        state = newState
        stateTimer = 0f
        frameTimer = 0f
        frameIndex = 0
        when (newState) {
            PlayerState.Land -> { dustRequest += 10; bodyScaleY.run(0.8f to 0.05f, 1f to 0.1f) }
            PlayerState.Jump -> bodyScaleY.run(1.15f to 0.06f, 1f to 0.1f)
            PlayerState.Bounce -> bodyScaleY.run(0.75f to 0.05f, 1.1f to 0.1f, 1f to 0.05f)
            PlayerState.Skid -> dustRequest += 6
            else -> Unit
        }
    }

    /** Visual timers only; also runs while the mission is finishing. */
    fun updateVisuals(dt: Float) {
        bodyScaleY.update(dt)
        rootScale.update(dt)
        if (failT >= 0) {
            failT += dt
            alpha = 1 - ((failT - 0.2f) / 0.3f).coerceIn(0f, 1f)
        }
    }

    private fun updateAnimation(dt: Float) {
        stateTimer += dt
        frameTimer += dt
        sprite = when (state) {
            PlayerState.Idle, PlayerState.Land, PlayerState.Hurt -> {
                blinkTimer -= dt
                if (blinkTimer < 0) blinkTimer = 2.2f + Random.nextFloat() * 1.8f
                if (blinkTimer < 0.12f) PixelSprite.AlinaBlink else PixelSprite.AlinaIdle
            }
            PlayerState.Walk, PlayerState.Run, PlayerState.Skid -> {
                val frameTime = if (state == PlayerState.Run) 0.08f else 0.13f
                if (frameTimer > frameTime) {
                    frameTimer = 0f
                    frameIndex = (frameIndex + 1) % 2
                    if (onGround && frameIndex == 0 && abs(vx) > 120) dustRequest += 3
                }
                if (frameIndex == 0) PixelSprite.AlinaRun else PixelSprite.AlinaIdle
            }
            PlayerState.Jump, PlayerState.Bounce -> PixelSprite.AlinaJump
            PlayerState.Fall, PlayerState.Glide -> PixelSprite.AlinaFall
        }
    }

    fun applyBounce(velocity: Float = GameConstants.STOMP_BOUNCE) {
        vy = velocity
        onGround = false
        airJumps = 1
        // Spring launches rise to full height even with jump released.
        if (velocity > GameConstants.STOMP_BOUNCE) jumpBoost = 0.5f
        stompGraceTimer = 0.35f
        setState(PlayerState.Bounce)
    }

    fun knockback(fromX: Float) {
        if (hurtCooldown > 0) return
        hurtCooldown = 1.2f
        vy = 380f
        vx = if (x < fromX) -280f else 280f
        setState(PlayerState.Hurt)
    }

    /** Clears motion after a respawn. */
    fun resetForRespawn(px: Float, py: Float) {
        x = px; y = py; vx = 0f; vy = 0f
        hurtCooldown = 1f
        setState(PlayerState.Idle)
    }
}
