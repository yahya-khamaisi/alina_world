import CoreGraphics

/// Pure placement math shared by the renderer and coverage tests for long-running missions.
enum BackgroundTiling {
    static func centers(visible: CGRect, tileWidth: CGFloat, time: CGFloat) -> [CGFloat] {
        guard tileWidth > 0 else { return [] }
        let period = tileWidth * 2
        let travel = visible.minX * 0.14 + time * 1.3
        let phase = (travel.truncatingRemainder(dividingBy: period) + period).truncatingRemainder(dividingBy: period)
        let count = Int(ceil(visible.width / tileWidth)) + 5
        return (0..<count).map { visible.minX + CGFloat($0 - 1) * tileWidth - phase + tileWidth / 2 }
    }
}
