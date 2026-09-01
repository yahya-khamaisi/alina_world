import SpriteKit

enum PlayerState {
    case idle
    case walk
    case run
    case jump
    case fall
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

    private var currentState: PlayerState = .idle
    private var stateTimer: CGFloat = 0
    private var wasOnGround = false

    private let visualRoot = SKNode()
    private let dressBack: SKShapeNode
    private let dressFront: SKShapeNode
    private let dressRuffle: SKShapeNode
    private let torso: SKShapeNode
    private let head: SKShapeNode
    private let hairBack: SKShapeNode
    private let hairFront: SKShapeNode
    private let braid: SKShapeNode
    private let braidTip: SKShapeNode
    private let eyeLeft: SKShapeNode
    private let eyeRight: SKShapeNode
    private let pupilLeft: SKShapeNode
    private let pupilRight: SKShapeNode
    private let eyebrowLeft: SKShapeNode
    private let eyebrowRight: SKShapeNode
    private let legLeft: SKShapeNode
    private let legRight: SKShapeNode
    private let bootLeft: SKShapeNode
    private let bootRight: SKShapeNode
    private let armLeft: SKShapeNode
    private let armRight: SKShapeNode
    private let handLeft: SKShapeNode
    private let handRight: SKShapeNode
    private var walkPhase: CGFloat = 0
    private var idlePhase: CGFloat = 0
    private var dustEmitter: SKEmitterNode?
    private var landDustEmitter: SKEmitterNode?

