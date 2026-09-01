import SpriteKit

final class EnemyNode: SKNode {
    enum EnemyKind {
        case crawler
        case flyer
        case boss
    }

    let enemyKind: EnemyKind
    var patrolDistance: CGFloat
    var direction: CGFloat = -1
    var moveSpeed: CGFloat
    var originX: CGFloat
    var alive = true
    var stompHitsRequired: Int
    private var stompHits = 0
    private let visualNode: SKNode

    init(kind: EnemyKind, palette: WorldPalette, patrol: Int = 80) {
        enemyKind = kind
        patrolDistance = CGFloat(patrol)
        originX = 0

        switch kind {
        case .crawler: moveSpeed = 55
        case .flyer: moveSpeed = 70
        case .boss: moveSpeed = 40
        }

        stompHitsRequired = kind == .boss ? 3 : 1
        visualNode = GameGraphics.makeEnemyNode(kind: kind, palette: palette)

        super.init()
        name = "enemy"
        zPosition = 3
        addChild(visualNode)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    var size: CGSize {
        switch enemyKind {
        case .crawler: return CGSize(width: 28, height: 22)
        case .flyer: return CGSize(width: 26, height: 20)
        case .boss: return CGSize(width: 48, height: 40)
        }
    }

    func configure(at position: CGPoint) {
        self.position = position
        originX = position.x
    }

    func update(delta: TimeInterval) {
        guard alive else { return }
        let dt = CGFloat(delta)
        position.x += direction * moveSpeed * dt
        visualNode.xScale = direction > 0 ? -1 : 1

        if position.x < originX - patrolDistance {
            direction = 1
        } else if position.x > originX + patrolDistance {
            direction = -1
        }

        if enemyKind == .flyer {
            position.y += sin(position.x * 0.05) * 0.4
        }
    }

    func stomp() -> Bool {
        stompHits += 1
        if stompHits >= stompHitsRequired {
            defeat()
            return true
        }
        let shrink = SKAction.scale(to: 0.85, duration: 0.05)
        let grow = SKAction.scale(to: 1.0, duration: 0.05)
        run(SKAction.sequence([shrink, grow]))
        return enemyKind != .boss
    }

    func defeat() {
        alive = false
        let fade = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        run(SKAction.sequence([fade, remove]))
    }
}
