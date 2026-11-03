import SwiftUI

struct MissionCompleteView: View {
    let result: MissionResult
    let onNext: () -> Void
    let onReplay: () -> Void
    let onMap: () -> Void

    @ObservedObject private var nav = MenuNavigationState.shared
    @State private var revealed = 0

    private let progress = GameProgress.shared
    private var mission: Mission? { MissionLoader.mission(id: result.missionID) }
    private var isFinale: Bool { result.missionID == GameProgress.missionCount }
    private var restoredCrystal: Bool { mission?.objective == .defeatBoss }

    var body: some View {
        ZStack {
            PixelBackdrop(theme: WorldThemes.ordered.last!)
                .ignoresSafeArea()

            HStack(alignment: .top, spacing: Space.xl) {
                resultsCard
                journeyCard
            }
            .padding(.horizontal, Space.xxl)
            .padding(.top, WindowChrome.titleBarHeight + Space.s)
            .padding(.bottom, Space.xxl)

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
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Eyebrow(text: "Mission \(result.missionID) · \(mission?.title ?? "")", color: Palette.mintText)
                Text(isFinale ? "The Isles Shine Again!" : "Mission Complete!")
                    .font(.rounded(38, .heavy))
                    .foregroundStyle(Palette.ink)
            }

            HStack(alignment: .bottom, spacing: Space.m) {
                star(0, size: 60)
                star(1, size: 80)
                star(2, size: 60)
            }
            .accessibilityElement()
            .accessibilityLabel("\(result.starCount) of 3 stars")

            VStack(spacing: Space.s) {
                resultRow(mission?.objectiveLabel ?? "Objective", value: "Done", earned: true)
                resultRow("Time · par \(formatTime(result.parTime))", value: formatTime(result.time) + (result.newBestTime ? "  New best" : ""), earned: result.stars[1])
                resultRow("Damage taken", value: result.hits == 0 ? "None" : "\(result.hits) hit\(result.hits == 1 ? "" : "s")", earned: result.stars[2])
            }

            VStack(alignment: .leading, spacing: Space.s) {
                Eyebrow(text: "Rewards")
                HStack(spacing: Space.s) {
                    reward(.petal, "+\(result.petals)", Palette.pinkSoft, Palette.pinkText)
                    if restoredCrystal {
                        reward(.crystal, "Crystal restored", Palette.goldSoft, Palette.goldText)
                    }
                    reward(nil, "\(progress.totalStars) ★ total", Palette.lavender, Palette.violet)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Button(action: onNext) {
                    Text(isFinale ? "Back to the Isles" : "Next Mission").frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(kind: .primary, height: 56, focused: nav.overlayFocus == 0))

                Button(action: onReplay) { Image(systemName: "arrow.counterclockwise").font(.system(size: 18, weight: .heavy)) }
                    .buttonStyle(ChunkyButtonStyle(kind: .secondary, height: 56, focused: nav.overlayFocus == 1, fullWidth: false))
                    .help("Replay")
                    .accessibilityLabel("Replay mission")
                Button(action: onMap) { Image(systemName: "map.fill").font(.system(size: 18, weight: .heavy)) }
                    .buttonStyle(ChunkyButtonStyle(kind: .secondary, height: 56, focused: nav.overlayFocus == 2, fullWidth: false))
                    .help("World map")
                    .accessibilityLabel("World map")
            }
        }
        .frame(width: 460)
        .frame(maxHeight: .infinity)
        .card(padding: Space.xxl)
    }

    private var journeyCard: some View {
        let theme = mission.map { WorldThemes.theme(for: $0.world) } ?? WorldThemes.ordered[0]
        let world = mission.map { WorldThemes.index(of: $0.world) } ?? 0

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("Journey").font(.rounded(24, .bold)).foregroundStyle(Palette.ink)
                Spacer()
                Text("\(Int(progress.completion * 100))% complete").font(.rounded(13, .heavy)).foregroundStyle(Palette.muted)
            }

