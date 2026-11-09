import SpriteKit

enum CollectibleKind {
    case coin
    case crystal
    case sunbloom
    case ribbon

    var isPowerUp: Bool { self == .sunbloom || self == .ribbon }
}

final class CollectibleNode: SKNode {
    let kind: CollectibleKind
    /// Set on pickup so the fade-out frames can't count it again.
    private(set) var collected = false

    init(kind: CollectibleKind, theme: WorldTheme) {
        self.kind = kind
        super.init()
        name = "collectible"
        zPosition = 3

        let visual: SKSpriteNode
        switch kind {
        case .coin:
            visual = PixelArt.node(.petal, scale: 2.5)
            let frames = [PixelArt.texture(.petal), PixelArt.texture(.petalTurn)]
            visual.run(.repeatForever(.animate(with: frames, timePerFrame: 0.22)))
        case .crystal:
            visual = PixelArt.node(.crystal, scale: 3)
            let glow = SKShapeNode(circleOfRadius: 20)
            glow.fillColor = SKColor(hex: 0xFFE98A, alpha: 0.35)
            glow.strokeColor = .clear
            glow.zPosition = -1
            glow.run(.repeatForever(.sequence([.fadeAlpha(to: 0.4, duration: 0.6), .fadeAlpha(to: 1, duration: 0.6)])))
            addChild(glow)
        case .sunbloom:
            visual = PixelArt.node(.sunbloom, theme: theme, scale: 3)
        case .ribbon:
            visual = PixelArt.node(.ribbon, scale: 3)
        }
        addChild(visual)

        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 0.45),
            SKAction.moveBy(x: 0, y: -5, duration: 0.45)
        ])
        bob.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(bob))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    /// Pops a power-up out of a bloom block before it starts bobbing.
    func emerge() {
        alpha = 0
        position.y -= 20
        run(.group([.fadeIn(withDuration: 0.25), .moveBy(x: 0, y: 30, duration: 0.3)]))
    }

    func collect() {
        collected = true
        removeAllActions()
        let burst = SKAction.group([
            SKAction.scale(to: 1.6, duration: 0.12),
            SKAction.fadeOut(withDuration: 0.12)
        ])
        run(SKAction.sequence([burst, SKAction.removeFromParent()]))
    }
}
