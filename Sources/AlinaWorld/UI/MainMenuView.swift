import AppKit
import SwiftUI

struct MainMenuView: View {
    let onContinue: () -> Void
    let onMap: () -> Void

    @ObservedObject private var nav = MenuNavigationState.shared
    @Environment(\.openSettings) private var openSettings
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage(SettingsKey.reduceMotion) private var reduceMotion = false
    @State private var bob = false

    private let progress = GameProgress.shared

    private enum Item: Int, CaseIterable {
        case play, map, settings, quit
    }

    var body: some View {
        ZStack {
            PixelBackdrop(theme: WorldThemes.ordered[0], framingTree: true)
                .ignoresSafeArea()

            GeometryReader { proxy in
                let compact = proxy.size.height < 760
                ZStack {
                    title
                        .scaleEffect(compact ? 0.82 : 1)
                        .position(x: proxy.size.width * 0.52, y: proxy.size.height * 0.20)
                    menu(compact: compact)
                        .position(x: proxy.size.width * 0.52, y: proxy.size.height * 0.66)
                    VStack {
                        HStack { Spacer(); stats }
                        Spacer()
                    }
                    .padding(.horizontal, Space.xxl)
                    .padding(.top, WindowChrome.titleBarHeight + Space.m)
                }
            }

            MenuKeyboardDriver { handleKeys() }
        }
        .onAppear {
            nav.mainMenuFocus = 0
            if !reduceMotion && !accessibilityReduceMotion {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { bob = true }
            }
        }
    }

    /// Storybook logo: plump pink "Alina" over golden "World", both with a white rim and a plum outline.
    private var title: some View {
        VStack(spacing: -34) {
            LogoWord(text: "Alina", size: 108, fill: [Color(hex: 0xFFA9CF), Color(hex: 0xF4559A)])
                .offset(x: -24)
            LogoWord(text: "World", size: 96, fill: [Color(hex: 0xFFE68A), Color(hex: 0xF2A93B)])
                .offset(x: 40)
        }
        .overlay(alignment: .topTrailing) {
            PixelImage(sprite: .flower, scale: 7).offset(x: 34, y: 18)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Alina World")
    }

    private var stats: some View {
        VStack(alignment: .trailing, spacing: 10) {
            statPill { PixelImage(sprite: .crystal, scale: 3) } value: { "\(progress.crystalsRestored)/\(GameProgress.worldCount)" }
            .accessibilityLabel("\(progress.crystalsRestored) of \(GameProgress.worldCount) Heart Crystals")
            statPill {
                Image(systemName: "star.fill").font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.gold)
                    .shadow(color: Palette.plum, radius: 0, x: 1.5, y: 1.5)
            } value: { "\(progress.totalStars)" }
            .accessibilityLabel("\(progress.totalStars) stars")
            statPill { PixelImage(sprite: .petal, scale: 3) } value: { "\(progress.totalPetals)" }
            .accessibilityLabel("\(progress.totalPetals) petals")
        }
        .font(.rounded(17, .bold))
        .monospacedDigit()
    }

    private func menu(compact: Bool) -> some View {
        VStack(spacing: compact ? 14 : 20) {
            // Alina stands on the Play button like a platform.
            PixelImage(sprite: .alinaIdle, scale: compact ? 4 : 5)
                .padding(.bottom, compact ? -18 : -24)
                .offset(y: bob ? -3 : 0)
                .zIndex(1)
                .accessibilityHidden(true)

            Button(action: { activate(.play) }) {
                HStack(spacing: 16) {
                    Image(systemName: "play.fill").font(.system(size: 34, weight: .black))
                    Text("PLAY").font(.rounded(46, .black)).tracking(2)
                    if let mission = continueMission {
                        Text(mission.code)
                            .font(.rounded(15, .heavy))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Palette.pinkText))
                    }
                }
            }
            .buttonStyle(StorybookButtonStyle(width: compact ? 340 : 380, height: compact ? 82 : 96, focused: nav.mainMenuFocus == Item.play.rawValue))
            .onHover { if $0 { nav.mainMenuFocus = Item.play.rawValue } }
            .accessibilityLabel(continueMission.map { "Play mission \($0.code)" } ?? "Play")

