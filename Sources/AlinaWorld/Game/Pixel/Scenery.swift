import CoreGraphics
import SpriteKit
import Foundation

/// Colours for the painted backdrop. The meadow gets a hand-picked golden-hour set; other worlds derive theirs
/// from their `WorldTheme` so every world keeps its identity.
struct BackdropPalette {
    var sky: [UInt32]
    var sun: UInt32
    var sunGlow: UInt32
    /// Light, body, underside.
    var cloud: (UInt32, UInt32, UInt32)
    /// Lit face, body, shaded face.
    var mountain: (UInt32, UInt32, UInt32)
    var haze: UInt32
    /// Rim light, body, shade, trees.
    var farHill: (UInt32, UInt32, UInt32, UInt32)
    var nearHill: (UInt32, UInt32, UInt32, UInt32)
    var flowers: [UInt32]

    static func forTheme(_ theme: WorldTheme) -> BackdropPalette {
        if theme.key == "meadow" {
            return BackdropPalette(
                sky: [0x6CA4EC, 0x8AB2F0, 0xADB5EE, 0xD0B6E6, 0xEFBDD6, 0xFFD3BF, 0xFFE2B8],
                sun: 0xFFF6CF, sunGlow: 0xFFE7AE,
                cloud: (0xFFF6F2, 0xFAD7E3, 0xDDB2D6),
                mountain: (0xD8B6E2, 0xB79DDA, 0x9883C8), haze: 0xEACBE0,
                farHill: (0xCFE08C, 0x97C67A, 0x74AC6C, 0x54905C),
                nearHill: (0xD8EC72, 0xA2D35A, 0x78B54C, 0x4F9446),
                flowers: [0xFF9CC8, 0xFFF4F8, 0xFFD45E]
            )
        }
        let mix = PixelCanvas.mix
        let sky = theme.sky
        return BackdropPalette(
            sky: sky,
            sun: 0xFFF8E0, sunGlow: mix(sky[4], 0xFFE9A0, 0.55),
            cloud: (0xFFFFFF, mix(0xFFFFFF, sky[4], 0.35), mix(sky[2], 0x9F8FD0, 0.3)),
            mountain: (mix(theme.hills.0, 0xC8B4E6, 0.4), mix(theme.hills.1, 0x9C8CD0, 0.4), mix(theme.hills.2, 0x7C6CB4, 0.4)),
            haze: mix(sky[4], theme.hills.0, 0.35),
            farHill: (theme.hills.0, theme.hills.1, theme.hills.2, mix(theme.hills.2, theme.leaves.1, 0.55)),
            nearHill: (theme.grass.0, theme.grass.1, mix(theme.grass.1, theme.grass.2, 0.5), theme.leaves.1),
            flowers: []
        )
    }
}

/// Procedurally painted parallax layers on a true pixel grid. Each layer is `layerWidth` pixels wide and tiles
/// seamlessly. One art pixel is drawn at `GameConstants.tilePixel` world units, the same density as the tiles.
enum Scenery {
    static let layerWidth = 512

    enum Layer: String, CaseIterable {
        case sky, clouds, mountains, farHills, nearHills
    }

    private static var cache: [String: CGImage] = [:]
    private static let lock = NSLock()

    static func image(_ layer: Layer, theme: WorldTheme) -> CGImage {
        let key = "\(theme.key)|\(layer.rawValue)"
        if let hit = lock.withLock({ cache[key] }) { return hit }
        let palette = BackdropPalette.forTheme(theme)
        let seed = UInt64(WorldThemes.index(of: theme.key) + 1) &* 7919
        let canvas: PixelCanvas
        switch layer {
        case .sky: canvas = sky(palette)
        case .clouds: canvas = clouds(palette, seed: seed)
        case .mountains: canvas = mountains(palette, seed: seed)
        case .farHills: canvas = farHills(palette, seed: seed)
        case .nearHills: canvas = nearHills(palette, seed: seed)
        }
        let image = canvas.cgImage()
        lock.withLock { cache[key] = image }
        return image
    }

    // MARK: Sky

    static let skySize = (width: 1024, height: 280)

