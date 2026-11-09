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
    /// Gameplay: hold ↓ or S to slow the auto-run to a stop.
    private(set) var brake = false
    private(set) var escapePressed = false
    private(set) var enterPressed = false
    private(set) var pausePressed = false
    private(set) var upPressed = false
    private(set) var downPressed = false
    private(set) var fullscreenPressed = false
    private(set) var tabPressed = false
    /// Latched on every fresh jump press, so a tap that goes down and up between frames still jumps.
    private var jumpTapped = false
    /// Gameplay: ← (or Z) punches, → (or X) kicks. Latched like jumps so quick taps never get lost.
    private var punchTapped = false
    private var kickTapped = false

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

    func consumeJumpTap() -> Bool {
        defer { jumpTapped = false }
        return jumpTapped
    }

    func consumePunch() -> Bool {
        defer { punchTapped = false }
        return punchTapped
    }

    func consumeKick() -> Bool {
        defer { kickTapped = false }
        return kickTapped
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

    /// Drops one-shot presses left over from the previous screen.
    func clearPresses() {
        jumpTapped = false
        punchTapped = false
        kickTapped = false
        escapePressed = false
        enterPressed = false
        pausePressed = false
        upPressed = false
        downPressed = false
        fullscreenPressed = false
        tabPressed = false
        if mode == .menu {
            left = false
            right = false
        }
    }

    private func resetHeld() {
        left = false
        right = false
        jumpHeld = false
        sprint = false
        brake = false
        punchTapped = false
        kickTapped = false
        escapePressed = false
        enterPressed = false
        pausePressed = false
        upPressed = false
        downPressed = false
        fullscreenPressed = false
        tabPressed = false
    }

    private func handle(_ event: NSEvent) {
        // Keys typed in the Settings window must not drive the game behind it.
        if let gameWindow = AppWindowController.gameWindow, event.window !== gameWindow {
            return
        }
        if event.type == .flagsChanged {
            sprint = event.modifierFlags.contains(.shift)
            return
        }

        let code = event.keyCode
        switch event.type {
        case .keyDown:
            switch code {
            case 123 where mode == .gameplay, 6 where mode == .gameplay:
                if !event.isARepeat { punchTapped = true }
            case 124 where mode == .gameplay, 7 where mode == .gameplay:
                if !event.isARepeat { kickTapped = true }
            case 0, 123:
                left = true
                if mode == .menu { right = false }
            case 2, 124:
                right = true
                if mode == .menu { left = false }
            case 49:
                if mode == .menu { enterPressed = true }
                else { if !event.isARepeat { jumpTapped = true }; jumpHeld = true }
            case 13:
                if mode == .gameplay { if !event.isARepeat { jumpTapped = true }; jumpHeld = true } else { upPressed = true; downPressed = false }
            case 126:
                if mode == .gameplay { if !event.isARepeat { jumpTapped = true }; jumpHeld = true }
                else { upPressed = true; downPressed = false }
            case 125, 1:
                if mode == .menu { downPressed = true; upPressed = false } else { brake = true }
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
            case 125, 1: brake = false
            case 49, 13, 126: jumpHeld = false
            default: break
            }
        default:
            break
        }
    }
}
