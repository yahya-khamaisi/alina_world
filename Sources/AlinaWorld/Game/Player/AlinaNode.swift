import SpriteKit

enum PlayerState {
    case idle
    case walk
    case run
    case jump
    case fall
    case glide
    case land
    case skid
    case hurt
    case bounce
}

final class AlinaNode: SKNode {
    var velocityX: CGFloat = 0
    var velocityY: CGFloat = 0
    var onGround = false
    var coyoteTimer: CGFloat = 0
    var jumpBufferTimer: CGFloat = 0
    var facingRight = true
    var hurtCooldown: CGFloat = 0
    var stompGraceTimer: CGFloat = 0

    /// Sunbloom: absorbs one hit and gilds Alina's bow.
    private(set) var bloom = false
    /// Glow Ribbon: hold jump while falling to glide.
    private(set) var hasRibbon = false

    private var currentState: PlayerState = .idle
    private var stateTimer: CGFloat = 0
    private var frameTimer: CGFloat = 0
    private var frameIndex = 0
    private var blinkTimer: CGFloat = 2.5
    private var wasOnGround = false
    private var lastJumpHeld = false

    private let visualRoot = SKNode()
    private let body: SKSpriteNode
    private let ribbonNode: SKSpriteNode
    private let aura: SKShapeNode
    private var textures: [PixelSprite: SKTexture] = [:]
    private var dust: SKEmitterNode?

    private static let pixel: CGFloat = 2
    private static let bloomOverrides: [Character: UInt32] = ["K": 0xF6C343, "D": 0xD9901A]

