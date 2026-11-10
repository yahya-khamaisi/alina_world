import SpriteKit

/// Soft, curved silhouettes for level tiles: every exposed outer corner of the land is cut into a smooth,
/// anti-aliased curve baked into the tile's texture, so steps, ledges and pit edges read as rounded shapes instead
/// of a grid of squares. Purely visual: collision still uses the tile grid.
enum RoundedTiles {
    struct Corners: OptionSet, Hashable {
        let rawValue: UInt8
        static let topLeft = Corners(rawValue: 1)
        static let topRight = Corners(rawValue: 2)
        static let bottomLeft = Corners(rawValue: 4)
        static let bottomRight = Corners(rawValue: 8)
        static let all: Corners = [.topLeft, .topRight, .bottomLeft, .bottomRight]
    }

    /// Land curves span most of a tile; separate blocks get a gentler, smaller radius.
    static let landRadius: CGFloat = 0.5
    static let blockRadius: CGFloat = 0.34

    /// Corners of the tile at (col, row) that face open space on both sides (convex corners).
    /// Rows count down from the top of the map; off the map sideways or below counts as land, above as sky.
    static func exposedCorners(col: Int, row: Int, map: TileMap) -> Corners {
        func land(_ c: Int, _ r: Int) -> Bool {
            if c < 0 || c >= map.width || r >= map.height { return true }
            if r < 0 { return false }
            switch map.kind(at: c, row: r) {
            case .solid, .ground, .brick, .question, .pipe, .spring,
                 .slopeUpRight, .slopeUpLeft, .slopeDownRight, .slopeDownLeft: return true
            default: return false
            }
        }
        let left = land(col - 1, row), right = land(col + 1, row)
        let up = land(col, row - 1), down = land(col, row + 1)
        var corners: Corners = []
        if !left && !up { corners.insert(.topLeft) }
        if !right && !up { corners.insert(.topRight) }
        if !left && !down { corners.insert(.bottomLeft) }
        if !right && !down { corners.insert(.bottomRight) }
        return corners
    }

    private static var cache: [String: SKTexture] = [:]

    /// `image` clipped to a rectangle whose chosen corners are rounded by `radius` × the tile. Tiles are drawn square
    /// whatever the image's own aspect, so the radius is a fraction of each side: the curve is circular on screen.
    static func texture(_ image: CGImage, key: String, corners: Corners, radius: CGFloat) -> SKTexture {
        let cacheKey = "\(key)|\(corners.rawValue)|\(radius)"
        if let hit = cache[cacheKey] { return hit }
        let w = CGFloat(image.width), h = CGFloat(image.height)
        let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setShouldAntialias(true)
        var scale = CGAffineTransform(scaleX: w, y: h)
        context.addPath(path(width: 1, height: 1, corners: corners, radius: radius).copy(using: &scale) ?? CGPath(rect: .zero, transform: nil))
        context.clip()
        context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        let texture = SKTexture(cgImage: context.makeImage() ?? image)
        texture.filteringMode = .linear
        cache[cacheKey] = texture
        return texture
    }

    /// Concave fillet for an inside corner: a square of soil (cut from the wall tile's lower edge) minus a quarter
    /// circle, so a floor meeting a wall curves up into it. `wallOnRight` is the side the wall stands on.
    static let filletRadius: CGFloat = 0.42

    static func fillet(theme: WorldTheme, variant: Int, wallOnRight: Bool) -> SKTexture {
        let cacheKey = "fillet|\(theme.key)|\(variant)|\(wallOnRight)"
        if let hit = cache[cacheKey] { return hit }
        let wall = PixelArt.image(.groundFill, theme: theme, overrides: ["#": UInt32(variant)])
        let cw = Int(CGFloat(wall.width) * filletRadius), ch = Int(CGFloat(wall.height) * filletRadius)
        // CGImage crops count from the top-left; take the wall's bottom strip on the side touching the corner.
        let crop = wall.cropping(to: CGRect(x: wallOnRight ? 0 : wall.width - cw, y: wall.height - ch, width: cw, height: ch)) ?? wall
        let context = CGContext(data: nil, width: cw, height: ch, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let w = CGFloat(cw), h = CGFloat(ch)
        // The corner sits at the bottom on the wall's side; the curve bulges away from it.
        let corner = CGPoint(x: wallOnRight ? w : 0, y: 0)
        let p = CGMutablePath()
        p.move(to: corner)
        p.addLine(to: CGPoint(x: corner.x, y: h))
        p.addQuadCurve(to: CGPoint(x: wallOnRight ? 0 : w, y: 0), control: corner)
        p.closeSubpath()
        context.addPath(p)
        context.clip()
        context.draw(crop, in: CGRect(x: 0, y: 0, width: w, height: h))
        let texture = SKTexture(cgImage: context.makeImage() ?? crop)
        texture.filteringMode = .linear
        cache[cacheKey] = texture
        return texture
    }

    /// Rectangle path (CoreGraphics coordinates, y up) with the given corners rounded.
    private static func path(width w: CGFloat, height h: CGFloat, corners: Corners, radius r: CGFloat) -> CGPath {
        let p = CGMutablePath()
        let tl = corners.contains(.topLeft) ? r : 0, tr = corners.contains(.topRight) ? r : 0
        let bl = corners.contains(.bottomLeft) ? r : 0, br = corners.contains(.bottomRight) ? r : 0
        p.move(to: CGPoint(x: bl, y: 0))
        p.addLine(to: CGPoint(x: w - br, y: 0))
        if br > 0 { p.addArc(tangent1End: CGPoint(x: w, y: 0), tangent2End: CGPoint(x: w, y: br), radius: br) }
        p.addLine(to: CGPoint(x: w, y: h - tr))
        if tr > 0 { p.addArc(tangent1End: CGPoint(x: w, y: h), tangent2End: CGPoint(x: w - tr, y: h), radius: tr) }
        p.addLine(to: CGPoint(x: tl, y: h))
        if tl > 0 { p.addArc(tangent1End: CGPoint(x: 0, y: h), tangent2End: CGPoint(x: 0, y: h - tl), radius: tl) }
        p.addLine(to: CGPoint(x: 0, y: bl))
        if bl > 0 { p.addArc(tangent1End: CGPoint(x: 0, y: 0), tangent2End: CGPoint(x: bl, y: 0), radius: bl) }
        p.closeSubpath()
        return p
    }
}
