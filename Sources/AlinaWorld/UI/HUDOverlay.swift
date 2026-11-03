import SwiftUI

struct HUDOverlay: View {
    let mission: Mission
    let hud: HUDSnapshot
    let showHint: Bool
    let onPause: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                HStack(alignment: .top) {
                    statusCard
                    Spacer()
                    rightCluster
                }
                objective
            }
            Spacer()
            ZStack(alignment: .bottom) {
                if mission.objective == .reachFlag {
                    beaconProgress
                }
                HStack {
                    if showHint {
                        ControlStrip(entries: Array(ControlStrip.gameplay.dropLast()))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, Space.xl)
        .padding(.vertical, 20)
    }

    /// Hearts, then any power-ups Alina is carrying.
    private var statusCard: some View {
        HStack(spacing: 6) {
            HStack(spacing: 5) {
                ForEach(0..<hud.maxHearts, id: \.self) { i in
                    PixelImage(sprite: i < hud.hearts ? .heart : .heartEmpty, scale: 4)
                }
            }
            .scaleEffect(hud.hearts == 1 ? 1.08 : 1)
            .animation(hud.hearts == 1 ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default, value: hud.hearts)
            .accessibilityElement()
            .accessibilityLabel("Hearts \(hud.hearts) of \(hud.maxHearts)")

            if hud.bloom || hud.ribbon {
                Rectangle().fill(Palette.line).frame(width: 2, height: 28).padding(.horizontal, 6)
                if hud.bloom { powerUp(.sunbloom, label: "Sunbloom") }
                if hud.ribbon { powerUp(.ribbon, label: "Glow Ribbon") }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(hudBackground(radius: 18))
    }

    private func powerUp(_ sprite: PixelSprite, label: String) -> some View {
        PixelImage(sprite: sprite, scale: 3)
            .transition(.scale.combined(with: .opacity))
            .help(label)
            .accessibilityLabel("\(label) active")
    }

    /// Top-center goal: one crystal per shard, guardian pips, or nothing for the beacon run.
    @ViewBuilder
    private var objective: some View {
        switch mission.objective {
        case .collectN:
            let target = hud.shardTarget ?? mission.collectRequired
            HStack(spacing: 8) {
                ForEach(0..<target, id: \.self) { i in
                    PixelImage(sprite: .crystal, scale: 3)
                        .opacity(i < hud.shards ? 1 : 0.3)
                        .saturation(i < hud.shards ? 1 : 0)
                        .scaleEffect(i < hud.shards ? 1 : 0.85)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: hud.shards)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(hudBackground(radius: 18))
            .accessibilityElement()
            .accessibilityLabel("Heart Shards \(hud.shards) of \(target)")
        case .defeatBoss:
            HStack(spacing: 10) {
                PixelImage(sprite: .guardian, scale: 2)
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < hud.bossHits ? Palette.pink : Palette.line)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().strokeBorder(i < hud.bossHits ? Palette.pinkDeep : Color(hex: 0xD9D0C3), lineWidth: 2))
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(hudBackground(radius: 18))
            .accessibilityElement()
            .accessibilityLabel("Guardian stomped \(hud.bossHits) of 3 times")
        case .reachFlag:
            EmptyView()
        }
    }

    private var rightCluster: some View {
        HStack(spacing: Space.s) {
            HStack(spacing: Space.s) {
                PixelImage(sprite: .petal, scale: 3)
                Text("\(hud.petals)")
            }
            .modifier(HUDPill())
            .accessibilityLabel("\(hud.petals) petals")

            HStack(spacing: Space.s) {
                Image(systemName: hud.countdown ? "timer" : "clock").font(.system(size: 17, weight: .bold))
                Text(String(format: "%d:%02d", hud.seconds / 60, hud.seconds % 60))
            }
            .foregroundStyle(hud.countdown && hud.seconds <= 15 ? Palette.pinkText : Palette.ink)
            .modifier(HUDPill())

            Button(action: onPause) {
                Image(systemName: "pause.fill").font(.system(size: 18, weight: .heavy))
            }
            .buttonStyle(IconButtonStyle(size: 52))
            .help("Pause (Esc)")
            .accessibilityLabel("Pause")
        }
    }

    private var beaconProgress: some View {
        GeometryReader { proxy in
            let x = proxy.size.width * min(1, max(0, hud.progress))
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.75))
                Capsule().fill(Palette.mint).frame(width: max(12, x))
                Capsule().fill(Palette.gold).frame(width: 4, height: 20).offset(x: proxy.size.width / 2 - 2)
                Circle().fill(Palette.pink)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 4))
                    .offset(x: x - 12)
                PixelImage(sprite: .beacon, scale: 2)
                    .offset(x: proxy.size.width - 2, y: -10)
            }
        }
        .frame(width: 480, height: 12)
        .shadow(color: Palette.ink.opacity(0.12), radius: 0, y: 3)
        .padding(.bottom, Space.s)
        .accessibilityElement()
        .accessibilityLabel("\(Int(hud.progress * 100)) percent to the beacon")
    }

    private func hudBackground(radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(.white.opacity(0.92))
            .shadow(color: Palette.ink.opacity(0.15), radius: 0, y: 4)
    }
}

