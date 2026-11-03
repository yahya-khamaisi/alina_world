import Combine
import Foundation

/// Shared keyboard-menu focus state, so arrow keys and the mouse move the same highlight.
final class MenuNavigationState: ObservableObject {
    static let shared = MenuNavigationState()

    @Published var mainMenuFocus = 0
    @Published var missionMapIndex = 0
    /// Focused row on overlay menus (pause, results, defeat).
    @Published var overlayFocus = 0

    func resetMissionMapSelection() {
        missionMapIndex = max(0, min(GameProgress.missionCount, GameProgress.shared.unlockedMission) - 1)
    }
}