    private static func sky(_ p: BackdropPalette) -> PixelCanvas {
        let (w, h) = skySize
        var c = PixelCanvas(width: w, height: h)
        for y in 0..<h {
            for x in 0..<w {
                c.set(x, y, PixelCanvas.ditheredRamp(p.sky, Double(y) / Double(h - 1), x: x, y: y))
            }
        }
        // Low sun with two dithered rings of glow, sitting on the mountain line.
        let sx = Double(w) * 0.66, sy = Double(h) * 0.47
        for y in 0..<h {
            for x in 0..<w {
                let d = hypot(Double(x) + 0.5 - sx, (Double(y) + 0.5 - sy) * 1.15)
                guard d < 120, let base = c.get(x, y) else { continue }
                let strength = pow(1 - d / 120, 1.6)
                if strength > PixelCanvas.bayer(x, y) {
                    c.set(x, y, PixelCanvas.mix(base, p.sunGlow, d < 40 ? 0.75 : 0.45))
                }
            }
        }
        c.fillEllipse(cx: sx, cy: sy, rx: 17, ry: 17, PixelCanvas.mix(p.sun, p.sunGlow, 0.4))
        c.fillEllipse(cx: sx, cy: sy, rx: 15, ry: 15, p.sun)
        c.fillEllipse(cx: sx - 4, cy: sy - 5, rx: 6, ry: 5, 0xFFFFFF)
        // A few wisps of high cloud.
        var rng = SeededRNG(seed: 99)
        for _ in 0..<26 {
            let x = Int(rng.next() % UInt64(w)), y = 14 + Int(rng.next() % 90)
            let len = 10 + Int(rng.next() % 34)
            c.fillRect(x, y, len, 1, PixelCanvas.mix(c.get(x, y) ?? p.sky[0], 0xFFFFFF, 0.35))
            c.fillRect(x + 4, y + 1, len - 8, 1, PixelCanvas.mix(c.get(x, y + 1) ?? p.sky[0], p.cloud.1, 0.35))
        }
        return c
    }

    // MARK: Clouds

    private static func clouds(_ p: BackdropPalette, seed: UInt64) -> PixelCanvas {
        var c = PixelCanvas(width: layerWidth, height: 110)
        c.wrapX = true
        var rng = SeededRNG(seed: seed &+ 11)
        var x = 20
        while x < layerWidth - 30 {
            let span = 50 + Int(rng.next() % 70)
            let base = 60 + Int(rng.next() % 44)
            cumulus(&c, x: x, base: base, span: span, palette: p, rng: &rng)
            x += span + 24 + Int(rng.next() % 50)
        }
        return c
    }

    /// Puffy cumulus: overlapping puffs, sunlit tops, a flat lilac underside.
    private static func cumulus(_ c: inout PixelCanvas, x: Int, base: Int, span: Int, palette p: BackdropPalette, rng: inout SeededRNG) {
        var puffs: [(Double, Double, Double)] = []
        let count = 3 + span / 22
        for i in 0..<count {
            let t = (Double(i) + 0.5) / Double(count)
            let middle = 1 - abs(t - 0.5) * 1.4
            let r = 7 + Double(rng.next() % 6) + middle * Double(span) * 0.16
            puffs.append((Double(x) + t * Double(span), Double(base) - r * 0.55 - middle * 6, r))
        }
        func paint(_ dx: Double, _ dy: Double, _ shrink: Double, _ color: UInt32) {
            for (cx, cy, r) in puffs {
                let rr = r * shrink
                for yy in Int(cy + dy - rr)...Int(cy + dy + rr) where yy <= base {
                    for xx in Int(cx + dx - rr)...Int(cx + dx + rr) {
                        let ddx = (Double(xx) + 0.5 - cx - dx), ddy = (Double(yy) + 0.5 - cy - dy)
                        if ddx * ddx + ddy * ddy <= rr * rr { c.set(xx, yy, color) }
                    }
                }
            }
        }
        paint(0, 0, 1, p.cloud.2)
        paint(-1, -2, 0.9, p.cloud.1)
        paint(-3, -4, 0.62, p.cloud.0)
        // Dithered seam between body and underside.
        for xx in (x - 10)...(x + span + 10) {
            for yy in (base - 4)...base where c.get(xx, yy) == p.cloud.1 && PixelCanvas.bayer(xx, yy) < 0.5 {
                c.set(xx, yy, p.cloud.2)
            }
        }
    }

