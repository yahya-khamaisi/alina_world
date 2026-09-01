import SwiftUI
import Combine

/// Polls keyboard input for menu navigation without requiring mouse clicks.
struct MenuKeyboardDriver: View {
    let onTick: () -> Void

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                InputController.shared.mode = .menu
                InputController.shared.startMonitoring()
            }
            .onReceive(Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()) { _ in
                onTick()
            }
    }
}
