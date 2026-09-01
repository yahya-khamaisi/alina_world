import SpriteKit

struct WorldPalette {
    let sky: SKColor
    let ground: SKColor
    let block: SKColor
    let accent: SKColor
    let hazard: SKColor

    func worldBackgroundColor() -> SKColor {
        sky
    }
}

enum WorldPalettes {
    static func palette(for world: String) -> WorldPalette {
        switch world.lowercased() {
        case "meadow":
            return WorldPalette(
                sky: SKColor(red: 0.55, green: 0.82, blue: 0.95, alpha: 1),
                ground: SKColor(red: 0.45, green: 0.72, blue: 0.35, alpha: 1),
                block: SKColor(red: 0.55, green: 0.40, blue: 0.25, alpha: 1),
                accent: SKColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 1),
                hazard: SKColor(red: 0.85, green: 0.25, blue: 0.2, alpha: 1)
            )
        case "brook":
            return WorldPalette(
                sky: SKColor(red: 0.50, green: 0.75, blue: 0.95, alpha: 1),
                ground: SKColor(red: 0.30, green: 0.55, blue: 0.75, alpha: 1),
                block: SKColor(red: 0.35, green: 0.45, blue: 0.55, alpha: 1),
                accent: SKColor(red: 0.65, green: 0.90, blue: 1.0, alpha: 1),
                hazard: SKColor(red: 0.9, green: 0.35, blue: 0.25, alpha: 1)
            )
        case "grove":
            return WorldPalette(
                sky: SKColor(red: 0.45, green: 0.70, blue: 0.55, alpha: 1),
                ground: SKColor(red: 0.25, green: 0.50, blue: 0.30, alpha: 1),
                block: SKColor(red: 0.40, green: 0.32, blue: 0.22, alpha: 1),
                accent: SKColor(red: 0.75, green: 0.95, blue: 0.55, alpha: 1),
                hazard: SKColor(red: 0.85, green: 0.30, blue: 0.20, alpha: 1)
            )
        case "cavern":
            return WorldPalette(
                sky: SKColor(red: 0.18, green: 0.16, blue: 0.22, alpha: 1),
                ground: SKColor(red: 0.35, green: 0.30, blue: 0.28, alpha: 1),
                block: SKColor(red: 0.48, green: 0.42, blue: 0.38, alpha: 1),
                accent: SKColor(red: 0.95, green: 0.75, blue: 0.45, alpha: 1),
                hazard: SKColor(red: 0.95, green: 0.40, blue: 0.15, alpha: 1)
            )
        case "ridge":
            return WorldPalette(
                sky: SKColor(red: 0.70, green: 0.55, blue: 0.45, alpha: 1),
                ground: SKColor(red: 0.55, green: 0.40, blue: 0.30, alpha: 1),
                block: SKColor(red: 0.62, green: 0.48, blue: 0.36, alpha: 1),
                accent: SKColor(red: 1.0, green: 0.65, blue: 0.35, alpha: 1),
                hazard: SKColor(red: 0.90, green: 0.25, blue: 0.15, alpha: 1)
            )
        case "marsh":
            return WorldPalette(
                sky: SKColor(red: 0.35, green: 0.45, blue: 0.50, alpha: 1),
                ground: SKColor(red: 0.22, green: 0.38, blue: 0.32, alpha: 1),
                block: SKColor(red: 0.30, green: 0.35, blue: 0.38, alpha: 1),
                accent: SKColor(red: 0.55, green: 0.85, blue: 0.75, alpha: 1),
                hazard: SKColor(red: 0.75, green: 0.20, blue: 0.35, alpha: 1)
            )
        case "spire":
            return WorldPalette(
                sky: SKColor(red: 0.25, green: 0.20, blue: 0.45, alpha: 1),
                ground: SKColor(red: 0.40, green: 0.35, blue: 0.55, alpha: 1),
                block: SKColor(red: 0.50, green: 0.42, blue: 0.62, alpha: 1),
                accent: SKColor(red: 0.85, green: 0.55, blue: 1.0, alpha: 1),
                hazard: SKColor(red: 0.95, green: 0.30, blue: 0.55, alpha: 1)
            )
        case "storm":
            return WorldPalette(
                sky: SKColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1),
                ground: SKColor(red: 0.28, green: 0.30, blue: 0.35, alpha: 1),
                block: SKColor(red: 0.38, green: 0.40, blue: 0.45, alpha: 1),
                accent: SKColor(red: 0.70, green: 0.85, blue: 1.0, alpha: 1),
                hazard: SKColor(red: 0.55, green: 0.65, blue: 0.95, alpha: 1)
            )
        case "throne":
            return WorldPalette(
                sky: SKColor(red: 0.12, green: 0.08, blue: 0.18, alpha: 1),
                ground: SKColor(red: 0.35, green: 0.25, blue: 0.40, alpha: 1),
                block: SKColor(red: 0.45, green: 0.32, blue: 0.50, alpha: 1),
                accent: SKColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 1),
                hazard: SKColor(red: 0.95, green: 0.20, blue: 0.45, alpha: 1)
            )
        default:
            return palette(for: "meadow")
        }
    }
}

enum GameConstants {
    static let tileSize: CGFloat = 32
    static let gravity: CGFloat = 2200
    static let playerWidth: CGFloat = 22
    static let playerHeight: CGFloat = 28
    static let stompBounceVelocity: CGFloat = 520
}