    override init() {
        body = PixelArt.node(.alinaIdle, scale: Self.pixel)
        ribbonNode = PixelArt.node(.ribbon, scale: 2)
        aura = SKShapeNode(circleOfRadius: 24)
        super.init()
        name = "alina"
        zPosition = 10

        // Sprite is 36 pt tall over a 28 pt hitbox: lift it so the boots sit on the hitbox floor.
        visualRoot.position = CGPoint(x: 0, y: 4)
        addChild(visualRoot)

        aura.fillColor = SKColor(hex: 0xFFE98A, alpha: 0.3)
        aura.strokeColor = .clear
        aura.isHidden = true
        aura.zPosition = -2
        aura.run(.repeatForever(.sequence([.scale(to: 1.1, duration: 0.5), .scale(to: 0.9, duration: 0.5)])))
        visualRoot.addChild(aura)

        ribbonNode.position = CGPoint(x: -10, y: 2)
        ribbonNode.zPosition = -1
        ribbonNode.isHidden = true
        visualRoot.addChild(ribbonNode)

        visualRoot.addChild(body)
        reloadTextures()
        setupDust()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func reloadTextures() {
        let overrides = bloom ? Self.bloomOverrides : [:]
        for sprite in [PixelSprite.alinaIdle, .alinaBlink, .alinaRun, .alinaJump, .alinaFall] {
            textures[sprite] = PixelArt.texture(sprite, overrides: overrides)
        }
        body.texture = textures[.alinaIdle]
        aura.isHidden = !bloom
    }

    private func setupDust() {
        let emitter = SKEmitterNode()
        emitter.particleTexture = PixelArt.squareTexture
        emitter.particleBirthRate = 0
        emitter.particleLifetime = 0.35
        emitter.particlePositionRange = CGVector(dx: 10, dy: 2)
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 3
        emitter.particleSpeed = 40
        emitter.particleSpeedRange = 20
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -2.2
        emitter.particleSize = CGSize(width: 4, height: 4)
        emitter.particleColor = SKColor(white: 1, alpha: 1)
        emitter.particleColorBlendFactor = 1
        emitter.position = CGPoint(x: 0, y: -14)
        emitter.zPosition = -1
        addChild(emitter)
        dust = emitter
    }

    var collisionRect: CGRect {
        let w = GameConstants.playerWidth
        let h = GameConstants.playerHeight
        return CGRect(x: position.x - w / 2, y: position.y - h / 2, width: w, height: h)
    }

    // MARK: Power-ups

    func grantBloom() {
        bloom = true
        reloadTextures()
        flashPowerUp()
    }

    func grantRibbon() {
        hasRibbon = true
        ribbonNode.isHidden = false
        flashPowerUp()
    }

    /// Spends the strongest power-up to survive a hit; returns false when Alina had none.
    func absorbHit() -> Bool {
        if bloom {
            bloom = false
            reloadTextures()
            return true
        }
        if hasRibbon {
            hasRibbon = false
            ribbonNode.isHidden = true
            return true
        }
        return false
    }

    private func flashPowerUp() {
        visualRoot.run(.sequence([
            .scale(to: 1.25, duration: 0.08),
            .scale(to: 0.95, duration: 0.08),
            .scale(to: 1.1, duration: 0.06),
            .scale(to: 1.0, duration: 0.06)
        ]))
    }

    // MARK: Update

    func update(input: InputController, delta: TimeInterval, difficulty: MissionDifficulty) {
        let dt = CGFloat(delta)
        wasOnGround = onGround

        let walkSpeed: CGFloat = difficulty == .hard ? 260 : (difficulty == .normal ? 230 : 200)
        let runSpeed: CGFloat = difficulty == .hard ? 360 : (difficulty == .normal ? 320 : 280)
        let maxSpeed = input.sprint ? runSpeed : walkSpeed
        let accel: CGFloat = onGround ? 1800 : 1200
        let friction: CGFloat = onGround ? 1400 : 400
        let jumpVelocity: CGFloat = input.sprint ? 720 : 640
        let gravity = GameConstants.gravity

        let movingLeft = input.left && !input.right
        let movingRight = input.right && !input.left
        let noHorizontalInput = !input.left && !input.right

        if movingLeft {
            velocityX -= accel * dt
            facingRight = false
        }
        if movingRight {
            velocityX += accel * dt
            facingRight = true
        }

        if noHorizontalInput && onGround {
            if velocityX > 0 {
                velocityX = max(0, velocityX - friction * dt)
            } else if velocityX < 0 {
                velocityX = min(0, velocityX + friction * dt)
            }
        }

        let wasSkidding = (velocityX > 0 && movingLeft) || (velocityX < 0 && movingRight)
        velocityX = max(-maxSpeed, min(maxSpeed, velocityX))

        // Buffer only fresh presses so holding jump (to glide) never auto-hops on landing.
        let jumpPressed = input.jumpHeld && !lastJumpHeld
        lastJumpHeld = input.jumpHeld
        if jumpPressed {
            jumpBufferTimer = 0.12
        } else if jumpBufferTimer > 0 {
            jumpBufferTimer -= dt
        }

        if onGround {
            coyoteTimer = 0.12
        } else if coyoteTimer > 0 {
            coyoteTimer -= dt
        }

        if jumpBufferTimer > 0 && coyoteTimer > 0 {
            velocityY = jumpVelocity
            jumpBufferTimer = 0
            coyoteTimer = 0
            onGround = false
            setState(.jump)
        }

        if !input.jumpHeld && velocityY > 200 {
            velocityY -= gravity * 0.45 * dt
        }

        velocityY -= gravity * dt

        let gliding = hasRibbon && !onGround && input.jumpHeld && velocityY < -110
        if gliding {
            velocityY = -110
        }

        if hurtCooldown > 0 {
            hurtCooldown -= dt
            visualRoot.alpha = Int(hurtCooldown * 14) % 2 == 0 ? 0.35 : 1
        } else {
            visualRoot.alpha = 1
        }

        if stompGraceTimer > 0 {
            stompGraceTimer -= dt
        }

        updateStateMachine(movingLeft: movingLeft, movingRight: movingRight, wasSkidding: wasSkidding, gliding: gliding, input: input)
        updateAnimation(dt: dt)

        visualRoot.xScale = facingRight ? 1 : -1
    }

    private func updateStateMachine(movingLeft: Bool, movingRight: Bool, wasSkidding: Bool, gliding: Bool, input: InputController) {
        let moving = (movingLeft || movingRight) && onGround
        if hurtCooldown > 0.7 { return }

        if !onGround {
            if gliding {
                setState(.glide)
            } else {
                setState(velocityY > 50 ? .jump : .fall)
            }
        } else if wasSkidding && abs(velocityX) > 50 {
            setState(.skid)
        } else if moving {
            setState(input.sprint ? .run : .walk)
        } else if !wasOnGround && onGround {
            setState(.land)
        } else if currentState != .land || stateTimer > 0.12 {
            setState(.idle)
        }
    }

    private func setState(_ newState: PlayerState) {
        if currentState == newState { return }
        currentState = newState
        stateTimer = 0
        frameTimer = 0
        frameIndex = 0

        switch newState {
        case .land:
            puffDust(rate: 600)
            body.run(.sequence([.scaleY(to: 0.8, duration: 0.05), .scaleY(to: 1.0, duration: 0.1)]))
        case .jump:
            body.run(.sequence([.scaleY(to: 1.15, duration: 0.06), .scaleY(to: 1.0, duration: 0.1)]))
        case .bounce:
            body.run(.sequence([.scaleY(to: 0.75, duration: 0.05), .scaleY(to: 1.1, duration: 0.1), .scaleY(to: 1.0, duration: 0.05)]))
        case .skid:
            puffDust(rate: 400)
        default:
            break
        }
    }

    private func puffDust(rate: CGFloat) {
        dust?.particleBirthRate = rate
        dust?.run(.sequence([.wait(forDuration: 0.06), .run { [weak self] in self?.dust?.particleBirthRate = 0 }]))
    }

    private func updateAnimation(dt: CGFloat) {
        stateTimer += dt
        frameTimer += dt

        let texture: SKTexture?
        switch currentState {
        case .idle, .land, .hurt:
            blinkTimer -= dt
            if blinkTimer < 0 { blinkTimer = .random(in: 2.2...4.0) }
            texture = blinkTimer < 0.12 ? textures[.alinaBlink] : textures[.alinaIdle]
        case .walk, .run, .skid:
            let frameTime: CGFloat = currentState == .run ? 0.08 : 0.13
            if frameTimer > frameTime {
                frameTimer = 0
                frameIndex = (frameIndex + 1) % 2
                if onGround && frameIndex == 0 && abs(velocityX) > 120 { puffDust(rate: 160) }
            }
            texture = frameIndex == 0 ? textures[.alinaRun] : textures[.alinaIdle]
        case .jump, .bounce:
            texture = textures[.alinaJump]
        case .fall, .glide:
            texture = textures[.alinaFall]
        }
        if let texture, body.texture !== texture { body.texture = texture }

        if currentState == .glide {
            ribbonNode.zRotation = sin(stateTimer * 18) * 0.25
            ribbonNode.position = CGPoint(x: -12, y: 10)
        } else {
            ribbonNode.zRotation = 0
            ribbonNode.position = CGPoint(x: -10, y: 2)
        }
        visualRoot.zRotation = currentState == .skid ? (facingRight ? -0.12 : 0.12) : 0
    }

    func applyBounce() {
        velocityY = GameConstants.stompBounceVelocity
        onGround = false
        stompGraceTimer = 0.35
        setState(.bounce)
    }

    func knockback(from enemyX: CGFloat) {
        guard hurtCooldown <= 0 else { return }
        hurtCooldown = 1.2
        velocityY = 380
        velocityX = position.x < enemyX ? -280 : 280
        setState(.hurt)
    }

    /// Clears motion and power state after a respawn.
    func resetForRespawn(at point: CGPoint) {
        position = point
        velocityX = 0
        velocityY = 0
        hurtCooldown = 1.0
        setState(.idle)
    }
}
