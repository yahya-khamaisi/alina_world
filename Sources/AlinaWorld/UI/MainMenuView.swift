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
                ZStack(alignment: .topLeading) {
                    PixelImage(sprite: .alinaIdle, scale: 12)
                        .offset(x: proxy.size.width * 0.6, y: groundTop - 216)
                    PixelImage(sprite: .crystal, scale: 7)
                        .offset(x: proxy.size.width * 0.6 + 210, y: groundTop - 290 + (bob ? -10 : 6))
                    PixelImage(sprite: .petal, scale: 5)
                        .offset(x: proxy.size.width * 0.6 - 110, y: groundTop - 170 + (bob ? 6 : -6))
                    PixelImage(sprite: .petal, scale: 4)
                        .offset(x: proxy.size.width * 0.6 + 240, y: groundTop - 150 + (bob ? -4 : 4))
                }
            }
            .ignoresSafeArea()

            HStack(alignment: .top, spacing: Space.xl) {
                menuCard
                Spacer(minLength: 0)
                statusColumn
            }
            .padding(.horizontal, 40)
            .padding(.top, WindowChrome.titleBarHeight + 12)
            .padding(.bottom, 40)

            MenuKeyboardDriver { handleKeys() }
        }
        .onAppear {
            nav.mainMenuFocus = 0
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { bob = true }
        }
    }

    private var menuCard: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: Space.m) {
                Text("A Lumen Isles Adventure".uppercased())
                    .font(.rounded(12, .heavy))
                    .tracking(1)
                    .foregroundStyle(Palette.goldText)
                    .padding(.horizontal, Space.m)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: 0xFFF1D6)))
                VStack(alignment: .leading, spacing: -6) {
                    Text("Alina").foregroundStyle(Palette.ink)
                    Text("World").foregroundStyle(Palette.pink)
                }
                .font(.rounded(60, .heavy))
            }

            VStack(spacing: Space.m) {
                Button(action: { activate(.play) }) {
                    HStack(spacing: 14) {
                        Image(systemName: "play.fill").font(.system(size: 20, weight: .bold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(continueTitle).font(.rounded(22, .bold))
                            Text(continueSubtitle)
                                .font(.rounded(13, .bold))
                                .foregroundStyle(Color(hex: 0xFFE3EF))
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        KeyCap(text: "↩", dark: true)
                    }
                }
                .buttonStyle(ChunkyButtonStyle(kind: .primary, height: 72, focused: nav.mainMenuFocus == Item.play.rawValue))
                .onHover { if $0 { nav.mainMenuFocus = Item.play.rawValue } }

                menuButton(.map, title: "World Map", icon: "map.fill", tint: Palette.sky,
                           trailing: "\(progress.totalStars) ★")
                menuButton(.settings, title: "Settings", icon: "gearshape.fill", tint: Color(hex: 0x8E7BD9), trailing: "⌘ ,")
                menuButton(.quit, title: "Quit", icon: "xmark", tint: Palette.muted, trailing: "⌘ Q")
            }

            Spacer(minLength: 0)

            HStack(spacing: Space.s) {
                KeyCap(text: "↑ ↓ Navigate")
                KeyCap(text: "↩ Select")
                KeyCap(text: "F Full Screen")
            }
        }
        .frame(width: 380, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .card(padding: Space.xxl)
    }

    private func menuButton(_ item: Item, title: String, icon: String, tint: Color, trailing: String) -> some View {
        Button(action: { activate(item) }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(tint))
                Text(title)
                Spacer(minLength: 0)
                Text(trailing).font(.rounded(13, .heavy)).foregroundStyle(Palette.muted)
            }
        }
        .buttonStyle(ChunkyButtonStyle(kind: .secondary, focused: nav.mainMenuFocus == item.rawValue))
        .onHover { if $0 { nav.mainMenuFocus = item.rawValue } }
    }

    private var statusColumn: some View {
        VStack(alignment: .trailing, spacing: Space.m) {
            HStack(spacing: Space.s) {
                HStack(spacing: Space.s) {
                    PixelImage(sprite: .crystal, scale: 2)
                    Text("\(progress.crystalsRestored) / 9 Crystals")
                }
                .pill()
                HStack(spacing: Space.s) {
                    PixelImage(sprite: .petal, scale: 2)
                    Text("\(progress.totalPetals.formatted()) Petals")
                }
                .pill()
            }

            HStack(spacing: Space.m) {
                Text("1")
                    .font(.rounded(18, .bold))
                    .foregroundStyle(Palette.goldText)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: 0xFFF1D6)))
                VStack(alignment: .leading, spacing: 5) {
                    Text("Journey · \(Int(progress.completion * 100))%")
                        .font(.rounded(14, .heavy))
                        .foregroundStyle(Palette.ink)
                    ProgressBar(value: progress.completion, tint: Palette.mint)
                        .frame(width: 160)
                    Text(playTimeLabel)
                        .font(.rounded(12, .semibold))
                        .foregroundStyle(Palette.muted)
                }
            }
            .padding(.vertical, Space.m)
            .padding(.leading, Space.m)
            .padding(.trailing, Space.l)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white)
                    .shadow(color: Palette.edge, radius: 0, y: 4)
            )
        }
    }

    private var continueMissionInfo: Mission? {
        MissionLoader.mission(id: progress.continueMission)
    }

    private var continueTitle: String {
        progress.unlockedMission <= 1 && !progress.isCompleted(missionID: 1) ? "Start Journey" : "Continue"
    }

    private var continueSubtitle: String {
        guard let mission = continueMissionInfo else { return "" }
        let world = WorldThemes.theme(for: mission.world)
        return "\(world.name) · Mission \(mission.id)"
    }

    private var playTimeLabel: String {
        let minutes = Int(progress.totalPlayTime / 60)
        if minutes == 0 { return "A new adventure awaits" }
        return minutes < 60 ? "\(minutes) min played" : "\(minutes / 60) h \(minutes % 60) m played"
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
        if input.consumeUp() { nav.mainMenuFocus = max(0, nav.mainMenuFocus - 1) }
        if input.consumeDown() { nav.mainMenuFocus = min(Item.allCases.count - 1, nav.mainMenuFocus + 1) }
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
