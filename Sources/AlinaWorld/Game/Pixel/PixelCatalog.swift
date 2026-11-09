import Foundation

enum PixelSprite: String, CaseIterable {
    case alinaIdle, alinaBlink, alinaRun, alinaRunB, alinaJump, alinaDoubleJump, alinaFall, alinaGlide
    case gloomling, gloomlingStep, thornbeetle, mothwisp, mothwispFlap, guardian
    case petal, petalTurn, crystal, sunbloom, ribbon, heart, heartEmpty, clock
    case bloomBlock, bloomBlockUsed, mossbrick, groundTop, groundFill, stone, stoneTop, log, thorns, leafPad, cloudPad, beacon
    case leafPadLeft, leafPadRight, leafPadSingle
    case sun, cloud, tree, bush, flower, hillFar, hillNear
    case frostpuff, shellcrab, starwisp, springShell
}

/// Every sprite in the game as a character map. `.` is transparent; letters index `basePalette`,
/// and the lowercase world letters (i g x u s v V k b j) are recolored per `WorldTheme`.
enum PixelCatalog {
    static let basePalette: [Character: UInt32] = [
        "o": 0x3A2230, // outline
        "H": 0x6A3A22, "h": 0x9A5E36, // hair
        "S": 0xF7CDA8, "E": 0x2B1810, "C": 0xF59AA6, "m": 0xC2455E, // skin, eyes, cheeks, mouth
        "P": 0xEE5C95, "D": 0xC13B73, "W": 0xFFF6FA, "B": 0x7A4428, "K": 0xFF7AB6, // dress, trim, boots, bow
        "G": 0xF6C343, "Q": 0xD9901A, "O": 0xFFFFFF, "Y": 0xFFE98A, "A": 0xFFB347, // gold, light
        "N": 0x3B3070, "n": 0x5E52A0, "L": 0x1A1330, // gloom
        "R": 0x8A4433, "r": 0xB9634A, "T": 0xF2E3C0, // beetle, thorns
        "M": 0x9B7BEA, "l": 0xC3A8FF, "F": 0xFF8DBE, "c": 0xDCEEFF, // moth, petal, cloud shade
        "a": 0xE6E0D4, "e": 0xC7BDAD, "d": 0x938674, // stone
        "q": 0xE09466, "w": 0xB0643F, "z": 0xF4DDBE, "t": 0x6B4A30, // brick, mortar, wood
        "i": 0xA6E37E, "g": 0x76CF63, "x": 0x3E9147, "u": 0xD9A86C, "s": 0xA98563,
        "v": 0x55B85C, "V": 0x2F8A45, "k": 0xBDE6D2, "b": 0x9CD4BD, "j": 0x86C2AA,
        "f": 0xFF7E6B, "p": 0xFFC0B0, "U": 0xA9C9E8, "J": 0x3E7FC4 // coral, coral light, ice, ice shadow
    ]

    /// Colours that belong to one sprite only (HUD icons, the hand-drawn Alina set).
    static func spritePalette(for sprite: PixelSprite) -> [Character: UInt32] {
        switch sprite {
        case .heart: return ["o": 0x4B1C3A, "P": 0xF2405F, "L": 0xFF8EA2, "W": 0xFFFFFF, "D": 0xC0244A]
        case .heartEmpty: return ["o": 0x4B1C3A, "P": 0xE3D2DA, "L": 0xF3EAEE, "W": 0xFFFFFF, "D": 0xC6B0BC]
        case .petal, .petalTurn: return ["o": 0x8E2D5E, "F": 0xFF9CC4, "W": 0xFFE2EE, "K": 0xE2609A]
        case .clock: return ["o": 0x4B1C3A, "G": 0xF6C343, "Q": 0xD9901A, "W": 0xFFF8EC, "d": 0x4B1C3A]
        default: return AlinaArt.palette(for: sprite)
        }
    }

