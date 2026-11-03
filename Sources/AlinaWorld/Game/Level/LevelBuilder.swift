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
    let theme: WorldTheme
    /// Top of the ground strip in world units, used to seat the parallax hills.
    let groundTop: CGFloat
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
        let theme = WorldThemes.theme(for: mission.world)
        scene.backgroundColor = SKColor(hex: theme.horizon)

        let map = TileMap(rows: padRows(mission.rows))
        let worldNode = SKNode()
        worldNode.name = "world"
        scene.addChild(worldNode)

        var collectibles: [CollectibleNode] = []
        var enemies: [EnemyNode] = []
        var hazards: [SKSpriteNode] = []
        var movingPlatforms: [MovingPlatform] = []
        var flagNode: SKNode?
        var crawlerCount = 0
        let spikyEnabled = mission.id >= 10

        for row in 0..<map.height {
            for col in 0..<map.width {
                let kind = map.kind(at: col, row: row)
                let rect = map.tileRect(col: col, row: row)
                let center = CGPoint(x: rect.midX, y: rect.midY)

                switch kind {
                case .solid, .ground, .brick, .question, .pipe:
                    let topExposed = !map.isSolid(map.kind(at: col, row: row - 1))
                    let block = BlockNode(kind: blockKind(for: kind), theme: theme, topExposed: topExposed)
                    block.position = center
                    worldNode.addChild(block)
                case .coin:
                    let coin = CollectibleNode(kind: .coin, theme: theme)
                    coin.position = center
                    worldNode.addChild(coin)
                    collectibles.append(coin)
                case .crystal:
                    let crystal = CollectibleNode(kind: .crystal, theme: theme)
                    crystal.position = center
                    worldNode.addChild(crystal)
                    collectibles.append(crystal)
                case .flag:
                    let beacon = GameGraphics.makeBeacon()
                    beacon.position = center
                    beacon.zPosition = 2
                    worldNode.addChild(beacon)
                    flagNode = beacon
                case .enemy:
                    crawlerCount += 1
                    let spiky = spikyEnabled && crawlerCount % 3 == 0
                    let enemy = EnemyNode(kind: spiky ? .spiky : .crawler, theme: theme)
                    enemy.configure(onTileWithCenter: center)
                    worldNode.addChild(enemy)
                    enemies.append(enemy)
                case .boss:
                    let boss = EnemyNode(kind: .boss, theme: theme, patrol: 120)
                    boss.configure(onTileWithCenter: center)
                    worldNode.addChild(boss)
                    enemies.append(boss)
                case .hazard:
                    let thorns = GameGraphics.makeThorns(theme: theme)
                    thorns.position = center
                    thorns.name = "hazard"
                    thorns.zPosition = 2
                    worldNode.addChild(thorns)
                    hazards.append(thorns)
                case .slopeUpRight, .slopeUpLeft, .slopeDownRight, .slopeDownLeft:
                    worldNode.addChild(createSlopeNode(kind: kind, rect: rect, theme: theme))
                case .platform:
                    let pad = GameGraphics.makeLeafPad(theme: theme)
                    pad.position = CGPoint(x: center.x, y: rect.maxY)
                    pad.zPosition = 1
                    worldNode.addChild(pad)
                case .movingPlatform:
                    let platform = GameGraphics.makeCloudPad()
                    platform.position = center
                    platform.zPosition = 1
                    if let data = map.movingPlatforms.first(where: { $0.col == col && $0.row == row }) {
                        movingPlatforms.append(MovingPlatform(node: platform, path: data.path, speed: data.speed))
                    }
                    worldNode.addChild(platform)
                case .empty:
                    break
                }
            }
        }

        for placement in mission.enemies {
            let rect = map.tileRect(col: placement.x, row: placement.y)
            let kind: EnemyNode.EnemyKind
            switch placement.kind.lowercased() {
            case "flyer", "fly": kind = .flyer
            case "boss": kind = .boss
            case "spiky": kind = .spiky
            default: kind = .crawler
            }
            let enemy = EnemyNode(kind: kind, theme: theme, patrol: placement.patrol ?? 80)
            enemy.configure(onTileWithCenter: CGPoint(x: rect.midX, y: rect.midY))
            worldNode.addChild(enemy)
            enemies.append(enemy)
        }

        addScenery(to: worldNode, map: map, theme: theme, seed: mission.layoutSeed)

        return BuiltLevel(
            map: map,
            worldNode: worldNode,
            playerStart: startPoint(in: map),
            flagNode: flagNode,
            collectibles: collectibles,
            enemies: enemies,
            hazards: hazards,
            movingPlatforms: movingPlatforms,
            theme: theme,
            groundTop: groundTop(in: map)
        )
    }

    private static func blockKind(for tile: TileKind) -> BlockKind {
        switch tile {
        case .solid: return .solid
        case .brick: return .brick
        case .question: return .question
        case .pipe: return .pipe
        default: return .ground
        }
    }

    /// Spawn above the highest solid tile in column 2, so floating blocks never become the start.
    private static func startPoint(in map: TileMap) -> CGPoint {
        let col = min(2, map.width - 1)
        for row in 0..<map.height where map.isSolid(map.kind(at: col, row: row)) {
            let rect = map.tileRect(col: col, row: row)
            return CGPoint(x: rect.midX, y: rect.maxY + GameConstants.playerHeight / 2)
        }
        return CGPoint(x: GameConstants.tileSize * 2, y: GameConstants.tileSize * 3)
    }

    private static func groundTop(in map: TileMap) -> CGFloat {
        for row in 0..<map.height where map.kind(at: 0, row: row) == .ground {
            return map.tileRect(col: 0, row: row).maxY
        }
        return GameConstants.tileSize * 2
    }

    /// Trees, bushes and flowers planted behind the tiles on exposed ground.
    private static func addScenery(to worldNode: SKNode, map: TileMap, theme: WorldTheme, seed: Int) {
        var rng = SeededRNG(seed: UInt64(seed) &* 2654435761)
        var col = 4
        while col < map.width - 3 {
            guard let row = surfaceRow(in: map, col: col) else { col += 1; continue }
            let rect = map.tileRect(col: col, row: row)
            let roll = rng.next() % 100
            let clear = (1...3).allSatisfy { map.kind(at: col, row: row - $0) == .empty }

            let node: SKSpriteNode?
            if roll < 14 && clear && surfaceRow(in: map, col: col + 1) == row {
                node = PixelArt.node(.tree, theme: theme, scale: 4)
                col += 4
            } else if roll < 30 {
                node = PixelArt.node(.bush, theme: theme, scale: 3)
                col += 2
            } else if roll < 52 {
                node = PixelArt.node(.flower, theme: theme, scale: 3)
                col += 1
            } else {
                node = nil
                col += 1
            }
            if let node {
                node.anchorPoint = CGPoint(x: 0.5, y: 0)
                node.position = CGPoint(x: rect.midX, y: rect.minY - 2)
                node.zPosition = -2
                worldNode.addChild(node)
            }
        }
    }

    /// Row of the first empty tile directly above ground in this column.
    private static func surfaceRow(in map: TileMap, col: Int) -> Int? {
        for row in 1..<map.height where map.kind(at: col, row: row) == .ground {
            return map.kind(at: col, row: row - 1) == .empty ? row - 1 : nil
        }
        return nil
    }

    private static func createSlopeNode(kind: TileKind, rect: CGRect, theme: WorldTheme) -> SKNode {
        let path = CGMutablePath()
        let half = GameConstants.tileSize / 2

        switch kind {
        case .slopeUpRight:
            path.move(to: CGPoint(x: -half, y: -half))
            path.addLine(to: CGPoint(x: half, y: half))
            path.addLine(to: CGPoint(x: half, y: -half))
        case .slopeUpLeft:
            path.move(to: CGPoint(x: half, y: -half))
            path.addLine(to: CGPoint(x: -half, y: half))
            path.addLine(to: CGPoint(x: -half, y: -half))
        case .slopeDownRight:
            path.move(to: CGPoint(x: -half, y: half))
            path.addLine(to: CGPoint(x: half, y: -half))
            path.addLine(to: CGPoint(x: -half, y: -half))
        case .slopeDownLeft:
            path.move(to: CGPoint(x: half, y: half))
            path.addLine(to: CGPoint(x: -half, y: -half))
            path.addLine(to: CGPoint(x: half, y: -half))
        default:
            break
        }
        path.closeSubpath()

        let slope = SKShapeNode(path: path)
        slope.fillColor = SKColor(hex: theme.dirt.0)
        slope.strokeColor = SKColor(hex: theme.grass.1)
        slope.lineWidth = 4
        slope.position = CGPoint(x: rect.midX, y: rect.midY)
        slope.zPosition = 1
        return slope
    }

    private static func padRows(_ rows: [String]) -> [String] {
        let width = rows.map(\.count).max() ?? 0
        return rows.map { $0.count < width ? $0 + String(repeating: ".", count: width - $0.count) : $0 }
    }
}

struct SeededRNG {
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
