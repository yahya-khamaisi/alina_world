import Foundation

/// 16 × 16 level tiles as character maps, built from small rules so they tile seamlessly in both directions.
/// Letters follow `PixelCatalog`: i g x = grass light/body/shade, X = grass outline, u y s = dirt body/light/mortar.
/// All of them are recoloured per world through `WorldTheme.spritePalette`.
enum TileArt {
    /// How far the grass tufts hang over the dirt in each column (repeats every 16 px).
    private static let tuft = [2, 3, 1, 0, 2, 4, 3, 1, 0, 1, 3, 2, 0, 2, 4, 1]

    /// Seeds of the rounded stones packed into each 16 × 16 tile (periodic, so neighbours join).
    private static let stones: [(Double, Double)] = [(3, 2.5), (11, 3), (7, 8.5), (15, 9), (2.5, 13), (10.5, 14), (6, 0.5)]

    /// Which stone owns a pixel, and how close it sits to the joint with the next stone.
    private static func stoneCell(_ x: Int, _ y: Int) -> (cell: Int, margin: Double) {
        var best = (Double.infinity, 0), second = Double.infinity
        for (i, s) in stones.enumerated() {
            for ox in [-16.0, 0, 16] {
                for oy in [-16.0, 0, 16] {
                    // Squash vertically so stones read wider than tall.
                    let dx = Double(x) + 0.5 - s.0 - ox, dy = (Double(y) + 0.5 - s.1 - oy) * 1.25
                    let d = (dx * dx + dy * dy).squareRoot()
                    if d < best.0 { second = best.0; best = (d, i) } else if d < second { second = d }
                }
            }
        }
        return (best.1, second - best.0)
    }

    /// Packed rounded cobbles: dark joints, a lit upper-left rim on every stone. Depends only on x, y mod 16.
    private static func cobble(_ x: Int, _ y: Int) -> Character {
        let x = ((x % 16) + 16) % 16, y = ((y % 16) + 16) % 16
        let here = stoneCell(x, y)
        if here.margin < 1.1 { return "s" }
        let up = stoneCell(x, y - 1), left = stoneCell(x - 1, y)
        if up.cell != here.cell || up.margin < 1.1 || left.cell != here.cell || left.margin < 1.1 { return "y" }
        if (x * 7 + y * 13) % 37 == 0 { return "s" }
        return "u"
    }

    /// Grass cap rows 0…(4 + tuft) over `body`.
    private static func grassCap(_ x: Int, _ y: Int, body: (Int, Int) -> Character) -> Character {
        let hang = 4 + tuft[x % 16]
        switch y {
        case 0: return (x % 7 == 3) ? "g" : "i"
        case 1: return (x % 5 == 1) ? "i" : "g"
        case 2: return (x % 6 == 4) ? "i" : "g"
        case _ where y < hang - 1: return (x + y) % 9 == 0 ? "x" : "g"
        case _ where y == hang - 1: return "x"
        case _ where y == hang: return "X"
        default: return body(x, y)
        }
    }

    static let groundTop: [String] = (0..<16).map { y in
        String((0..<16).map { x in grassCap(x, y, body: cobble) })
    }

    static let groundFill: [String] = (0..<16).map { y in String((0..<16).map { x in cobble(x, y) }) }

    /// A free-standing block (steps, ledges): cobbles framed by a dark rim, with a grass cap when nothing sits on it.
    static func rockBlock(cap: Bool) -> [String] {
        (0..<16).map { y in
            String((0..<16).map { x -> Character in
                if cap, y < 9, case let c = grassCap(x, y, body: { _, _ in "?" }), c != "?" { return c }
                if x == 0 || x == 15 || y == 15 { return "X" }
                if y == 0 { return "s" }
                if x == 1 { return "y" }
                if x == 14 || y == 14 { return "s" }
                return cobble(x, y)
            })
        }
    }

