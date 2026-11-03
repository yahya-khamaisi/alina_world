import SpriteKit

enum BlockKind {
    case solid
    case ground
    case brick
    case question
    case pipe
}

final class BlockNode: SKNode {
    let blockKind: BlockKind
    var hitCount = 0
    var revealed = false
    private let visualNode: SKSpriteNode

    init(kind: BlockKind, theme: WorldTheme, topExposed: Bool = true) {
        blockKind = kind
        visualNode = GameGraphics.makeBlockNode(kind: kind, theme: theme, topExposed: topExposed)

        super.init()
        name = "block"
        zPosition = 1
        addChild(visualNode)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    /// Swaps a bloom block to its emptied stone look.
    func markUsed() {
        visualNode.texture = PixelArt.texture(.bloomBlockUsed)
    }

    func bump() {
        let up = SKAction.moveBy(x: 0, y: 6, duration: 0.08)
        let down = SKAction.moveBy(x: 0, y: -6, duration: 0.08)
        run(SKAction.sequence([up, down]))
    }
}
