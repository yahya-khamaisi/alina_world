package app.jannat.alinaworld.pixel

enum class PixelSprite {
    AlinaIdle, AlinaBlink, AlinaRun, AlinaJump, AlinaFall,
    Gloomling, GloomlingStep, Thornbeetle, Mothwisp, MothwispFlap, Guardian,
    Petal, PetalTurn, Crystal, Sunbloom, Ribbon, Heart, HeartEmpty,
    BloomBlock, BloomBlockUsed, Mossbrick, GroundTop, GroundFill, Stone, Log, Thorns, LeafPad, CloudPad, Beacon,
    Sun, Cloud, Tree, Bush, Flower, HillFar, HillNear
}

/**
 * Every sprite in the game as a character map, shared with the Mac app. `.` is transparent; letters index
 * [basePalette], and the lowercase world letters (i g x u s v V k b j) are recolored per world theme.
 */
object PixelCatalog {
    val basePalette: Map<Char, Int> = mapOf(
        'o' to 0x3A2230, // outline
        'H' to 0x6A3A22, 'h' to 0x9A5E36, // hair
        'S' to 0xF7CDA8, 'E' to 0x2B1810, 'C' to 0xF59AA6, 'm' to 0xC2455E, // skin, eyes, cheeks, mouth
        'P' to 0xEE5C95, 'D' to 0xC13B73, 'W' to 0xFFF6FA, 'B' to 0x7A4428, 'K' to 0xFF7AB6, // dress, trim, boots, bow
        'G' to 0xF6C343, 'Q' to 0xD9901A, 'O' to 0xFFFFFF, 'Y' to 0xFFE98A, 'A' to 0xFFB347, // gold, light
        'N' to 0x3B3070, 'n' to 0x5E52A0, 'L' to 0x1A1330, // gloom
        'R' to 0x8A4433, 'r' to 0xB9634A, 'T' to 0xF2E3C0, // beetle, thorns
        'M' to 0x9B7BEA, 'l' to 0xC3A8FF, 'F' to 0xFF8DBE, 'c' to 0xDCEEFF, // moth, petal, cloud shade
        'a' to 0xE6E0D4, 'e' to 0xC7BDAD, 'd' to 0x938674, // stone
        'q' to 0xE09466, 'w' to 0xB0643F, 'z' to 0xF4DDBE, 't' to 0x6B4A30, // brick, mortar, wood
        'i' to 0xA6E37E, 'g' to 0x76CF63, 'x' to 0x3E9147, 'u' to 0xD9A86C, 's' to 0xA98563,
        'v' to 0x55B85C, 'V' to 0x2F8A45, 'k' to 0xBDE6D2, 'b' to 0x9CD4BD, 'j' to 0x86C2AA
    )

    fun rows(sprite: PixelSprite): List<String> = when (sprite) {
        PixelSprite.AlinaIdle -> alinaHead + alinaIdleBody
        PixelSprite.AlinaBlink -> alinaBlinkHead + alinaIdleBody
        PixelSprite.AlinaRun -> alinaHead + alinaRunBody
        PixelSprite.AlinaJump -> alinaHead + alinaJumpBody
        PixelSprite.AlinaFall -> alinaHead + alinaFallBody
        PixelSprite.Gloomling -> gloomling
        PixelSprite.GloomlingStep -> gloomling.dropLast(2) + listOf(".NN.NNNN.NN.", "N...N..N...N")
        PixelSprite.Thornbeetle -> thornbeetle
        PixelSprite.Mothwisp -> mothwisp
        PixelSprite.MothwispFlap -> mothwispFlap
        PixelSprite.Guardian -> guardian
        PixelSprite.Petal -> petal
        PixelSprite.PetalTurn -> petalTurn
        PixelSprite.Crystal -> crystal
        PixelSprite.Sunbloom -> sunbloom
        PixelSprite.Ribbon -> ribbon
        PixelSprite.Heart -> heart
        PixelSprite.HeartEmpty -> heart.map { row -> row.map { if (it == '.') '.' else 'e' }.joinToString("") }
        PixelSprite.BloomBlock -> bloomBlock
        PixelSprite.BloomBlockUsed -> bloomBlockUsed
        PixelSprite.Mossbrick -> mossbrick
        PixelSprite.GroundTop -> groundTop
        PixelSprite.GroundFill -> groundTop.takeLast(11) + groundTop.takeLast(11).take(5)
        PixelSprite.Stone -> stone
        PixelSprite.Log -> log
        PixelSprite.Thorns -> thorns
        PixelSprite.LeafPad -> leafPad
        PixelSprite.CloudPad -> cloudPad
        PixelSprite.Beacon -> beacon
        PixelSprite.Sun -> sun
        PixelSprite.Cloud -> cloud
        PixelSprite.Tree -> tree
        PixelSprite.Bush -> bush
        PixelSprite.Flower -> flower
        PixelSprite.HillFar -> hillFar
        PixelSprite.HillNear -> hillFar.map { row ->
            row.map { ch -> when (ch) { 'b' -> 'g'; 'k' -> 'i'; 'j' -> 'x'; else -> ch } }.joinToString("")
        }
    }