    // MARK: Mountains

    private static func mountains(_ p: BackdropPalette, seed: UInt64) -> PixelCanvas {
        let h = 104
        var c = PixelCanvas(width: layerWidth, height: h)
        c.wrapX = true
        // Peaks as tents with a little noise on the slopes; the tallest tent at each column wins.
        var rng = SeededRNG(seed: seed &+ 3)
        var peaks: [(x: Double, height: Double, left: Double, right: Double)] = []
        var x = 0.0
        while x < Double(layerWidth) {
            let tall = rng.next() % 3 != 0
            let height = tall ? 50 + Double(rng.next() % 30) : 30 + Double(rng.next() % 18)
            peaks.append((x, height, 0.55 + Double(rng.next() % 40) / 100, 0.6 + Double(rng.next() % 50) / 100))
            x += 46 + Double(rng.next() % 60)
        }
        let rough = LoopNoise(period: layerWidth, seed: seed &+ 4, harmonics: [17, 29, 43], falloff: 0.7)
        func best(_ x: Int) -> (top: Int, peak: Double) {
            var top = 0.0, peakX = 0.0
            for peak in peaks {
                for shift in [-Double(layerWidth), 0, Double(layerWidth)] {
                    let dx = Double(x) + 0.5 - (peak.x + shift)
                    let height = peak.height - abs(dx) * (dx < 0 ? peak.left : peak.right)
                    if height > top { top = height; peakX = peak.x + shift }
                }
            }
            return (h - Int(top + rough.value(Double(x)) * 3), peakX)
        }
        for x in 0..<layerWidth {
            let (t, peakX) = best(x)
            let litSide = Double(x) + 0.5 > peakX
            for y in max(0, t)..<h {
                let d = y - t
                var color = p.mountain.1
                if litSide {
                    // Sunlit face: bright near the ridge, fading into the body.
                    let fade = 1 - Double(d) / 40
                    if fade > PixelCanvas.bayer(x, y) { color = p.mountain.0 }
                    if d < 2 { color = PixelCanvas.mix(p.mountain.0, 0xFFFFFF, 0.35) }
                } else {
                    let fade = Double(d) / 30
                    if fade > PixelCanvas.bayer(x, y) || d < 1 { color = p.mountain.2 }
                }
                let hazeT = Double(y - (h - 22)) / 22
                if hazeT > PixelCanvas.bayer(x, y) { color = p.haze }
                c.set(x, y, color)
            }
        }
        return c
    }

    // MARK: Hills

    private static func farHills(_ p: BackdropPalette, seed: UInt64) -> PixelCanvas {
        let h = 84
        var c = PixelCanvas(width: layerWidth, height: h)
        c.wrapX = true
        let noise = LoopNoise(period: layerWidth, seed: seed &+ 5, harmonics: [3, 4, 7, 11], falloff: 0.55)
        func top(_ x: Int) -> Int { h - Int(40 + 26 * noise.value(Double(x))) }
        for x in 0..<layerWidth {
            let t = top(x)
            for y in t..<h {
                let d = y - t
                var color = p.farHill.1
                if d < 2 || (d < 6 && Double(6 - d) / 5 > PixelCanvas.bayer(x, y)) { color = p.farHill.0 }
                if Double(d - 18) / 40 > PixelCanvas.bayer(x, y) { color = p.farHill.2 }
                c.set(x, y, color)
            }
        }
        // Clumps of small trees on the slopes.
        var rng = SeededRNG(seed: seed &+ 17)
        for _ in 0..<150 {
            let x = Int(rng.next() % UInt64(layerWidth))
            let y = top(x) + 3 + Int(rng.next() % 34)
            smallTree(&c, x: x, y: y, color: p.farHill.3, light: PixelCanvas.mix(p.farHill.3, p.farHill.0, 0.45), tall: rng.next() % 3 == 0)
        }
        return c
    }

