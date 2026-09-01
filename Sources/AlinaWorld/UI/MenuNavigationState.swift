import Combine
import Foundation

/// Shared keyboard-menu focus state (avoids SwiftUI @State macro dependency in SPM builds).
final class MenuNavigationState: ObservableObject {
    static let shared = MenuNavigationState()

    @Published var mainMenuFocus = 0
    @Published var playHighlighted = false
    @Published var missionMapIndex = 0
    @Published var victoryFocusNext = true

    func resetMissionMapSelection() {
        missionMapIndex = max(0, GameProgress.shared.unlockedMission - 1)
    }
}
