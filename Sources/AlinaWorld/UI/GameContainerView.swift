import SwiftUI
import SpriteKit

private final class GameSceneHolder {
    let scene = GameScene()
    private var timer: Timer?

    func startHUDPolling(model: GameHUDModel) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [self] _ in
            let state = self.scene.hudState
            model.lives = state.lives
            model.coins = state.coins
            model.crystals = state.crystals
            model.title = state.missionTitle
            model.elapsed = state.elapsed
            model.timeLimit = state.timeLimit
        }
    }

    func stopHUDPolling() {
        timer?.invalidate()
        timer = nil
    }
}

struct GameContainerView: View {
    let mission: Mission
    let onOutcome: (GameOutcome, Int) -> Void

    @ObservedObject private var hudModel = GameHUDModel()
    private let sceneHolder = GameSceneHolder()

    var body: some View {
        ZStack {
            SpriteView(
                scene: sceneHolder.scene,
                preferredFramesPerSecond: 60,
                options: [.ignoresSiblingOrder]
            )
            .ignoresSafeArea()

            HUDOverlay(
                lives: hudModel.lives,
                coins: hudModel.coins,
                crystals: hudModel.crystals,
                title: hudModel.title,
                elapsed: hudModel.elapsed,
                timeLimit: hudModel.timeLimit,
                collectTarget: mission.objective == .collectN ? mission.collectRequired : nil
            )
        }
        .onAppear {
            sceneHolder.scene.size = CGSize(width: 960, height: 540)
            sceneHolder.scene.scaleMode = .resizeFill
            sceneHolder.scene.mission = mission
            sceneHolder.scene.onOutcome = onOutcome
            sceneHolder.startHUDPolling(model: hudModel)
            InputController.shared.mode = .gameplay
        }
        .onDisappear {
            sceneHolder.stopHUDPolling()
            InputController.shared.mode = .menu
        }
    }
}