    static func rows(for sprite: PixelSprite) -> [String] {
        switch sprite {
        case .alinaIdle, .alinaBlink, .alinaRun, .alinaRunB, .alinaJump, .alinaDoubleJump, .alinaFall, .alinaGlide:
            return AlinaArt.rows(for: sprite) ?? []
        case .gloomling: return gloomling
        case .gloomlingStep: return Array(gloomling.dropLast(2)) + [".NN.NNNN.NN.", "N...N..N...N"]
        case .thornbeetle: return thornbeetle
        case .mothwisp: return mothwisp
        case .mothwispFlap: return mothwispFlap
        case .guardian: return guardian
        case .petal: return petal
        case .petalTurn: return petalTurn
        case .crystal: return crystal
        case .sunbloom: return sunbloom
        case .ribbon: return ribbon
        case .heart: return heart
        case .heartEmpty: return heart
        case .clock: return clock
        case .bloomBlock: return bloomBlock
        case .bloomBlockUsed: return bloomBlockUsed
        case .mossbrick: return mossbrick
        case .groundTop: return TileArt.groundTop
        case .groundFill: return TileArt.groundFill
        case .stone: return TileArt.rockBlock(cap: false)
        case .stoneTop: return TileArt.rockBlock(cap: true)
        case .leafPadLeft: return TileArt.leafPad(left: true, right: false)
        case .leafPadRight: return TileArt.leafPad(left: false, right: true)
        case .leafPadSingle: return TileArt.leafPad(left: true, right: true)
        case .log: return log
        case .thorns: return thorns
        case .leafPad: return TileArt.leafPad(left: false, right: false)
        case .cloudPad: return cloudPad
        case .beacon: return TileArt.beacon
        case .sun: return sun
        case .cloud: return cloud
        case .tree: return tree
        case .bush: return bush
        case .flower: return flower
        case .hillFar: return hillFar
        case .frostpuff: return frostpuff
        case .shellcrab: return shellcrab
        case .starwisp: return starwisp
        case .springShell: return springShell
        case .hillNear:
            return hillFar.map { row in
                String(row.map { ch in ch == "b" ? "g" : ch == "k" ? "i" : ch == "j" ? "x" : ch })
            }
        }
    }

    // MARK: Night Crown minions

    private static let gloomling = [
        "....nnnn....", "..nnNNNNnn..", ".nNNNNNNNNn.", ".NNYYNNYYNN.", ".NNYLNNYLNN.",
        "NNNNNNNNNNNN", "NNNNLLLLNNNN", "NNNNNNNNNNNN", ".NNN.NN.NNN.", "..N..NN..N.."
    ]
    private static let thornbeetle = [
        "...T...T....", "..TRRTRRTR..", ".RRRRRRRRRR.", "RRrrRRRRrrRR",
        "RRRRRRRRRRRR", "YLRrrRRrrRRR", "LLLLLLLLLLLL", ".L.L..L..L.."
    ]
    private static let mothwisp = [
        "MM........MM", "MlM......MlM", "MllM.nn.MllM", "MllMnYYnMllM",
        ".MMMnnnnMMM.", "..MMnnnnMM..", ".MlM.nn.MlM.", ".MM......MM."
    ]
    private static let mothwispFlap = [
        "............", "MM...nn...MM", "MlMMnYYnMMlM", "MllMnnnnMllM",
        ".MlMnnnnMlM.", "..MM.nn.MM..", "............", "............"
    ]
    private static let guardian = [
        "...G..G..G..G...",
        "...GGGGGGGGGG...",
        "...GQGGQGGQGG...",
        "..nnnnnnnnnnnn..",
        ".nNNNNNNNNNNNNn.",
        "nNNNNNNNNNNNNNNn",
        "NNNYYYNNNNYYYNNN",
        "NNNYLYNNNNYLYNNN",
        "NNNNNNNNNNNNNNNN",
        "NNNNNLLLLLLNNNNN",
        "NNNNNNLTTLNNNNNN",
        "NNNNNNNNNNNNNNNN",
        ".NNNN.NNNN.NNNN.",
        "..NN...NN...NN.."
    ]

