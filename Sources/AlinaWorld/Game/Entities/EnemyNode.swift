import SpriteKit

final class EnemyNode: SKNode {
    enum EnemyKind {
        /// Gloomling — walks a patrol, defeated by a stomp.
        case crawler
        /// Thornbeetle — spiked shell, hurts Alina if she lands on it.
        case spiky
        /// Mothwisp — floats in the air.
        case flyer
        /// World guardian — takes three stomps.
        case boss
    }

    /// How a creature moves, on top of its patrol.
    enum Behavior {
        /// Plain patrol back and forth.
        case walk
        /// Bounds along its patrol in hops.
        case hop
        /// Patrols, then lowers its head and rushes when Alina is ahead of it.
        case charge
        /// Floats on a sine wave.
        case float
        /// Floats, then dives at Alina when she passes underneath.
        case swoop
    }

    /// Each world has its own cast: two ground creatures that alternate along the level and one flyer.
    static func cast(for world: String) -> (ground: [CreatureRig.Species], flyer: CreatureRig.Species) {
        switch world {
        case "brook": return ([.bubblefrog, .gloomling], .mothwisp)
        case "grove": return ([.barkling, .gloomling], .mothwisp)
        case "cavern": return ([.gloomling, .barkling], .cinderbat)
        case "ridge": return ([.rockram, .gloomling], .cinderbat)
        case "marsh": return ([.bubblefrog, .barkling], .bogglebug)
        case "spire": return ([.prismite, .gloomling], .bogglebug)
        case "storm": return ([.rockram, .prismite], .sparkcloud)
        case "throne": return ([.gloomknight, .gloomling], .sparkcloud)
        case "frost": return ([.frostpuff, .rockram], .mothwisp)
        case "coral": return ([.shellcrab, .bubblefrog], .bogglebug)
        case "starfall": return ([.prismite, .gloomknight], .starwisp)
        default: return ([.gloomling, .gloomling], .mothwisp)
        }
    }

    static func behavior(of species: CreatureRig.Species) -> Behavior {
        switch species {
        case .bubblefrog, .prismite: return .hop
        case .rockram, .gloomknight: return .charge
        case .cinderbat, .sparkcloud: return .swoop
        case .mothwisp, .bogglebug, .starwisp: return .float
        default: return .walk
        }
    }

    let enemyKind: EnemyKind
    let species: CreatureRig.Species
    let behavior: Behavior
    var patrolDistance: CGFloat
    var direction: CGFloat = -1
    var moveSpeed: CGFloat
    var originX: CGFloat
    var originY: CGFloat = 0
    var alive = true
    var stompHitsRequired: Int
    private(set) var stompHits = 0
    private var age: CGFloat = 0
    private let visualNode: SKSpriteNode
    /// Cut-out puppet used once `CreatureRig.png` is bundled; `visualNode` then only sets the size.
    private var rig: CreatureRig?
    /// Hop motion above the patrol line.
    private var hopVelocity: CGFloat = 0
    private var hopTimer = CGFloat.random(in: 0.3...1.2)
    private var hopHeight: CGFloat = 0
    /// Charge: wind-up then rush, then a rest before it can charge again.
    private var chargeTimer: CGFloat = 0
    private var chargeRest: CGFloat = 0
    /// Swoop: 0 = resting at altitude, rising to 1 at the bottom of the dive.
    private var swoopDepth: CGFloat = 0
    private var swooping = false

