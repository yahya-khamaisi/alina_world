import SwiftUI

struct MissionCompleteView: View {
    let result: MissionResult
    let onNext: () -> Void
    let onReplay: () -> Void
    let onMap: () -> Void

    @ObservedObject private var nav = MenuNavigationState.shared
    @State private var revealed = 0

    private var mission: Mission? { MissionLoader.mission(id: result.missionID) }
    private var nextMission: Mission? { MissionLoader.mission(id: result.missionID + 1) }
    private var isFinale: Bool { result.missionID == GameProgress.missionCount }
    private var restoredCrystal: Bool { mission?.objective == .defeatBoss }
    private var theme: WorldTheme { mission.map { WorldThemes.theme(for: $0.world) } ?? WorldThemes.ordered[0] }

    var body: some View {
        ZStack {
            PixelBackdrop(theme: theme, dense: theme.key == "grove")
                .ignoresSafeArea()

            GeometryReader { proxy in
                let groundTop = proxy.size.height - max(96, proxy.size.height * 0.16)
                ZStack(alignment: .topLeading) {
                    PixelImage(sprite: .alinaJump, scale: 7)
                        .offset(x: proxy.size.width * 0.16, y: groundTop - 170)
                    PixelImage(sprite: restoredCrystal ? .crystal : .beacon, scale: 7)
                        .offset(x: proxy.size.width * 0.78, y: groundTop - (restoredCrystal ? 160 : 112))
                }
            }
            .ignoresSafeArea()

            resultsCard

            MenuKeyboardDriver { handleKeys() }
        }
        .onAppear {
            nav.overlayFocus = 0
            for i in 1...3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 * Double(i)) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { revealed = i }
                }
            }
        }
    }

    private var resultsCard: some View {
        VStack(spacing: 22) {
            Text(isFinale ? "The Isles Shine!" : "Clear!")
                .font(.rounded(44, .heavy))
                .foregroundStyle(Palette.ink)

            HStack(alignment: .bottom, spacing: 14) {
                star(0, size: 64)
                star(1, size: 86)
                star(2, size: 64)
            }
            .accessibilityElement()
            .accessibilityLabel("\(result.starCount) of 3 stars")

            HStack(spacing: 10) {
                StatChip(value: formatTime(result.time),
                         fill: result.stars[1] ? Palette.mintSoft : Palette.sand,
                         text: result.stars[1] ? Palette.mintText : Palette.body, height: 52, size: 22) {
                    Image(systemName: "timer").font(.system(size: 18, weight: .bold))
                    if result.newBestTime {
                        Image(systemName: "arrow.up").font(.system(size: 14, weight: .black))
                    }
                }
                .help("Par \(formatTime(result.parTime))")
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Time \(formatTime(result.time))\(result.newBestTime ? ", new best" : "")")

                StatChip(value: "+\(result.petals)", fill: Palette.pinkSoft, text: Palette.pinkText, height: 52, size: 22) {
                    PixelImage(sprite: .petal, scale: 3)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(result.petals) petals")

                StatChip(value: result.hits == 0 ? "" : "−\(result.hits)",
                         fill: result.stars[2] ? Palette.goldSoft : Palette.sand,
                         text: Palette.body, height: 52, size: 22) {
                    PixelImage(sprite: result.hits == 0 ? .heart : .heartEmpty, scale: 3)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(result.hits == 0 ? "No damage" : "\(result.hits) hits taken")

                if restoredCrystal {
                    StatChip(fill: Palette.goldSoft, height: 52) {
                        PixelImage(sprite: .crystal, scale: 3)
                    }
                    .accessibilityLabel("Heart Crystal restored")
                }
            }

            HStack(spacing: Space.m) {
                Button(action: onNext) {
                    HStack(spacing: 12) {
                        if isFinale {
                            Image(systemName: "map.fill")
                        } else {
                            Text(nextMission?.code ?? "")
                            Image(systemName: "arrow.right").font(.system(size: 24, weight: .heavy))
                        }
                    }
                }
                .buttonStyle(TileButtonStyle(kind: .primary, size: 72, focused: nav.overlayFocus == 0))
                .onHover { if $0 { nav.overlayFocus = 0 } }
                .accessibilityLabel(isFinale ? "Back to the isles" : "Next mission")

                Button(action: onReplay) { Image(systemName: "arrow.counterclockwise") }
                    .buttonStyle(TileButtonStyle(kind: .secondary, size: 72, width: 72, focused: nav.overlayFocus == 1))
                    .onHover { if $0 { nav.overlayFocus = 1 } }
                    .help("Replay")
                    .accessibilityLabel("Replay mission")
                Button(action: onMap) { Image(systemName: "map.fill") }
                    .buttonStyle(TileButtonStyle(kind: .secondary, size: 72, width: 72, focused: nav.overlayFocus == 2))
                    .onHover { if $0 { nav.overlayFocus = 2 } }
                    .help("World map")
                    .accessibilityLabel("World map")
            }
        }
        .frame(width: 420)
        .card(padding: Space.xxl, radius: 32)
    }

    private func star(_ index: Int, size: CGFloat) -> some View {
        let earned = result.stars[index]
        let shown = revealed > index
        return Image(systemName: "star.fill")
            .font(.system(size: size, weight: .black))
            .foregroundStyle(earned && shown ? Palette.gold : Color(hex: 0xEDE5D8))
            .shadow(color: earned && shown ? Color(hex: 0xD9901A) : .clear, radius: 0, y: 3)
            .scaleEffect(shown ? 1 : 0.4)
            .opacity(shown ? 1 : 0.5)
    }

    private func handleKeys() {
        let input = InputController.shared
        if input.consumeLeft() || input.consumeUp() { nav.overlayFocus = max(0, nav.overlayFocus - 1) }
        if input.consumeRight() || input.consumeDown() { nav.overlayFocus = min(2, nav.overlayFocus + 1) }
        if input.consumeEnter() {
            switch nav.overlayFocus {
            case 0: onNext()
            case 1: onReplay()
            default: onMap()
            }
        }
        if input.consumeEscape() { onMap() }
        if input.consumeFullscreen() { AppWindowController.toggleFullscreen() }
    }
}

struct DefeatView: View {
    let missionID: Int
    let reason: String
    let onRetry: () -> Void
    let onMap: () -> Void

    @ObservedObject private var nav = MenuNavigationState.shared

    private var mission: Mission? { MissionLoader.mission(id: missionID) }
    private var timedOut: Bool { reason.localizedCaseInsensitiveContains("light faded") }

    var body: some View {
        ZStack {
            PixelBackdrop(theme: mission.map { WorldThemes.theme(for: $0.world) } ?? WorldThemes.ordered[0])
                .ignoresSafeArea()
            Palette.ink.opacity(0.25).ignoresSafeArea()

            VStack(spacing: 22) {
                PixelImage(sprite: .alinaFall, scale: 6)
                Text("Oops!").font(.rounded(40, .heavy)).foregroundStyle(Palette.ink)

                Group {
                    if timedOut {
                        StatChip(value: "0:00", fill: Palette.skySoft, text: Palette.skyText, height: 52, size: 22) {
                            Image(systemName: "timer").font(.system(size: 18, weight: .bold))
                        }
                    } else {
                        StatChip(fill: Palette.pinkSoft, height: 52) {
                            ForEach(0..<3, id: \.self) { _ in PixelImage(sprite: .heartEmpty, scale: 3) }
                        }
                    }
                }
                .help(reason)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(reason)

                HStack(spacing: Space.m) {
                    Button(action: onRetry) {
                        Image(systemName: "arrow.counterclockwise").font(.system(size: 28, weight: .heavy))
                    }
                    .buttonStyle(TileButtonStyle(kind: .primary, size: 72, focused: nav.overlayFocus == 0))
                    .onHover { if $0 { nav.overlayFocus = 0 } }
                    .help("Try again (↩)")
                    .accessibilityLabel("Try again")

                    Button(action: onMap) { Image(systemName: "map.fill") }
                        .buttonStyle(TileButtonStyle(kind: .secondary, size: 72, width: 72, focused: nav.overlayFocus == 1))
                        .onHover { if $0 { nav.overlayFocus = 1 } }
                        .help("World map")
                        .accessibilityLabel("World map")
                }
            }
            .frame(width: 320)
            .card(padding: Space.xxl, radius: 32)

            MenuKeyboardDriver {
                let input = InputController.shared
                if input.consumeLeft() || input.consumeUp() { nav.overlayFocus = 0 }
                if input.consumeRight() || input.consumeDown() { nav.overlayFocus = 1 }
                if input.consumeEnter() { nav.overlayFocus == 0 ? onRetry() : onMap() }
                if input.consumeEscape() { onMap() }
            }
        }
        .onAppear { nav.overlayFocus = 0 }
    }
}
