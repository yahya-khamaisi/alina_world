import AppKit
import Combine

final class InputController {
    static let shared = InputController()

    enum Mode {
        case gameplay
        case menu
    }

    private(set) var left = false
    private(set) var right = false
    private(set) var jumpHeld = false
    private(set) var sprint = false
    private(set) var escapePressed = false
    private(set) var enterPressed = false
    private(set) var pausePressed = false
    private(set) var upPressed = false
    private(set) var downPressed = false
    private(set) var fullscreenPressed = false
    private(set) var tabPressed = false

    var mode: Mode = .menu

    private var monitor: Any?

    func startMonitoring() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { event in
            self.handle(event)
            return event
        }
    }

    func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        resetHeld()
    }

    func consumeEscape() -> Bool {
        if escapePressed {
            escapePressed = false
            return true
        }
        return false
    }

    func consumeEnter() -> Bool {
        if enterPressed {
            enterPressed = false
            return true
        }
        return false
    }

    func consumePause() -> Bool {
        if pausePressed {
            pausePressed = false
            return true
        }
        return false
    }

    func consumeUp() -> Bool {
        if upPressed {
            upPressed = false
            return true
        }
        return false
    }

    func consumeDown() -> Bool {
        if downPressed {
            downPressed = false
            return true
        }
        return false
    }

    func consumeLeft() -> Bool {
        if mode == .menu && left {
            left = false
            return true
        }
        return false
    }

    func consumeRight() -> Bool {
        if mode == .menu && right {
            right = false
            return true
        }
        return false
    }

    func consumeFullscreen() -> Bool {
        if fullscreenPressed {
            fullscreenPressed = false
            return true
        }
        return false
    }

    func consumeTab() -> Bool {
        if tabPressed {
            tabPressed = false
            return true
        }
        return false
    }

    private func resetHeld() {
        left = false
        right = false
        jumpHeld = false
        sprint = false
        escapePressed = false
        enterPressed = false
        pausePressed = false
        upPressed = false
        downPressed = false
        fullscreenPressed = false
        tabPressed = false
    }

    private func handle(_ event: NSEvent) {
        if event.type == .flagsChanged {
            sprint = event.modifierFlags.contains(.shift)
            return
        }

        let code = event.keyCode
        switch event.type {
        case .keyDown:
            switch code {
            case 0, 123:
                left = true
                if mode == .menu { right = false }
            case 2, 124:
                right = true
                if mode == .menu { left = false }
            case 49:
                if mode == .menu { enterPressed = true }
                else { jumpHeld = true }
            case 13:
                if mode == .gameplay { jumpHeld = true }
            case 126:
                if mode == .gameplay { jumpHeld = true }
                else { upPressed = true; downPressed = false }
            case 125:
                if mode == .menu { downPressed = true; upPressed = false }
            case 53:
                escapePressed = true
                pausePressed = true
            case 36:
                enterPressed = true
            case 3:
                fullscreenPressed = true
            case 48:
                tabPressed = true
            default:
                break
            }
        case .keyUp:
            switch code {
            case 0, 123: left = false
            case 2, 124: right = false
            case 49, 13, 126: jumpHeld = false
            default: break
            }
        default:
            break
        }
    }
}
