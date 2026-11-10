#if DEBUG
import AppKit

/// Debug-only scripted key presses for testing without accessibility permission, alongside ALINA_START_ROUTE.
/// `ALINA_INPUT_SCRIPT="1.0 right down; 1.5 space down; 1.6 space up; 2.0 esc tap"` — seconds after launch,
/// a key name, and `down`, `up` or `tap`.
enum DevInputScript {
    private static let codes: [String: UInt16] = [
        "left": 123, "right": 124, "up": 126, "down": 125, "space": 49, "esc": 53, "enter": 36
    ]

    static func run(_ spec: String?) {
        guard let spec else { return }
        for step in spec.split(separator: ";") {
            let parts = step.split(separator: " ").map(String.init)
            guard parts.count == 3, let time = Double(parts[0]), let code = codes[parts[1]] else { continue }
            let actions: [(Double, NSEvent.EventType)] = switch parts[2] {
            case "down": [(0, .keyDown)]
            case "up": [(0, .keyUp)]
            default: [(0, .keyDown), (0.08, .keyUp)]
            }
            for (delay, type) in actions {
                DispatchQueue.main.asyncAfter(deadline: .now() + time + delay) { post(type, code) }
            }
        }
    }

    private static func post(_ type: NSEvent.EventType, _ code: UInt16) {
        guard let window = AppWindowController.gameWindow,
              let event = NSEvent.keyEvent(
                  with: type, location: .zero, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                  windowNumber: window.windowNumber, context: nil, characters: "", charactersIgnoringModifiers: "",
                  isARepeat: false, keyCode: code
              ) else { return }
        NSApp.postEvent(event, atStart: false)
    }
}
#endif