    private static func smallTree(_ c: inout PixelCanvas, x: Int, y: Int, color: UInt32, light: UInt32, tall: Bool) {
        guard c.get(x, y) != nil else { return }
        if tall {
            // Little conifer.
            for i in 0..<7 {
                let half = i / 2
                c.fillRect(x - half, y - 7 + i, half * 2 + 1, 1, color)
            }
            c.set(x, y - 7, light)
            c.set(x - 1, y - 4, light)
        } else {
            c.fillEllipse(cx: Double(x) + 0.5, cy: Double(y) - 2, rx: 3, ry: 3, color)
            c.set(x - 1, y - 4, light)
            c.set(x, y - 4, light)
            c.set(x - 2, y - 3, light)
        }
    }

    private static func nearHills(_ p: BackdropPalette, seed: UInt64) -> PixelCanvas {
        let h = 80
        var c = PixelCanvas(width: layerWidth, height: h)
        c.wrapX = true
        let noise = LoopNoise(period: layerWidth, seed: seed &+ 23, harmonics: [2, 3, 5, 9], falloff: 0.5)
        func top(_ x: Int) -> Int { h - Int(30 + 20 * noise.value(Double(x))) }
        for x in 0..<layerWidth {
            let t = top(x)
            for y in t..<h {
                let d = y - t
                var color = p.nearHill.1
                if d < 2 || (d < 8 && Double(8 - d) / 7 > PixelCanvas.bayer(x, y)) { color = p.nearHill.0 }
                if Double(d - 22) / 30 > PixelCanvas.bayer(x, y) { color = p.nearHill.2 }
                c.set(x, y, color)
            }
        }
        var rng = SeededRNG(seed: seed &+ 31)
        // Round trees with a trunk, lit from the upper right like the sun.
        var x = Int(rng.next() % 40)
        while x < layerWidth {
            let r = 6 + Double(rng.next() % 5)
            let y = top(x) + 4 + Int(rng.next() % 6)
            roundTree(&c, x: x, y: y, r: r, palette: p)
            if rng.next() % 2 == 0 {
                roundTree(&c, x: x + Int(r * 1.3), y: y + 2, r: r * 0.75, palette: p)
            }
            x += 40 + Int(rng.next() % 70)
        }
        for _ in 0..<220 where !p.flowers.isEmpty {
            let fx = Int(rng.next() % UInt64(layerWidth))
            let fy = top(fx) + 12 + Int(rng.next() % 40)
            guard fy < h else { continue }
            c.tint(fx, fy, p.flowers[Int(rng.next() % UInt64(p.flowers.count))])
        }
        return c
    }

    private static func roundTree(_ c: inout PixelCanvas, x: Int, y: Int, r: Double, palette p: BackdropPalette) {
        let trunk: UInt32 = 0x7A4E36
        c.fillRect(x - 1, y - Int(r * 0.6), 3, Int(r * 0.6) + 2, trunk)
        let cy = Double(y) - r * 1.3
        c.fillEllipse(cx: Double(x) + 0.5, cy: cy, rx: r, ry: r * 0.95, p.nearHill.3)
        c.fillEllipse(cx: Double(x) + 1.5, cy: cy - 1.5, rx: r * 0.78, ry: r * 0.72, PixelCanvas.mix(p.nearHill.3, p.nearHill.1, 0.6))
        c.fillEllipse(cx: Double(x) + r * 0.3 + 0.5, cy: cy - r * 0.35, rx: r * 0.4, ry: r * 0.35, p.nearHill.0)
    }
}

/// Painted foreground props planted along the ground: blossom trees, flowering bushes, boulders, fences, flowers.
enum Props {
    enum Kind: String {
        case tree, bush, rock, fence, flowers
    }

    private static var cache: [String: SKTexture] = [:]
    private static let lock = NSLock()

