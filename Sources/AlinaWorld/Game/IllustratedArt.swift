import CoreGraphics
import Foundation

/// Smooth, supersampled artwork for terrain, creatures, pickups and scenery.
/// Logical sprite bounds stay the same as the gameplay geometry; source textures have eight times the detail.
enum IllustratedArt {
    static func image(_ sprite: PixelSprite, theme: WorldTheme, scale: Int, variant: Int = 0) -> CGImage {
        if let frame = CharacterAtlas.image(sprite) { return frame }
        if let frame = IllustratedAtlas.sprite(sprite) { return frame }
        if let tile = IllustratedTerrain.image(sprite, theme: theme, variant: variant) { return tile }
        let size = PixelArt.size(of: sprite)
        return Drawing.image(size: size, scale: max(8, scale)) { p in
            switch sprite {
            case .heart, .heartEmpty: p.heart(empty: sprite == .heartEmpty)
            case .petal, .petalTurn: p.petal(turned: sprite == .petalTurn)
            case .crystal: p.crystal()
            case .flower, .sunbloom: p.flower(x: 50, y: 42, radius: 29, color: sprite == .sunbloom ? 0xFFD865 : 0xF991BB, stem: true)
            case .ribbon: p.bow()
            case .clock: p.clock()
            case .gloomling, .gloomlingStep, .guardian, .frostpuff, .thornbeetle, .shellcrab:
                p.creature(sprite)
            case .mothwisp, .mothwispFlap: p.moth(folded: sprite == .mothwispFlap)
            case .starwisp: p.star(cx: 50, cy: 48, radius: 43, fill: 0xFFE99A); p.eyes(y: 45)
            case .groundTop, .groundFill, .stone, .stoneTop:
                p.ground(theme, cap: sprite == .groundTop || sprite == .stoneTop)
            case .mossbrick, .bloomBlock, .bloomBlockUsed: p.block(sprite, theme: theme)
            case .leafPad, .leafPadLeft, .leafPadRight, .leafPadSingle: p.island(theme)
            case .log: p.log()
            case .thorns: p.thorns(theme)
            case .springShell: p.shell()
            case .beacon: p.beacon()
            case .cloud, .cloudPad: p.cloud()
            case .sun: p.ellipse(10, 10, 80, 80, [0xFFF9DA, 0xFFD56C], outline: 0xE3A748)
            case .tree: p.tree(theme)
            case .bush: p.bush(theme)
            case .hillFar, .hillNear: p.ellipse(-15, 10, 130, 160, [theme.hills.0, theme.hills.2], outline: nil)
            default: p.fallbackAlina()
            }
        }
    }

    static func propSize(_ kind: Props.Kind) -> CGSize {
        switch kind {
        case .tree: return CGSize(width: 64, height: 72)
        case .bush: return CGSize(width: 30, height: 16)
        case .rock: return CGSize(width: 20, height: 13)
        case .fence: return CGSize(width: 34, height: 18)
        case .flowers: return CGSize(width: 22, height: 14)
        }
    }

    private static var props: [String: CGImage] = [:]
    static func prop(_ kind: Props.Kind, theme: WorldTheme, variant: Int) -> CGImage {
        if let painting = IllustratedAtlas.prop(kind, theme: theme) { return painting }
        let key = "\(kind)|\(theme.key)|\(variant)"
        if let image = props[key] { return image }
        let image = Drawing.image(size: propSize(kind), scale: 6) { p in
            switch kind {
            case .tree: p.tree(theme)
            case .bush: p.bush(theme)
            case .rock: p.rock()
            case .fence: p.fence()
            case .flowers:
                for i in 0..<5 {
                    p.flower(x: 12 + Double(i) * 19, y: 35 + Double((i + variant) % 3) * 15,
                             radius: 12, color: [0xFF93B8, 0xFFFCED, 0xFFD75F][(i + variant) % 3], stem: true)
                }
            }
        }
        props[key] = image
        return image
    }
}

/// A normalised 100 × 100 drawing surface with antialiasing, curves and dimensional colour gradients.
struct Drawing {
    let c: CGContext
    static let outline: UInt32 = 0x4B263F

