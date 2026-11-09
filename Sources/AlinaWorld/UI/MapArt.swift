import CoreGraphics

/// Coordinates measured against the production painting. The serpentine trail follows actual mission order.
enum MapArt {
    static let size = CGSize(width: 1200, height: 800)

    struct Island {
        let key: String
        let center: CGPoint
    }

    static let islands: [Island] = [
        Island(key: "meadow", center: CGPoint(x: 175, y: 620)),
        Island(key: "brook", center: CGPoint(x: 455, y: 620)),
        Island(key: "grove", center: CGPoint(x: 730, y: 620)),
        Island(key: "cavern", center: CGPoint(x: 1015, y: 620)),
        Island(key: "ridge", center: CGPoint(x: 1015, y: 412)),
        Island(key: "marsh", center: CGPoint(x: 730, y: 412)),
        Island(key: "spire", center: CGPoint(x: 455, y: 412)),
        Island(key: "storm", center: CGPoint(x: 175, y: 412)),
        Island(key: "throne", center: CGPoint(x: 175, y: 216)),
        Island(key: "frost", center: CGPoint(x: 455, y: 216)),
        Island(key: "coral", center: CGPoint(x: 730, y: 216)),
        Island(key: "starfall", center: CGPoint(x: 1015, y: 216))
    ]

    static let backdrop: CGImage = {
        if let painting = StorybookArt.image(.map) { return painting }
        return PixelCanvas(width: 2, height: 2, fill: 0x348DB4).cgImage()
    }()

    /// Start, control and end of a sea-only quadratic segment; turns go around the outer cliffs.
    static func trail(leg: Int) -> (CGPoint, CGPoint, CGPoint) {
        let a = islands[leg].center
        let b = islands[leg + 1].center
        if leg == 3 {
            return (CGPoint(x: a.x + 116, y: a.y), CGPoint(x: 1220, y: (a.y + b.y) / 2), CGPoint(x: b.x + 116, y: b.y))
        }
        if leg == 7 {
            return (CGPoint(x: a.x - 116, y: a.y), CGPoint(x: -20, y: (a.y + b.y) / 2), CGPoint(x: b.x - 116, y: b.y))
        }
        let direction: CGFloat = b.x > a.x ? 1 : -1
        return (CGPoint(x: a.x + 120 * direction, y: a.y + 8),
                CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 + 24),
                CGPoint(x: b.x - 120 * direction, y: b.y + 8))
    }
}
