import AppKit

enum AppWindowController {
    static func toggleFullscreen() {
        guard let window = NSApplication.shared.windows.first(where: { $0.isVisible }) else { return }
        window.toggleFullScreen(nil)
    }

    static func enterFullscreenIfNeeded() {
        guard let window = NSApplication.shared.windows.first(where: { $0.isVisible }) else { return }
        if !window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
    }

    static var isFullscreen: Bool {
        guard let window = NSApplication.shared.windows.first(where: { $0.isVisible }) else { return false }
        return window.styleMask.contains(.fullScreen)
    }
}
