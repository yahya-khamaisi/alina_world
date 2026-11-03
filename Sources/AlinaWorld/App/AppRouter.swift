import Combine
import Foundation

enum AppRoute: Equatable {
    case menu
    case missionMap
    case story(Int)
    case playing(Int)
    case victory(MissionResult)
    case defeat(Int, String)
}

final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    @Published var route: AppRoute = .menu
    /// Bumped on retry so the game view rebuilds its scene even when the mission is the same.
    @Published private(set) var attempt = 0

    func play(_ missionID: Int) {
        attempt += 1
        route = .playing(missionID)
    }

    /// Development shortcut: `ALINA_START_ROUTE=map|story:8|play:8` opens a screen directly at launch.
    func applyLaunchRoute(_ value: String?) {
        guard let value else { return }
        let parts = value.split(separator: ":")
        let id = parts.count > 1 ? Int(parts[1]) ?? 1 : 1
        switch parts.first {
        case "map": route = .missionMap
        case "story": route = .story(id)
        case "play": play(id)
        case "win":
            route = .victory(MissionResult(missionID: id, petals: 42, time: 41, hits: 1, parTime: 48, stars: [true, true, false], newBestTime: true))
        case "lose": route = .defeat(id, "Alina ran out of hearts.")
        default: break
        }
    }

    var routeKey: String {
        switch route {
        case .menu: return "menu"
        case .missionMap: return "map"
        case .story(let id): return "story-\(id)"
        case .playing(let id): return "play-\(id)-\(attempt)"
        case .victory(let result): return "win-\(result.missionID)"
        case .defeat(let id, _): return "lose-\(id)"
        }
    }
}