    // Act IV minions: Frostpeak, Coral Lagoon and Starfall variants of the crawler and flyer.

    private static let frostpuff = [
        "....UUUU....", "..UUOOOOUU..", ".UOOOOOOOOU.", ".UOOJOOJOOU.", ".UOOJOOJOOU.",
        "UOOOOOOOOOOU", "UOOOOUUOOOOU", "UOOOOOOOOOOU", ".UUU.UU.UUU.", "..U..UU..U.."
    ]
    private static let shellcrab = [
        ".f........f.", "fpf......fpf", ".f..ffff..f.", "...fppppf...", "..ffLffLff..",
        ".ffppppppff.", "ffppppppppff", ".ffffffffff.", ".f.f....f.f.", "f..f....f..f"
    ]
    private static let starwisp = [
        ".....G......", "....GYG.....", "GGGGGYGGGGG.", ".GYYLYLYYG..", "..GYYYYYG...",
        ".GYYG.GYYG..", ".GG.....GG..", "............"
    ]
    /// Coral Lagoon spring: landing on it bounces Alina high.
    private static let springShell = [
        "................",
        "................",
        "......ffff......",
        "....ffppppff....",
        "...fpfpffpfpf...",
        "..fppfppppfppf..",
        "..fpfppffppfpf..",
        ".fppfppffppfppf.",
        ".fpfppfffppfpff.",
        ".fppfppffppfppf.",
        "fppfppfppfppfppf",
        "ffffffffffffffff",
        "..uuuuuuuuuuuu..",
        ".uuuuuuuuuuuuuu.",
        "uuuuuuuuuuuuuuuu",
        "uuuusuuuuuusuuuu"
    ]

    // MARK: Items

    private static let petal = [
        "....oooo..",
        "...oWWFFo.",
        "..oWWFFFFo",
        "..oWFFFFFo",
        ".oWFFFFFKo",
        ".oFFFFFFKo",
        "oFFFFFFKo.",
        "oFFFFFKKo.",
        "oFFFFKKo..",
        "oFFKKKo...",
        ".oKKoo....",
        "..oo......"
    ]
    private static let petalTurn = petal.map { row in
        let chars = Array(row)
        return String([0, 2, 4, 5, 7, 9].map { chars[$0] })
    }
    private static let clock = [
        ".oo......oo.",
        "oGGo.oo.oGGo",
        "oGooQGGQooGo",
        ".ooQGWWGQoo.",
        ".oQWWWdWWQo.",
        "oQWWWWdWWWQo",
        "oQWWWWddWWQo",
        "oQWWWWWWWWQo",
        ".oQWWWWWWQo.",
        ".ooQGWWGQoo.",
        ".o.oQQQQo.o.",
        "o...oooo...o"
    ]
    private static let crystal = [
        "..GG..GG..", ".GOGGGGQG.", "GOGGGGGGQG", "GGGGGGGGQG", "GGGGGGGGQG",
        ".GGGGGGQG.", "..GGGGQG..", "...GGQG...", "....GG...."
    ]
    private static let sunbloom = [
        "...YYYY...", "..YGGGGY..", ".YGQQQQGY.", ".YGQQQQGY.", "..YGGGGY..",
        "...YYYY...", "....xx....", "..g.xx.g..", "..ggxxgg..", "....xx...."
    ]
    private static let ribbon = ["KK......KK", "KPK....KPK", "KPPKKKKPPK", "KPPPKKPPPK", "KPPKKKKPPK", "KPK.KK.KPK", "KK..KK..KK", "....K.K..."]
    private static let heart = [
        "..ooo...ooo..",
        ".oWLPo.oLPPo.",
        "oWLPPPoPPPPDo",
        "oLPPPPPPPPPDo",
        "oPPPPPPPPPPDo",
        "oPPPPPPPPPDDo",
        ".oPPPPPPPDDo.",
        "..oPPPPPDDo..",
        "...oPPPDDo...",
        "....oPDDo....",
        ".....oDo.....",
        "......o......"
    ]

