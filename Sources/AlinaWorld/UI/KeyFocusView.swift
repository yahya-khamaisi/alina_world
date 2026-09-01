import AppKit
import SwiftUI

/// Captures keyboard focus so Enter / Space work without clicking first.
struct KeyFocusView: NSViewRepresentable {
    let onKeyDown: (UInt16) -> Void

    func makeNSView(context: Context) -> KeyFocusNSView {
        let view = KeyFocusNSView()
        view.onKeyDown = onKeyDown
        return view
    }

    func updateNSView(_ nsView: KeyFocusNSView, context: Context) {
        nsView.onKeyDown = onKeyDown
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

final class KeyFocusNSView: NSView {
    var onKeyDown: ((UInt16) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        onKeyDown?(event.keyCode)
    }
}