    static func image(size: CGSize, scale: Int, paint: (Drawing) -> Void) -> CGImage {
        let width = max(1, Int(size.width) * scale), height = max(1, Int(size.height) * scale)
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: CGFloat(width) / 100, y: -CGFloat(height) / 100)
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        paint(Drawing(c: context))
        return context.makeImage()!
    }

    static func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
        CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
                blue: CGFloat(hex & 255) / 255, alpha: alpha)
    }

    func shape(_ path: CGPath, _ colors: [UInt32], outline: UInt32? = Drawing.outline, line: CGFloat = 2.0) {
        c.saveGState()
        c.addPath(path)
        c.clip()
        let bounds = path.boundingBoxOfPath
        if colors.count > 1 {
            let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                      colors: colors.map { Self.color($0) } as CFArray, locations: nil)!
            c.drawLinearGradient(gradient, start: CGPoint(x: bounds.midX, y: bounds.minY),
                                 end: CGPoint(x: bounds.midX + bounds.width * 0.2, y: bounds.maxY), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        } else {
            c.setFillColor(Self.color(colors[0])); c.fill(bounds)
        }
        c.restoreGState()
        if let outline { stroke(path, outline, line) }
    }

    func stroke(_ path: CGPath, _ color: UInt32, _ width: CGFloat = 2, alpha: CGFloat = 1) {
        c.setStrokeColor(Self.color(color, alpha: alpha)); c.setLineWidth(width); c.addPath(path); c.strokePath()
    }

    func ellipse(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ colors: [UInt32], outline: UInt32? = Drawing.outline, line: CGFloat = 2) {
        shape(CGPath(ellipseIn: CGRect(x: x, y: y, width: w, height: h), transform: nil), colors, outline: outline, line: line)
    }

    func rounded(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ radius: Double, _ colors: [UInt32], outline: UInt32? = Drawing.outline, line: CGFloat = 2) {
        shape(CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerWidth: radius, cornerHeight: radius, transform: nil), colors, outline: outline, line: line)
    }

    func path(_ points: [(Double, Double)], close: Bool = true) -> CGPath {
        let p = CGMutablePath()
        if let first = points.first { p.move(to: CGPoint(x: first.0, y: first.1)) }
        for point in points.dropFirst() { p.addLine(to: CGPoint(x: point.0, y: point.1)) }
        if close { p.closeSubpath() }
        return p
    }

    func star(cx: Double, cy: Double, radius: Double, fill: UInt32, points: Int = 5) {
        let coords = (0..<points * 2).map { i -> (Double, Double) in
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let r = i.isMultiple(of: 2) ? radius : radius * 0.44
            return (cx + cos(angle) * r, cy + sin(angle) * r)
        }
        shape(path(coords), [0xFFF7CA, fill, 0xE8A844], outline: 0xA66B39)
    }

    func heart(empty: Bool) {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 50, y: 91))
        p.addCurve(to: CGPoint(x: 9, y: 29), control1: CGPoint(x: 22, y: 70), control2: CGPoint(x: -2, y: 49))
        p.addCurve(to: CGPoint(x: 50, y: 23), control1: CGPoint(x: 18, y: 5), control2: CGPoint(x: 43, y: 7))
        p.addCurve(to: CGPoint(x: 91, y: 29), control1: CGPoint(x: 57, y: 7), control2: CGPoint(x: 82, y: 5))
        p.addCurve(to: CGPoint(x: 50, y: 91), control1: CGPoint(x: 102, y: 49), control2: CGPoint(x: 78, y: 70))
        p.closeSubpath()
        shape(p, empty ? [0xF0DBD9, 0xCBB6C1] : [0xFF9AA2, 0xF54168, 0xB71F54], line: 4)
        let shine = CGMutablePath(); shine.move(to: CGPoint(x: 18, y: 34))
        shine.addCurve(to: CGPoint(x: 35, y: 21), control1: CGPoint(x: 19, y: 23), control2: CGPoint(x: 28, y: 19))
        stroke(shine, 0xFFFFFF, 5, alpha: empty ? 0.25 : 0.8)
    }

    func petal(turned: Bool) {
        c.saveGState()
        if turned { c.translateBy(x: 25, y: 0); c.scaleBy(x: 0.5, y: 1) }
        let p = CGMutablePath(); p.move(to: CGPoint(x: 14, y: 88))
        p.addCurve(to: CGPoint(x: 82, y: 9), control1: CGPoint(x: -5, y: 41), control2: CGPoint(x: 47, y: 14))
        p.addCurve(to: CGPoint(x: 14, y: 88), control1: CGPoint(x: 110, y: 64), control2: CGPoint(x: 48, y: 86))
        shape(p, [0xFFF1F8, 0xFF9BC9, 0xDB4C8A], outline: 0x81345D, line: 3)
        let vein = CGMutablePath(); vein.move(to: CGPoint(x: 20, y: 82)); vein.addQuadCurve(to: CGPoint(x: 76, y: 19), control: CGPoint(x: 57, y: 51))
        stroke(vein, 0xFFF4DF, 3)
        c.restoreGState()
    }

    func crystal() {
        shape(path([(50, 4), (80, 25), (94, 55), (50, 96), (6, 55), (20, 25)]), [0xE8BCFF, 0xA459ED, 0x622BB4], line: 3)
        shape(path([(50, 5), (63, 35), (50, 94), (36, 35)]), [0xFFFFFF, 0xD9A6FF, 0xA155DD], outline: nil)
        shape(path([(20, 26), (36, 35), (50, 94), (7, 55)]), [0xB575F3, 0x6E37B7], outline: nil)
        stroke(path([(20, 25), (36, 35), (63, 35), (80, 25)], close: false), 0xFFEAFE, 2)
    }

    func flower(x: Double, y: Double, radius: Double, color: UInt32, stem: Bool = false) {
        if stem {
            let p = CGMutablePath(); p.move(to: CGPoint(x: x, y: y + radius * 0.3)); p.addQuadCurve(to: CGPoint(x: x - 5, y: 96), control: CGPoint(x: x + 3, y: 80))
            stroke(p, 0x427744, 4)
            ellipse(x - 21, y + radius + 10, 18, 8, [0xA4CB69, 0x43864C], outline: nil)
        }
        for i in 0..<5 {
            let a = Double(i) / 5 * .pi * 2 - .pi / 2
            let px = x + cos(a) * radius * 0.54, py = y + sin(a) * radius * 0.54
            ellipse(px - radius * 0.43, py - radius * 0.43, radius * 0.86, radius * 0.86,
                    [PixelCanvas.mix(color, 0xFFFFFF, 0.6), color], outline: 0xB75679, line: 0.9)
        }
        ellipse(x - radius * 0.26, y - radius * 0.26, radius * 0.52, radius * 0.52, [0xFFF3AF, 0xE8AF3E], outline: 0xB5773D, line: 1)
    }

    func bow() {
        shape(path([(50, 39), (12, 17), (8, 69), (48, 55)]), [0xFFB7D4, 0xF260A6, 0xB72C73], line: 3)
        shape(path([(50, 39), (88, 17), (92, 69), (52, 55)]), [0xFFB7D4, 0xF260A6, 0xB72C73], line: 3)
        shape(path([(46, 50), (28, 92), (46, 82), (50, 92), (58, 52)]), [0xFFABD0, 0xD93A87], line: 2)
        ellipse(40, 35, 20, 26, [0xFFB6D9, 0xDF428F], line: 2)
    }

    func clock() {
        ellipse(9, 8, 30, 20, [0xFFE6A0, 0xD99138], line: 3)
        ellipse(61, 8, 30, 20, [0xFFE6A0, 0xD99138], line: 3)
        ellipse(10, 18, 80, 76, [0xFFF2B9, 0xD8983E], line: 4)
        ellipse(19, 26, 62, 60, [0xFFFFFF, 0xFFF4D8], line: 2)
        stroke(path([(50, 36), (50, 57), (65, 63)], close: false), Drawing.outline, 4)
        for i in 0..<12 { let a = Double(i) / 12 * .pi * 2; ellipse(49 + cos(a) * 25, 55 + sin(a) * 24, 2, 2, [0x72566A], outline: nil) }
    }

    func eyes(y: Double = 51) {
        ellipse(24, y, 20, 19, [0xFFF2AE, 0xE6C557], outline: nil)
        ellipse(58, y, 20, 19, [0xFFF2AE, 0xE6C557], outline: nil)
        ellipse(34, y + 4, 5, 11, [0x38233D], outline: nil)
        ellipse(62, y + 4, 5, 11, [0x38233D], outline: nil)
        stroke(path([(24, y), (45, y + 8)], close: false), Drawing.outline, 4)
        stroke(path([(57, y + 8), (78, y)], close: false), Drawing.outline, 4)
    }

    func creature(_ sprite: PixelSprite) {
        let frost = sprite == .frostpuff, crab = sprite == .shellcrab, spiky = sprite == .thornbeetle
        let guardian = sprite == .guardian
        let base: UInt32 = frost ? 0xD1EFFF : (crab ? 0xF38A88 : (spiky ? 0x986785 : 0x8362A9))
        let feet: UInt32 = frost ? 0x82B4D1 : (crab ? 0xC85B64 : 0xA96C91)
        ellipse(sprite == .gloomlingStep ? 15 : 10, 78, 28, 18, [0xE5A3BA, feet], line: 2)
        ellipse(sprite == .gloomlingStep ? 65 : 62, 78, 28, 18, [0xE5A3BA, feet], line: 2)
        let p = CGMutablePath(); p.move(to: CGPoint(x: 8, y: 80))
        p.addCurve(to: CGPoint(x: 50, y: 14), control1: CGPoint(x: -2, y: 42), control2: CGPoint(x: 21, y: 15))
        p.addCurve(to: CGPoint(x: 92, y: 80), control1: CGPoint(x: 79, y: 15), control2: CGPoint(x: 102, y: 42))
        p.addCurve(to: CGPoint(x: 8, y: 80), control1: CGPoint(x: 81, y: 95), control2: CGPoint(x: 20, y: 95))
        shape(p, [PixelCanvas.mix(base, 0xFFF3FD, 0.4), base, PixelCanvas.mix(base, 0x352244, 0.5)], line: 3)
        if spiky {
            for i in 0..<5 { let x = Double(i) * 16 + 12; shape(path([(x, 33), (x + 7, 6 + Double(abs(i - 2)) * 3), (x + 17, 36)]), [0xF7D6AF, 0xB17A67], line: 2) }
        }
        if guardian {
            shape(path([(24, 27), (18, 3), (36, 15), (50, 0), (65, 15), (82, 3), (76, 27)]), [0xFFF0A2, 0xDBA143], line: 2)
            ellipse(45, 12, 10, 11, [0xFFA4C8, 0xBD327C], line: 1)
        }
        if crab {
            ellipse(0, 40, 15, 28, [0xFFA8A0, 0xC55E6F], line: 2)
            ellipse(85, 40, 15, 28, [0xFFA8A0, 0xC55E6F], line: 2)
        }
        eyes(y: 48)
        let smile = CGMutablePath(); smile.move(to: CGPoint(x: 41, y: 77)); smile.addQuadCurve(to: CGPoint(x: 59, y: 77), control: CGPoint(x: 50, y: 83))
        stroke(smile, Drawing.outline, 2)
        // Gloomlings intentionally have no flower sprout: their silhouette is distinct from pickups.
    }

    func moth(folded: Bool) {
        let span = folded ? 18.0 : 35.0
        ellipse(43 - span, 10, span, 52, [0xF1D7FF, 0xA48BD6, 0x6C5A9B], line: 2)
        ellipse(57, 10, span, 52, [0xF1D7FF, 0xA48BD6, 0x6C5A9B], line: 2)
        ellipse(48 - span, 54, span, 30, [0xE9C9FB, 0x8D72BF], line: 2)
        ellipse(52, 54, span, 30, [0xE9C9FB, 0x8D72BF], line: 2)
        ellipse(38, 28, 24, 52, [0xAA8EC8, 0x473655], line: 2)
        ellipse(39, 31, 7, 10, [0xFFF3AD], outline: nil); ellipse(54, 31, 7, 10, [0xFFF3AD], outline: nil)
    }

    func ground(_ theme: WorldTheme, cap: Bool) {
        rounded(-2, -2, 104, 104, 0, [PixelCanvas.mix(theme.dirt.0, 0xFFD7A3, 0.22), theme.dirt.0, theme.dirt.1], outline: nil)
        var rng = SeededRNG(seed: 1023)
        for i in 0..<14 {
            let x = Double(rng.next() % 100), y = Double(rng.next() % 100)
            let w = 8 + Double(rng.next() % 18), h = 4 + Double(rng.next() % 12)
            rounded(x - w / 2, y, w, h, h * 0.45, [PixelCanvas.mix(theme.dirt.0, 0xFEE1AF, i % 3 == 0 ? 0.4 : 0.17), theme.dirt.0], outline: theme.dirt.1, line: 0.65)
        }
        if cap { grass(theme) }
    }

    func grass(_ theme: WorldTheme) {
        let p = CGMutablePath(); p.move(to: CGPoint(x: -2, y: -2)); p.addLine(to: CGPoint(x: 102, y: -2)); p.addLine(to: CGPoint(x: 102, y: 15))
        for i in stride(from: 100, through: 0, by: -10) {
            let x = CGFloat(i); p.addQuadCurve(to: CGPoint(x: x - 10, y: 15), control: CGPoint(x: x - 5, y: 32 + (i % 20 == 0 ? 4 : 0)))
        }
        p.closeSubpath(); shape(p, [theme.grass.0, theme.grass.1, theme.grass.2], outline: nil)
        for i in 0..<12 {
            let x = Double(i) * 9
            stroke(path([(x, 11), (x + 2, 4), (x + 5, 12)], close: false), theme.grass.0, 1.6)
        }
        stroke(path([(-2, 2), (102, 2)], close: false), PixelCanvas.mix(theme.grass.0, 0xFFEDAC, 0.4), 2)
    }

    func block(_ sprite: PixelSprite, theme: WorldTheme) {
        let bloom = sprite == .bloomBlock
        rounded(3, 3, 94, 94, 13, bloom ? [0xFFE69B, 0xD9A14C, 0xA36D36] : [0xD9BA91, 0xA57A59, 0x775942], line: 4)
        rounded(10, 10, 80, 78, 9, bloom ? [0xFFEAB2, 0xECB95E] : [0xC9AC87, 0x997A5C], outline: 0xF9DCAB, line: 2)
        if bloom { flower(x: 50, y: 50, radius: 25, color: 0xFFF7E5) }
        if sprite == .bloomBlockUsed { ellipse(42, 42, 16, 16, [0x8F6C55], outline: nil) }
        if sprite == .mossbrick {
            for y in [34.0, 66] { stroke(path([(8, y), (92, y)], close: false), 0x7C5E50, 3) }
            stroke(path([(50, 8), (50, 34)], close: false), 0x7C5E50, 3)
            stroke(path([(32, 34), (32, 66)], close: false), 0x7C5E50, 3)
            ellipse(6, 6, 35, 12, [theme.grass.0, theme.grass.2], outline: nil)
        }
    }

    func island(_ theme: WorldTheme) {
        shape(path([(1, 8), (99, 8), (91, 55), (75, 69), (56, 62), (39, 76), (16, 57)]), [0xB79975, theme.dirt.0, theme.dirt.1], line: 1.3)
        grass(theme)
        for (x, length) in [(20.0, 93.0), (80, 82)] {
            let p = CGMutablePath(); p.move(to: CGPoint(x: x, y: 20)); p.addCurve(to: CGPoint(x: x - 5, y: length), control1: CGPoint(x: x - 14, y: 40), control2: CGPoint(x: x + 10, y: 62))
            stroke(p, theme.leaves.1, 2)
            for y in stride(from: 38.0, to: length, by: 17) { ellipse(x - 9, y, 13, 8, [theme.leaves.0, theme.leaves.1], outline: nil) }
        }
    }

    func log() {
        rounded(10, -2, 80, 104, 10, [0xC98B5B, 0x9A5B38, 0x6B3D2B], line: 3)
        for i in 0..<6 {
            let x = Double(i) * 12 + 18
            let p = CGMutablePath(); p.move(to: CGPoint(x: x, y: 10)); p.addCurve(to: CGPoint(x: x + 2, y: 98), control1: CGPoint(x: x - 6, y: 40), control2: CGPoint(x: x + 8, y: 70))
            stroke(p, i.isMultiple(of: 2) ? 0xE2B17E : 0x774831, 1.4)
        }
        ellipse(8, 0, 84, 23, [0xF0C795, 0xC28A59], line: 3)
        ellipse(24, 4, 52, 13, [0xE9B581], outline: 0x9D6C45, line: 1)
        ellipse(38, 7, 24, 7, [0xE9B581], outline: 0x9D6C45, line: 1)
    }

    func thorns(_ theme: WorldTheme) {
        for i in 0..<5 {
            let x = Double(i) * 21
            shape(path([(x - 2, 94), (x + 8, 24 + Double(i % 2) * 12), (x + 22, 94)]), [0xE5EBA9, theme.grass.2, theme.leaves.1], line: 1.5)
        }
    }

    func shell() {
        ellipse(5, 60, 90, 34, [0xFFF0C2, 0xD0A87D], line: 3)
        shape(path([(8, 65), (13, 31), (30, 16), (50, 8), (71, 16), (88, 31), (93, 65)]), [0xFFD5DE, 0xF68EAA, 0xC55780], line: 3)
        for x in [26.0, 50, 74] { stroke(path([(50, 64), (x, 19)], close: false), 0xFFE4E8, 3) }
    }

    func beacon() {
        rounded(67, 5, 12, 91, 3, [0xDCA46E, 0x8D5439], line: 2)
        rounded(20, 8, 65, 9, 3, [0xDCA46E, 0x8D5439], line: 2)
        stroke(path([(37, 16), (37, 36)], close: false), 0xAD773D, 2)
        rounded(15, 38, 43, 45, 5, [0xFFD366, 0xEB9440], line: 2)
        rounded(21, 43, 31, 32, 3, [0xFFFBD1, 0xFFD56B], outline: 0xBE742A, line: 1.5)
        shape(path([(10, 39), (37, 27), (63, 39)]), [0xFFE19A, 0xBA773D], line: 2)
        flower(x: 37, y: 60, radius: 9, color: 0xFFFFFF)
        rounded(8, 94, 82, 6, 2, [0xD9C0A6, 0xA18B83], line: 1)
    }

    func cloud() {
        let p = CGMutablePath(); p.move(to: CGPoint(x: 12, y: 86))
        p.addCurve(to: CGPoint(x: 16, y: 43), control1: CGPoint(x: -2, y: 84), control2: CGPoint(x: -2, y: 48))
        p.addCurve(to: CGPoint(x: 50, y: 31), control1: CGPoint(x: 12, y: 11), control2: CGPoint(x: 43, y: 3))
        p.addCurve(to: CGPoint(x: 82, y: 47), control1: CGPoint(x: 59, y: 8), control2: CGPoint(x: 85, y: 22))
        p.addCurve(to: CGPoint(x: 90, y: 87), control1: CGPoint(x: 104, y: 42), control2: CGPoint(x: 104, y: 82))
        p.closeSubpath(); shape(p, [0xFFFFFF, 0xFBE3ED, 0xCEB9DD], outline: 0xA695BA, line: 1)
    }

    func tree(_ theme: WorldTheme) {
        let bark = CGMutablePath(); bark.move(to: CGPoint(x: 34, y: 97)); bark.addCurve(to: CGPoint(x: 45, y: 35), control1: CGPoint(x: 49, y: 83), control2: CGPoint(x: 43, y: 50))
        bark.addLine(to: CGPoint(x: 58, y: 35)); bark.addCurve(to: CGPoint(x: 70, y: 97), control1: CGPoint(x: 54, y: 66), control2: CGPoint(x: 55, y: 83)); bark.closeSubpath()
        shape(bark, [0xD7A36F, 0x975E3F, 0x63422F], line: 1.2)
        let blossom = theme.key == "meadow"
        let colors: [UInt32] = blossom ? [0xFFE1EC, 0xF3A1BF, 0xBE668F] : [theme.grass.0, theme.leaves.0, theme.leaves.1]
        for (x, y, w, h) in [(8.0, 23.0, 42.0, 34.0), (52, 22, 41, 34), (21, 6, 41, 43), (42, 7, 40, 39), (28, 28, 40, 32)] {
            ellipse(x, y, w, h, colors, outline: blossom ? 0xA4557D : theme.leaves.1, line: 0.7)
        }
        for i in 0..<21 {
            let x = 15.0 + Double((i * 19) % 70), y = 15.0 + Double((i * 11) % 34)
            if blossom { flower(x: x, y: y, radius: 3.1, color: i.isMultiple(of: 3) ? 0xFFE9F1 : 0xE585AC) }
            else { ellipse(x, y, 6, 3, [theme.grass.0], outline: nil) }
        }
    }

    func bush(_ theme: WorldTheme) {
        for (x, y, w, h) in [(2.0, 34.0, 48.0, 60.0), (24, 12, 52, 81), (57, 35, 41, 59)] {
            ellipse(x, y, w, h, [theme.grass.0, theme.leaves.0, theme.leaves.1], outline: theme.leaves.1, line: 1)
        }
        for i in 0..<8 { flower(x: 12 + Double(i) * 11, y: 42 + Double(i % 3) * 14, radius: 6, color: i.isMultiple(of: 2) ? 0xFFDCEB : 0xFFF5D9) }
    }

    func rock() {
        let p = CGMutablePath(); p.move(to: CGPoint(x: 4, y: 93)); p.addCurve(to: CGPoint(x: 34, y: 15), control1: CGPoint(x: -2, y: 56), control2: CGPoint(x: 16, y: 24)); p.addCurve(to: CGPoint(x: 94, y: 92), control1: CGPoint(x: 74, y: -3), control2: CGPoint(x: 97, y: 50)); p.closeSubpath()
        shape(p, [0xEAE1E6, 0xB5A8BB, 0x84778E], outline: 0x71657C, line: 1.8)
        stroke(path([(28, 24), (40, 46), (70, 52), (87, 77)], close: false), 0xF1E5E7, 2)
    }

    func fence() {
        for x in [7.0, 82] { rounded(x, 5, 10, 94, 2, [0xE4B180, 0xA36A46], outline: 0x754631, line: 1.5) }
        for y in [28.0, 62] { rounded(0, y, 100, 12, 2, [0xE3AC77, 0xA66E49], outline: 0x754631, line: 1.2) }
        for x in [11.0, 86] { for y in [32.0, 66] { ellipse(x, y, 3, 4, [0xFFE7BC], outline: 0x79523A, line: 0.5) } }
    }

    func fallbackAlina() {
        ellipse(22, 8, 58, 55, [0xB07145, 0x643B2B], line: 2)
        ellipse(35, 22, 40, 34, [0xFFE0B9, 0xECA99D], line: 1.4)
        rounded(40, 69, 8, 27, 3, [0xF7D8BC, 0x8D523B], line: 1)
        rounded(60, 69, 8, 27, 3, [0xF7D8BC, 0x8D523B], line: 1)
        shape(path([(43, 54), (65, 54), (81, 80), (29, 80)]), [0xFFABD0, 0xE95699], line: 1.5)
        ellipse(46, 34, 4, 7, [0x38233A], outline: nil); ellipse(62, 34, 4, 7, [0x38233A], outline: nil)
    }
}
