import SwiftUI
import SpriteKit
import AppKit

@main
struct AlinaWorldApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 960, minHeight: 540)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if let window = NSApplication.shared.windows.first(where: { $0.isVisible }) {
                            window.collectionBehavior.insert(.fullScreenPrimary)
                        }
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
