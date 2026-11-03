import CoreGraphics
import Foundation

/// The illustrated Lumen Isles: one pixel island per world, each with a landmark showing what's there,
/// joined by a stepping-stone trail that turns gold as worlds are cleared. Drawn in an 900 × 620 design space.
enum MapArt {
    static let size = CGSize(width: 900, height: 620)

    struct Island {
        let key: String
        let top: UInt32
        let cliff: UInt32
        let center: CGPoint
        let radius: CGSize
        var floating: Bool { key == "starfall" }
    }

    static let islands: [Island] = [
        Island(key: "meadow", top: 0x7FD06B, cliff: 0xB98A55, center: CGPoint(x: 105, y: 530), radius: CGSize(width: 84, height: 34)),
        Island(key: "brook", top: 0x6CCB84, cliff: 0xA08A6A, center: CGPoint(x: 270, y: 455), radius: CGSize(width: 80, height: 32)),
        Island(key: "grove", top: 0x4FAE5A, cliff: 0x8E6440, center: CGPoint(x: 440, y: 535), radius: CGSize(width: 84, height: 34)),
        Island(key: "cavern", top: 0xE3AE88, cliff: 0x9C5B3B, center: CGPoint(x: 610, y: 470), radius: CGSize(width: 82, height: 32)),
        Island(key: "ridge", top: 0xD9C08A, cliff: 0x956643, center: CGPoint(x: 790, y: 525), radius: CGSize(width: 84, height: 34)),
        Island(key: "marsh", top: 0x8CC79A, cliff: 0x6E6754, center: CGPoint(x: 805, y: 345), radius: CGSize(width: 80, height: 32)),
        Island(key: "spire", top: 0xB9A6EC, cliff: 0x7C6B98, center: CGPoint(x: 625, y: 300), radius: CGSize(width: 82, height: 34)),
        Island(key: "storm", top: 0x9DB2CC, cliff: 0x646A7C, center: CGPoint(x: 440, y: 345), radius: CGSize(width: 80, height: 32)),
        Island(key: "throne", top: 0xE8A6C8, cliff: 0x5E4660, center: CGPoint(x: 255, y: 290), radius: CGSize(width: 84, height: 34)),
        Island(key: "frost", top: 0xE8F4FF, cliff: 0x8FA0C0, center: CGPoint(x: 100, y: 150), radius: CGSize(width: 80, height: 32)),
        Island(key: "coral", top: 0xF2E3C0, cliff: 0xD9A86C, center: CGPoint(x: 340, y: 125), radius: CGSize(width: 82, height: 32)),
        Island(key: "starfall", top: 0xFFF6DE, cliff: 0xC3B1F0, center: CGPoint(x: 620, y: 105), radius: CGSize(width: 84, height: 30))
    ]

    private static let palette: [Character: UInt32] = [
        "o": 0x3A2230, "g": 0x76CF63, "i": 0xA6E37E, "x": 0x3E9147, "v": 0x55B85C, "V": 0x2F8A45,
        "t": 0x6B4A30, "T": 0x8B6542, "F": 0xFF8DBE, "Y": 0xF6C343, "y": 0xFFE98A, "O": 0xFFFFFF, "w": 0x5FB4EE,
        "c": 0xDCEEFF, "r": 0x8A8F9C, "R": 0x5E6270, "e": 0xFFB347, "E": 0xE0662E, "k": 0x2A2238,
        "q": 0xC9845A, "Q": 0x9C5B3B, "z": 0xE8B98C, "m": 0x79B87A, "M": 0x4A855A, "n": 0xB9D9C9,
        "p": 0xC3B1F0, "P": 0x8E72D6, "L": 0x5E47A6, "l": 0xECE6FB, "s": 0x7F8AA6, "S": 0x4C5672,
        "h": 0xE8A6C8, "H": 0xC77AA5, "K": 0x8E4C79, "a": 0xE8F4FF, "A": 0xA9C9E8, "b": 0x7FA7CF,
        "f": 0xFF7E6B, "j": 0xFFB0A0, "u": 0xF2E3C0, "U": 0xD9C29A, "d": 0x2F7F8F
    ]

