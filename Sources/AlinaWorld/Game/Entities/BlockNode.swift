import SpriteKit

enum BlockKind {
    case solid
    case ground
    case brick
    case question
    case pipe
    case spring
}

final class BlockNode: SKNode {
    let blockKind: BlockKind
    var hitCount = 0
    var revealed = false
    private let visualNode: SKSpriteNode
    private let theme: WorldTheme

    init(kind: BlockKind, theme: WorldTheme, topExposed: Bool = true, artVariant: Int = 0, corners: RoundedTiles.Corners = []) {
        blockKind = kind
        self.theme = theme
        visualNode = GameGraphics.makeBlockNode(kind: kind, theme: theme, topExposed: topExposed, artVariant: artVariant, corners: corners)

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
        GameGraphics.roundBlock(visualNode, sprite: .bloomBlockUsed, kind: blockKind, theme: theme, corners: .all)
    }

    func bump() {
        let up = SKAction.moveBy(x: 0, y: 6, duration: 0.08)
        let down = SKAction.moveBy(x: 0, y: -6, duration: 0.08)
        run(SKAction.sequence([up, down]))
    }
}