    override init() {
        dressBack = SKShapeNode(rectOf: CGSize(width: 20, height: 16), cornerRadius: 5)
        dressFront = SKShapeNode(rectOf: CGSize(width: 18, height: 14), cornerRadius: 4)
        dressRuffle = SKShapeNode(rectOf: CGSize(width: 22, height: 6), cornerRadius: 3)
        torso = SKShapeNode(rectOf: CGSize(width: 14, height: 16), cornerRadius: 3)
        head = SKShapeNode(circleOfRadius: 11)
        hairBack = SKShapeNode(rectOf: CGSize(width: 24, height: 16), cornerRadius: 8)
        hairFront = SKShapeNode(rectOf: CGSize(width: 22, height: 10), cornerRadius: 6)
        braid = SKShapeNode(rectOf: CGSize(width: 6, height: 18), cornerRadius: 3)
        braidTip = SKShapeNode(circleOfRadius: 3)
        eyeLeft = SKShapeNode(circleOfRadius: 2.5)
        eyeRight = SKShapeNode(circleOfRadius: 2.5)
        pupilLeft = SKShapeNode(circleOfRadius: 1.2)
        pupilRight = SKShapeNode(circleOfRadius: 1.2)
        eyebrowLeft = SKShapeNode(rectOf: CGSize(width: 6, height: 1.5), cornerRadius: 0.75)
        eyebrowRight = SKShapeNode(rectOf: CGSize(width: 6, height: 1.5), cornerRadius: 0.75)
        legLeft = SKShapeNode(rectOf: CGSize(width: 6, height: 12), cornerRadius: 2)
        legRight = SKShapeNode(rectOf: CGSize(width: 6, height: 12), cornerRadius: 2)
        bootLeft = SKShapeNode(rectOf: CGSize(width: 8, height: 5), cornerRadius: 2)
        bootRight = SKShapeNode(rectOf: CGSize(width: 8, height: 5), cornerRadius: 2)
        armLeft = SKShapeNode(rectOf: CGSize(width: 5, height: 14), cornerRadius: 2)
        armRight = SKShapeNode(rectOf: CGSize(width: 5, height: 14), cornerRadius: 2)
        handLeft = SKShapeNode(circleOfRadius: 3.5)
        handRight = SKShapeNode(circleOfRadius: 3.5)

        super.init()
        name = "alina"
        zPosition = 10

        setupVisuals()
        setupEmitters()
        startIdleAnimation()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func setupVisuals() {
        dressBack.fillColor = GameGraphics.dressShadow()
        dressBack.strokeColor = GameGraphics.dressShadow().withAlphaComponent(0.8)
        dressBack.lineWidth = 1.5
        dressBack.position = CGPoint(x: 0, y: -2)

        dressFront.fillColor = GameGraphics.dressColor()
        dressFront.strokeColor = GameGraphics.dressShadow()
        dressFront.lineWidth = 2
        dressFront.position = CGPoint(x: 0, y: -1)

        dressRuffle.fillColor = SKColor(red: 1.0, green: 0.5, blue: 0.7, alpha: 1)
        dressRuffle.strokeColor = .clear
        dressRuffle.position = CGPoint(x: 0, y: -10)
        dressRuffle.zPosition = 1

        torso.fillColor = GameGraphics.skinTone()
        torso.strokeColor = SKColor(red: 0.85, green: 0.65, blue: 0.5, alpha: 1)
        torso.lineWidth = 1.5
        torso.position = CGPoint(x: 0, y: 10)

        head.fillColor = GameGraphics.skinTone()
        head.strokeColor = SKColor(red: 0.85, green: 0.65, blue: 0.5, alpha: 1)
        head.lineWidth = 2
        head.position = CGPoint(x: 0, y: 24)

        hairBack.fillColor = GameGraphics.hairColor()
        hairBack.strokeColor = .clear
        hairBack.position = CGPoint(x: 0, y: 28)

        hairFront.fillColor = SKColor(red: 0.25, green: 0.15, blue: 0.1, alpha: 1)
        hairFront.strokeColor = .clear
        hairFront.position = CGPoint(x: 0, y: 26)

        braid.fillColor = GameGraphics.hairColor()
        braid.strokeColor = .clear
        braid.position = CGPoint(x: -11, y: 18)
        braid.zPosition = 2

        braidTip.fillColor = SKColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1)
        braidTip.strokeColor = .clear
        braidTip.position = CGPoint(x: 0, y: -9)
        braid.addChild(braidTip)

        eyeLeft.fillColor = .white
        eyeRight.fillColor = .white
        eyeLeft.strokeColor = SKColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
        eyeRight.strokeColor = SKColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
        eyeLeft.lineWidth = 1
        eyeRight.lineWidth = 1
        eyeLeft.position = CGPoint(x: -4, y: 25)
        eyeRight.position = CGPoint(x: 4, y: 25)

        pupilLeft.fillColor = SKColor(red: 0.15, green: 0.12, blue: 0.2, alpha: 1)
        pupilRight.fillColor = SKColor(red: 0.15, green: 0.12, blue: 0.2, alpha: 1)
        pupilLeft.strokeColor = .clear
        pupilRight.strokeColor = .clear
        pupilLeft.position = CGPoint(x: -4, y: 25)
        pupilRight.position = CGPoint(x: 4, y: 25)
        pupilLeft.zPosition = 1
        pupilRight.zPosition = 1

        eyebrowLeft.fillColor = GameGraphics.hairColor()
        eyebrowRight.fillColor = GameGraphics.hairColor()
        eyebrowLeft.strokeColor = .clear
        eyebrowRight.strokeColor = .clear
        eyebrowLeft.position = CGPoint(x: -4, y: 28.5)
        eyebrowRight.position = CGPoint(x: 4, y: 28.5)
        eyebrowLeft.zPosition = 2
        eyebrowRight.zPosition = 2

        legLeft.fillColor = GameGraphics.skinTone()
        legRight.fillColor = GameGraphics.skinTone()
        legLeft.strokeColor = .clear
        legRight.strokeColor = .clear
        legLeft.position = CGPoint(x: -5, y: -8)
        legRight.position = CGPoint(x: 5, y: -8)

        bootLeft.fillColor = SKColor(red: 0.2, green: 0.15, blue: 0.25, alpha: 1)
        bootRight.fillColor = SKColor(red: 0.2, green: 0.15, blue: 0.25, alpha: 1)
        bootLeft.strokeColor = SKColor(red: 0.1, green: 0.08, blue: 0.15, alpha: 1)
        bootRight.strokeColor = SKColor(red: 0.1, green: 0.08, blue: 0.15, alpha: 1)
        bootLeft.lineWidth = 1
        bootRight.lineWidth = 1
        bootLeft.position = CGPoint(x: -5, y: -16)
        bootRight.position = CGPoint(x: 5, y: -16)

        armLeft.fillColor = GameGraphics.skinTone()
        armRight.fillColor = GameGraphics.skinTone()
        armLeft.strokeColor = .clear
        armRight.strokeColor = .clear
        armLeft.position = CGPoint(x: -11, y: 8)
        armRight.position = CGPoint(x: 11, y: 8)

        handLeft.fillColor = GameGraphics.skinTone()
        handRight.fillColor = GameGraphics.skinTone()
        handLeft.strokeColor = .clear
        handRight.strokeColor = .clear
        handLeft.position = CGPoint(x: 0, y: -7)
        handRight.position = CGPoint(x: 0, y: -7)

        visualRoot.addChild(dressBack)
        visualRoot.addChild(dressFront)
        visualRoot.addChild(dressRuffle)
        visualRoot.addChild(legLeft)
        visualRoot.addChild(legRight)
        visualRoot.addChild(bootLeft)
        visualRoot.addChild(bootRight)
        visualRoot.addChild(torso)
        visualRoot.addChild(armLeft)
        visualRoot.addChild(armRight)
        visualRoot.addChild(handLeft)
        visualRoot.addChild(handRight)
        visualRoot.addChild(hairBack)
        visualRoot.addChild(braid)
        visualRoot.addChild(head)
        visualRoot.addChild(hairFront)
        visualRoot.addChild(eyeLeft)
        visualRoot.addChild(eyeRight)
        visualRoot.addChild(pupilLeft)
        visualRoot.addChild(pupilRight)
        visualRoot.addChild(eyebrowLeft)
        visualRoot.addChild(eyebrowRight)
        addChild(visualRoot)

        let idleBob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 2, duration: 0.6),
            SKAction.moveBy(x: 0, y: -2, duration: 0.6)
        ])
        visualRoot.run(SKAction.repeatForever(idleBob), withKey: "idleBob")

        let blink = SKAction.sequence([
            SKAction.wait(forDuration: 3.0 + CGFloat.random(in: 0...2)),
            SKAction.scaleY(to: 0.1, duration: 0.08),
            SKAction.scaleY(to: 1.0, duration: 0.08)
        ])
        eyeLeft.run(SKAction.repeatForever(blink))
        eyeRight.run(SKAction.repeatForever(blink))
        pupilLeft.run(SKAction.repeatForever(blink))
        pupilRight.run(SKAction.repeatForever(blink))
    }

    private func setupEmitters() {
        dustEmitter = SKEmitterNode()
        dustEmitter?.particleBirthRate = 0
        dustEmitter?.numParticlesToEmit = 4
        dustEmitter?.particleLifetime = 0.3
        dustEmitter?.particleLifetimeRange = 0.1
        dustEmitter?.particlePositionRange = CGVector(dx: 8, dy: 2)
        dustEmitter?.emissionAngle = .pi / 2
        dustEmitter?.emissionAngleRange = .pi / 4
        dustEmitter?.particleSpeed = 40
        dustEmitter?.particleSpeedRange = 20
        dustEmitter?.particleAlpha = 0.6
        dustEmitter?.particleAlphaRange = 0.2
        dustEmitter?.particleAlphaSpeed = -2.0
        dustEmitter?.particleScale = 0.15
        dustEmitter?.particleScaleRange = 0.05
        dustEmitter?.particleScaleSpeed = -0.3
        dustEmitter?.particleColor = SKColor(white: 0.7, alpha: 1)
        dustEmitter?.particleColorBlendFactor = 1.0
        dustEmitter?.zPosition = 5
        dustEmitter?.targetNode = self
        if let emitter = dustEmitter { visualRoot.addChild(emitter) }

        landDustEmitter = SKEmitterNode()
        landDustEmitter?.particleBirthRate = 0
        landDustEmitter?.numParticlesToEmit = 8
        landDustEmitter?.particleLifetime = 0.4
        landDustEmitter?.particleLifetimeRange = 0.15
        landDustEmitter?.particlePositionRange = CGVector(dx: 16, dy: 4)
        landDustEmitter?.emissionAngle = .pi / 2
        landDustEmitter?.emissionAngleRange = .pi / 3
        landDustEmitter?.particleSpeed = 80
        landDustEmitter?.particleSpeedRange = 40
        landDustEmitter?.particleAlpha = 0.7
        landDustEmitter?.particleAlphaRange = 0.2
        landDustEmitter?.particleAlphaSpeed = -1.8
        landDustEmitter?.particleScale = 0.25
        landDustEmitter?.particleScaleRange = 0.1
        landDustEmitter?.particleScaleSpeed = -0.4
        landDustEmitter?.particleColor = SKColor(white: 0.6, alpha: 1)
        landDustEmitter?.particleColorBlendFactor = 1.0
        landDustEmitter?.zPosition = 5
        landDustEmitter?.targetNode = self
        if let emitter = landDustEmitter { visualRoot.addChild(emitter) }
    }

    private func startIdleAnimation() {
    }

    var collisionRect: CGRect {
        let w = GameConstants.playerWidth
        let h = GameConstants.playerHeight
        return CGRect(x: position.x - w / 2, y: position.y - h / 2, width: w, height: h)
    }

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

        let inputLeft = input.left
        let inputRight = input.right
        let movingLeft = inputLeft && !inputRight
        let movingRight = inputRight && !inputLeft
        let noHorizontalInput = !inputLeft && !inputRight

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

        if input.jumpHeld {
            jumpBufferTimer = 0.12
        } else if jumpBufferTimer > 0 {
            jumpBufferTimer -= dt
        }

        if onGround {
            coyoteTimer = 0.12
        } else if coyoteTimer > 0 {
            coyoteTimer -= dt
        }

        let jumped = jumpBufferTimer > 0 && coyoteTimer > 0
        if jumped {
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

        if hurtCooldown > 0 {
            hurtCooldown -= dt
            visualRoot.alpha = 0.65 + sin(hurtCooldown * 20) * 0.15
            if currentState != .hurt { setState(.hurt) }
        } else {
            visualRoot.alpha = 1
        }

        if stompGraceTimer > 0 {
            stompGraceTimer -= dt
        }

        updateStateMachine(dt: dt, movingLeft: movingLeft, movingRight: movingRight, noHorizontalInput: noHorizontalInput, wasSkidding: wasSkidding, input: input)
        updateAnimation(dt: dt)
        updateVisuals()

        visualRoot.xScale = facingRight ? 1 : -1
        braid.position = CGPoint(x: facingRight ? -11 : 11, y: 18)
        hairFront.position.x = facingRight ? 2 : -2
        hairBack.position.x = facingRight ? 1 : -1
    }

    private func updateStateMachine(dt: CGFloat, movingLeft: Bool, movingRight: Bool, noHorizontalInput: Bool, wasSkidding: Bool, input: InputController) {
        let moving = (movingLeft || movingRight) && onGround
        let speed = abs(velocityX)
        let isRunning = input.sprint && moving

        if hurtCooldown > 0 { return }

        if !onGround {
            if velocityY > 50 {
                setState(.jump)
            } else {
                setState(.fall)
            }
        } else if wasSkidding && speed > 50 {
            setState(.skid)
        } else if moving {
            setState(isRunning ? .run : .walk)
        } else if !wasOnGround && onGround {
            setState(.land)
        } else {
            setState(.idle)
        }
    }

    private func setState(_ newState: PlayerState) {
        if currentState == newState { return }
        currentState = newState
        stateTimer = 0

        switch newState {
        case .land:
            landDustEmitter?.resetSimulation()
            landDustEmitter?.particleBirthRate = 800
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.landDustEmitter?.particleBirthRate = 0
            }
            visualRoot.run(SKAction.sequence([
                SKAction.scaleY(to: 0.75, duration: 0.05),
                SKAction.scaleY(to: 1.0, duration: 0.1),
                SKAction.scaleY(to: 0.95, duration: 0.05),
                SKAction.scaleY(to: 1.0, duration: 0.05)
            ]))
        case .jump:
            visualRoot.run(SKAction.sequence([
                SKAction.scaleY(to: 0.85, duration: 0.05),
                SKAction.scaleY(to: 1.0, duration: 0.1)
            ]))
        case .hurt:
            visualRoot.run(SKAction.sequence([
                SKAction.colorize(with: .red, colorBlendFactor: 0.6, duration: 0.05),
                SKAction.wait(forDuration: 0.15),
                SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
            ]))
        default:
            break
        }
    }

    private func updateAnimation(dt: CGFloat) {
        stateTimer += dt
        idlePhase += dt * 2
        let speed = abs(velocityX)
        let isRunning = speed > 200

        switch currentState {
        case .idle:
            visualRoot.removeAction(forKey: "walkCycle")
            legLeft.position.y = -8 + sin(idlePhase * 0.5) * 0.5
            legRight.position.y = -8 - sin(idlePhase * 0.5) * 0.5
            bootLeft.position.y = -16 + sin(idlePhase * 0.5) * 0.5
            bootRight.position.y = -16 - sin(idlePhase * 0.5) * 0.5
            armLeft.position.y = 8 + sin(idlePhase) * 1
            armRight.position.y = 8 - sin(idlePhase) * 1
            handLeft.position.y = -7 + sin(idlePhase) * 1
            handRight.position.y = -7 - sin(idlePhase) * 1
            torso.position.y = 10 + sin(idlePhase * 0.5) * 0.5
            head.position.y = 24 + sin(idlePhase * 0.5) * 0.5
            hairBack.position.y = 28 + sin(idlePhase * 0.5) * 0.5
            hairFront.position.y = 26 + sin(idlePhase * 0.5) * 0.5

        case .walk, .run:
            walkPhase += dt * (isRunning ? 20 : 14)
            let legSwing = sin(walkPhase) * (isRunning ? 7 : 5)
            let armSwing = sin(walkPhase) * (isRunning ? 9 : 6)

            legLeft.position.y = -8 + legSwing
            legRight.position.y = -8 - legSwing
            bootLeft.position.y = -16 + legSwing
            bootRight.position.y = -16 - legSwing
            armLeft.position.y = 8 - armSwing
            armRight.position.y = 8 + armSwing
            armLeft.position.x = -11 + cos(walkPhase) * 2
            armRight.position.x = 11 - cos(walkPhase) * 2
            handLeft.position.y = -7 - armSwing * 0.5
            handRight.position.y = -7 + armSwing * 0.5

            torso.position.y = 10 + abs(sin(walkPhase)) * 1.5
            head.position.y = 24 + abs(sin(walkPhase)) * 1
            hairBack.position.y = 28 + abs(sin(walkPhase)) * 1
            hairFront.position.y = 26 + abs(sin(walkPhase)) * 0.5
            braid.position.y = 18 + abs(sin(walkPhase)) * 1.5

            if onGround && speed > 30 && Int(stateTimer * 10) % 3 == 0 {
                dustEmitter?.particleBirthRate = 200
            } else {
                dustEmitter?.particleBirthRate = 0
            }

        case .jump:
            visualRoot.removeAction(forKey: "walkCycle")
            dustEmitter?.particleBirthRate = 0
            legLeft.position.y = -8 - 6
            legRight.position.y = -8 + 2
            bootLeft.position.y = -16 - 6
            bootRight.position.y = -16 + 2
            armLeft.position.y = 8 - 12
            armRight.position.y = 8 - 12
            armLeft.position.x = -13
            armRight.position.x = 13
            handLeft.position.y = -7 - 10
            handRight.position.y = -7 - 10
            torso.position.y = 10 - 2
            head.position.y = 24 - 2
            hairBack.position.y = 28 - 1
            hairFront.position.y = 26 - 1

        case .fall:
            visualRoot.removeAction(forKey: "walkCycle")
            dustEmitter?.particleBirthRate = 0
            legLeft.position.y = -8 + 4
            legRight.position.y = -8 - 2
            bootLeft.position.y = -16 + 4
            bootRight.position.y = -16 - 2
            armLeft.position.y = 8 + 6
            armRight.position.y = 8 + 6
            armLeft.position.x = -9
            armRight.position.x = 9
            handLeft.position.y = -7 + 5
            handRight.position.y = -7 + 5
            torso.position.y = 10 + 1
            head.position.y = 24 + 1
            hairBack.position.y = 28 + 2
            hairFront.position.y = 26 + 2

        case .skid:
            visualRoot.removeAction(forKey: "walkCycle")
            dustEmitter?.particleBirthRate = 300
            legLeft.position.y = -8 - 4
            legRight.position.y = -8 + 4
            bootLeft.position.y = -16 - 4
            bootRight.position.y = -16 + 4
            armLeft.position.y = 8 + 10
            armRight.position.y = 8 - 10
            armLeft.position.x = facingRight ? -15 : -7
            armRight.position.x = facingRight ? 7 : 15
            handLeft.position.y = -7 + 8
            handRight.position.y = -7 - 8
            torso.position.y = 10 + 3
            visualRoot.zRotation = facingRight ? -0.15 : 0.15

        case .land:
            legLeft.position.y = -8 + 5
            legRight.position.y = -8 - 5
            bootLeft.position.y = -16 + 5
            bootRight.position.y = -16 - 5
            armLeft.position.y = 8 + 8
            armRight.position.y = 8 - 8
            handLeft.position.y = -7 + 6
            handRight.position.y = -7 - 6
            torso.position.y = 10 + 3
            head.position.y = 24 + 1
            hairBack.position.y = 28 + 1
            hairFront.position.y = 26 + 1

        case .hurt:
            legLeft.position.y = -8 + 6
            legRight.position.y = -8 - 6
            bootLeft.position.y = -16 + 6
            bootRight.position.y = -16 - 6
            armLeft.position.y = 8 + 12
            armRight.position.y = 8 + 12
            handLeft.position.y = -7 + 10
            handRight.position.y = -7 + 10

        case .bounce:
            visualRoot.run(SKAction.sequence([
                SKAction.scaleY(to: 0.7, duration: 0.05),
                SKAction.scaleY(to: 1.1, duration: 0.1),
                SKAction.scaleY(to: 1.0, duration: 0.05)
            ]))
        }
    }

    private func updateVisuals() {
        if currentState != .skid {
            visualRoot.zRotation = lerp(visualRoot.zRotation, 0, 0.15)
        }
        if currentState == .land && stateTimer > 0.15 {
            setState(onGround ? .idle : .fall)
        }
        if currentState == .skid && abs(velocityX) < 50 {
            setState(.idle)
        }
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    func applyBounce() {
        velocityY = GameConstants.stompBounceVelocity
        onGround = false
        stompGraceTimer = 0.35
        setState(.bounce)
    }

    func knockback(from enemyX: CGFloat) {
        guard hurtCooldown <= 0 else { return }
        hurtCooldown = 1.0
        velocityY = 380
        velocityX = position.x < enemyX ? -280 : 280
        setState(.hurt)
    }
}