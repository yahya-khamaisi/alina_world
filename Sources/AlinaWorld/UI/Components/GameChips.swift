import SwiftUI

/// Icon-first building blocks: values carry meaning through a sprite or symbol instead of a label.

/// Tinted chip holding an icon and a short value, e.g. a crystal and "3/5".
struct StatChip<Icon: View>: View {
    var value: String = ""
    var fill: Color = .white
    var text: Color = Palette.ink
    var height: CGFloat = 48
    var size: CGFloat = 20
    @ViewBuilder var icon: Icon

    var body: some View {
        HStack(spacing: Space.s) {
            icon
            if !value.isEmpty {
                Text(value).font(.rounded(size, .bold)).monospacedDigit()
            }
        }
        .foregroundStyle(text)
        .padding(.horizontal, 14)
        .frame(height: height)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(fill))
    }
}

/// Square icon-only button with a drop edge, sized for a big tap target.
struct TileButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, danger, white }

    var kind: Kind = .secondary
    var size: CGFloat = 64
    var width: CGFloat? = nil
    var focused = false

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let edgeHeight: CGFloat = size >= 64 ? 6 : 4
        let shape = RoundedRectangle(cornerRadius: size * 0.31, style: .continuous)

        configuration.label
            .font(kind == .primary ? .rounded(size * 0.4, .bold) : .system(size: size * 0.36, weight: .heavy))
            .foregroundStyle(colors.fg)
            .frame(width: width, height: size)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .background(
                ZStack {
                    shape.fill(colors.fill)
                    shape.inset(by: 6).stroke(.white.opacity(0.6), lineWidth: 2)
                        .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center))
                    shape.inset(by: 1.5).stroke(Palette.plum, lineWidth: 3)
                }
            )
            .overlay(shape.inset(by: -6).strokeBorder(focused ? Color(hex: 0xF6C343) : .clear, lineWidth: 4))
            .background(shape.fill(colors.edge).offset(y: pressed ? 1 : edgeHeight))
            .offset(y: pressed ? edgeHeight - 1 : 0)
            .padding(.bottom, edgeHeight)
            .contentShape(shape)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }

    private var colors: (fill: Color, edge: Color, fg: Color) {
        switch kind {
        case .primary: return (Color(hex: 0xF0619D), Palette.plum, .white)
        case .secondary: return (Palette.parchment, Palette.plum, Palette.violet)
        case .danger: return (Palette.pinkSoft, Palette.plum, Palette.pinkText)
        case .white: return (Palette.parchment, Palette.plum, Palette.ink)
        }
    }
}

/// Three stars in a row; earned ones are gold.
struct StarsView: View {
    let stars: [Bool]
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(stars[i] ? Palette.gold : Color(hex: 0xD9D0C3))
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(stars.filter { $0 }.count) of 3 stars")
    }
}

/// Keycaps paired with a symbol for what they do, in place of a written controls list.
struct ControlStrip: View {
    struct Entry: Hashable {
        let key: String
        let symbol: String
        let label: String
    }

    static let gameplay: [Entry] = [
        Entry(key: "←", symbol: "hand.raised.fill", label: "Punch"),
        Entry(key: "→", symbol: "figure.kickboxing", label: "Kick"),
        Entry(key: "␣ ×2", symbol: "arrow.up", label: "Jump; press again in the air to double jump, hold to glide"),
        Entry(key: "↓", symbol: "hand.raised.slash.fill", label: "Brake: hold to slow down"),
        Entry(key: "esc", symbol: "pause.fill", label: "Pause")
    ]

    var entries: [Entry] = gameplay

    var body: some View {
        HStack(spacing: 10) {
            ForEach(entries, id: \.self) { entry in
                HStack(spacing: Space.s) {
                    Text(entry.key)
                        .font(.rounded(13, .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .frame(minWidth: 30, minHeight: 30)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Palette.ink))
                    Image(systemName: entry.symbol)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                }
                .padding(.leading, 6)
                .padding(.trailing, Space.m)
                .frame(height: 42)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.92)))
                .help(entry.label)
                .accessibilityElement()
                .accessibilityLabel("\(entry.label): \(entry.key)")
            }
        }
    }
}

extension Mission {
    /// Short code like "3-2": world number, then the mission's slot in that world.
    var code: String {
        "\(WorldThemes.index(of: world) + 1)-\((id - 1) % 3 + 1)"
    }

    /// Sprite standing for the objective.
    var goalSprite: PixelSprite {
        switch objective {
        case .reachFlag: return .beacon
        case .collectN: return .crystal
        case .defeatBoss: return .guardian
        }
    }
}
