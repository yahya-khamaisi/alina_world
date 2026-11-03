import SpriteKit

enum GameConstants {
    static let tileSize: CGFloat = 32
    static let gravity: CGFloat = 2200
    static let playerWidth: CGFloat = 22
    static let playerHeight: CGFloat = 28
    static let stompBounceVelocity: CGFloat = 520
    /// World units visible vertically; the camera scales so every window size frames the level the same way.
    static let viewHeight: CGFloat = 560
    /// Integer upscale applied to 16 px tile art so it fills a 32 pt tile.
    static let tilePixel: CGFloat = 2
}

/// Per-world colors shared by the SpriteKit scene and the SwiftUI menus.
/// Values are 0xRRGGBB so the same palette feeds pixel textures and UI colors.
struct WorldTheme {
    let key: String
    let name: String
    let blurb: String
    /// Five sky bands, top to horizon.
    let sky: [UInt32]
    /// Grass highlight, grass, grass shadow.
    let grass: (UInt32, UInt32, UInt32)
    /// Dirt, dirt speckle.
    let dirt: (UInt32, UInt32)
    /// Leaf, leaf shadow.
    let leaves: (UInt32, UInt32)
    /// Far hill highlight, body, shade.
    let hills: (UInt32, UInt32, UInt32)
    /// Ambient particles drifting through the level.
    let particles: AmbientParticles

    enum AmbientParticles {
        case petals, rain, leaves, embers, dust, mist, sparkles, storm, motes, snow, bubbles
    }

    /// Palette overrides consumed by `PixelCatalog` for world-tinted sprites.
    var spritePalette: [Character: UInt32] {
        [
            "i": grass.0, "g": grass.1, "x": grass.2,
            "u": dirt.0, "s": dirt.1,
            "v": leaves.0, "V": leaves.1,
            "k": hills.0, "b": hills.1, "j": hills.2
        ]
    }

    var horizon: UInt32 { sky[4] }
}

