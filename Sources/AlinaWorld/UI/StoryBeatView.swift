import SwiftUI

/// Mission briefing: level preview, objective, star goals and who Alina will meet.
struct StoryBeatView: View {
    let mission: Mission
    let onContinue: () -> Void
    let onBack: () -> Void

    private let progress = GameProgress.shared
    private var theme: WorldTheme { WorldThemes.theme(for: mission.world) }

    var body: some View {
        ZStack {
            PixelBackdrop(theme: theme, dense: theme.key == "grove")
                .ignoresSafeArea()

            HStack(alignment: .top, spacing: Space.xl) {
                briefingCard
                sideColumn
            }
            .padding(.horizontal, Space.xxl)
            .padding(.top, WindowChrome.titleBarHeight + Space.s)
            .padding(.bottom, Space.xxl)

            MenuKeyboardDriver {
                if InputController.shared.consumeEnter() { onContinue() }
                if InputController.shared.consumeEscape() { onBack() }
                if InputController.shared.consumeFullscreen() { AppWindowController.toggleFullscreen() }
            }
        }
    }

    private var briefingCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: Space.m) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .heavy))
                }
                .buttonStyle(IconButtonStyle(size: 44))
                .accessibilityLabel("Back to world map")
                VStack(alignment: .leading, spacing: 2) {
                    Eyebrow(text: "Mission \(mission.id) · \(theme.name) · \(mission.difficulty.rawValue.capitalized)", color: Palette.mintText)
                    Text(mission.title).font(.rounded(30, .bold)).foregroundStyle(Palette.ink)
                }
            }

            preview

            VStack(alignment: .leading, spacing: 6) {
                Text(mission.briefing.replacingOccurrences(of: #" ?World: \w+\.$"#, with: "", options: .regularExpression))
                    .font(.rounded(15, .medium))
                    .foregroundStyle(Palette.body)
                    .fixedSize(horizontal: false, vertical: true)
                Text(StoryCatalog.beat(for: mission).actTitle)
                    .font(.rounded(13, .semibold))
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .top, spacing: Space.l) {
                VStack(alignment: .leading, spacing: Space.s) {
                    Eyebrow(text: "Star goals")
                    starGoal(mission.objectiveLabel, earned: progress.stars(for: mission.id)[0])
                    starGoal("Finish under \(formatTime(parTime))", earned: progress.stars(for: mission.id)[1])
                    starGoal("Take no damage", earned: progress.stars(for: mission.id)[2])
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: Space.s) {
                    Eyebrow(text: "You'll meet")
                    HStack(spacing: Space.s) {
                        ForEach(enemySprites, id: \.self) { sprite in
                            PixelImage(sprite: sprite, scale: 3, theme: theme)
                                .frame(width: 64, height: 56)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.lavender))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)

            Button(action: onContinue) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("Start Mission")
                    Spacer(minLength: 0)
                    KeyCap(text: "↩", dark: true)
                }
            }
            .buttonStyle(ChunkyButtonStyle(kind: .primary, height: 56, focused: true))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .card()
    }

    private var preview: some View {
        ZStack(alignment: .bottomLeading) {
            PixelBackdrop(theme: theme, dense: theme.key == "grove", groundHeight: 64, sunPosition: 0.8)
                .frame(height: 300)
            HStack(alignment: .bottom, spacing: 0) {
                PixelImage(sprite: .alinaRun, scale: 3).padding(.leading, 48)
                Spacer()
                if mission.objective == .collectN {
                    PixelImage(sprite: .crystal, scale: 4).padding(.bottom, 70)
                    Spacer()
                }
                PixelImage(sprite: mission.objective == .defeatBoss ? .guardian : .gloomling, scale: 3)
                Spacer()
                if mission.objective == .reachFlag {
                    PixelImage(sprite: .beacon, scale: 3).padding(.trailing, 48)
                }
            }
            .padding(.bottom, 64)
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white, lineWidth: 4))
    }

    private var sideColumn: some View {
        VStack(spacing: Space.l) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your best").font(.rounded(22, .bold)).foregroundStyle(Palette.ink)
                HStack(spacing: Space.s) {
                    statTile("Stars", value: "\(progress.starCount(for: mission.id)) / 3", fill: Palette.goldSoft, text: Palette.goldText)
                    statTile("Time", value: progress.bestTime(for: mission.id).map(formatTime) ?? "—", fill: Palette.skySoft, text: Palette.skyText)
                    statTile("Petals", value: "\(progress.bestCoins(for: mission.id))", fill: Palette.pinkSoft, text: Palette.pinkText)
                }
                if let limit = mission.timeLimit {
                    Label("Timed mission: \(formatTime(CGFloat(limit)))", systemImage: "timer")
                        .font(.rounded(13, .heavy))
                        .foregroundStyle(Palette.pinkText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()

            VStack(alignment: .leading, spacing: Space.m) {
                Text("Power-ups").font(.rounded(18, .bold)).foregroundStyle(Palette.ink)
                powerUpRow(.sunbloom, "Sunbloom", "Shields one hit and breaks bricks in one bump.")
                powerUpRow(.ribbon, "Glow Ribbon", "Hold jump while falling to glide.")
                Text("Bump bloom blocks to find them.")
                    .font(.rounded(12, .semibold))
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()

            VStack(alignment: .leading, spacing: 10) {
                Text("Controls").font(.rounded(18, .bold)).foregroundStyle(Palette.ink)
                ControlsList()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
        .frame(width: 400)
    }

    private func powerUpRow(_ sprite: PixelSprite, _ title: String, _ detail: String) -> some View {
        HStack(spacing: Space.m) {
            PixelImage(sprite: sprite, scale: 3, theme: theme)
                .frame(width: 52, height: 52)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.goldSoft))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.rounded(15, .heavy)).foregroundStyle(Palette.ink)
                Text(detail).font(.rounded(13, .medium)).foregroundStyle(Palette.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func statTile(_ label: String, value: String, fill: Color, text: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.rounded(12, .heavy)).foregroundStyle(text)
            Text(value).font(.rounded(20, .bold)).foregroundStyle(text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.m)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(fill))
    }

    private func starGoal(_ text: String, earned: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "star.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(earned ? Palette.gold : Color(hex: 0xD9D0C3))
            Text(text).font(.rounded(14, .bold)).foregroundStyle(Palette.ink)
        }
    }

    private var enemySprites: [PixelSprite] {
        let rows = mission.rows.joined()
        var sprites: [PixelSprite] = []
        if rows.contains("E") { sprites.append(.gloomling) }
        if rows.contains("E") && mission.id >= 10 { sprites.append(.thornbeetle) }
        if mission.enemies.contains(where: { $0.kind.lowercased().hasPrefix("fl") }) { sprites.append(.mothwisp) }
        if mission.objective == .defeatBoss { sprites.append(.guardian) }
        return sprites.isEmpty ? [.gloomling] : sprites
    }

    /// Par time used for the second star; mirrors `GameScene.parTime`.
    private var parTime: CGFloat {
        if let limit = mission.timeLimit { return CGFloat(limit) * 0.75 }
        return CGFloat(mission.rows.first?.count ?? 100) * 0.3 + 10
    }
}

struct ControlsList: View {
    private let rows: [(String, String)] = [
        ("Move", "← → / A D"),
        ("Jump · glide", "Space / W"),
        ("Sprint", "Shift"),
        ("Pause", "Esc"),
        ("Full screen", "F")
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(rows, id: \.0) { row in
                HStack {
                    Text(row.0).font(.rounded(14, .bold)).foregroundStyle(Palette.ink)
                    Spacer()
                    KeyCap(text: row.1)
                }
            }
        }
    }
}

func formatTime(_ seconds: CGFloat) -> String {
    let total = Int(seconds.rounded(.down))
    return String(format: "%d:%02d", total / 60, total % 60)
}