    static func texture(_ kind: Kind, theme: WorldTheme, variant: Int = 0) -> SKTexture {
        let key = "\(theme.key)|\(kind.rawValue)|\(variant)"
        if let hit = lock.withLock({ cache[key] }) { return hit }
        let texture = canvas(kind, theme: theme, variant: variant).texture()
        lock.withLock { cache[key] = texture }
        return texture
    }

    static func canvas(_ kind: Kind, theme: WorldTheme, variant: Int) -> PixelCanvas {
        var rng = SeededRNG(seed: UInt64(variant + 1) &* 977 &+ UInt64(kind.rawValue.count))
        switch kind {
        case .tree: return tree(theme, rng: &rng)
        case .bush: return bush(theme, rng: &rng)
        case .rock: return rock(rng: &rng)
        case .fence: return fence()
        case .flowers: return flowers(theme, rng: &rng)
        }
    }

    /// Canopy light, body, shade; the meadow blooms pink.
    private static func canopy(_ theme: WorldTheme) -> (UInt32, UInt32, UInt32, UInt32) {
        if theme.key == "meadow" { return (0xFFD3E4, 0xF795BF, 0xDE6AA2, 0xB84C86) }
        let l = theme.leaves
        return (PixelCanvas.mix(l.0, 0xFFFFFF, 0.4), l.0, PixelCanvas.mix(l.0, l.1, 0.6), l.1)
    }

    private static func outlineColor(_ theme: WorldTheme) -> UInt32 { PixelCanvas.mix(theme.leaves.1, 0x3A1E36, 0.55) }

    private static func tree(_ theme: WorldTheme, rng: inout SeededRNG) -> PixelCanvas {
        let w = 64, h = 72
        var c = PixelCanvas(width: w, height: h)
        let bark: (UInt32, UInt32, UInt32) = (0xC08458, 0x8E5A3C, 0x63402E)
        // Trunk with a lean and flared roots, lit from the right.
        for y in 30..<h {
            let t = Double(y - 30) / Double(h - 30)
            let half = 3.5 + t * t * 6
            let cx = 32 + sin(t * 2.4) * 2
            for x in Int(cx - half)...Int(cx + half) {
                let u = (Double(x) - (cx - half)) / (2 * half)
                var col = bark.1
                if u > 0.62 { col = bark.0 }
                if u < 0.22 { col = bark.2 }
                if (x * 3 + y * 5) % 11 == 0 { col = bark.2 }
                c.set(x, y, col)
            }
        }
        // Two boughs.
        for i in 0..<12 {
            c.fillRect(31 - i, 34 - i / 2, 3, 2, bark.1)
            c.fillRect(33 + i, 32 - i / 2, 3, 2, i % 3 == 0 ? bark.0 : bark.1)
        }
        let (light, body, shade, deep) = canopy(theme)
        var puffs: [(Double, Double, Double)] = []
        for _ in 0..<16 {
            let a = Double(rng.next() % 628) / 100
            let d = Double(rng.next() % 100) / 100
            puffs.append((32 + cos(a) * 22 * d, 22 + sin(a) * 12 * d, 7 + Double(rng.next() % 5)))
        }
        for (x, y, r) in puffs { c.fillEllipse(cx: x, cy: y + 2, rx: r, ry: r * 0.85, deep) }
        for (x, y, r) in puffs { c.fillEllipse(cx: x - 0.5, cy: y, rx: r - 1, ry: r * 0.85 - 1, shade) }
        for (x, y, r) in puffs { c.fillEllipse(cx: x + 0.5, cy: y - 1.5, rx: r * 0.72, ry: r * 0.6, body) }
        for (x, y, r) in puffs where r > 8 { c.fillEllipse(cx: x + 1.5, cy: y - 3, rx: r * 0.35, ry: r * 0.28, light) }
        // Scattered single blossoms for texture.
        for _ in 0..<70 {
            let x = Int(rng.next() % UInt64(w)), y = Int(rng.next() % 40)
            if c.get(x, y) == body { c.set(x, y, light) } else if c.get(x, y) == shade { c.set(x, y, body) }
        }
        c.outline(outlineColor(theme))
        return c
    }