    // MARK: Tiles (16 × 16)

    private static let bloomBlock = [
        "QQQQQQQQQQQQQQQQ",
        "QOOGGGGGGGGGGGGQ",
        "QOGGGGGFFGGGGGGQ",
        "QGGGGGFFFFGGGGGQ",
        "QGGGGFFGGFFGGGGQ",
        "QGGGFFGYYGFFGGGQ",
        "QGGFFGYYYYGFFGGQ",
        "QGGFFGYYYYGFFGGQ",
        "QGGGFFGYYGFFGGGQ",
        "QGGGGFFGGFFGGGGQ",
        "QGGGGGFFFFGGGGGQ",
        "QGGGGGGFFGGGGGGQ",
        "QGGGGGGGGGGGGGGQ",
        "QGGGGGGGGGGGGGAQ",
        "QGGGGGGGGGGGGAAQ",
        "QQQQQQQQQQQQQQQQ"
    ]
    private static let bloomBlockUsed = [
        "dddddddddddddddd",
        "deeeeeeeeeeeeeed",
        "deaeeeeeeeeeeaed",
        "deeeeeeeeeeeeeed",
        "deeeeeeeeeeeeeed",
        "deeeeeeeeeeeeeed",
        "deeeeeeeeeeeeeed",
        "deeeeeeeeeeeeeed",
        "deeeeeeeeeeeeeed",
        "deeeeeeeeeeeeeed",
        "deeeeeeeeeeeeeed",
        "deeeeeeeeeeeeeed",
        "deeeeeeeeeeeeeed",
        "deaeeeeeeeeeeaed",
        "deeeeeeeeeeeeeed",
        "dddddddddddddddd"
    ]
    private static let mossbrick = [
        "iigiiigiiigiiigi",
        "gxggxggxggxgxggx",
        "qqqqqqqzqqqqqqqz",
        "qqqqqqqzqqqqqqqz",
        "wwwwwwwzwwwwwwwz",
        "zzzzzzzzzzzzzzzz",
        "qqqzqqqqqqqzqqqq",
        "qqqzqqqqqqqzqqqq",
        "wwwzwwwwwwwzwwww",
        "zzzzzzzzzzzzzzzz",
        "qqqqqqqzqqqqqqqz",
        "qqqqqqqzqqqqqqqz",
        "wwwwwwwzwwwwwwwz",
        "zzzzzzzzzzzzzzzz",
        "qqqzqqqqqqqzqqqq",
        "wwwzwwwwwwwzwwww"
    ]
    private static let groundTop = [
        "iigiiigiiigiiigi",
        "gggggggggggggggg",
        "ggxgggggxgggggxg",
        "xxgxxxgxxxgxxxgx",
        "uxuuuxuuuuxuuuxu",
        "uuuuuuuuuuuuuuuu",
        "uusuuuuuuuuusuuu",
        "uuuuuuusuuuuuuuu",
        "uuuuuuuuuuuuuuuu",
        "usuuuuuuuuuusuuu",
        "uuuuuusuuuuuuuuu",
        "uuuuuuuuuuuuuuuu",
        "uuuusuuuuuuuusuu",
        "uuuuuuuuuuuuuuuu",
        "uuuuuuuuusuuuuuu",
        "suuuuuuuuuuuuuuu"
    ]
    private static let stone = [
        "aaaaaaaaaaaaaaae",
        "aeeeeeeeeeeeeeed",
        "aeeeeeeeeeeeeeed",
        "aeeeeeeeeddeeeed",
        "aeeeeeeeeedeeeed",
        "aeeeeeeeeeeeeeed",
        "aeedeeeeeeeeeeed",
        "aeeddeeeeeeeeeed",
        "aeeeeeeeeeeeeeed",
        "aeeeeeeeeeeeeeed",
        "aeeeeeeeeeedeeed",
        "aeeeeeeeeeeddeed",
        "aeeeeeeeeeeeeeed",
        "aeeeeeeeeeeeeeed",
        "aeeeeeeeeeeeeeed",
        "eddddddddddddddd"
    ]
    /// Upright log: dark rim, bark grooves, light down the sunlit right side.
    private static let log: [String] = (0..<16).map { y in
        String((0..<16).map { x -> Character in
            if x == 0 || x == 15 { return "o" }
            if x == 1 { return "t" }
            if x >= 12 && x <= 13 { return (x + y) % 6 == 0 ? "B" : "q" }
            if x == 14 { return "B" }
            let groove = [3, 6, 10][(y / 5) % 3]
            if x == groove || (x == groove + 1 && y % 4 == 1) { return "t" }
            return (x * 3 + y * 7) % 13 == 0 ? "h" : "B"
        })
    }
    private static let thorns = [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "...T.......T....",
        "...T.......T....",
        "..TTT.....TTT...",
        "..TrT.....TrT...",
        ".TTrTT...TTrTT..",
        ".TrrrT...TrrrT..",
        "TTrrrTT.TTrrrTT.",
        "RRRRRRRRRRRRRRRR",
        "RrRRrRRrRRrRRrRR",
        "RRRRRRRRRRRRRRRR"
    ]
    private static let leafPad = [
        "vvvvvvvvvvvvvvvv",
        "iivviiivviiivvii",
        "vvvvvvvvvvvvvvvv",
        "VvvVvvvVvvvVvvvV",
        "VVVVVVVVVVVVVVVV",
        "..t.........t..."
    ]
    private static let cloudPad = [
        "..OOOOOO....OOOOOOO....OOOOOO...",
        ".OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.",
        "OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",
        "OcOOOcOOOOcOOOOcOOOOcOOOOOcOOOcO",
        ".cccccccccccccccccccccccccccccc."
    ]
    private static let beacon = [
        "..QQQQ..", ".QYYYYQ.", ".QYOYYQ.", ".QYYYYQ.", "..QQQQ..", "...tt...", "...tt...", "...tt...",
        "...tt...", "...tt...", "...tt...", "...tt...", "...tt...", "...tt...", "..tttt..", ".tttttt."
    ]

