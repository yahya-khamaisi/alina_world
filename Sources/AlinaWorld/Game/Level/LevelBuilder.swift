import SpriteKit

struct BuiltLevel {
    let map: TileMap
    let worldNode: SKNode
    let playerStart: CGPoint
    let flagNode: SKNode?
    let collectibles: [CollectibleNode]
    let enemies: [EnemyNode]
    let hazards: [SKSpriteNode]
    let movingPlatforms: [MovingPlatform]
    let palette: WorldPalette
}

struct MovingPlatform {
    let node: SKNode
    let path: [CGPoint]
    let speed: CGFloat
    var currentIndex: Int = 0
    var progress: CGFloat = 0
    var direction: CGFloat = 1
}

final class LevelBuilder {
    static func build(mission: Mission, in scene: SKScene) -> BuiltLevel {
        let palette = WorldPalettes.palette(for: mission.world)
        scene.backgroundColor = palette.sky

        let expandedRows = expandRows(mission.rows, seed: mission.layoutSeed, difficulty: mission.difficulty)
        let map = TileMap(rows: expandedRows)
        let worldNode = SKNode()
        worldNode.name = "world"
        scene.addChild(worldNode)

        var collectibles: [CollectibleNode] = []
        var enemies: [EnemyNode] = []
        var hazards: [SKSpriteNode] = []
        var movingPlatforms: [MovingPlatform] = []
        var flagNode: SKNode?
        var playerStart = CGPoint(x: GameConstants.tileSize * 2, y: GameConstants.tileSize * 3)

        for row in 0..<map.height {
            for col in 0..<map.width {
                let kind = map.kind(at: col, row: row)
                let rect = map.tileRect(col: col, row: row)
                let center = CGPoint(x: rect.midX, y: rect.midY)

                switch kind {
                case .solid:
                    let block = BlockNode(kind: .solid, palette: palette)
                    block.position = center
                    worldNode.addChild(block)
                case .ground:
                    let block = BlockNode(kind: .ground, palette: palette)
                    block.position = center
                    worldNode.addChild(block)
                case .brick:
                    let block = BlockNode(kind: .brick, palette: palette)
                    block.position = center
                    worldNode.addChild(block)
                case .question:
                    let block = BlockNode(kind: .question, palette: palette)
                    block.position = center
                    worldNode.addChild(block)
                case .pipe:
                    let block = BlockNode(kind: .pipe, palette: palette)
                    block.position = center
                    worldNode.addChild(block)
                case .coin:
                    let coin = CollectibleNode(kind: .coin, palette: palette)
                    coin.position = center
                    worldNode.addChild(coin)
                    collectibles.append(coin)
                case .crystal:
                    let crystal = CollectibleNode(kind: .crystal, palette: palette)
                    crystal.position = center
                    worldNode.addChild(crystal)
                    collectibles.append(crystal)
                case .flag:
                    let pole = GameGraphics.makeFlagPole(height: 80)
                    pole.position = center
                    pole.zPosition = 2
                    worldNode.addChild(pole)
                    flagNode = pole
                case .enemy:
                    let enemy = EnemyNode(kind: .crawler, palette: palette)
                    enemy.configure(at: center)
                    worldNode.addChild(enemy)
                    enemies.append(enemy)
                case .boss:
                    let boss = EnemyNode(kind: .boss, palette: palette, patrol: 120)
                    boss.configure(at: center)
                    worldNode.addChild(boss)
                    enemies.append(boss)
                case .hazard:
                    let spike = createSpikeNode(at: center, palette: palette)
                    worldNode.addChild(spike)
                    hazards.append(spike)
                case .slopeUpRight, .slopeUpLeft, .slopeDownRight, .slopeDownLeft:
                    let slope = createSlopeNode(kind: kind, rect: rect, palette: palette)
                    worldNode.addChild(slope)
                case .platform:
                    let platform = createPlatformNode(at: center, palette: palette)
                    worldNode.addChild(platform)
                case .movingPlatform:
                    let platform = createMovingPlatformNode(at: center, palette: palette)
                    if let platformData = map.movingPlatforms.first(where: { $0.col == col && $0.row == row }) {
                        let movingPlatform = MovingPlatform(
                            node: platform,
                            path: platformData.path,
                            speed: platformData.speed
                        )
                        movingPlatforms.append(movingPlatform)
                    }
                    worldNode.addChild(platform)
                case .empty:
                    break
                }
            }
        }

        for placement in mission.enemies {
            let col = placement.x
            let row = placement.y
            let rect = map.tileRect(col: col, row: row)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let kind: EnemyNode.EnemyKind
            switch placement.kind.lowercased() {
            case "flyer", "fly": kind = .flyer
            case "boss": kind = .boss
            default: kind = .crawler
            }
            let enemy = EnemyNode(kind: kind, palette: palette, patrol: placement.patrol ?? 80)
            enemy.configure(at: center)
            worldNode.addChild(enemy)
            enemies.append(enemy)
        }

        if let firstGround = map.solidRects().first {
            playerStart = CGPoint(x: firstGround.minX + GameConstants.tileSize * 1.5, y: firstGround.maxY + GameConstants.playerHeight / 2)
        }

        return BuiltLevel(
            map: map,
            worldNode: worldNode,
            playerStart: playerStart,
            flagNode: flagNode,
            collectibles: collectibles,
            enemies: enemies,
            hazards: hazards,
            movingPlatforms: movingPlatforms,
            palette: palette
        )
    }