    /// What each world is about, drawn on its island.
    static let landmarks: [String: [String]] = [
        "meadow": [
            "........VVV...........", ".......VvivV..........", "......VvvvvvV.........", "......VvvvvVV.........",
            ".......VVtVV..........", ".F.......t.......F.F..", "FYF......t......FYFYF.", ".x...F...t...F...x.x..",
            ".x..FYF..t..FYF..x.x.."
        ],
        "brook": [
            ".....rrrrrr.........", "....rRrrrrRr........", "...rRrwwwrrRr.......", "...rRrwOwrrRr.......",
            "...RRrwwwrRRR.......", "......wOw.....VV....", "......www....VvvV...", ".....wwOww...VvvV...",
            "....TTTTTTT...Vt....", "....T.www.T....t...."
        ],
        "grove": [
            "..VV.......VVV.......", ".VvvV.....VvivV..VV..", "VvivvV...VvvvvvVVvvV.", "VvvvvV..VvvvvvvvVvivV",
            ".VvvV...VvvvvvvV.VvV.", "..tt.....VVvvVV...t..", "..tt.......tt.....t..", "..tt..y....tt..y..t.."
        ],
        "cavern": [
            ".....e..........e.....", "........qqqqqq........", "......qqzzzzzqqq..e...", "....qqzzqqqqqzzqq.....",
            "...qzzqqkkkkkqqzqq....", "..qqzqqkkkkkkkqqzqq...", ".qqqqqkkkEkkkkkqqqqq..", "QQQQQQkkEeEkkkkQQQQQQ."
        ],
        "ridge": [
            "..........QQQQ........", ".........QzzzzQ.......", "....QQQ..QzqqzQQQ.....", "...QzzzQQzqqqqzzzQ....",
            "..QzqqqzzqqqqqqqqzQ...", "..QqqqqqqqqqqqqqqqqQ..", ".QQqqQqqqqqQqqqqQqqQQ."
        ],
        "marsh": [
            ".n.nnnn....nnnnn.n....", "......................", "..M......M.....M..M...", ".MmM..M..mM...MmM.M...",
            ".MmM.MmM.mM.M.MmM.mM..", "..m..MmM..m.Mm.m..m...", "dddmddmddddmdmddmddmdd", ".dddddddddddddddddddd."
        ],
        "spire": [
            ".........l............", "........lp............", "........pP....l.......", "...l...lpP....pP......",
            "...pP..ppPP..lpP......", "..lpP..ppPP..ppPP..lP.", "..ppPP.ppPPL.ppPP..pP.", ".LppPPLppPPLLppPPLLpPL"
        ],
        "storm": [
            "....sssss.sss.........", "..ssSSSSSsSSSss.......", ".sSSSSSSSSSSSSSs......", ".SSSSSSYSSSSSSSS......",
            "..b..b.YY.b..b........", ".b..b..Y.b..b.........", "..TTTTTTTTTTTTTTT.....", "..T...T...T...T.T....."
        ],
        "throne": [
            "..........Y...........", ".........YYY..........", "....h.....H.....h.....", "...hHh...hHh...hHh....",
            "...HHH..hhhhh..HHH....", "...HKH.hhKKKhh.HKH....", "...HHHhhhhhhhhhHHH....", "...HHHhhhKKKhhhHHH....",
            "...HHHhhhKkKhhhHHH...."
        ],
        "frost": [
            "..........aa..........", ".........aaaa.........", "........aaAaaa........", ".......aaAAbaaa.......",
            "......AaAAbbbAaa......", ".....AAAAbbbbbAAa.....", "....AAAbbbbbbbbAAA....", "...AAbbbbbbbbbbbbAA..."
        ],
        "coral": [
            ".......V..............", "......VvV...V.........", ".....V.t.V.VvV........", ".......t....t...f..j..",
            ".......t....t..fjf.fj.", "...f...t....t...f..j..", "..fjf..uuuuuuu..f..j..", ".uuuuuuuUUUUUuuuuuuu.."
        ],
        "starfall": [
            "....y...........y.....", "...yYy.....Y........y.", "....y.....YYY.........", ".........YYOYY....y...",
            ".y.........YYY........", "...........Y..........", "....OOOOOOOOOOOOOO....", "..OOcOOOOcOOOOOcOOOO.."
        ]
    ]

    private static let cloud = [
        "....OOOO........", "..OOOOOOOO.OOO..", ".OOOOOOOOOOOOOO.", "OOOOOOOOOOOOOOOO", "OccOOOOOOcOOOccO", ".cccccccccccccc."
    ]

    private static var cache: [String: CGImage] = [:]

