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
    private let visualNode: SKNode

    init(kind: BlockKind, palette: WorldPalette) {
        blockKind = kind
        visualNode = GameGraphics.makeBlockNode(kind: kind, palette: palette)

        super.init()
        name = "block"
        zPosition = 1
        addChild(visualNode)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    var color: SKColor {
        get { (visualNode.children.first as? SKShapeNode)?.fillColor ?? .clear }
        set { (visualNode.children.first as? SKShapeNode)?.fillColor = newValue }
    }

    func bump() {
        let up = SKAction.moveBy(x: 0, y: 6, duration: 0.08)
        let down = SKAction.moveBy(x: 0, y: -6, duration: 0.08)
        run(SKAction.sequence([up, down]))
    }
}
