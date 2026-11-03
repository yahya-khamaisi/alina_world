import Foundation

enum PixelSprite: String, CaseIterable {
    case alinaIdle, alinaBlink, alinaRun, alinaJump, alinaFall
    case gloomling, gloomlingStep, thornbeetle, mothwisp, mothwispFlap, guardian
    case petal, petalTurn, crystal, sunbloom, ribbon, heart, heartEmpty
    case bloomBlock, bloomBlockUsed, mossbrick, groundTop, groundFill, stone, log, thorns, leafPad, cloudPad, beacon
    case sun, cloud, tree, bush, flower, hillFar, hillNear
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
        "v": 0x55B85C, "V": 0x2F8A45, "k": 0xBDE6D2, "b": 0x9CD4BD, "j": 0x86C2AA
    ]

    static func rows(for sprite: PixelSprite) -> [String] {
        switch sprite {
        case .alinaIdle: return alinaHead + alinaIdleBody
        case .alinaBlink: return alinaBlinkHead + alinaIdleBody
        case .alinaRun: return alinaHead + alinaRunBody
        case .alinaJump: return alinaHead + alinaJumpBody
        case .alinaFall: return alinaHead + alinaFallBody
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
        case .heartEmpty: return heart.map { String($0.map { $0 == "." ? "." : "e" }) }
        case .bloomBlock: return bloomBlock
        case .bloomBlockUsed: return bloomBlockUsed
        case .mossbrick: return mossbrick
        case .groundTop: return groundTop
        case .groundFill: return Array(groundTop.suffix(11)) + Array(groundTop.suffix(11).prefix(5))
        case .stone: return stone
        case .log: return log
        case .thorns: return thorns
        case .leafPad: return leafPad
        case .cloudPad: return cloudPad
        case .beacon: return beacon
        case .sun: return sun
        case .cloud: return cloud
        case .tree: return tree
        case .bush: return bush
        case .flower: return flower
        case .hillFar: return hillFar
        case .hillNear:
            return hillFar.map { row in
                String(row.map { ch in ch == "b" ? "g" : ch == "k" ? "i" : ch == "j" ? "x" : ch })
            }
        }
    }

    // MARK: Alina (14 × 18)

    private static let alinaHead = [
        "....oooooo....",
        "...oHHHHHHo...",
        "..oHHhhHHHHo..",
        ".oHHhHHHHHHHo.",
        ".oHHSSSSSSHHo.",
        ".oHSSESSSESHo.",
        ".oHSSESSSESHo.",
        "KoHSCSSSSSCHo."
    ]
    private static let alinaBlinkHead = Array(alinaHead.prefix(5)) + [
        ".oHSSSSSSSSHo.",
        ".oHSSoSSSoSHo.",
        "KoHSCSSSSSCHo."
    ]
    private static let alinaIdleBody = [
        "KKoHSSSmSSHo..",
        ".KoHoPPPPoHo..",
        "..oSPPPGPPPSo.",
        "..oSPDPPPDPSo.",
        "..ooPPPPPPPoo.",
        "..oPPPPPPPPPo.",
        "..oWWWWWWWWWo.",
        "...oooSoSooo..",
        "....oBBoBBo...",
        "....oBBoBBo..."
    ]
    private static let alinaRunBody = [
        "KKoHSSSmSSHo..",
        ".KoHoPPPPoHo..",
        "...oPPPGPPPSo.",
        "..oSPDPPPDPo..",
        "..ooPPPPPPPoo.",
        "..oPPPPPPPPPo.",
        "..oWWWWWWWWWo.",
        "..ooSoooSoo...",
        ".oBBo...oBBo..",
        ".oBo.....oBo.."
    ]
    private static let alinaJumpBody = [
        "KKoHSSSmSSHoS.",
        ".KoHoPPPPoHoS.",
        "..oSPPPGPPPo..",
        "...oPDPPPDPo..",
        "..ooPPPPPPPoo.",
        "..oPPPPPPPPPo.",
        "..oWWWWWWWWWo.",
        "...ooSooSoo...",
        "...oBBooBBo...",
        ".............."
    ]
    private static let alinaFallBody = [
        "KKoHSSSmSSHo..",
        ".KoHoPPPPoHo..",
        "SooPPPGPPPooS.",
        "...oPDPPPDPo..",
        "..ooPPPPPPPoo.",
        "..oPPPPPPPPPo.",
        "..oWWWWWWWWWo.",
        "...ooSooSoo...",
        "...oBBooBBo...",
        ".............."
    ]

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

    // MARK: Items

    private static let petal = ["...FF...", "..FFFF..", "FF.GG.FF", "FFFGGFFF", "FFFGGFFF", "FF.GG.FF", "..FFFF..", "...FF..."]
    private static let petalTurn = ["...FF...", "...FF...", "..FGGF..", "..FGGF..", "..FGGF..", "..FGGF..", "...FF...", "...FF..."]
    private static let crystal = [
        "..GG..GG..", ".GOGGGGQG.", "GOGGGGGGQG", "GGGGGGGGQG", "GGGGGGGGQG",
        ".GGGGGGQG.", "..GGGGQG..", "...GGQG...", "....GG...."
    ]
    private static let sunbloom = [
        "...YYYY...", "..YGGGGY..", ".YGQQQQGY.", ".YGQQQQGY.", "..YGGGGY..",
        "...YYYY...", "....xx....", "..g.xx.g..", "..ggxxgg..", "....xx...."
    ]
    private static let ribbon = ["KK......KK", "KPK....KPK", "KPPKKKKPPK", "KPPPKKPPPK", "KPPKKKKPPK", "KPK.KK.KPK", "KK..KK..KK", "....K.K..."]
    private static let heart = [".PP.PP.", "PWPPPPP", "PPPPPPD", ".PPPPD.", "..PPD..", "...D..."]

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
    private static let log: [String] = (0..<16).map { $0 % 5 == 2 ? "tBhhBBhBtBhBBhBt" : "tBhhBBhBBhhBBhBt" }
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
