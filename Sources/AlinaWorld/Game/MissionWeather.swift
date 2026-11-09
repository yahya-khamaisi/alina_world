import Foundation

/// Authored conditions for every mission. Weather is a simulation, independent of the computer's location.
struct MissionWeather: Equatable {
    enum Kind: String { case sunny, breeze, sunshower, rain, storm, mist, snow, blizzard, embers, dust, magic, starlight }
    let kind: Kind
    let seed: Int

    static func forMission(_ mission: Mission) -> MissionWeather {
        let key = WorldThemes.theme(for: mission.world).key
        let conditions: [Kind]
        switch key {
        case "meadow": conditions = [.sunny, .breeze, .sunshower]
        case "brook": conditions = [.sunny, .rain, .storm]
        case "grove": conditions = [.breeze, .mist, .rain]
        case "cavern": conditions = [.embers, .embers, .embers]
        case "ridge": conditions = [.sunny, .breeze, .dust]
        case "marsh": conditions = [.mist, .rain, .storm]
        case "spire": conditions = [.magic, .mist, .magic]
        case "storm": conditions = [.rain, .storm, .storm]
        case "throne": conditions = [.starlight, .breeze, .storm]
        case "frost": conditions = [.snow, .snow, .blizzard]
        case "coral": conditions = [.sunny, .breeze, .sunshower]
        case "starfall": conditions = [.starlight, .magic, .starlight]
        default: conditions = [.sunny, .breeze, .rain]
        }
        return MissionWeather(kind: conditions[max(0, mission.id - 1) % 3], seed: mission.layoutSeed)
    }

    var label: String {
        switch kind {
        case .sunny: return "Sunny"
        case .breeze: return "Breezy"
        case .sunshower: return "Sunshowers"
        case .rain: return "Rain"
        case .storm: return "Thunderstorm"
        case .mist: return "Misty"
        case .snow: return "Snowfall"
        case .blizzard: return "Snowstorm"
        case .embers: return "Drifting embers"
        case .dust: return "Desert wind"
        case .magic: return "Crystal shimmer"
        case .starlight: return "Starlight"
        }
    }

    var symbol: String {
        switch kind {
        case .sunny: return "sun.max.fill"
        case .breeze, .dust: return "wind"
        case .sunshower: return "cloud.sun.rain.fill"
        case .rain: return "cloud.rain.fill"
        case .storm: return "cloud.bolt.rain.fill"
        case .mist: return "cloud.fog.fill"
        case .snow, .blizzard: return "cloud.snow.fill"
        case .embers: return "flame.fill"
        case .magic: return "sparkles"
        case .starlight: return "moon.stars.fill"
        }
    }

    var rain: CGFloat { kind == .storm ? 1 : kind == .rain ? 0.65 : kind == .sunshower ? 0.28 : 0 }
    var snow: CGFloat { kind == .blizzard ? 1 : kind == .snow ? 0.4 : 0 }
    var wind: CGFloat { [.storm, .blizzard, .dust].contains(kind) ? 1 : kind == .breeze ? 0.6 : 0.18 }
    var cloudCover: CGFloat {
        switch kind {
        case .storm, .blizzard: return 0.82
        case .rain, .mist: return 0.6
        case .sunshower, .snow: return 0.35
        case .embers, .magic, .starlight: return 0.12
        default: return 0.18
        }
    }
    var sunshine: CGFloat { kind == .sunny ? 0.9 : kind == .breeze ? 0.65 : kind == .sunshower ? 0.55 : 0 }
    var fog: CGFloat { kind == .mist ? 0.22 : kind == .blizzard ? 0.14 : rain > 0 ? 0.05 : 0 }
}

extension Mission {
    var weather: MissionWeather { .forMission(self) }
}