    private static func bush(_ theme: WorldTheme, rng: inout SeededRNG) -> PixelCanvas {
        var c = PixelCanvas(width: 30, height: 16)
        let l = theme.leaves
        let light = PixelCanvas.mix(l.0, 0xFFFFFF, 0.3)
        let puffs: [(Double, Double, Double)] = [(8, 10, 6), (15, 8, 7.5), (22, 10, 6)]
        for (x, y, r) in puffs { c.fillEllipse(cx: x, cy: y + 1, rx: r, ry: r * 0.85, l.1) }
        for (x, y, r) in puffs { c.fillEllipse(cx: x + 0.5, cy: y - 0.5, rx: r * 0.75, ry: r * 0.6, l.0) }
        for (x, y, r) in puffs { c.fillEllipse(cx: x + 1.5, cy: y - 2.5, rx: r * 0.3, ry: r * 0.25, light) }
        c.clearRect(0, 15, 30, 1)
        if theme.key == "meadow" || theme.key == "grove" || theme.key == "brook" {
            let colors: [UInt32] = [0xFF8DBE, 0xFFF6FA, 0xFFD45E]
            for _ in 0..<7 {
                let x = 3 + Int(rng.next() % 24), y = 4 + Int(rng.next() % 8)
                guard c.get(x, y) != nil else { continue }
                let col = colors[Int(rng.next() % 3)]
                c.tint(x, y, col); c.tint(x + 1, y, col); c.tint(x, y + 1, col); c.tint(x + 1, y + 1, PixelCanvas.mix(col, 0xD9901A, 0.4))
            }
        }
        c.outline(outlineColor(theme))
        return c
    }

    private static func rock(rng: inout SeededRNG) -> PixelCanvas {
        var c = PixelCanvas(width: 20, height: 13)
        let (light, body, shade) = (0xD9D2DE as UInt32, 0xB2A8BE as UInt32, 0x8A7F9C as UInt32)
        c.fillEllipse(cx: 10, cy: 8, rx: 9, ry: 6.5, shade)
        c.fillEllipse(cx: 9.5, cy: 7, rx: 8, ry: 5.5, body)
        c.fillEllipse(cx: 8, cy: 5, rx: 4.5, ry: 2.5, light)
        c.clearRect(0, 12, 20, 1)
        c.outline(0x5A4A66)
        return c
    }

    private static func fence() -> PixelCanvas {
        var c = PixelCanvas(width: 34, height: 18)
        let (light, body, shade) = (0xD39A62 as UInt32, 0xA86C42 as UInt32, 0x7A4A2E as UInt32)
        for px in [2, 28] {
            c.fillRect(px, 1, 4, 17, body)
            c.fillRect(px + 3, 1, 1, 17, light)
            c.fillRect(px, 1, 1, 17, shade)
            c.fillRect(px, 1, 4, 1, light)
        }
        for ry in [4, 10] {
            c.fillRect(0, ry, 34, 3, body)
            c.fillRect(0, ry, 34, 1, light)
            c.fillRect(0, ry + 2, 34, 1, shade)
        }
        c.outline(0x4B2A24)
        return c
    }

    private static func flowers(_ theme: WorldTheme, rng: inout SeededRNG) -> PixelCanvas {
        var c = PixelCanvas(width: 22, height: 14)
        let stem = theme.leaves.1
        let palette: [UInt32] = theme.key == "meadow" ? [0xFF8DBE, 0xFFF6FA, 0xFF6F9F, 0xFFD45E] : [0xFFF6FA, 0xFFD45E, 0xFF8DBE]
        for i in 0..<4 {
            let x = 3 + i * 5 + Int(rng.next() % 2), top = 2 + Int(rng.next() % 5)
            c.fillRect(x, top + 2, 1, 14 - top, stem)
            if i % 2 == 0 { c.set(x + 1, top + 6, theme.leaves.0); c.set(x + 2, top + 5, theme.leaves.0) }
            let col = palette[Int(rng.next() % UInt64(palette.count))]
            c.set(x, top, col); c.set(x - 1, top + 1, col); c.set(x + 1, top + 1, col); c.set(x, top + 2, col)
            c.set(x, top + 1, 0xFFD45E)
        }
        return c
    }
}