enum WorldThemes {
    static let ordered: [WorldTheme] = [
        WorldTheme(
            key: "meadow", name: "Sunpetal Meadow",
            blurb: "Rolling hills and warm wind. Learn to run, jump and stomp before the Night Crown notices.",
            sky: [0x6EC1F2, 0x86CCF4, 0x9FD7F6, 0xB9E2F8, 0xD4EEFA],
            grass: (0xA6E37E, 0x76CF63, 0x3E9147), dirt: (0xD9A86C, 0xA98563),
            leaves: (0x55B85C, 0x2F8A45), hills: (0xBDE6D2, 0x9CD4BD, 0x86C2AA), particles: .petals
        ),
        WorldTheme(
            key: "brook", name: "Glimmer Brook",
            blurb: "Streams split the path. Leaf-pads float over the gaps — time your jumps.",
            sky: [0x5FB4EE, 0x79C2F2, 0x93CFF5, 0xAEDCF8, 0xCBEAFB],
            grass: (0xA8E6B0, 0x6CCB84, 0x3C8F5A), dirt: (0xC9B79A, 0x9C8A70),
            leaves: (0x4FB07A, 0x2D7F55), hills: (0xC4E4F2, 0xA3D2EA, 0x86BEDC), particles: .rain
        ),
        WorldTheme(
            key: "grove", name: "Whisper Grove",
            blurb: "Ancient trees hum with stolen light. Mothwisps drift through the canopy.",
            sky: [0x74C9C4, 0x8BD4CB, 0xA3DED3, 0xBCE7DC, 0xD5F0E6],
            grass: (0x9BE07A, 0x62BF55, 0x2F7F3F), dirt: (0xC08F5C, 0x8E6440),
            leaves: (0x3FA552, 0x1F6E38), hills: (0xA8DCC4, 0x86C7AA, 0x6AB091), particles: .leaves
        ),
        WorldTheme(
            key: "cavern", name: "Ember Cavern",
            blurb: "Warm stone and glowing embers. Thorns line the floor — watch your step.",
            sky: [0xF2B07A, 0xF5C08C, 0xF8CFA0, 0xFADDB6, 0xFCEACD],
            grass: (0xF2C48A, 0xD99A5B, 0xA3633A), dirt: (0xB57A55, 0x7E4F35),
            leaves: (0xD9824A, 0xA3532E), hills: (0xF4C9A6, 0xE3AE88, 0xCC9470), particles: .embers
        ),
        WorldTheme(
            key: "ridge", name: "Copper Ridge",
            blurb: "Sun-baked cliffs and long drops. Thornbeetles can't be stomped — jump over them.",
            sky: [0xF4C48E, 0xF6CF9F, 0xF8D9B0, 0xFAE3C3, 0xFCEDD7],
            grass: (0xD8E07A, 0xA8BE55, 0x6E8A35), dirt: (0xC79466, 0x956643),
            leaves: (0x9DB04C, 0x667A2E), hills: (0xEBD3B4, 0xDCBC98, 0xC9A27E), particles: .dust
        ),
        WorldTheme(
            key: "marsh", name: "Mist Marsh",
            blurb: "Soft ground and drifting fog. Every leap counts in the reeds.",
            sky: [0xA9CFC8, 0xB7D7D1, 0xC5DFDA, 0xD3E7E3, 0xE2F0EC],
            grass: (0xA9D9A0, 0x79B87A, 0x4A855A), dirt: (0x9C9278, 0x6E6754),
            leaves: (0x5E9E6E, 0x3B6E4C), hills: (0xC9DED8, 0xAFCFC6, 0x93BCB2), particles: .mist
        ),
        WorldTheme(
            key: "spire", name: "Violet Spire",
            blurb: "Crystal towers hum overhead. The clock is ticking from here on.",
            sky: [0xC3B1F0, 0xCDBEF3, 0xD7CBF6, 0xE2D9F9, 0xECE6FB],
            grass: (0xC9B8F2, 0x9B86DA, 0x6B57AE), dirt: (0xA897C2, 0x7C6B98),
            leaves: (0x8E72D6, 0x5E47A6), hills: (0xDCD0F6, 0xC6B6EE, 0xAE9CE0), particles: .sparkles
        ),
        WorldTheme(
            key: "storm", name: "Thunder Reach",
            blurb: "Rain lashes the bridges. Keep moving — the storm won't wait.",
            sky: [0x9FB4D6, 0xADBFDC, 0xBBCAE3, 0xCAD6EA, 0xD9E2F1],
            grass: (0xA9C7D8, 0x7FA2BC, 0x527692), dirt: (0x8C93A6, 0x646A7C),
            leaves: (0x6C8FB0, 0x46637F), hills: (0xC3CFE2, 0xA9B8D2, 0x8FA0C0), particles: .storm
        ),
        WorldTheme(
            key: "throne", name: "Night Crown Keep",
            blurb: "The last Heart Crystal glows in the throne room. Bring it home.",
            sky: [0xF49FA6, 0xF7B4AA, 0xF9C7B0, 0xFBD8BA, 0xFDE8C8],
            grass: (0xE8A6C8, 0xC77AA5, 0x8E4C79), dirt: (0x8F6C8C, 0x5E4660),
            leaves: (0xB46A9E, 0x7C3F6C), hills: (0xF2C6D2, 0xE2A9BC, 0xCC8EA6), particles: .motes
        ),
        WorldTheme(
            key: "frost", name: "Frostpeak Hollow",
            blurb: "Snow drifts and slippery ice. Plan each landing before you leap.",
            sky: [0x9FC7EA, 0xB0D2EE, 0xC2DDF2, 0xD4E8F6, 0xE6F2FA],
            grass: (0xF4FAFF, 0xD8EAF7, 0x9DBAD6), dirt: (0xA9C9E8, 0x86A9CC),
            leaves: (0x7FA7CF, 0x55799E), hills: (0xE6F0FA, 0xCFE0F1, 0xB5CCE6), particles: .snow
        ),
        WorldTheme(
            key: "coral", name: "Coral Lagoon",
            blurb: "Warm tide pools and bouncy shells. Ride a shell to the high ledges.",
            sky: [0x7FD3E6, 0x93DBEA, 0xA8E3EE, 0xBEEAF2, 0xD7F3F7],
            grass: (0xFFF0C8, 0xF2DCA0, 0xD9B76E), dirt: (0xF2E3C0, 0xD9C29A),
            leaves: (0x4FB07A, 0x2D7F55), hills: (0xC6F0EE, 0xA6E2E0, 0x86D0CF), particles: .bubbles
        ),
        WorldTheme(
            key: "starfall", name: "Starfall Sky",
            blurb: "Islands of cloud under a sky of wishes. Double jump between them.",
            sky: [0x5E52A0, 0x7466B5, 0x8C7DC8, 0xA898DA, 0xC6B8EA],
            grass: (0xFFFFFF, 0xEDE6FF, 0xC3B1F0), dirt: (0xD7CBF6, 0xB9A6EC),
            leaves: (0xFFFFFF, 0xDCD0F6), hills: (0xB9A6EC, 0x9B86DA, 0x8170C4), particles: .sparkles
        )
    ]

    static func theme(for world: String) -> WorldTheme {
        let key = world.lowercased()
        return ordered.first { $0.key == key } ?? ordered[0]
    }

    static func index(of world: String) -> Int {
        ordered.firstIndex { $0.key == world.lowercased() } ?? 0
    }
}

extension SKColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
