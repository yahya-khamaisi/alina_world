import Combine
import SpriteKit
import SwiftUI

/// Owns the scene for one attempt and republishes its HUD values when they change.
final class GameSession: ObservableObject {
    let scene = GameScene()
    @Published var hud = HUDSnapshot()
    @Published var paused = false
    @Published var showHint = true
    private var timer: Timer?

    init(mission: Mission, onOutcome: @escaping (GameOutcome) -> Void) {
        let defaults = UserDefaults.standard
        scene.size = CGSize(width: 1280, height: 760)
        scene.scaleMode = .resizeFill
        scene.mission = mission
        scene.assistMode = defaults.bool(forKey: SettingsKey.assistMode)
        scene.ambientParticles = defaults.object(forKey: SettingsKey.ambientEffects) as? Bool ?? true
        scene.onOutcome = { [weak self] outcome in
            self?.stop()
            onOutcome(outcome)
        }
        scene.onPauseRequested = { [weak self] in
            MenuNavigationState.shared.overlayFocus = 0
            ChiptuneEngine.shared.play(.pause)
            ChiptuneEngine.shared.setDucked(true)
            self?.paused = true
        }
        showHint = defaults.object(forKey: SettingsKey.showHints) as? Bool ?? true
    }

    func start() {
        InputController.shared.clearPresses()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let snapshot = self.scene.hudSnapshot
            if snapshot != self.hud { self.hud = snapshot }
        }
        if ProcessInfo.processInfo.environment["ALINA_START_ROUTE"]?.hasSuffix(":paused") == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.pause() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            withAnimation(.easeOut(duration: 0.4)) { self?.showHint = false }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func pause() {
        scene.pauseGame()
        MenuNavigationState.shared.overlayFocus = 0
        ChiptuneEngine.shared.play(.pause)
        ChiptuneEngine.shared.setDucked(true)
        paused = true
    }

    func resume() {
        ChiptuneEngine.shared.setDucked(false)
        paused = false
        scene.resumeGame()
    }

    func restartFromCheckpoint() {
        ChiptuneEngine.shared.setDucked(false)
        paused = false
        scene.restartFromCheckpoint()
    }

    deinit { timer?.invalidate() }
}

struct GameContainerView: View {
    let mission: Mission
    let onRetry: () -> Void
    let onQuit: () -> Void

    @StateObject private var session: GameSession
    @AppStorage(SettingsKey.frameRate) private var frameRate = 120

    init(mission: Mission, onOutcome: @escaping (GameOutcome) -> Void, onRetry: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.mission = mission
        self.onRetry = onRetry
        self.onQuit = onQuit
        _session = StateObject(wrappedValue: GameSession(mission: mission, onOutcome: onOutcome))
    }

    var body: some View {
        ZStack {
            SpriteView(scene: session.scene, preferredFramesPerSecond: frameRate, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            HUDOverlay(mission: mission, hud: session.hud, showHint: session.showHint && !session.paused, onPause: session.pause)
                .padding(.top, WindowChrome.titleBarHeight)
                .allowsHitTesting(!session.paused)

            if session.paused {
                PauseOverlay(
                    mission: mission,
                    hud: session.hud,
                    onResume: session.resume,
                    onCheckpoint: session.restartFromCheckpoint,
                    onRestart: onRetry,
                    onQuit: onQuit
                )
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .animation(.easeOut(duration: 0.18), value: session.paused)
        .onAppear {
            session.start()
            InputController.shared.mode = .gameplay
        }
        .onDisappear {
            session.stop()
            InputController.shared.mode = .menu
        }
    }
}