    // Alina (14 × 18)

    private val alinaHead = listOf(
        "....oooooo....",
        "...oHHHHHHo...",
        "..oHHhhHHHHo..",
        ".oHHhHHHHHHHo.",
        ".oHHSSSSSSHHo.",
        ".oHSSESSSESHo.",
        ".oHSSESSSESHo.",
        "KoHSCSSSSSCHo."
    )
    private val alinaBlinkHead = alinaHead.take(5) + listOf(
        ".oHSSSSSSSSHo.",
        ".oHSSoSSSoSHo.",
        "KoHSCSSSSSCHo."
    )
    private val alinaIdleBody = listOf(
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
    )
    private val alinaRunBody = listOf(
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
    )
    private val alinaJumpBody = listOf(
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
    )
    private val alinaFallBody = listOf(
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
    )

    // Night Crown minions

    private val gloomling = listOf(
        "....nnnn....", "..nnNNNNnn..", ".nNNNNNNNNn.", ".NNYYNNYYNN.", ".NNYLNNYLNN.",
        "NNNNNNNNNNNN", "NNNNLLLLNNNN", "NNNNNNNNNNNN", ".NNN.NN.NNN.", "..N..NN..N.."
    )
    private val thornbeetle = listOf(
        "...T...T....", "..TRRTRRTR..", ".RRRRRRRRRR.", "RRrrRRRRrrRR",
        "RRRRRRRRRRRR", "YLRrrRRrrRRR", "LLLLLLLLLLLL", ".L.L..L..L.."
    )
    private val mothwisp = listOf(
        "MM........MM", "MlM......MlM", "MllM.nn.MllM", "MllMnYYnMllM",
        ".MMMnnnnMMM.", "..MMnnnnMM..", ".MlM.nn.MlM.", ".MM......MM."
    )
    private val mothwispFlap = listOf(
        "............", "MM...nn...MM", "MlMMnYYnMMlM", "MllMnnnnMllM",
        ".MlMnnnnMlM.", "..MM.nn.MM..", "............", "............"
    )
    private val guardian = listOf(
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
    )

    // Items

    private val petal = listOf("...FF...", "..FFFF..", "FF.GG.FF", "FFFGGFFF", "FFFGGFFF", "FF.GG.FF", "..FFFF..", "...FF...")
    private val petalTurn = listOf("...FF...", "...FF...", "..FGGF..", "..FGGF..", "..FGGF..", "..FGGF..", "...FF...", "...FF...")
    private val crystal = listOf(
        "..GG..GG..", ".GOGGGGQG.", "GOGGGGGGQG", "GGGGGGGGQG", "GGGGGGGGQG",
        ".GGGGGGQG.", "..GGGGQG..", "...GGQG...", "....GG...."
    )
    private val sunbloom = listOf(
        "...YYYY...", "..YGGGGY..", ".YGQQQQGY.", ".YGQQQQGY.", "..YGGGGY..",
        "...YYYY...", "....xx....", "..g.xx.g..", "..ggxxgg..", "....xx...."
    )
    private val ribbon = listOf("KK......KK", "KPK....KPK", "KPPKKKKPPK", "KPPPKKPPPK", "KPPKKKKPPK", "KPK.KK.KPK", "KK..KK..KK", "....K.K...")
    private val heart = listOf(".PP.PP.", "PWPPPPP", "PPPPPPD", ".PPPPD.", "..PPD..", "...D...")

