import SpriteKit

/// Softens the land's outline beyond what the tiles' own rounded corners do: curved soil fillets in inside
/// corners (where a floor meets a wall), and roots or vines hanging under floating ledges.
/// Root and vine art comes from `TerrainEdges.png` (2 × 2: overhang, side wall, roots, vine).
/// Purely visual: collision still uses the tile grid.
enum TerrainEdges {
    private enum Piece: Int, CaseIterable { case overhang, wall, roots, vine }

    private static var cache: [String: SKTexture] = [:]

    private static let frames: [[Int]] = {
        guard let url = Bundle.module.url(forResource: "TerrainEdgesFrames", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let values = try? JSONDecoder().decode([[Int]].self, from: data),
              values.count == Piece.allCases.count, values.allSatisfy({ $0.count == 4 }) else { return [] }
        return values
    }()

    static var isAvailable: Bool { !frames.isEmpty && StorybookArt.image(.terrainEdges) != nil }

    /// Adds edge dressing for every ground or stone tile with an open side.
    static func decorate(_ worldNode: SKNode, map: TileMap, theme: WorldTheme) {
        guard isAvailable else { return }
        let tile = GameConstants.tileSize
        func earth(_ col: Int, _ row: Int) -> Bool {
            switch map.kind(at: col, row: row) {
            case .ground, .solid: return true
            default: return false
            }
        }
        func closed(_ col: Int, _ row: Int) -> Bool {
            // Anything solid next door hides the side; out-of-map columns count as closed (level borders).
            if col < 0 || col >= map.width { return true }
            return map.isSolid(map.kind(at: col, row: row))
        }

        for row in 0..<map.height {
            for col in 0..<map.width where earth(col, row) {
                let rect = map.tileRect(col: col, row: row)
                // Outer corners are rounded in the tiles themselves (`RoundedTiles`). Inside corners, where this tile
                // is a wall rising from a floor beside it, get a curved soil fillet so the outline flows.
                for side in [-1, 1] where !closed(col + side, row) && earth(col + side, row + 1) {
                    let fillet = SKSpriteNode(texture: RoundedTiles.fillet(theme: theme, variant: (col + row) % 8, wallOnRight: side < 0),
                                              size: CGSize(width: tile * RoundedTiles.filletRadius, height: tile * RoundedTiles.filletRadius))
                    fillet.anchorPoint = CGPoint(x: side < 0 ? 1 : 0, y: 0)
                    fillet.position = CGPoint(x: side < 0 ? rect.minX : rect.maxX, y: rect.minY)
                    fillet.zPosition = 1.05
                    worldNode.addChild(fillet)
                }

                // Under a ledge that floats over open space, now and then let roots or a vine hang down.
                if row + 1 < map.height, !closed(col, row + 1) {
                    let hash = (col &* 73_856_093) ^ (row &* 19_349_663)
                    if hash % 3 == 0 {
                        let piece: Piece = hash % 2 == 0 ? .vine : .roots
                        let hang = sprite(piece, theme: theme, width: piece == .vine ? tile * 0.5 : tile * 0.7)
                        hang.anchorPoint = CGPoint(x: 0.5, y: 0.96)
                        hang.position = CGPoint(x: rect.midX + CGFloat(hash % 9) - 4, y: rect.minY + 2)
                        hang.zPosition = 1.1
                        if !UserDefaults.standard.bool(forKey: SettingsKey.reduceMotion) {
                            let sway = SKAction.sequence([.rotate(toAngle: 0.06, duration: 1.6), .rotate(toAngle: -0.06, duration: 1.6)])
                            sway.timingMode = .easeInEaseOut
                            hang.run(.repeatForever(sway))
                        }
                        worldNode.addChild(hang)
                    }
                }
            }
        }
    }

    /// Sprite for one piece, sized by width or height keeping the painting's aspect.
    private static func sprite(_ piece: Piece, theme: WorldTheme, width: CGFloat? = nil, height: CGFloat? = nil) -> SKSpriteNode {
        let texture = self.texture(piece, theme: theme)
        let aspect = texture.size().width / max(1, texture.size().height)
        let size = width.map { CGSize(width: $0, height: $0 / aspect) } ?? CGSize(width: (height ?? 32) * aspect, height: height ?? 32)
        return SKSpriteNode(texture: texture, size: size)
    }

    /// The meadow uses the painting as is; other worlds recolour soil and grass like `IllustratedTerrain` does.
    private static func texture(_ piece: Piece, theme: WorldTheme) -> SKTexture {
        let key = "\(piece.rawValue)|\(theme.key)"
        if let hit = cache[key] { return hit }
        let b = frames[piece.rawValue]
        let crop = StorybookArt.image(.terrainEdges)!.cropping(to: CGRect(x: b[0], y: b[1], width: b[2], height: b[3]))!
        var image = crop
        if theme.key != "meadow" {
            let grassy = piece == .overhang || piece == .vine
            let context = CGContext(data: nil, width: crop.width, height: crop.height, bitsPerComponent: 8, bytesPerRow: 0,
                                    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            let rect = CGRect(x: 0, y: 0, width: crop.width, height: crop.height)
            context.draw(crop, in: rect)
            context.clip(to: rect, mask: crop)
            context.setBlendMode(.color)
            context.setFillColor(Drawing.color(grassy ? theme.grass.1 : theme.dirt.0, alpha: grassy ? 0.85 : 0.72))
            context.fill(rect)
            image = context.makeImage() ?? crop
        }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        cache[key] = texture
        return texture
    }
}
