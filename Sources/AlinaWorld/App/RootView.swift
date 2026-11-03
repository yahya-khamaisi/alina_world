import SwiftUI

struct RootView: View {
    @ObservedObject private var router = AppRouter.shared

    var body: some View {
        ZStack {
            Palette.cream.ignoresSafeArea()

            Group {
                switch router.route {
                case .menu:
                    MainMenuView(
                        onContinue: { router.route = .story(GameProgress.shared.continueMission) },
                        onMap: { router.route = .missionMap }
                    )
                case .missionMap:
                    MissionMapView(
                        missions: MissionLoader.loadAll(),
                        onSelect: { router.route = .story($0.id) },
                        onBack: { router.route = .menu }
                    )
                case .story(let id):
                    if let mission = MissionLoader.mission(id: id) {
                        StoryBeatView(
                            mission: mission,
                            onContinue: { router.play(id) },
                            onBack: { router.route = .missionMap }
                        )
                    }
                case .playing(let id):
                    if let mission = MissionLoader.mission(id: id) {
                        GameContainerView(
                            mission: mission,
                            onOutcome: { outcome in
                                switch outcome {
                                case .won(let result): router.route = .victory(result)
                                case .lost(let reason): router.route = .defeat(id, reason)
                                }
                            },
                            onRetry: { router.play(id) },
                            onQuit: { router.route = .missionMap }
                        )
                        .id(router.attempt)
                    }
                case .victory(let result):
                    MissionCompleteView(
                        result: result,
                        onNext: {
                            let next = result.missionID + 1
                            if next <= GameProgress.missionCount, GameProgress.shared.isUnlocked(missionID: next) {
                                MenuNavigationState.shared.missionMapIndex = next - 1
                                router.route = .story(next)
                            } else {
                                router.route = .missionMap
                            }
                        },
                        onReplay: { router.play(result.missionID) },
                        onMap: { router.route = .missionMap }
                    )
                case .defeat(let id, let reason):
                    DefeatView(
                        missionID: id,
                        reason: reason,
                        onRetry: { router.play(id) },
                        onMap: { router.route = .missionMap }
                    )
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: router.routeKey)
        }
        .background(WindowAccessor())
        .onChange(of: router.routeKey, initial: true) { playMusic(for: router.route) }
        .onAppear {
            InputController.shared.startMonitoring()
            InputController.shared.mode = .menu
            router.applyLaunchRoute(ProcessInfo.processInfo.environment["ALINA_START_ROUTE"])
        }
    }

    private func playMusic(for route: AppRoute) {
        let audio = ChiptuneEngine.shared
        switch route {
        case .menu, .missionMap, .story:
            audio.play(Songs.title)
        case .playing(let id):
            guard let mission = MissionLoader.mission(id: id) else { return }
            audio.play(Songs.level(worldIndex: WorldThemes.index(of: mission.world), guardian: mission.objective == .defeatBoss))
        case .victory:
            audio.play(Songs.victory)
        case .defeat:
            audio.play(Songs.defeat)
        }
        audio.setDucked(false)
    }
}