    /// The whole map at `scale` pixels per design point; `cleared` worlds get a gold trail, worlds past
    /// `unlocked` are faded with a wisp of fog, and `current` glows.
    static func image(cleared: Int, unlocked: Int, current: Int, scale: Int = 2) -> CGImage {
        let key = "\(cleared)|\(unlocked)|\(current)|\(scale)"
        if let cached = cache[key] { return cached }
        let context = CGContext(
            data: nil, width: Int(size.width) * scale, height: Int(size.height) * scale, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        // Draw top-down like the design space.
        context.translateBy(x: 0, y: size.height * CGFloat(scale))
        context.scaleBy(x: CGFloat(scale), y: -CGFloat(scale))
        let painter = Painter(context: context)

        painter.rect(0, 0, size.width, size.height, 0x8ED2F2)
        painter.rect(0, 0, size.width, 250, 0x84CBEE)
        var rng = SeededRNG(seed: 3)
        for _ in 0..<70 {
            let x = CGFloat(rng.next() % 225) * 4
            let y = CGFloat(rng.next() % 155) * 4
            painter.rect(x, y, CGFloat([8, 12, 16][Int(rng.next() % 3)]), 4, 0xFFFFFF, alpha: 0.35)
        }
        for (x, y) in [(560.0, 230.0), (20, 330), (800, 40)] { painter.sprite(cloud, x: x, y: y, unit: 3, alpha: 0.65) }

        painter.trail(islands.map { CGPoint(x: $0.center.x, y: $0.center.y + 4) }, golden: cleared)

        for (index, island) in islands.enumerated() {
            if index == current {
                painter.ellipse(island.center.x, island.center.y + 6, island.radius.width + 24, island.radius.height + 16, 0xFFE98A, alpha: 0.55)
            }
            painter.faded = index >= unlocked
            painter.island(island)
            painter.faded = false
            if index >= unlocked {
                painter.sprite(cloud, x: island.center.x - island.radius.width - 6, y: island.center.y + 4, unit: 3, alpha: 0.92)
            }
        }
        let image = context.makeImage()!
        cache[key] = image
        return image
    }

    private final class Painter {
        let context: CGContext
        var faded = false

        init(context: CGContext) { self.context = context }

        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ hex: UInt32, alpha: CGFloat = 1) {
            var color = hex
            if faded {
                // Locked worlds: mostly grey, a little lighter, so the landmark still reads.
                let r = Double((hex >> 16) & 0xFF), g = Double((hex >> 8) & 0xFF), b = Double(hex & 0xFF)
                let grey = 0.3 * r + 0.59 * g + 0.11 * b
                func mix(_ c: Double) -> UInt32 { UInt32(min(255, (c * 0.3 + grey * 0.7) * 1.05 + 10)) }
                color = mix(r) << 16 | mix(g) << 8 | mix(b)
            }
            context.setFillColor(CGColor(
                srgbRed: CGFloat((color >> 16) & 0xFF) / 255, green: CGFloat((color >> 8) & 0xFF) / 255,
                blue: CGFloat(color & 0xFF) / 255, alpha: alpha
            ))
            context.fill(CGRect(x: x, y: y, width: w, height: h))
        }

        func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rw: CGFloat, _ rh: CGFloat, _ hex: UInt32, alpha: CGFloat = 1, unit: CGFloat = 4) {
            var dy = -(rh / unit).rounded(.down) * unit
            while dy <= rh {
                let t = 1 - (dy / rh) * (dy / rh)
                if t > 0 {
                    let half = (rw * sqrt(t) / unit).rounded() * unit
                    rect(cx - half, cy + dy, 2 * half, unit, hex, alpha: alpha)
                }
                dy += unit
            }
        }

        func sprite(_ rows: [String], x: CGFloat, y: CGFloat, unit: CGFloat, alpha: CGFloat = 1) {
            for (r, row) in rows.enumerated() {
                for (c, ch) in row.enumerated() {
                    guard let hex = MapArt.palette[ch] else { continue }
                    rect(x + CGFloat(c) * unit, y + CGFloat(r) * unit, unit, unit, hex, alpha: alpha)
                }
            }
        }

        func island(_ island: Island) {
            let (cx, cy) = (island.center.x, island.center.y)
            let (rw, rh) = (island.radius.width, island.radius.height)
            if island.floating {
                ellipse(cx, cy + 58, rw - 14, 8, 0x2B2148, alpha: 0.12)
                ellipse(cx, cy + 22, rw - 8, rh, 0xC3B1F0)
                ellipse(cx, cy + 14, rw, rh, 0xFFFFFF)
            } else {
                ellipse(cx, cy + 16, rw + 14, rh + 10, 0xFFFFFF, alpha: 0.5)
                ellipse(cx, cy + 18, rw, rh, 0x2B2148, alpha: 0.25)
                ellipse(cx, cy + 14, rw, rh, island.cliff)
                ellipse(cx, cy, rw + 4, rh + 2, 0xF6E3B4)
            }
            ellipse(cx, cy - 2, rw, rh, island.top)
            ellipse(cx - rw / 5, cy - rh / 2, rw / 2, rh / 3, 0xFFFFFF, alpha: 0.18)
            if let rows = MapArt.landmarks[island.key] {
                let unit: CGFloat = 6
                let width = CGFloat(rows.map(\.count).max() ?? 0) * unit
                sprite(rows, x: cx - width / 2, y: cy + 8 - CGFloat(rows.count) * unit, unit: unit)
            }
        }

        /// Square stepping stones between islands; the first `golden` legs are gold.
        func trail(_ points: [CGPoint], golden: Int) {
            for (leg, (a, b)) in zip(points, points.dropFirst()).enumerated() {
                let steps = Int(hypot(b.x - a.x, b.y - a.y) / 20)
                guard steps > 1 else { continue }
                for s in 1..<steps {
                    let t = CGFloat(s) / CGFloat(steps)
                    let x = ((a.x + (b.x - a.x) * t) / 2).rounded() * 2
                    let y = ((a.y + (b.y - a.y) * t) / 2).rounded() * 2
                    let done = leg < golden
                    rect(x - 4, y - 2, 8, 8, done ? 0xD9901A : 0xCDB98E)
                    rect(x - 4, y - 4, 8, 6, done ? 0xF6C343 : 0xF6E3B4)
                }
            }
        }
    }
}