    // MARK: Scenery

    private static let sun = [
        "....A..A....", "..A......A..", "....GGGG....", "A..GYYYYG..A", "..GYOYYYYG..", "..GYYYYYYG..",
        "..GYYYYYYG..", "..GYYYYYYG..", "A..GYYYYG..A", "....GGGG....", "..A......A..", "....A..A...."
    ]
    private static let cloud = [
        "....OOOO........", "..OOOOOOOO.OOO..", ".OOOOOOOOOOOOOO.",
        "OOOOOOOOOOOOOOOO", "OccOOOOOOcOOOccO", ".cccccccccccccc."
    ]
    private static let tree = [
        ".....VVVV.....", "...VVvvvvVV...", "..VvviivvvVV..", ".VvviivvvvvVV.", ".VviivvvvvvVV.",
        "VvvvvvvvvvvvVV", "VvvvvvvvvvVVVV", "VvvvvvVvvvvVVV", ".VVvvVVVvvVVV.", "..VVVVtVVVVV..",
        "....VVttVV....", "......tt......", "......tt......", "......tt......", ".....tttt....."
    ]
    private static let bush = ["...VVVV.VV..", ".VVvvvvVvvV.", "VvviivvvvivV", "VvvvvvvvvvvV", ".VVVVVVVVVV."]
    private static let flower = [".F.F.", "FFGFF", ".FFF.", "..x..", ".xx..", "..x.."]
    private static let hillFar = [
        "........kkkkkkkk........",
        ".....kkkbbbbbbbbkkk.....",
        "...kkbbbbbbbbbbbbbbkk...",
        "..kbbbbbbjbbbbbbbbbbbk..",
        ".kbbbbbbbbbbbbbjbbbbbbk.",
        "kbbbbjbbbbbbbbbbbbbbbbbk",
        "bbbbbbbbbbbbbjbbbbbbbbbb",
        "bbbbbbbbbbbbbbbbbbbbbbbb"
    ]
}
