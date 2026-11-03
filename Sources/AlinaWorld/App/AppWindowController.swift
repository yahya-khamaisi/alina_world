import AppKit
import SwiftUI

enum AppWindowController {
    /// The main game window, captured by `WindowAccessor` so input and full screen ignore the Settings window.
    static weak var gameWindow: NSWindow?

    private static var window: NSWindow? {
        gameWindow ?? NSApplication.shared.windows.first(where: { $0.isVisible })
    }

    static func toggleFullscreen() {
        guard let window else { return }
        window.toggleFullScreen(nil)
    }

    static func enterFullscreenIfNeeded() {
        guard let window else { return }
        if !window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
    }

    static var isFullscreen: Bool {
        guard let window else { return false }
        return window.styleMask.contains(.fullScreen)
    }
}


/// Hands the hosting NSWindow to `AppWindowController` once the view is in a window.
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                AppWindowController.gameWindow = window
                window.collectionBehavior.insert(.fullScreenPrimary)
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = false
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