    private static func createSpikeNode(at position: CGPoint, palette: WorldPalette) -> SKSpriteNode {
        let container = SKNode()
        let spikeCount = 3
        for i in 0..<spikeCount {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -10, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 16))
            path.addLine(to: CGPoint(x: 10, y: 0))
            path.closeSubpath()

            let spike = SKShapeNode(path: path)
            spike.fillColor = palette.hazard
            spike.strokeColor = SKColor(red: 0.6, green: 0.1, blue: 0.1, alpha: 1)
            spike.lineWidth = 1.5
            spike.position = CGPoint(x: CGFloat(i - 1) * 12, y: 0)
            container.addChild(spike)
        }

        let base = SKShapeNode(rectOf: CGSize(width: 32, height: 8), cornerRadius: 2)
        base.fillColor = palette.ground
        base.strokeColor = .clear
        base.position = CGPoint(x: 0, y: -12)
        container.addChild(base)

        let node = SKSpriteNode(color: .clear, size: CGSize(width: 32, height: 24))
        node.position = position
        node.addChild(container)
        node.name = "hazard"
        node.zPosition = 2
        return node
    }

    private static func createSlopeNode(kind: TileKind, rect: CGRect, palette: WorldPalette) -> SKNode {
        let path = CGMutablePath()
        let tileSize = GameConstants.tileSize

        switch kind {
        case .slopeUpRight:
            path.move(to: CGPoint(x: -tileSize/2, y: -tileSize/2))
            path.addLine(to: CGPoint(x: tileSize/2, y: tileSize/2))
            path.addLine(to: CGPoint(x: tileSize/2, y: -tileSize/2))
        case .slopeUpLeft:
            path.move(to: CGPoint(x: tileSize/2, y: -tileSize/2))
            path.addLine(to: CGPoint(x: -tileSize/2, y: tileSize/2))
            path.addLine(to: CGPoint(x: -tileSize/2, y: -tileSize/2))
        case .slopeDownRight:
            path.move(to: CGPoint(x: -tileSize/2, y: tileSize/2))
            path.addLine(to: CGPoint(x: tileSize/2, y: -tileSize/2))
            path.addLine(to: CGPoint(x: -tileSize/2, y: -tileSize/2))
        case .slopeDownLeft:
            path.move(to: CGPoint(x: tileSize/2, y: tileSize/2))
            path.addLine(to: CGPoint(x: -tileSize/2, y: -tileSize/2))
            path.addLine(to: CGPoint(x: tileSize/2, y: -tileSize/2))
        default:
            break
        }
        path.closeSubpath()

        let slope = SKShapeNode(path: path)
        slope.fillColor = palette.block.withAlphaComponent(0.9)
        slope.strokeColor = palette.ground.withAlphaComponent(0.5)
        slope.lineWidth = 1.5
        slope.position = rect.origin
        slope.zPosition = 1

        let grass = SKShapeNode(rectOf: CGSize(width: tileSize - 4, height: 6), cornerRadius: 1)
        grass.fillColor = palette.accent.withAlphaComponent(0.8)
        grass.strokeColor = .clear
        grass.position = CGPoint(x: 0, y: tileSize/2 - 3)
        grass.zPosition = 2
        slope.addChild(grass)

        return slope
    }

    private static func createPlatformNode(at position: CGPoint, palette: WorldPalette) -> SKNode {
        let tileSize = GameConstants.tileSize
        let platform = SKShapeNode(rectOf: CGSize(width: tileSize * 3, height: 12), cornerRadius: 3)
        platform.fillColor = palette.block
        platform.strokeColor = palette.ground.withAlphaComponent(0.5)
        platform.lineWidth = 2
        platform.position = position
        platform.zPosition = 1

        let highlight = SKShapeNode(rectOf: CGSize(width: tileSize * 3 - 4, height: 3), cornerRadius: 1)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.3)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: 0, y: 5)
        highlight.zPosition = 2
        platform.addChild(highlight)

        return platform
    }

    private static func createMovingPlatformNode(at position: CGPoint, palette: WorldPalette) -> SKNode {
        let tileSize = GameConstants.tileSize
        let platform = SKShapeNode(rectOf: CGSize(width: tileSize * 4, height: 14), cornerRadius: 4)
        platform.fillColor = SKColor(red: 0.6, green: 0.7, blue: 0.8, alpha: 1)
        platform.strokeColor = SKColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1)
        platform.lineWidth = 2
        platform.position = position
        platform.zPosition = 1

        let highlight = SKShapeNode(rectOf: CGSize(width: tileSize * 4 - 4, height: 3), cornerRadius: 1)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.4)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: 0, y: 6)
        highlight.zPosition = 2
        platform.addChild(highlight)

        let gear1 = SKShapeNode(circleOfRadius: 4)
        gear1.fillColor = SKColor(red: 0.4, green: 0.5, blue: 0.7, alpha: 1)
        gear1.strokeColor = .clear
        gear1.position = CGPoint(x: -tileSize * 1.5, y: -8)
        gear1.zPosition = 2
        platform.addChild(gear1)

        let gear2 = SKShapeNode(circleOfRadius: 4)
        gear2.fillColor = SKColor(red: 0.4, green: 0.5, blue: 0.7, alpha: 1)
        gear2.strokeColor = .clear
        gear2.position = CGPoint(x: tileSize * 1.5, y: -8)
        gear2.zPosition = 2
        platform.addChild(gear2)

        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 2.0)
        gear1.run(SKAction.repeatForever(rotate))
        gear2.run(SKAction.repeatForever(rotate.reversed()))

        return platform
    }

    private static func expandRows(_ rows: [String], seed: Int, difficulty: MissionDifficulty) -> [String] {
        guard rows.isEmpty == false else { return rows }
        let width = rows.map(\.count).max() ?? 0
        var result = rows.map { row -> String in
            if row.count < width {
                return row + String(repeating: ".", count: width - row.count)
            }
            return row
        }

        var rng = SeededRNG(seed: UInt64(seed))
        let extraPads = difficulty == .hard ? 2 : (difficulty == .normal ? 1 : 0)
        if extraPads > 0 && result.count >= 2 {
            let groundIndex = result.count - 2
            var ground = Array(result[groundIndex])
            for i in stride(from: 8, to: ground.count - 8, by: 12) {
                if rng.next() % 3 == 0 {
                    ground[i] = "="
                }
            }
            result[groundIndex] = String(ground)
        }
        return result
    }
}

private struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