            HStack(spacing: 28) {
                tile(.map, icon: "map.fill", tint: Color(hex: 0x3E9A5A), label: "World map")
                tile(.settings, icon: "gearshape.fill", tint: Color(hex: 0x7C6CB4), label: "Settings")
                tile(.quit, icon: "door.left.hand.open", tint: Color(hex: 0xA65A37), label: "Quit")
            }
        }
        .overlay(alignment: .leading) {
            PixelImage(sprite: .petal, scale: 4)
                .rotationEffect(.degrees(-22))
                .offset(x: -72, y: bob ? -18 : -8)
                .allowsHitTesting(false)
        }
    }

    private func statPill<Icon: View>(@ViewBuilder icon: () -> Icon, value: () -> String) -> some View {
        HStack(spacing: Space.m) {
            icon().frame(width: 34)
            Spacer(minLength: 0)
            Text(value())
        }
        .font(.rounded(24, .heavy))
        .monospacedDigit()
        .foregroundStyle(Palette.plum)
        .frame(width: 136)
        .storybookPill(height: 50, horizontal: 16)
    }

    private func tile(_ item: Item, icon: String, tint: Color, label: String) -> some View {
        Button(action: { activate(item) }) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(tint)
                .shadow(color: Palette.plum.opacity(0.5), radius: 0, x: 1.5, y: 1.5)
        }
        .buttonStyle(StorybookButtonStyle(width: 88, height: 88, round: true, focused: nav.mainMenuFocus == item.rawValue))
        .onHover { if $0 { nav.mainMenuFocus = item.rawValue } }
        .help(label)
        .accessibilityLabel(label)
    }

    private var continueMission: Mission? {
        MissionLoader.mission(id: progress.continueMission)
    }

    private func activate(_ item: Item) {
        switch item {
        case .play: onContinue()
        case .map: onMap()
        case .settings: openSettings()
        case .quit: NSApplication.shared.terminate(nil)
        }
    }

    private func handleKeys() {
        let input = InputController.shared
        let focus = nav.mainMenuFocus
        var next = focus
        if input.consumeUp() { next = Item.play.rawValue }
        if input.consumeDown(), focus == Item.play.rawValue { next = Item.map.rawValue }
        if input.consumeLeft(), focus > Item.map.rawValue { next = focus - 1 }
        if input.consumeRight() { next = min(Item.quit.rawValue, max(Item.map.rawValue, focus + 1)) }
        if next != focus { nav.mainMenuFocus = next; ChiptuneEngine.shared.play(.select) }
        if input.consumeEnter(), let item = Item(rawValue: nav.mainMenuFocus) { activate(item) }
        if input.consumeFullscreen() { AppWindowController.toggleFullscreen() }
        _ = input.consumeEscape()
    }
}

/// Rounded progress track used on cards and the HUD.
struct ProgressBar: View {
    var value: Double
    var tint: Color = Palette.mint
    var height: CGFloat = 6
    var track: Color = Palette.line

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(tint).frame(width: max(height, proxy.size.width * min(1, max(0, value))))
                    .opacity(value > 0 ? 1 : 0)
            }
        }
        .frame(height: height)
    }
}

/// One word of the title logo: thick plum outline, white rim, warm vertical gradient fill.
struct LogoWord: View {
    let text: String
    let size: CGFloat
    let fill: [Color]

    var body: some View {
        let font = Font.system(size: size, weight: .black, design: .rounded)
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                let a = Double(i) / 16 * 2 * .pi
                Text(text).font(font).foregroundStyle(Palette.plum)
                    .offset(x: cos(a) * 11, y: sin(a) * 11 + 4)
            }
            ForEach(0..<12, id: \.self) { i in
                let a = Double(i) / 12 * 2 * .pi
                Text(text).font(font).foregroundStyle(.white)
                    .offset(x: cos(a) * 5, y: sin(a) * 5)
            }
            Text(text).font(font)
                .foregroundStyle(LinearGradient(colors: fill, startPoint: .top, endPoint: .bottom))
            Text(text).font(font).foregroundStyle(.white.opacity(0.55))
                .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.35)))
        }
        .fixedSize()
    }
}

/// Pink storybook button (Play) or cream round icon button, both with a plum outline and a drop edge.
struct StorybookButtonStyle: ButtonStyle {
    var width: CGFloat
    var height: CGFloat
    var round = false
    var focused = false

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: height / 2, style: .continuous)
        let fill = round ? [Color(hex: 0xFFF8EE), Palette.parchmentShade] : [Color(hex: 0xFF8CC0), Color(hex: 0xE84E8A)]
        configuration.label
            .foregroundStyle(.white)
            .shadow(color: round ? .clear : Palette.plum, radius: 0, x: 0, y: 3)
            .frame(width: width, height: height)
            .background(
                ZStack {
                    shape.fill(LinearGradient(colors: fill, startPoint: .top, endPoint: .bottom))
                    shape.inset(by: 7).stroke(.white.opacity(0.65), lineWidth: 3)
                        .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center))
                    shape.inset(by: 2).stroke(Palette.plum, lineWidth: 4)
                }
            )
            .background(shape.fill(Palette.plum).offset(y: pressed ? 2 : 7))
            .overlay(shape.inset(by: -7).stroke(focused ? Color(hex: 0xFFE98A) : .clear, lineWidth: 4))
            .scaleEffect(focused && !pressed ? 1.04 : 1)
            .offset(y: pressed ? 5 : 0)
            .padding(.bottom, 7)
            .contentShape(shape)
            .animation(.easeOut(duration: 0.1), value: pressed)
            .animation(.spring(duration: 0.25), value: focused)
    }
}