    /// Floating grassy island, 16 × 12: grass with a flower or two, a rounded dirt underside and hanging vines.
    /// `left` / `right` round off that end; middle pieces join seamlessly.
    static func leafPad(left: Bool, right: Bool) -> [String] {
        let depth = [8, 9, 10, 9, 8, 9, 10, 10, 9, 8, 9, 10, 9, 8, 9, 9]
        let vines: [Int: Int] = [3: 11, 11: 10]
        return (0..<12).map { y in
            String((0..<16).map { x -> Character in
                // Rounded ends.
                var bottom = depth[x]
                if left { bottom = min(bottom, [3, 5, 7, 8][min(x, 3)] + (x > 3 ? 9 : 0)) }
                if right { bottom = min(bottom, [3, 5, 7, 8][min(15 - x, 3)] + (15 - x > 3 ? 9 : 0)) }
                let edge = (left && x == 0) || (right && x == 15)
                if edge && y == 0 { return "." }
                if let vine = vines[x], !left || x > 3, !right || x < 12, y > bottom, y <= vine {
                    return y == vine ? "i" : (y % 2 == 0 ? "x" : "g")
                }
                if y > bottom { return "." }
                if y == bottom || edge { return "X" }
                // Little white flowers on the turf.
                if (x == 5 || x == 12) && y == 1 { return "G" }
                if ((x == 4 || x == 6 || x == 11 || x == 13) && y == 1) || ((x == 5 || x == 12) && (y == 0 || y == 2)) { return "O" }
                if y <= 4 { return grassCap(x, y, body: cobble) }
                let hang = 4 + tuft[x] / 2
                if y < hang { return "g" }
                if y == hang { return "x" }
                if y == bottom - 1 { return "s" }
                return (x + y) % 5 == 0 ? "y" : "u"
            })
        }
    }

    /// The beacon: a timber post with a lantern banner hanging from its arm, on a stone footing. 22 × 44.
    static let beacon: [String] = [
        "..............oooooo..",
        ".ooooooooooooohhhhBBo.",
        "ohhhhhhhhhhhhhhhhhhBo.",
        "oBBBBBBBBBBBBBBBBBBBo.",
        ".oooooootooooooBBhBBo.",
        ".......QQ.....oBhhBo..",
        ".......GQ....oBhhBBo..",
        ".......QQ...oBhhoBBo..",
        "......oQQo..oBhoohBo..",
        "....ooQGGQoo.ooohhBo..",
        "...oQGGGGGGQo..ohhBo..",
        "..oGYYYYYYYYGo.ohhBo..",
        "..oGPPPPPPPPGo.ohhBo..",
        "..oGPPPOOPPPGo.ohhBo..",
        "..oGPPOGGOPPGo.ohhBo..",
        "..oGPOOGGOOPGo.ohhBo..",
        "..oGPPOOOOPPGo.ohhBo..",
        "..oGPPPOOPPPGo.ohhBo..",
        "..oGDPPPPPPDGo.ohhBo..",
        "..oGQGGGGGGQGo.ohhBo..",
        "...oQQGGGGQQo..ohhBo..",
        "....ooQGGQoo...ohhBo..",
        "......oQQo.....ohhBo..",
        ".......oo......ohhBo..",
        "...............ohhBo..",
        "...............ohtBo..",
        "...............ohhBo..",
        "...............ohhBo..",
        "...............ohhBo..",
        "...............ohhBo..",
        "...............ohhBo..",
        "...............ohtBo..",
        "...............ohhBo..",
        "...............ohhBo..",
        "...............ohhBo..",
        "...............ohhBo..",
        "..............oohhBoo.",
        ".............oBhhhBBBo",
        "............oaaaaaaaeo",
        "...........oaaeeeaaeeo",
        "...........oaeeeeedeeo",
        "...........oeeeddeeedo",
        "...........odeeeeeeddo",
        "...........oddddddddd."
    ]
}