    // Tiles (16 × 16)

    private val bloomBlock = listOf(
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
    )
    private val bloomBlockUsed = listOf("dddddddddddddddd", "deeeeeeeeeeeeeed", "deaeeeeeeeeeeaed") +
        List(10) { "deeeeeeeeeeeeeed" } + listOf("deaeeeeeeeeeeaed", "deeeeeeeeeeeeeed", "dddddddddddddddd")
    private val mossbrick = listOf(
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
    )
    private val groundTop = listOf(
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
    )
    private val stone = listOf(
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
    )
    private val log = List(16) { if (it % 5 == 2) "tBhhBBhBtBhBBhBt" else "tBhhBBhBBhhBBhBt" }
    private val thorns = List(6) { "................" } + listOf(
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
    )
    private val leafPad = listOf(
        "vvvvvvvvvvvvvvvv",
        "iivviiivviiivvii",
        "vvvvvvvvvvvvvvvv",
        "VvvVvvvVvvvVvvvV",
        "VVVVVVVVVVVVVVVV",
        "..t.........t..."
    )
    private val cloudPad = listOf(
        "..OOOOOO....OOOOOOO....OOOOOO...",
        ".OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.",
        "OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",
        "OcOOOcOOOOcOOOOcOOOOcOOOOOcOOOcO",
        ".cccccccccccccccccccccccccccccc."
    )
    private val beacon = listOf(
        "..QQQQ..", ".QYYYYQ.", ".QYOYYQ.", ".QYYYYQ.", "..QQQQ..", "...tt...", "...tt...", "...tt...",
        "...tt...", "...tt...", "...tt...", "...tt...", "...tt...", "...tt...", "..tttt..", ".tttttt."
    )

    // Scenery

    private val sun = listOf(
        "....A..A....", "..A......A..", "....GGGG....", "A..GYYYYG..A", "..GYOYYYYG..", "..GYYYYYYG..",
        "..GYYYYYYG..", "..GYYYYYYG..", "A..GYYYYG..A", "....GGGG....", "..A......A..", "....A..A...."
    )
    private val cloud = listOf(
        "....OOOO........", "..OOOOOOOO.OOO..", ".OOOOOOOOOOOOOO.",
        "OOOOOOOOOOOOOOOO", "OccOOOOOOcOOOccO", ".cccccccccccccc."
    )
    private val tree = listOf(
        ".....VVVV.....", "...VVvvvvVV...", "..VvviivvvVV..", ".VvviivvvvvVV.", ".VviivvvvvvVV.",
        "VvvvvvvvvvvvVV", "VvvvvvvvvvVVVV", "VvvvvvVvvvvVVV", ".VVvvVVVvvVVV.", "..VVVVtVVVVV..",
        "....VVttVV....", "......tt......", "......tt......", "......tt......", ".....tttt....."
    )
    private val bush = listOf("...VVVV.VV..", ".VVvvvvVvvV.", "VvviivvvvivV", "VvvvvvvvvvvV", ".VVVVVVVVVV.")
    private val flower = listOf(".F.F.", "FFGFF", ".FFF.", "..x..", ".xx..", "..x..")
    private val hillFar = listOf(
        "........kkkkkkkk........",
        ".....kkkbbbbbbbbkkk.....",
        "...kkbbbbbbbbbbbbbbkk...",
        "..kbbbbbbjbbbbbbbbbbbk..",
        ".kbbbbbbbbbbbbbjbbbbbbk.",
        "kbbbbjbbbbbbbbbbbbbbbbbk",
        "bbbbbbbbbbbbbjbbbbbbbbbb",
        "bbbbbbbbbbbbbbbbbbbbbbbb"
    )
}
