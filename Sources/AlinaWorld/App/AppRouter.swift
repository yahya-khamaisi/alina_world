import Combine
import Foundation

enum AppRoute {
    case menu
    case missionMap
    case story(Int)
    case playing(Int)
    case victory(Int, Int)
}

final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    @Published var route: AppRoute = .menu

    var routeKey: String {
        switch route {
        case .menu: return "menu"
        case .missionMap: return "map"
        case .story(let id): return "story-\(id)"
        case .playing(let id): return "play-\(id)"
        case .victory(let id, _): return "win-\(id)"
        }
    }
}

final class GameHUDModel: ObservableObject {
    @Published var lives = 3
    @Published var coins = 0
    @Published var crystals = 0
    @Published var title = ""
    @Published var elapsed: CGFloat = 0
    @Published var timeLimit: Int?
}
