import Foundation
import SpriteKit

/// Hand-drawn Alina, 24 × 33 on a true pixel grid (v3 look): big pink bow, long wavy hair, puff-sleeve dress,
/// white hem, boots. Frames share one head so they stay on model; each is a full character map.
enum AlinaArt {
    static let size = (width: 24, height: 33)

    static let colors: [Character: UInt32] = [
        "o": 0x4B1C3A, // outline
        "H": 0x5E301C, "h": 0x8B4A2B, "j": 0xB5693C, // hair shade, hair, hair shine
        "S": 0xFFD6B3, "s": 0xEDAE8A, "E": 0x2E1420, "e": 0x8A4630, "W": 0xFFFFFF, "C": 0xFF9EB0, "m": 0xB83A55,
        "K": 0xFF5BA7, "k": 0xD23A82, "L": 0xFFA6D0, // bow
        "P": 0xF75E9B, "p": 0xCC3F7A, "l": 0xFF94BE, "w": 0xFFF6F8, "c": 0xE9CBD8, "G": 0xF6C343, // dress, hem, belt
        "B": 0xA65A37, "b": 0x6E351E, "n": 0xD08454 // boots
    ]

    /// Sunbloom gilds the bow.
    static let bloomOverrides: [Character: UInt32] = ["K": 0xF6C343, "k": 0xD9901A, "L": 0xFFF0A8]

    static func palette(for sprite: PixelSprite) -> [Character: UInt32] {
        rows(for: sprite) == nil ? [:] : colors
    }

    static func rows(for sprite: PixelSprite) -> [String]? {
        switch sprite {
        case .alinaIdle: return idle
        case .alinaBlink: return blink
        case .alinaRun: return runA
        case .alinaRunB: return runB
        case .alinaJump: return jump
        case .alinaDoubleJump: return doubleJump
        case .alinaFall: return fall
        case .alinaGlide: return glide
        default: return nil
        }
    }

