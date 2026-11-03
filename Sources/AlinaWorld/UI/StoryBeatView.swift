import SwiftUI

/// Mission briefing: level preview, goal chips and who Alina will meet.
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
            Palette.cream.opacity(0.4).ignoresSafeArea()

            briefingCard

            VStack {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left").font(.system(size: 18, weight: .heavy))
                    }
                    .buttonStyle(IconButtonStyle(size: 52))
                    .help("Back (Esc)")
                    .accessibilityLabel("Back to world map")
                    Spacer()
                }
                Spacer()
            }
            .padding(.horizontal, Space.xxl)
            .padding(.top, WindowChrome.titleBarHeight + Space.s)

            MenuKeyboardDriver {
                if InputController.shared.consumeEnter() { onContinue() }
                if InputController.shared.consumeEscape() { onBack() }
                if InputController.shared.consumeFullscreen() { AppWindowController.toggleFullscreen() }
            }
        }
    }

    private var briefingCard: some View {
        let stars = progress.stars(for: mission.id)

        return VStack(spacing: 22) {
            preview

            HStack(spacing: Space.m) {
                goalChip(earned: stars[0])
                StatChip(value: formatTime(parTime), fill: Palette.sand, height: 60) {
                    starIcon(stars[1])
                    Image(systemName: "timer").font(.system(size: 18, weight: .bold))
                }
                .help("Finish under \(formatTime(parTime))")
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Star for finishing under \(formatTime(parTime))")
                StatChip(fill: Palette.sand, height: 60) {
                    starIcon(stars[2])
                    PixelImage(sprite: .heart, scale: 3)
                }
                .help("Take no damage")
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Star for taking no damage")

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    ForEach(enemySprites, id: \.self) { sprite in
                        PixelImage(sprite: sprite, scale: 3, theme: theme)
                            .frame(width: 60, height: 60)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.lavender))
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("Enemies in this mission")
            }

            Button(action: onContinue) {
                HStack(spacing: 14) {
                    Image(systemName: "play.fill").font(.system(size: 24, weight: .bold))
                    Text("Go!").font(.rounded(30, .heavy))
                }
            }
            .buttonStyle(TileButtonStyle(kind: .primary, size: 72, focused: true))
            .accessibilityLabel("Start mission")
        }
        .frame(width: 720)
        .card(padding: Space.xl, radius: 32)
    }

    private var preview: some View {
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .bottomLeading) {
                PixelBackdrop(theme: theme, dense: theme.key == "grove", groundHeight: 56, sunPosition: 0.8)
                    .frame(height: 260)
                HStack(alignment: .bottom, spacing: 0) {
                    PixelImage(sprite: .alinaRun, scale: 4).padding(.leading, 56)
                    Spacer()
                    if mission.objective == .collectN {
                        PixelImage(sprite: .crystal, scale: 5).padding(.bottom, 80)
                        Spacer()
                    }
                    PixelImage(sprite: mission.objective == .defeatBoss ? .guardian : .gloomling, scale: mission.objective == .defeatBoss ? 2 : 4, theme: theme)
                    Spacer()
                    if mission.objective == .reachFlag {
                        PixelImage(sprite: .beacon, scale: 4).padding(.trailing, 56)
                    }
                }
                .padding(.bottom, 56)
            }

            HStack(spacing: 10) {
                Text(mission.code)
                    .font(.rounded(18, .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 36)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(hex: theme.grass.2)))
                Text(mission.title).font(.rounded(24, .bold)).foregroundStyle(Palette.ink)
            }
            .padding(Space.s)
            .padding(.trailing, Space.s)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white).shadow(color: Palette.ink.opacity(0.15), radius: 0, y: 4))
            .padding(Space.l)
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    /// The objective as a sprite and a count (shards ×N, guardian ×3) or the beacon alone.
    private func goalChip(earned: Bool) -> some View {
        let value: String
        switch mission.objective {
        case .collectN: value = "×\(mission.collectRequired)"
        case .defeatBoss: value = "×3"
        case .reachFlag: value = ""
        }
        return StatChip(value: value, fill: Palette.goldSoft, text: Palette.goldText, height: 60, size: 24) {
            PixelImage(sprite: mission.goalSprite, scale: mission.objective == .defeatBoss ? 2 : 3, theme: theme)
            if let limit = mission.timeLimit {
                Text(formatTime(CGFloat(limit)))
                    .font(.rounded(13, .heavy))
                    .foregroundStyle(Palette.pinkText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Palette.pinkSoft))
            }
        }
        .help(mission.objectiveLabel + (mission.timeLimit.map { " before \(formatTime(CGFloat($0)))" } ?? ""))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mission.objectiveLabel)
    }

    private func starIcon(_ earned: Bool) -> some View {
        Image(systemName: "star.fill")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(earned ? Palette.gold : Color(hex: 0xD9D0C3))
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

func formatTime(_ seconds: CGFloat) -> String {
    let total = Int(seconds.rounded(.down))
    return String(format: "%d:%02d", total / 60, total % 60)
}