private struct HUDPill: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.rounded(21, .bold))
            .monospacedDigit()
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, Space.l)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.92))
                    .shadow(color: Palette.ink.opacity(0.15), radius: 0, y: 4)
            )
    }
}

struct PauseOverlay: View {
    let mission: Mission
    let hud: HUDSnapshot
    let onResume: () -> Void
    let onCheckpoint: () -> Void
    let onRestart: () -> Void
    let onQuit: () -> Void

    @ObservedObject private var nav = MenuNavigationState.shared
    @Environment(\.openSettings) private var openSettings

    /// Focus 0 is Resume; 1…4 are the icon tiles left to right.
    private var tiles: [(icon: String, label: String, kind: TileButtonStyle.Kind, action: () -> Void)] {
        [
            ("flag.fill", "Restart from checkpoint", .secondary, onCheckpoint),
            ("arrow.counterclockwise", "Restart mission", .secondary, onRestart),
            ("gearshape.fill", "Settings", .secondary, { openSettings() }),
            ("map.fill", "Quit to world map", .danger, onQuit)
        ]
    }

    var body: some View {
        ZStack {
            Palette.ink.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: Space.xl) {
                    Text("Paused").font(.rounded(40, .heavy)).foregroundStyle(Palette.ink)

                    HStack(spacing: 10) {
                        if mission.objective == .collectN {
                            StatChip(value: "\(hud.shards)/\(hud.shardTarget ?? mission.collectRequired)", fill: Palette.goldSoft, text: Palette.goldText) {
                                PixelImage(sprite: .crystal, scale: 2)
                            }
                        } else {
                            StatChip(value: "\(Int(hud.progress * 100))%", fill: Palette.mintSoft, text: Palette.mintText) {
                                PixelImage(sprite: mission.goalSprite, scale: 2)
                            }
                        }
                        StatChip(value: "\(hud.petals)", fill: Palette.pinkSoft, text: Palette.pinkText) {
                            PixelImage(sprite: .petal, scale: 2)
                        }
                        StatChip(value: String(format: "%d:%02d", hud.seconds / 60, hud.seconds % 60), fill: Palette.skySoft, text: Palette.skyText) {
                            Image(systemName: hud.countdown ? "timer" : "clock").font(.system(size: 17, weight: .bold))
                        }
                    }

                    VStack(spacing: Space.m) {
                        Button(action: onResume) {
                            Image(systemName: "play.fill").font(.system(size: 30, weight: .bold))
                        }
                        .buttonStyle(TileButtonStyle(kind: .primary, size: 72, focused: nav.overlayFocus == 0))
                        .onHover { if $0 { nav.overlayFocus = 0 } }
                        .help("Resume (Esc)")
                        .accessibilityLabel("Resume")

                        HStack(spacing: Space.m) {
                            ForEach(Array(tiles.enumerated()), id: \.offset) { index, tile in
                                Button(action: tile.action) { Image(systemName: tile.icon) }
                                    .buttonStyle(TileButtonStyle(kind: tile.kind, size: 64, focused: nav.overlayFocus == index + 1))
                                    .onHover { if $0 { nav.overlayFocus = index + 1 } }
                                    .help(tile.label)
                                    .accessibilityLabel(tile.label)
                            }
                        }
                    }
                }
                .frame(width: 360)
                .card(padding: Space.xxl, radius: 32)

                ControlStrip()
            }

            MenuKeyboardDriver { handleKeys() }
        }
        .onAppear { nav.overlayFocus = 0 }
    }

    private func handleKeys() {
        let input = InputController.shared
        if input.consumeEscape() { _ = input.consumePause(); onResume(); return }
        let focus = nav.overlayFocus
        if input.consumeUp() { nav.overlayFocus = 0 }
        if input.consumeDown(), focus == 0 { nav.overlayFocus = 1 }
        if input.consumeLeft(), focus > 1 { nav.overlayFocus = focus - 1 }
        if input.consumeRight() { nav.overlayFocus = min(tiles.count, max(1, focus + 1)) }
        if input.consumeEnter() {
            if nav.overlayFocus == 0 { onResume() } else { tiles[nav.overlayFocus - 1].action() }
        }
        if input.consumeFullscreen() { AppWindowController.toggleFullscreen() }
    }
}
