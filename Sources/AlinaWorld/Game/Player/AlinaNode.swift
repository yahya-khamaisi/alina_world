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
    /// One extra jump in the air; refilled on landing and by stomping an enemy.
    private(set) var airJumps = 1
    /// Set for one frame when the air jump fires, so the scene can leave a sparkle puff.
    var didAirJump = false
    /// Frostpeak ice: less grip, so Alina slides before she stops.
    var slippery = false
    /// Spring launches rise to full height even with jump released.
    private var fullRiseTimer: CGFloat = 0

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
    /// The long glowing ribbon held overhead while gliding.
    private let glideRibbon: SKSpriteNode
    private let aura: SKSpriteNode
    /// Shows the double-jump pose for a moment after the air jump fires.
    private var doubleJumpTimer: CGFloat = 0
    private var textures: [PixelSprite: SKTexture] = [:]
    /// Cut-out puppet with procedural animation; replaces the painted frames once `AlinaRig.png` is bundled.
    private var rig: AlinaRig?
    private var dust: SKEmitterNode?
    private let groundShadow = SKSpriteNode(texture: EffectTextures.glow, size: CGSize(width: 28, height: 7))

    /// World units per art pixel. The 24 × 33 sprite stands about 50 units tall over the 28-unit hitbox
    /// (the chibi head rises above it, like the v3 mockups).
    private static let pixel: CGFloat = 1.5
    private static let bloomOverrides = AlinaArt.bloomOverrides
    private static let doubleJumpDuration: CGFloat = 0.42
    /// Centre of the body sprite so the boots sit on the hitbox floor and the torso is over the hitbox.
    private static let bodyOffset = CGPoint(x: -1.5, y: -GameConstants.playerHeight / 2 + CGFloat(AlinaArt.size.height) * pixel / 2)

    override init() {
        body = PixelArt.node(.alinaIdle, scale: Self.pixel)
        ribbonNode = PixelArt.node(.ribbon, scale: 2)
        glideRibbon = SKSpriteNode(
            texture: AlinaEffects.ribbonFrames[0],
            size: CGSize(width: CGFloat(AlinaEffects.ribbonSize.width) * Self.pixel, height: CGFloat(AlinaEffects.ribbonSize.height) * Self.pixel)
        )
        let glowContext = CGContext(data: nil, width: 128, height: 128, bitsPerComponent: 8, bytesPerRow: 0,
                                    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let glow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                              colors: [Drawing.color(0xFFE99A, alpha: 0.38), Drawing.color(0xFFE99A, alpha: 0)] as CFArray,
                              locations: [0, 1])!
        glowContext.drawRadialGradient(glow, startCenter: CGPoint(x: 64, y: 64), startRadius: 8,
                                       endCenter: CGPoint(x: 64, y: 64), endRadius: 64, options: [])
        aura = SKSpriteNode(texture: SKTexture(cgImage: glowContext.makeImage()!), size: CGSize(width: 64, height: 64))
        super.init()
        name = "alina"
        zPosition = 10

        groundShadow.color = SKColor(hex: 0x35243A)
        groundShadow.colorBlendFactor = 1
        groundShadow.alpha = 0.24
        groundShadow.position = CGPoint(x: 0, y: -13)
        groundShadow.zPosition = -1
        addChild(groundShadow)
        addChild(visualRoot)
        body.position = Self.bodyOffset

        aura.isHidden = true
        aura.zPosition = -2
        aura.run(.repeatForever(.sequence([.scale(to: 1.1, duration: 0.5), .scale(to: 0.9, duration: 0.5)])))
        visualRoot.addChild(aura)

        ribbonNode.position = CGPoint(x: -12, y: 4)
        ribbonNode.zPosition = -1
        ribbonNode.isHidden = true
        visualRoot.addChild(ribbonNode)

        // Pin the ribbon's handle pixel to the raised hand in the glide frame (art pixel 22.5, 17.5).
        let handle = AlinaEffects.ribbonHandle
        glideRibbon.anchorPoint = CGPoint(
            x: handle.x / CGFloat(AlinaEffects.ribbonSize.width),
            y: 1 - handle.y / CGFloat(AlinaEffects.ribbonSize.height)
        )
        glideRibbon.position = CGPoint(
            x: Self.bodyOffset.x + (22.5 - CGFloat(AlinaArt.size.width) / 2) * Self.pixel,
            y: Self.bodyOffset.y + (CGFloat(AlinaArt.size.height) / 2 - 17.5) * Self.pixel
        )
        glideRibbon.zPosition = -1
        glideRibbon.isHidden = true
        visualRoot.addChild(glideRibbon)

        visualRoot.addChild(body)
        if AlinaRig.isAvailable {
            let rig = AlinaRig(height: 52, feetY: -GameConstants.playerHeight / 2)
            visualRoot.addChild(rig)
            self.rig = rig
            body.isHidden = true
        }
        reloadTextures()
        setupDust()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func reloadTextures() {
        let overrides = bloom ? Self.bloomOverrides : [:]
        for sprite in [PixelSprite.alinaIdle, .alinaBlink, .alinaRun, .alinaRunB, .alinaJump, .alinaDoubleJump, .alinaFall, .alinaGlide] {
            textures[sprite] = PixelArt.texture(sprite, overrides: overrides)
        }
        body.texture = textures[.alinaIdle]
        aura.isHidden = !bloom
    }

    private func setupDust() {
        let emitter = SKEmitterNode()
        emitter.particleTexture = EffectTextures.softDot
        emitter.particleBirthRate = 0
        emitter.particleLifetime = 0.35
        emitter.particlePositionRange = CGVector(dx: 10, dy: 2)
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 3
        emitter.particleSpeed = 40
        emitter.particleSpeedRange = 20
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -2.2
        emitter.particleSize = CGSize(width: 9, height: 9)
        emitter.particleScaleSpeed = 1.6
        emitter.particleColor = SKColor(hex: 0xF6E6D2)
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
        let accel: CGFloat = onGround ? (slippery ? 900 : 1800) : 1200
        let friction: CGFloat = onGround ? (slippery ? 260 : 1400) : 400
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
        // Always consume the tap, so a press seen as an edge doesn't fire a second (air) jump next frame.
        let tapped = input.consumeJumpTap()
        let jumpPressed = (input.jumpHeld && !lastJumpHeld) || tapped
        lastJumpHeld = input.jumpHeld
        if jumpPressed {
            jumpBufferTimer = 0.12
        } else if jumpBufferTimer > 0 {
            jumpBufferTimer -= dt
        }

        if onGround {
            coyoteTimer = 0.12
            airJumps = 1
        } else if coyoteTimer > 0 {
            coyoteTimer -= dt
        }

        didAirJump = false
        if jumpBufferTimer > 0 && coyoteTimer > 0 {
            velocityY = jumpVelocity
            jumpBufferTimer = 0
            coyoteTimer = 0
            onGround = false
            setState(.jump)
            ChiptuneEngine.shared.play(.jump)
        } else if jumpPressed && !onGround && airJumps > 0 {
            // Double jump: a fresh press in the air resets the fall into a slightly smaller hop.
            airJumps -= 1
            velocityY = jumpVelocity * 0.9
            jumpBufferTimer = 0
            didAirJump = true
            doubleJumpTimer = Self.doubleJumpDuration
            currentState = .fall
            setState(.jump)
            ChiptuneEngine.shared.play(.doubleJump)
        }

        if fullRiseTimer > 0 { fullRiseTimer -= dt }
        if !input.jumpHeld && fullRiseTimer <= 0 && velocityY > 200 {
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
            body.run(.sequence([.scaleY(to: 0.8, duration: 0.05), .scaleY(to: 1.0, duration: 0.1)]), withKey: "pose")
        case .jump:
            body.run(.sequence([.scaleY(to: 1.15, duration: 0.06), .scaleY(to: 1.0, duration: 0.1)]), withKey: "pose")
        case .bounce:
            body.run(.sequence([.scaleY(to: 0.75, duration: 0.05), .scaleY(to: 1.1, duration: 0.1), .scaleY(to: 1.0, duration: 0.05)]), withKey: "pose")
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
            let frames = CharacterAtlas.runFrames
            let count = frames.isEmpty ? 2 : frames.count
            let frameTime = max(0.045, min(0.12, 14 / max(abs(velocityX), 80)))
            if frameTimer >= frameTime {
                frameIndex = (frameIndex + Int(frameTimer / frameTime)) % count
                frameTimer = frameTimer.truncatingRemainder(dividingBy: frameTime)
                if onGround && frameIndex.isMultiple(of: max(1, count / 2)) && abs(velocityX) > 120 { puffDust(rate: 110) }
            }
            texture = frames.isEmpty ? (frameIndex == 0 ? textures[.alinaRun] : textures[.alinaRunB]) : frames[frameIndex]
        case .jump, .bounce:
            texture = doubleJumpTimer > 0 ? textures[.alinaDoubleJump] : textures[.alinaJump]
        case .fall:
            texture = doubleJumpTimer > 0 ? textures[.alinaDoubleJump] : textures[.alinaFall]
        case .glide:
            texture = textures[.alinaGlide]
        }
        if doubleJumpTimer > 0 { doubleJumpTimer -= dt }
        if let texture, body.texture !== texture {
            body.texture = texture
            body.size.width = currentState == .glide ? 30 * Self.pixel : 24 * Self.pixel
        }

        let gliding = currentState == .glide
        // The illustrated glide pose already includes the ribbon; only legacy fallback art needs the overlay.
        glideRibbon.isHidden = !gliding || CharacterAtlas.image(.alinaGlide) != nil
        ribbonNode.isHidden = !hasRibbon || gliding
        if gliding {
            let frames = AlinaEffects.ribbonFrames
            let frame = frames[Int(stateTimer * 12) % frames.count]
            if glideRibbon.texture !== frame { glideRibbon.texture = frame }
        }
        groundShadow.isHidden = !onGround
        let breathing = currentState == .idle ? sin(stateTimer * 2.2) : 0
        let floating = gliding ? sin(stateTimer * 3.2) : 0
        body.position = CGPoint(x: Self.bodyOffset.x + floating * 0.5, y: Self.bodyOffset.y + breathing * 0.25 + floating * 0.65)
        if body.action(forKey: "pose") == nil { body.yScale = 1 + breathing * 0.008 }
        body.zRotation = gliding ? floating * 0.025 : 0
        visualRoot.zRotation = currentState == .skid ? (facingRight ? -0.12 : 0.12) : 0

        if let rig {
            body.isHidden = true
            glideRibbon.isHidden = true
            visualRoot.zRotation = 0
            rig.update(AlinaRig.Motion(
                state: currentState,
                velocity: CGVector(dx: velocityX, dy: velocityY),
                onGround: onGround,
                bloom: bloom,
                flip: doubleJumpTimer > 0 ? 1 - doubleJumpTimer / Self.doubleJumpDuration : nil,
                dt: dt
            ))
        }
    }

    func applyBounce(velocity: CGFloat = GameConstants.stompBounceVelocity) {
        velocityY = velocity
        onGround = false
        airJumps = 1
        fullRiseTimer = velocity > GameConstants.stompBounceVelocity ? 0.5 : 0
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
