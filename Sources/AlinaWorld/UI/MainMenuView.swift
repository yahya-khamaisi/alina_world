import AppKit
import SwiftUI

struct MainMenuView: View {
    let onContinue: () -> Void
    let onMap: () -> Void

    @ObservedObject private var nav = MenuNavigationState.shared
    @Environment(\.openSettings) private var openSettings
    @State private var bob = false

    private let progress = GameProgress.shared

    private enum Item: Int, CaseIterable {
        case play, map, settings, quit
    }

    var body: some View {
        ZStack {
            PixelBackdrop(theme: WorldThemes.ordered[0])
                .ignoresSafeArea()

            GeometryReader { proxy in
                let groundTop = proxy.size.height - max(96, proxy.size.height * 0.16)
                let center = proxy.size.width / 2
                ZStack(alignment: .topLeading) {
                    PixelImage(sprite: .crystal, scale: 6)
                        .offset(x: center + 200, y: groundTop - 360 + (bob ? -10 : 6))
                    PixelImage(sprite: .petal, scale: 5)
                        .offset(x: center - 260, y: groundTop - 300 + (bob ? 6 : -6))
                    PixelImage(sprite: .petal, scale: 4)
                        .offset(x: center + 260, y: groundTop - 170 + (bob ? -4 : 4))
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    stats
                }
                title.padding(.top, Space.s)
                Spacer()
                menu
            }
            .padding(.horizontal, Space.xxl)
            .padding(.top, WindowChrome.titleBarHeight + Space.s)
            .padding(.bottom, 48)

            MenuKeyboardDriver { handleKeys() }
        }
        .onAppear {
            nav.mainMenuFocus = 0
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { bob = true }
        }
    }

    private var title: some View {
        HStack(spacing: 18) {
            Text("Alina").foregroundStyle(Palette.ink)
            Text("World").foregroundStyle(Palette.pink)
        }
        .font(.rounded(88, .heavy))
        .shadow(color: .white, radius: 0, y: 5)
        .shadow(color: Palette.edge, radius: 0, y: 9)
        .accessibilityElement(children: .combine)
    }

    private var stats: some View {
        HStack(spacing: Space.s) {
            HStack(spacing: Space.s) {
                PixelImage(sprite: .crystal, scale: 2)
                Text("\(progress.crystalsRestored)/9")
            }
            .pill()
            .accessibilityLabel("\(progress.crystalsRestored) of 9 Heart Crystals")
            HStack(spacing: Space.s) {
                Image(systemName: "star.fill").foregroundStyle(Palette.gold)
                Text("\(progress.totalStars)")
            }
            .pill()
            .accessibilityLabel("\(progress.totalStars) stars")
            HStack(spacing: Space.s) {
                PixelImage(sprite: .petal, scale: 2)
                Text("\(progress.totalPetals)")
            }
            .pill()
            .accessibilityLabel("\(progress.totalPetals) petals")
        }
        .font(.rounded(17, .bold))
        .monospacedDigit()
    }

    private var menu: some View {
        VStack(spacing: 20) {
            // Alina stands on the Play button like a platform.
            PixelImage(sprite: .alinaIdle, scale: 9)
                .padding(.bottom, -26)
                .zIndex(1)
                .accessibilityHidden(true)

            Button(action: { activate(.play) }) {
                HStack(spacing: 14) {
                    Image(systemName: "play.fill").font(.system(size: 28, weight: .bold))
                    Text("Play").font(.rounded(34, .heavy))
                    if let mission = continueMission {
                        Text(mission.code)
                            .font(.rounded(15, .heavy))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Palette.pinkText))
                    }
                }
            }
            .buttonStyle(TileButtonStyle(kind: .primary, size: 84, width: 320, focused: nav.mainMenuFocus == Item.play.rawValue))
            .onHover { if $0 { nav.mainMenuFocus = Item.play.rawValue } }
            .accessibilityLabel(continueMission.map { "Play mission \($0.code)" } ?? "Play")

            HStack(spacing: Space.l) {
                tile(.map, icon: "map.fill", label: "World map")
                tile(.settings, icon: "gearshape.fill", label: "Settings")
                tile(.quit, icon: "power", label: "Quit")
            }
        }
    }

    private func tile(_ item: Item, icon: String, label: String) -> some View {
        Button(action: { activate(item) }) {
            Image(systemName: icon)
        }
        .buttonStyle(TileButtonStyle(kind: .white, size: 64, width: 64, focused: nav.mainMenuFocus == item.rawValue))
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
