import SwiftUI

/// Design tokens for the menus: cream and white cards, plum ink, Alina pink.
enum Palette {
    static let ink = Color(hex: 0x2B2148)
    static let muted = Color(hex: 0x6B6386)
    static let body = Color(hex: 0x4E4668)
    static let cream = Color(hex: 0xFFFBF4)
    static let sand = Color(hex: 0xF6F1EA)
    static let line = Color(hex: 0xF1EADF)
    static let edge = Color(hex: 0xE5D3BC)
    static let pink = Color(hex: 0xE84E8A)
    static let pinkDeep = Color(hex: 0xB8306A)
    static let pinkText = Color(hex: 0xC13B73)
    static let pinkSoft = Color(hex: 0xFFEAF2)
    static let lavender = Color(hex: 0xF4F0FF)
    static let lavenderEdge = Color(hex: 0xDED6F7)
    static let violet = Color(hex: 0x6B57C9)
    static let gold = Color(hex: 0xF6C343)
    static let goldSoft = Color(hex: 0xFFF6DE)
    static let goldText = Color(hex: 0x8A5A00)
    static let mint = Color(hex: 0x3DBE8B)
    static let mintSoft = Color(hex: 0xE3F6EC)
    static let mintText = Color(hex: 0x1F7A50)
    static let sky = Color(hex: 0x4AA8E8)
    static let skySoft = Color(hex: 0xE7F4FD)
    static let skyText = Color(hex: 0x1F5F8C)
}

/// 8-pt spacing scale.
enum Space {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

extension Font {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Game button with a chunky drop edge that compresses when pressed or keyboard-activated.
struct ChunkyButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, quiet }

    var kind: Kind = .secondary
    var height: CGFloat = 52
    var focused = false
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let edgeHeight: CGFloat = kind == .quiet ? 0 : (kind == .primary ? 6 : 4)
        let shape = RoundedRectangle(cornerRadius: height >= 60 ? 18 : 14, style: .continuous)

        configuration.label
            .font(.rounded(kind == .primary ? 19 : 16, kind == .primary ? .bold : .heavy))
            .foregroundStyle(foreground)
            .padding(.horizontal, Space.l + 2)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: height, alignment: .leading)
            .background(shape.fill(fill))
            .overlay(shape.strokeBorder(kind == .quiet ? Palette.line : .clear, lineWidth: 2))
            .overlay(
                shape.inset(by: -4).strokeBorder(focused ? Palette.ink.opacity(0.85) : .clear, lineWidth: 3)
            )
            .background(shape.fill(edge).offset(y: pressed ? 1 : edgeHeight))
            .offset(y: pressed ? edgeHeight - 1 : 0)
            .padding(.bottom, edgeHeight)
            .contentShape(shape)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }

    private var fill: Color {
        switch kind {
        case .primary: return Palette.pink
        case .secondary: return Palette.lavender
        case .quiet: return .white
        }
    }

    private var edge: Color {
        switch kind {
        case .primary: return Palette.pinkDeep
        case .secondary: return Palette.lavenderEdge
        case .quiet: return .clear
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary: return .white
        case .secondary: return Palette.ink
        case .quiet: return Palette.pinkText
        }
    }
}

/// White card with the warm drop edge used across every menu.
struct CardBackground: ViewModifier {
    var padding: CGFloat = Space.xl
    var radius: CGFloat = 28

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.white)
                    .shadow(color: Palette.edge, radius: 0, y: 8)
                    .shadow(color: Palette.ink.opacity(0.12), radius: 24, y: 16)
            )
    }
}

extension View {
    func card(padding: CGFloat = Space.xl, radius: CGFloat = 28) -> some View {
        modifier(CardBackground(padding: padding, radius: radius))
    }

    /// Small white pill with a drop edge, used for stats over the scenery.
    func pill(height: CGFloat = 44) -> some View {
        self
            .font(.rounded(15, .heavy))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, Space.l)
            .frame(height: height)
            .background(
                Capsule().fill(.white).shadow(color: Palette.edge, radius: 0, y: 4)
            )
    }
}

/// Keyboard shortcut chip.
struct KeyCap: View {
    let text: String
    var dark = false

    var body: some View {
        Text(text)
            .font(.rounded(12, .heavy))
            .foregroundStyle(dark ? .white : Palette.muted)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(dark ? Palette.ink : Palette.sand)
            )
    }
}

/// Uppercase section label.
struct Eyebrow: View {
    let text: String
    var color: Color = Palette.muted

    var body: some View {
        Text(text.uppercased())
            .font(.rounded(12, .heavy))
            .tracking(1.2)
            .foregroundStyle(color)
    }
}

/// Mac window title bar inset so content clears the traffic lights in a hidden-title-bar window.
enum WindowChrome {
    static let titleBarHeight: CGFloat = 28
}
