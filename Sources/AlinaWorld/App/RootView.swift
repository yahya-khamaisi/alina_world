import SwiftUI

struct RootView: View {
    @ObservedObject private var router = AppRouter.shared

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.14, blue: 0.22), Color(red: 0.22, green: 0.18, blue: 0.32)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Group {
                switch router.route {
                case .menu:
                    MainMenuView(onPlay: { router.route = .missionMap })
                case .missionMap:
                    MissionMapView(
                        missions: MissionLoader.loadAll(),
                        onSelect: { mission in
                            router.route = .story(mission.id)
                        },
                        onBack: { router.route = .menu }
                    )
                case .story(let id):
                    if let mission = MissionLoader.mission(id: id) {
                        StoryBeatView(
                            mission: mission,
                            onContinue: { router.route = .playing(id) },
                            onBack: { router.route = .missionMap }
                        )
                    }
                case .playing(let id):
                    if let mission = MissionLoader.mission(id: id) {
                        GameContainerView(
                            mission: mission,
                            onOutcome: { outcome, coins in
                                switch outcome {
                                case .won: router.route = .victory(id, coins)
                                case .lost, .paused: router.route = .missionMap
                                case .playing: break
                                }
                            }
                        )
                    }
                case .victory(let id, let coins):
                    if let mission = MissionLoader.mission(id: id) {
                        VictoryView(
                            mission: mission,
                            coins: coins,
                            onContinue: { router.route = .missionMap },
                        onNextMission: { nextId in
                            MenuNavigationState.shared.victoryFocusNext = true
                            MenuNavigationState.shared.missionMapIndex = nextId - 1
                            if GameProgress.shared.isUnlocked(missionID: nextId) {
                                    router.route = .story(nextId)
                                } else {
                                    router.route = .missionMap
                                }
                            },
                            onMenu: { router.route = .menu }
                        )
                    }
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.35), value: router.routeKey)
        }
        .onAppear {
            InputController.shared.startMonitoring()
            InputController.shared.mode = .menu
        }
    }
}