    private static let idle = [
        ".oo.....oo..............",
        "oLKoo.ooKLo....oooo.....",
        "oLKKKoKKKKo..oohjjhhoo..",
        "oKKKkKkKKKo.ohhhjjjhhhho",
        "okKKoKoKKkoohhhhhhjjhhho",
        ".okkohokkoohhhhhhhhhjhho",
        ".ohhhhhhhhhhhhhhhhhhhhho",
        ".ohhhjjhhhhhhHhhhhhHhhho",
        "ohhhjjhhjhhhHShhhhHSShho",
        "ohhhjhhhjhhHSSShhhSSSSho",
        "ohhjhhhhhhHSSSSHSSSSSSHo",
        "ohhjhhhhhhSEESSSSSEESSho",
        "ohhhHhhhhhSWeSSSSSWeSSho",
        "ohhhHhhhhoSeeSSSSSeeSSho",
        ".ohhHhhhhoCSSSSmmSSSCSo.",
        ".ohhHhhhhhoSSSSSSSSSSo..",
        ".ohhHhhhhhhoossSSssoo...",
        "..ohjhhHhhho.osSso......",
        "..ohhhHhhhowwwSSwwwo....",
        "..ohhhHhhoPPwwGwwPPPo...",
        "...ohjhhoPllPPPPPPpPo...",
        "...ohjhhoSollPPPPpoSo...",
        "....ohhoSSoGGGGGGGoSSo..",
        ".....oo.SoPlPPPPPpPoSo..",
        "........olPPPPPPPPPpo...",
        ".......olPPPPPPPPPPPpo..",
        ".......owwcwwcwwcwwcwo..",
        "........owowwowwowwoo...",
        ".........oSSo..oSSo.....",
        ".........owwo..owwo.....",
        "........oBnBo..oBnBo....",
        "........oBBBBo.oBBBBo...",
        "........obbbbo.obbbbo..."
    ]
    private static let blink = [
        ".oo.....oo..............",
        "oLKoo.ooKLo....oooo.....",
        "oLKKKoKKKKo..oohjjhhoo..",
        "oKKKkKkKKKo.ohhhjjjhhhho",
        "okKKoKoKKkoohhhhhhjjhhho",
        ".okkohokkoohhhhhhhhhjhho",
        ".ohhhhhhhhhhhhhhhhhhhhho",
        ".ohhhjjhhhhhhHhhhhhHhhho",
        "ohhhjjhhjhhhHShhhhHSShho",
        "ohhhjhhhjhhHSSShhhSSSSho",
        "ohhjhhhhhhHSSSSHSSSSSSHo",
        "ohhhhhhhhhSSSSSSSSSSSSho",
        "ohhhHhhhhhSEESSSSSEESSho",
        "ohhhHhhhhoSSSSSSSSSSSSho",
        ".ohhHhhhhoCSSSSmmSSSCSo.",
        ".ohhHhhhhhoSSSSSSSSSSo..",
        ".ohhHhhhhhhoossSSssoo...",
        "..ohjhhHhhho.osSso......",
        "..ohhhHhhhowwwSSwwwo....",
        "..ohhhHhhoPPwwGwwPPPo...",
        "...ohjhhoPllPPPPPPpPo...",
        "...ohjhhoSollPPPPpoSo...",
        "....ohhoSSoGGGGGGGoSSo..",
        ".....oo.SoPlPPPPPpPoSo..",
        "........olPPPPPPPPPpo...",
        ".......olPPPPPPPPPPPpo..",
        ".......owwcwwcwwcwwcwo..",
        "........owowwowwowwoo...",
        ".........oSSo..oSSo.....",
        ".........owwo..owwo.....",
        "........oBnBo..oBnBo....",
        "........oBBBBo.oBBBBo...",
        "........obbbbo.obbbbo..."
    ]
    private static let runA = [
        ".oo.....oo..............",
        "oLKoo.ooKLo....oooo.....",
        "oLKKKoKKKKo..oohjjhhoo..",
        "oKKKkKkKKKo.ohhhjjjhhhho",
        "okKKoKoKKkoohhhhhhjjhhho",
        ".okkohokkoohhhhhhhhhjhho",
        ".ohhhhhhhhhhhhhhhhhhhhho",
        ".ohhhjjhhhhhhHhhhhhHhhho",
        "ohhhjjhhjhhhHShhhhHSShho",
        "ohhhjhhhjhhHSSShhhSSSSho",
        "ohhjhhhhhhHSSSSHSSSSSSHo",
        "ohhjhhhhhhSEESSSSSEESSho",
        "ohhhHhhhhhSWeSSSSSWeSSho",
        "ohhhHhhhhoSeeSSSSSeeSSho",
        ".ohhHhhhhoCSSSSmmSSSCSo.",
        ".ohhHhhhhhoSSSSSSSSSSo..",
        ".ohhHhhhhhhoossSSssoo...",
        "..ohjhhHhhho.osSso......",
        "..ohhhHhhhowwwSSwwwo....",
        "..ohhhHhhoPPwwGwwPPPoo..",
        "...ohjhhoPllPPPPPPpPoSSo",
        "...ohjhhoSollPPPPpPooSSo",
        "....ohhoSSoGGGGGGGGo.oo.",
        ".....oooooPlPPPPPPpo....",
        "........olPPPPPPPPPpo...",
        ".......olPPPPPPPPPPPpo..",
        "......owwcwwcwwcwwcwwo..",
        ".......oowwowwowwowoo...",
        "......oSSo.....oSSo.....",
        "....ooSwo.......oSwo....",
        "..oBBnBo.........oBnBo..",
        "..obbBBo.........oBBBBo.",
        "...oooo..........obbbbo."
    ]
    private static let runB = [
        ".oo.....oo..............",
        "oLKoo.ooKLo....oooo.....",
        "oLKKKoKKKKo..oohjjhhoo..",
        "oKKKkKkKKKo.ohhhjjjhhhho",
        "okKKoKoKKkoohhhhhhjjhhho",
        ".okkohokkoohhhhhhhhhjhho",
        ".ohhhhhhhhhhhhhhhhhhhhho",
        ".ohhhjjhhhhhhHhhhhhHhhho",
        "ohhhjjhhjhhhHShhhhHSShho",
        "ohhhjhhhjhhHSSShhhSSSSho",
        "ohhjhhhhhhHSSSSHSSSSSSHo",
        "ohhjhhhhhhSEESSSSSEESSho",
        "ohhhHhhhhhSWeSSSSSWeSSho",
        "ohhhHhhhhoSeeSSSSSeeSSho",
        ".ohhHhhhhoCSSSSmmSSSCSo.",
        ".ohhHhhhhhoSSSSSSSSSSo..",
        ".ohhHhhhhhhoossSSssoo...",
        "..ohjhhHhhho.osSso......",
        "..ohhhHhhhowwwSSwwwo....",
        "..ohhhHhhoPPwwGwwPPPoo..",
        "...ohjhhoPllPPPPPPpPoSSo",
        "...ohjhhoSollPPPPpPooSSo",
        "....ohhoSSoGGGGGGGGo.oo.",
        ".....oooooPlPPPPPPpo....",
        "........olPPPPPPPPPpo...",
        ".......olPPPPPPPPPPPpo..",
        "......owwcwwcwwcwwcwwo..",
        ".......oowwowwowwowoo...",
        ".........oSSo.oSSo......",
        ".........owwo.oSwoo.....",
        "........oBnBo.oBnBBo....",
        "........oBBBBo.obbbo....",
        "........obbbbo..ooo....."
    ]
    private static let jump = [
        ".oo.....oo..............",
        "oLKoo.ooKLo....oooo.....",
        "oLKKKoKKKKo..oohjjhhoo..",
        "oKKKkKkKKKo.ohhhjjjhhhho",
        "okKKoKoKKkoohhhhhhjjhhho",
        ".okkohokkoohhhhhhhhhjhho",
        ".ohhhhhhhhhhhhhhhhhhhhho",
        ".ohhhjjhhhhhhHhhhhhHhhho",
        "ohhhjjhhjhhhHShhhhHSShho",
        "ohhhjhhhjhhHSSShhhSSSSho",
        "ohhjhhhhhhHSSSSHSSSSSSHo",
        "ohhjhhhhhhSEESSSSSEESSho",
        "ohhhHhhhhhSWeSSSSSWeSSho",
        "ohhhHhhhhoSeeSSSSSeeSSho",
        ".ohhHhhhhoCSSSSmmSSSCSo.",
        ".ohhHhhhhhoSSSSSSSSSSo..",
        ".ohhHhhhhhhoossSSssoo...",
        "..ohjhhHhhho.osSso..oSo.",
        "..ohhhHhhhowwwSSwwwooSo.",
        "..ohhhHhhoPPwwGwwPPPPSo.",
        "...ohjhhoPllPPPPPPpPPo..",
        "...ohjhhoPllPPPPPPpo....",
        "....ohhooGGGGGGGGGGo....",
        ".....ooolPlPPPPPPpPo....",
        "........olPPPPPPPPPpo...",
        ".......olPPPPPPPPPPPpo..",
        "......owwcwwcwwcwwcwwo..",
        ".......oowwowwowwowoo...",
        "........oSSo..oSSo......",
        ".......oBnBo..oSwo......",
        "......oBBBBo..oBnBo.....",
        "......obbbbo..oBBBBo....",
        ".......oooo...obbbbo...."
    ]
    private static let doubleJump = [
        ".oo.....oo..............",
        "oLKoo.ooKLo....oooo.....",
        "oLKKKoKKKKo..oohjjhhoo..",
        "oKKKkKkKKKo.ohhhjjjhhhho",
        "okKKoKoKKkoohhhhhhjjhhho",
        ".okkohokkoohhhhhhhhhjhho",
        ".ohhhhhhhhhhhhhhhhhhhhho",
        ".ohhhjjhhhhhhHhhhhhHhhho",
        "ohhhjjhhjhhhHShhhhHSShho",
        "ohhhjhhhjhhHSSShhhSSSSho",
        "ohhjhhhhhhHSSSSHSSSSSSHo",
        "ohhjhhhhhhSEESSSSSEESSho",
        "ohhhHhhhhhSWeSSSSSWeSSho",
        "ohhhHhhhhoSeeSSSSSeeSSho",
        ".ohhHhhhhoCSSSSmmSSSCSo.",
        ".ohhHhhhhhoSSSSSSSSSSo..",
        ".ohhHhhhhhhoossSSssoo...",
        "..ohjhhHhhho.osSso..oSo.",
        "..ohhhHhhhowwwSSwwwooSo.",
        "..ohhhHhhoPPwwGwwPPPPSo.",
        "...ohjhhoPllPPPPPPpPPo..",
        "...ohjhhoPllPPPPPPpo....",
        "....ohhooGGGGGGGGGGo....",
        ".....ooolPlPPPPPPpPo....",
        "........olPPPPPPPPPpo...",
        ".......olPPPPPPPPPPPpo..",
        "......owwcwwcwwcwwcwwo..",
        ".......oowwowwowwowoo...",
        ".......oSSSo.oSSSo......",
        "......oBnBSo.oBnBSo.....",
        ".....oBBBBo.oBBBBo......",
        ".....obbbbo.obbbbo......",
        "......oooo...oooo......."
    ]
    private static let fall = [
        ".oo.....oo..............",
        "oLKoo.ooKLo....oooo.....",
        "oLKKKoKKKKo..oohjjhhoo..",
        "oKKKkKkKKKo.ohhhjjjhhhho",
        "okKKoKoKKkoohhhhhhjjhhho",
        ".okkohokkoohhhhhhhhhjhho",
        ".ohhhhhhhhhhhhhhhhhhhhho",
        ".ohhhjjhhhhhhHhhhhhHhhho",
        "ohhhjjhhjhhhHShhhhHSShho",
        "ohhhjhhhjhhHSSShhhSSSSho",
        "ohhjhhhhhhHSSSSHSSSSSSHo",
        "ohhjhhhhhhSEESSSSSEESSho",
        "ohhhHhhhhhSWeSSSSSWeSSho",
        "ohhhHhhhhoSeeSSSSSeeSSho",
        ".ohhHhhhhoCSSSSmmSSSCSo.",
        ".ohhHhhhhhoSSSSSSSSSSo..",
        ".ohhHhhhhhhoossSSssoo...",
        "..ohjhhHhhho.osSso......",
        "..ohhhHhhhowwwSSwwwo....",
        "..ohhhHhhoPPwwGwwPPPoooo",
        "...ohjhhoPllPPPPPPpPSSSo",
        "...ohjhhoPllPPPPPPpoooo.",
        "....ohhooGGGGGGGGGo.....",
        ".....ooolPlPPPPPPpPo....",
        "........olPPPPPPPPPpo...",
        ".......olPPPPPPPPPPPpo..",
        "......owwcwwcwwcwwcwwo..",
        ".......oowwowwowwowoo...",
        "........oSSo.oSSo.......",
        "........owwo.owwo.......",
        ".......oBnBo.oBnBo......",
        ".......oBBBBooBBBBo.....",
        ".......obbbbo.obbbbo...."
    ]
    private static let glide = [
        ".oo.....oo..............",
        "oLKoo.ooKLo....oooo.....",
        "oLKKKoKKKKo..oohjjhhoo..",
        "oKKKkKkKKKo.ohhhjjjhhhho",
        "okKKoKoKKkoohhhhhhjjhhho",
        ".okkohokkoohhhhhhhhhjhho",
        ".ohhhhhhhhhhhhhhhhhhhhho",
        ".ohhhjjhhhhhhHhhhhhHhhho",
        "ohhhjjhhjhhhHShhhhHSShho",
        "ohhhjhhhjhhHSSShhhSSSSho",
        "ohhjhhhhhhHSSSSHSSSSSSHo",
        "ohhjhhhhhhSEESSSSSEESSho",
        "ohhhHhhhhhSWeSSSSSWeSSho",
        "ohhhHhhhhoSeeSSSSSeeSSho",
        ".ohhHhhhhoCSSSSmmSSSCSo.",
        ".ohhHhhhhhoSSSSSSSSSSo..",
        ".ohhHhhhhhhoossSSssoo...",
        "..ohjhhHhhho.osSso...oSo",
        "..ohhhHhhhowwwSSwwwooSo.",
        "..ohhhHhhoPPwwGwwPPPPo..",
        "...ohjhhoPllPPPPPPpPo...",
        "...ohjhhoPllPPPPPPpo....",
        "....ohhooGGGGGGGGGo.....",
        ".....ooolPlPPPPPPpPo....",
        "........olPPPPPPPPPpo...",
        ".......olPPPPPPPPPPPpo..",
        "......owwcwwcwwcwwcwwo..",
        ".......oowwowwowwowoo...",
        "........oSSo.oSSo.......",
        ".........oSSo.oSSo......",
        "..........oBnBooBnBo....",
        "..........oBBBBoBBBBo...",
        "..........obbbbobbbbo..."
    ]
}