    /// `variant` picks between the world's ground creatures, so neighbours differ.
    init(kind: EnemyKind, theme: WorldTheme, patrol: Int = 80, variant: Int = 0) {
        enemyKind = kind
        patrolDistance = CGFloat(patrol)
        originX = 0
        let cast = Self.cast(for: theme.key)
        switch kind {
        case .crawler: species = cast.ground[variant % cast.ground.count]
        case .spiky: species = .thornbeetle
        case .flyer: species = cast.flyer
        case .boss: species = .guardian
        }
        behavior = Self.behavior(of: species)

        switch kind {
        case .crawler: moveSpeed = 55
        case .spiky: moveSpeed = 40
        case .flyer: moveSpeed = 70
        case .boss: moveSpeed = 60
        }

        // Armoured creatures take two hits.
        stompHitsRequired = kind == .boss ? 3 : ([.barkling, .gloomknight].contains(species) ? 2 : 1)
        if behavior == .hop { moveSpeed *= 1.2 }

        let frames: [PixelSprite]
        switch (kind, theme.key) {
        // Act IV worlds dress the crawler and flyer as their own minions.
        case (.crawler, "frost"): frames = [.frostpuff]
        case (.crawler, "coral"): frames = [.shellcrab]
        case (.flyer, "starfall"): frames = [.starwisp]
        case (.crawler, _): frames = [.gloomling, .gloomlingStep]
        case (.spiky, _): frames = [.thornbeetle]
        case (.flyer, _): frames = [.mothwisp, .mothwispFlap]
        case (.boss, _): frames = [.guardian]
        }
        visualNode = PixelArt.node(frames[0], theme: theme, scale: 3)

        super.init()
        name = "enemy"
        zPosition = 3
        addChild(visualNode)

        if CreatureRig.isAvailable {
            // Until the second cast is painted, each new creature stands in as a tinted first-cast cousin.
            var drawn = species
            var tint: (UInt32, CGFloat)?
            if !CreatureRig.hasArt(species) {
                switch species {
                case .bubblefrog: drawn = .frostpuff; tint = (0x3FB7A8, 0.55)
                case .barkling: drawn = .gloomling; tint = (0x7A5233, 0.6)
                case .rockram: drawn = .gloomling; tint = (0xC0703A, 0.55)
                case .prismite: drawn = .frostpuff; tint = (0x9B6BFF, 0.55)
                case .gloomknight: drawn = .gloomling; tint = (0x2E2448, 0.55)
                case .cinderbat: drawn = .mothwisp; tint = (0xE0602C, 0.5)
                case .bogglebug: drawn = .mothwisp; tint = (0x6FAE3A, 0.5)
                case .sparkcloud: drawn = .mothwisp; tint = (0xB9C3D6, 0.55)
                default: break
                }
            }
            let widthFactor: CGFloat = switch drawn {
            case .shellcrab: 0.72
            case .starwisp, .thornbeetle: 0.95
            case .mothwisp, .cinderbat, .bogglebug: 0.55
            case .sparkcloud: 0.7
            case .guardian: 0.9
            case .rockram, .gloomknight: 0.95
            default: 0.86
            }
            let rig = CreatureRig(species: drawn, width: visualNode.size.width * widthFactor, floorY: -visualNode.size.height / 2)
            if let tint { rig.tint(SKColor(hex: tint.0), amount: tint.1) }
            addChild(rig)
            self.rig = rig
            visualNode.isHidden = true
        } else if frames.count > 1 {
            let textures = frames.map { PixelArt.texture($0, theme: theme) }
            visualNode.run(.repeatForever(.animate(with: textures, timePerFrame: kind == .flyer ? 0.14 : 0.24)))
        } else {
            visualNode.run(.repeatForever(.sequence([
                .scaleY(to: 0.94, duration: 0.3),
                .scaleY(to: 1.0, duration: 0.3)
            ])))
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    /// Hitbox, slightly inside the sprite so near-misses feel fair.
    var size: CGSize {
        switch enemyKind {
        case .crawler: return CGSize(width: 30, height: 24)
        case .spiky: return CGSize(width: 32, height: 20)
        case .flyer: return CGSize(width: 30, height: 20)
        case .boss: return CGSize(width: 44, height: 38)
        }
    }

    /// Places the enemy so its feet rest on the bottom edge of the tile it was authored in.
    func configure(onTileWithCenter center: CGPoint) {
        let floating = enemyKind == .flyer
        let y = floating ? center.y : center.y - GameConstants.tileSize / 2 + visualNode.size.height / 2
        position = CGPoint(x: center.x, y: y)
        originX = center.x
        originY = y
    }

    /// `target` is Alina's position, which chargers and swoopers react to.
    func update(delta: TimeInterval, target: CGPoint? = nil) {
        guard alive else { return }
        let dt = CGFloat(delta)
        age += dt
        var speed = moveSpeed
        var lift: CGFloat = 0

        switch behavior {
        case .walk, .float:
            break
        case .hop:
            // Moves only while airborne; crouches a beat between hops.
            hopTimer -= dt
            if hopHeight <= 0 && hopTimer <= 0 {
                hopVelocity = 330
                hopTimer = .random(in: 0.55...0.95)
                rig?.run(.sequence([.scaleY(to: 0.8, duration: 0.05), .scaleY(to: 1.12, duration: 0.08), .scaleY(to: 1, duration: 0.1)]))
            }
            if hopHeight > 0 || hopVelocity > 0 {
                hopVelocity -= GameConstants.gravity * 0.8 * dt
                hopHeight = max(0, hopHeight + hopVelocity * dt)
                if hopHeight == 0 { hopVelocity = 0 }
            } else {
                speed = 0
            }
            lift = hopHeight
        case .charge:
            if chargeRest > 0 { chargeRest -= dt }
            if let target, chargeTimer <= 0, chargeRest <= 0,
               abs(target.y - position.y) < 50, (target.x - position.x) * direction > 0, abs(target.x - position.x) < 260 {
                chargeTimer = 1.1
            }
            if chargeTimer > 0 {
                chargeTimer -= dt
                // Paw the ground (stand still and shake), then rush.
                if chargeTimer > 0.75 {
                    speed = 0
                    rig?.position.x = sin(age * 60) * 1.5
                } else {
                    speed = moveSpeed * 3.4
                    rig?.position.x = 0
                }
                if chargeTimer <= 0 { chargeRest = 1.4 }
            }
        case .swoop:
            if let target, !swooping, swoopDepth <= 0, abs(target.x - position.x) < 120, target.y < position.y - 20 {
                swooping = true
            }
            swoopDepth = swooping ? min(1, swoopDepth + dt * 2.2) : max(0, swoopDepth - dt * 0.9)
            if swoopDepth >= 1 { swooping = false }
        }

        position.x += direction * speed * dt
        visualNode.xScale = direction > 0 ? -1 : 1
        if let rig {
            rig.xScale = visualNode.xScale
            rig.update(dt: dt, speed: speed)
        }

        // Chargers run past the end of the patrol a little, then turn back.
        let slack: CGFloat = chargeTimer > 0 ? 80 : 0
        if position.x < originX - patrolDistance - slack {
            direction = 1
            chargeTimer = min(chargeTimer, 0)
        } else if position.x > originX + patrolDistance + slack {
            direction = -1
            chargeTimer = min(chargeTimer, 0)
        }

        if enemyKind == .flyer {
            let dive = swoopDepth * swoopDepth * (3 - 2 * swoopDepth) * 70
            position.y = originY + sin(age * 2.4) * 10 - dive
        } else {
            position.y = originY + lift
        }
    }

    func stomp() -> Bool {
        stompHits += 1
        if stompHits >= stompHitsRequired {
            defeat()
            return true
        }
        visualNode.run(.sequence([
            .colorize(with: .white, colorBlendFactor: 0.8, duration: 0.05),
            .scale(to: 0.85, duration: 0.06),
            .scale(to: 1.0, duration: 0.08),
            .colorize(withColorBlendFactor: 0, duration: 0.1)
        ]))
        rig?.hit()
        moveSpeed += 25
        return false
    }

    func defeat() {
        alive = false
        removeAllActions()
        rig?.squashFlat()
        run(.sequence([
            .group([.scaleY(to: 0.3, duration: 0.12), .moveBy(x: 0, y: -8, duration: 0.12)]),
            .fadeOut(withDuration: 0.15),
            .removeFromParent()
        ]))
    }
}
