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

    let enemyKind: EnemyKind
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

    init(kind: EnemyKind, theme: WorldTheme, patrol: Int = 80) {
        enemyKind = kind
        patrolDistance = CGFloat(patrol)
        originX = 0

        switch kind {
        case .crawler: moveSpeed = 55
        case .spiky: moveSpeed = 40
        case .flyer: moveSpeed = 70
        case .boss: moveSpeed = 60
        }

        stompHitsRequired = kind == .boss ? 3 : 1

        let frames: [PixelSprite]
        switch kind {
        case .crawler: frames = [.gloomling, .gloomlingStep]
        case .spiky: frames = [.thornbeetle]
        case .flyer: frames = [.mothwisp, .mothwispFlap]
        case .boss: frames = [.guardian]
        }
        visualNode = PixelArt.node(frames[0], theme: theme, scale: 3)

        super.init()
        name = "enemy"
        zPosition = 3
        addChild(visualNode)

        if frames.count > 1 {
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

    func update(delta: TimeInterval) {
        guard alive else { return }
        let dt = CGFloat(delta)
        age += dt
        position.x += direction * moveSpeed * dt
        visualNode.xScale = direction > 0 ? -1 : 1

        if position.x < originX - patrolDistance {
            direction = 1
        } else if position.x > originX + patrolDistance {
            direction = -1
        }

        if enemyKind == .flyer {
            position.y = originY + sin(age * 2.4) * 10
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
        moveSpeed += 25
        return false
    }

    func defeat() {
        alive = false
        removeAllActions()
        run(.sequence([
            .group([.scaleY(to: 0.3, duration: 0.12), .moveBy(x: 0, y: -8, duration: 0.12)]),
            .fadeOut(withDuration: 0.15),
            .removeFromParent()
        ]))
    }
}