/// Painted effects that go with the Alina set: the glowing glide ribbon and the double-jump sparkle puff.
enum AlinaEffects {
    static let ribbonSize = (width: 40, height: 22)
    /// The pixel of the ribbon Alina holds; it is pinned to her raised hand.
    static let ribbonHandle = CGPoint(x: 36.5, y: 19.5)

    /// One glowing ribbon held in her raised hand, billowing up over her head and trailing behind.
    static let ribbonFrames: [SKTexture] = (0..<4).map { ribbon(phase: Double($0) / 4 * 2 * .pi).texture() }

    private static func ribbon(phase: Double) -> PixelCanvas {
        var c = PixelCanvas(width: ribbonSize.width, height: ribbonSize.height)
        let (glow, body, light, edge): (UInt32, UInt32, UInt32, UInt32) = (0xFFD9EC, 0xFF6FAE, 0xFFB8D8, 0xC2337A)
        func point(_ t: Double) -> (Double, Double) {
            let p0 = (36.0, 19.0), p1 = (22.0, -5.0), p2 = (2.0, 11.0)
            let u = 1 - t
            let x = u * u * p0.0 + 2 * u * t * p1.0 + t * t * p2.0
            let y = u * u * p0.1 + 2 * u * t * p1.1 + t * t * p2.1 + sin(t * 3 * .pi + phase) * 2.2 * t
            return (x, y)
        }
        // Soft glow first, then the band, then a highlight along its upper edge.
        for i in 0...120 {
            let t = Double(i) / 120
            let (x, y) = point(t)
            let w = 1.2 + 2.2 * sin(.pi * min(1, t * 1.3))
            c.fillEllipse(cx: x, cy: y, rx: w + 1.6, ry: w + 1.6, glow)
        }
        for i in 0...120 {
            let t = Double(i) / 120
            let (x, y) = point(t)
            let w = 0.8 + 2 * sin(.pi * min(1, t * 1.3))
            c.fillEllipse(cx: x, cy: y, rx: w, ry: w, body)
        }
        for i in 0...120 {
            let t = Double(i) / 120
            let (x, y) = point(t)
            let w = 0.8 + 2 * sin(.pi * min(1, t * 1.3))
            c.set(Int(x), Int(y - w + 0.6), light)
            if Int(y + w - 0.4) != Int(y - w + 0.6) { c.set(Int(x), Int(y + w - 0.4), edge) }
        }
        // Twinkles that move with the phase.
        var rng = SeededRNG(seed: UInt64(phase * 100) + 5)
        for _ in 0..<4 {
            let (x, y) = point(Double(rng.next() % 100) / 100)
            let sx = Int(x) + Int(rng.next() % 5) - 2, sy = Int(y) - 4 - Int(rng.next() % 3)
            c.set(sx, sy, 0xFFFFFF); c.set(sx - 1, sy, glow); c.set(sx + 1, sy, glow); c.set(sx, sy - 1, glow); c.set(sx, sy + 1, glow)
        }
        return c
    }

