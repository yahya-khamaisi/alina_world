import CoreGraphics
import ImageIO
import SpriteKit

/// Production paintings shared by SwiftUI and SpriteKit. The UI and all interactive objects remain live.
enum StorybookArt {
    enum Plate: String {
        case title = "TitleMeadow"
        case map = "LumenIsles"
        case meadow = "MeadowDistance"
        case alina = "AlinaIllustrated"
        case props = "SceneryIllustrated"
        case enemies = "CreaturesIllustrated"
        case terrain = "MeadowTerrain"
        case brook = "BrookDistance"
        case grove = "GroveDistance"
        case cavern = "CavernDistance"
        case ridge = "RidgeDistance"
        case marsh = "MarshDistance"
        case spire = "SpireDistance"
        case storm = "StormDistance"
        case throne = "ThroneDistance"
        case frost = "FrostDistance"
        case coral = "CoralDistance"
        case starfall = "StarfallDistance"
        case runCycle = "AlinaRunCycle"
        case biomeProps = "BiomeScenery"
        case levelObjects = "LevelObjects"
        case alinaRig = "AlinaRig"
        case creatureRig = "CreatureRig"
        case creatureRig2 = "CreatureRig2"
        case terrainEdges = "TerrainEdges"

        static func environment(for key: String) -> Plate {
            switch key {
            case "brook": return .brook
            case "grove": return .grove
            case "cavern": return .cavern
            case "ridge": return .ridge
            case "marsh": return .marsh
            case "spire": return .spire
            case "storm": return .storm
            case "throne": return .throne
            case "frost": return .frost
            case "coral": return .coral
            case "starfall": return .starfall
            default: return .meadow
            }
        }
    }

    private static var images: [Plate: CGImage] = [:]

    static func image(_ plate: Plate) -> CGImage? {
        if let image = images[plate] { return image }
        // World backdrops ship as large JPEGs (opaque, dehazed and upscaled); everything else is transparent PNG.
        guard let url = Bundle.module.url(forResource: plate.rawValue, withExtension: "png")
                ?? Bundle.module.url(forResource: plate.rawValue, withExtension: "jpg"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        images[plate] = image
        return image
    }

    static func texture(_ plate: Plate) -> SKTexture? {
        guard let image = image(plate) else { return nil }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        return texture
    }
}
