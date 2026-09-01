import SpriteKit

enum CollectibleKind {
    case coin
    case crystal
}

final class CollectibleNode: SKNode {
    let kind: CollectibleKind

    init(kind: CollectibleKind, palette: WorldPalette) {
        self.kind = kind
        super.init()
        name = "collectible"
        zPosition = 3

        let visual: SKNode
        switch kind {
        case .coin:
            visual = GameGraphics.makeCoinNode()
        case .crystal:
            visual = GameGraphics.makeCrystalNode(palette: palette)
        }
        addChild(visual)

        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 0.35),
            SKAction.moveBy(x: 0, y: -5, duration: 0.35)
        ])
        run(SKAction.repeatForever(bob))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func collect() {
        let burst = SKAction.group([
            SKAction.scale(to: 1.6, duration: 0.12),
            SKAction.fadeOut(withDuration: 0.12)
        ])
        run(SKAction.sequence([burst, SKAction.removeFromParent()]))
    }
}