    /// Pink cloud puff with sparkles left under Alina's boots by the double jump.
    static let sparklePuff: SKTexture = {
        var c = PixelCanvas(width: 26, height: 14)
        let (shade, body, light): (UInt32, UInt32, UInt32) = (0xF07FB4, 0xFFB3D6, 0xFFE6F1)
        let puffs: [(Double, Double, Double)] = [(7, 9, 4.5), (13, 8, 5.5), (19, 9, 4.5)]
        for (x, y, r) in puffs { c.fillEllipse(cx: x, cy: y + 1, rx: r, ry: r * 0.8, shade) }
        for (x, y, r) in puffs { c.fillEllipse(cx: x - 0.5, cy: y, rx: r - 0.8, ry: r * 0.7, body) }
        for (x, y, r) in puffs { c.fillEllipse(cx: x - 1.5, cy: y - 1.5, rx: r * 0.4, ry: r * 0.3, light) }
        for (sx, sy) in [(3, 2), (23, 3), (13, 1)] {
            c.set(sx, sy, 0xFFFFFF); c.set(sx - 1, sy, 0xFFE98A); c.set(sx + 1, sy, 0xFFE98A); c.set(sx, sy - 1, 0xFFE98A); c.set(sx, sy + 1, 0xFFE98A)
        }
        return c.texture()
    }()
}