            ZStack(alignment: .bottom) {
                PixelBackdrop(theme: theme, dense: theme.key == "grove", groundHeight: 48, sunPosition: 0.78)
                    .frame(height: 220)
                PixelImage(sprite: .alinaJump, scale: 6)
                    .padding(.bottom, 62)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(alignment: .leading, spacing: Space.s) {
                Eyebrow(text: "Heart Crystals")
                HStack(spacing: 6) {
                    ForEach(0..<9, id: \.self) { i in
                        PixelImage(sprite: .crystal, scale: 3)
                            .opacity(i < progress.crystalsRestored ? 1 : 0.2)
                            .saturation(i < progress.crystalsRestored ? 1 : 0)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.sand))
                    }
                }
            }

            VStack(alignment: .leading, spacing: Space.s) {
                Eyebrow(text: "\(theme.name)")
                ForEach((world * 3 + 1)...(world * 3 + 3), id: \.self) { id in
                    if let m = MissionLoader.mission(id: id) {
                        let stars = progress.stars(for: id)
                        HStack {
                            Text("\(id) · \(m.title)").font(.rounded(14, .heavy))
                                .foregroundStyle(progress.isUnlocked(missionID: id) ? Palette.ink : Palette.muted)
                            Spacer()
                            HStack(spacing: 2) {
                                ForEach(0..<3, id: \.self) { i in
                                    Image(systemName: "star.fill").font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(stars[i] ? Palette.gold : Color(hex: 0xD9D0C3))
                                }
                            }
                        }
                        .padding(.horizontal, Space.m)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(id == result.missionID ? Palette.pinkSoft : Palette.sand))
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .card()
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

    private func resultRow(_ label: String, value: String, earned: Bool) -> some View {
        HStack {
            Image(systemName: "star.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(earned ? Palette.gold : Color(hex: 0xD9D0C3))
            Text(label).font(.rounded(15, .bold)).foregroundStyle(Palette.ink)
            Spacer()
            Text(value).font(.rounded(15, .heavy)).foregroundStyle(earned ? Color(hex: 0xA86A00) : Palette.muted)
        }
        .padding(.horizontal, Space.l)
        .padding(.vertical, Space.m)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.sand))
    }

    private func reward(_ sprite: PixelSprite?, _ text: String, _ fill: Color, _ color: Color) -> some View {
        HStack(spacing: Space.s) {
            if let sprite { PixelImage(sprite: sprite, scale: 2) }
            Text(text).font(.rounded(14, .heavy)).foregroundStyle(color)
        }
        .padding(.horizontal, Space.m)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(fill))
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

    var body: some View {
        ZStack {
            PixelBackdrop(theme: mission.map { WorldThemes.theme(for: $0.world) } ?? WorldThemes.ordered[0])
                .ignoresSafeArea()
            Palette.ink.opacity(0.25).ignoresSafeArea()

            VStack(spacing: 20) {
                PixelImage(sprite: .alinaFall, scale: 6)
                VStack(spacing: 6) {
                    Text("Not this time").font(.rounded(34, .heavy)).foregroundStyle(Palette.ink)
                    Text(reason).font(.rounded(15, .medium)).foregroundStyle(Palette.body).multilineTextAlignment(.center)
                    Text("Mission \(missionID) · \(mission?.title ?? "")").font(.rounded(13, .bold)).foregroundStyle(Palette.muted)
                }
                VStack(spacing: 10) {
                    Button(action: onRetry) {
                        HStack { Image(systemName: "arrow.counterclockwise"); Text("Try Again"); Spacer(); KeyCap(text: "↩", dark: true) }
                    }
                    .buttonStyle(ChunkyButtonStyle(kind: .primary, height: 56, focused: nav.overlayFocus == 0))
                    .onHover { if $0 { nav.overlayFocus = 0 } }
                    Button(action: onMap) {
                        HStack { Image(systemName: "map.fill").foregroundStyle(Palette.violet); Text("World Map") }
                    }
                    .buttonStyle(ChunkyButtonStyle(kind: .secondary, height: 50, focused: nav.overlayFocus == 1))
                    .onHover { if $0 { nav.overlayFocus = 1 } }
                }
                Text("Tip: bloom blocks hide a Sunbloom — it shields you from one hit.")
                    .font(.rounded(12, .semibold))
                    .foregroundStyle(Palette.muted)
            }
            .frame(width: 400)
            .card(padding: Space.xxl)

            MenuKeyboardDriver {
                let input = InputController.shared
                if input.consumeUp() { nav.overlayFocus = 0 }
                if input.consumeDown() { nav.overlayFocus = 1 }
                if input.consumeEnter() { nav.overlayFocus == 0 ? onRetry() : onMap() }
                if input.consumeEscape() { onMap() }
            }
        }
        .onAppear { nav.overlayFocus = 0 }
    }
}
