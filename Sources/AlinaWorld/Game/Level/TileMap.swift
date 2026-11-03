import CoreGraphics

enum TileKind: Character {
    case empty = "."
    case solid = "#"
    case ground = "="
    case brick = "B"
    case question = "?"
    case pipe = "P"
    case coin = "C"
    case crystal = "*"
    case flag = "F"
    case enemy = "E"
    case hazard = "^"
    case boss = "X"
    case slopeUpRight = "/"
    case slopeUpLeft = "\\"
    case slopeDownRight = "}"
    case slopeDownLeft = "{"
    case platform = "_"
    case movingPlatform = "M"
    case spring = "S"
}

struct TileMap {
    let width: Int
    let height: Int
    let tiles: [TileKind]
    let movingPlatforms: [MovingPlatformData]

    struct MovingPlatformData {
        let col: Int
        let row: Int
        let path: [CGPoint]
        let speed: CGFloat
    }

    init(rows: [String]) {
        let height = rows.count
        let width = rows.map(\.count).max() ?? 0
        var buffer: [TileKind] = []
        var platforms: [MovingPlatformData] = []

        for (rowIndex, row) in rows.enumerated() {
            for (colIndex, char) in row.enumerated() {
                let kind = TileKind(rawValue: char) ?? .empty
                buffer.append(kind)

                if kind == .movingPlatform {
                    let path = Self.generatePlatformPath(at: colIndex, row: rowIndex, in: rows)
                    platforms.append(MovingPlatformData(
                        col: colIndex,
                        row: rowIndex,
                        path: path,
                        speed: 50 + CGFloat.random(in: 0...30)
                    ))
                }
            }
            if row.count < width {
                buffer.append(contentsOf: repeatElement(.empty, count: width - row.count))
            }
        }

        self.height = height
        self.width = width
        self.tiles = buffer
        self.movingPlatforms = platforms
    }

    private static func generatePlatformPath(at col: Int, row: Int, in rows: [String]) -> [CGPoint] {
        let tileSize = GameConstants.tileSize
        let baseX = CGFloat(col) * tileSize
        let baseY = CGFloat(rows.count - 1 - row) * tileSize

        var path: [CGPoint] = []
        path.append(CGPoint(x: baseX, y: baseY))

        var currentCol = col
        var direction = 1

        for _ in 0..<10 {
            currentCol += direction
            if currentCol < 0 || currentCol >= rows[row].count || rows[row][rows[row].index(rows[row].startIndex, offsetBy: currentCol)] != "_" && rows[row][rows[row].index(rows[row].startIndex, offsetBy: currentCol)] != "M" {
                direction *= -1
                currentCol += direction * 2
            }
            let x = CGFloat(currentCol) * tileSize
            path.append(CGPoint(x: x, y: baseY))
            if path.count >= 4 { break }
        }

        if path.count < 2 {
            path.append(CGPoint(x: baseX + 100, y: baseY))
        }

        return path
    }

    func kind(at col: Int, row: Int) -> TileKind {
        guard col >= 0, row >= 0, col < width, row < height else { return .empty }
        return tiles[row * width + col]
    }

    func isSolid(_ kind: TileKind) -> Bool {
        switch kind {
        case .solid, .ground, .brick, .question, .pipe, .slopeUpRight, .slopeUpLeft, .slopeDownRight, .slopeDownLeft, .platform, .movingPlatform, .spring:
            return true
        default:
            return false
        }
    }

    func isSlope(_ kind: TileKind) -> Bool {
        switch kind {
        case .slopeUpRight, .slopeUpLeft, .slopeDownRight, .slopeDownLeft:
            return true
        default:
            return false
        }
    }

    func slopeNormal(for kind: TileKind, at point: CGPoint, in rect: CGRect) -> CGVector? {
        let localX = point.x - rect.minX
        let tileSize = GameConstants.tileSize
        let t = localX / tileSize

        switch kind {
        case .slopeUpRight:
            return CGVector(dx: -t, dy: 1 - t).normalized()
        case .slopeUpLeft:
            return CGVector(dx: t - 1, dy: 1 - t).normalized()
        case .slopeDownRight:
            return CGVector(dx: t, dy: t).normalized()
        case .slopeDownLeft:
            return CGVector(dx: 1 - t, dy: t).normalized()
        default:
            return nil
        }
    }

    func worldSize() -> CGSize {
        CGSize(width: CGFloat(width) * GameConstants.tileSize, height: CGFloat(height) * GameConstants.tileSize)
    }

    func tileRect(col: Int, row: Int) -> CGRect {
        let x = CGFloat(col) * GameConstants.tileSize
        let y = CGFloat(height - 1 - row) * GameConstants.tileSize
        return CGRect(x: x, y: y, width: GameConstants.tileSize, height: GameConstants.tileSize)
    }

    func solidRects() -> [CGRect] {
        var rects: [CGRect] = []
        for row in 0..<height {
            for col in 0..<width {
                let kind = kind(at: col, row: row)
                // Leaf-pads are one-way: Alina jumps up through them and lands on top (see platformRects).
                if isSolid(kind) && !isSlope(kind) && kind != .movingPlatform && kind != .platform {
                    rects.append(tileRect(col: col, row: row))
                }
            }
        }
        return rects
    }

    func slopeRects() -> [(rect: CGRect, kind: TileKind)] {
        var slopes: [(CGRect, TileKind)] = []
        for row in 0..<height {
            for col in 0..<width {
                let kind = kind(at: col, row: row)
                if isSlope(kind) {
                    slopes.append((tileRect(col: col, row: row), kind))
                }
            }
        }
        return slopes
    }

    func platformRects() -> [CGRect] {
        var rects: [CGRect] = []
        for row in 0..<height {
            for col in 0..<width {
                let kind = kind(at: col, row: row)
                if kind == .platform || kind == .movingPlatform {
                    rects.append(tileRect(col: col, row: row))
                }
            }
        }
        return rects
    }
}

extension CGVector {
    func normalized() -> CGVector {
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return CGVector(dx: 0, dy: 1) }
        return CGVector(dx: dx / length, dy: dy / length)
    }
}
