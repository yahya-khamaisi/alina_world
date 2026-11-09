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
                    VStack(alignment: .leading, spacing: 8) {
                        statusCard
                        WeatherBadge(weather: mission.weather)
                    }
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
                        .shadow(color: Palette.plum.opacity(0.35), radius: 0, y: 3)
                }
            }
            .scaleEffect(hud.hearts == 1 ? 1.08 : 1)
            .animation(hud.hearts == 1 ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default, value: hud.hearts)
            // Losing (or gaining) a heart jolts the row.
            .keyframeAnimator(initialValue: CGFloat(0), trigger: hud.hearts) { content, x in
                content.offset(x: x)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(-9, duration: 0.05); CubicKeyframe(8, duration: 0.07); CubicKeyframe(-5, duration: 0.07)
                    CubicKeyframe(3, duration: 0.07); CubicKeyframe(0, duration: 0.08)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Hearts \(hud.hearts) of \(hud.maxHearts)")

            if hud.bloom || hud.ribbon {
                HStack(spacing: 8) {
                    if hud.bloom { powerUp(.sunbloom, label: "Sunbloom") }
                    if hud.ribbon { powerUp(.ribbon, label: "Glow Ribbon") }
                }
                .storybookPill(height: 44, horizontal: 12)
                .padding(.leading, 8)
            }
        }
        .frame(height: 52)
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
            HStack(spacing: 10) {
                PixelImage(sprite: .petal, scale: 3)
                    // Each pickup spins the petal icon once.
                    .keyframeAnimator(initialValue: Angle.zero, trigger: hud.petals) { content, angle in
                        content.rotationEffect(angle)
                    } keyframes: { _ in
                        KeyframeTrack { CubicKeyframe(.degrees(-30), duration: 0.08); SpringKeyframe(.zero, duration: 0.35, spring: .bouncy) }
                    }
                Text("\(hud.petals)")
                    .contentTransition(.numericText(value: Double(hud.petals)))
                    .animation(.spring(duration: 0.25), value: hud.petals)
            }
            .modifier(HUDPill())
            // ...and bumps the whole pill as the petal lands in it.
            .keyframeAnimator(initialValue: CGFloat(1), trigger: hud.petals) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack { CubicKeyframe(1, duration: 0.45); SpringKeyframe(1.18, duration: 0.08); SpringKeyframe(1, duration: 0.3, spring: .bouncy) }
            }
            .accessibilityLabel("\(hud.petals) petals")

            HStack(spacing: Space.s) {
                PixelImage(sprite: .clock, scale: 3)
                Text(String(format: "%d:%02d", hud.seconds / 60, hud.seconds % 60))
                    .contentTransition(.numericText(countsDown: hud.countdown))
                    .animation(.snappy(duration: 0.2), value: hud.seconds)
            }
            .modifier(HUDPill(tint: hud.countdown && hud.seconds <= 15 ? Palette.pinkText : nil))
            // The last fifteen seconds of a countdown throb on every tick.
            .keyframeAnimator(initialValue: CGFloat(1), trigger: hud.countdown && hud.seconds <= 15 ? hud.seconds : -1) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack { SpringKeyframe(hud.countdown && hud.seconds <= 15 ? 1.12 : 1, duration: 0.1); SpringKeyframe(1, duration: 0.3) }
            }

            Button(action: onPause) {
                Image(systemName: "pause.fill").font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Palette.plum)
                    .frame(width: 52, height: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .storybookPill(height: 52, horizontal: 0)
            .help("Pause (Esc)")
            .accessibilityLabel("Pause")
        }
    }

    private var beaconProgress: some View {
        GeometryReader { proxy in
            let x = proxy.size.width * min(1, max(0, hud.progress))
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.parchment)
                Capsule().fill(Palette.pink).frame(width: max(14, x)).padding(3)
                Capsule().strokeBorder(Palette.plum, lineWidth: 3)
                Circle().fill(Palette.pink)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().strokeBorder(Palette.plum, lineWidth: 3))
                    .overlay(Circle().fill(.white).frame(width: 6, height: 6).offset(x: -3, y: -3))
                    .offset(x: x - 11)
                PixelImage(sprite: .beacon, scale: 1)
                    .offset(x: proxy.size.width + 4, y: -14)
            }
        }
        .frame(width: 480, height: 16)
        .shadow(color: Palette.plum.opacity(0.3), radius: 0, y: 3)
        .padding(.bottom, Space.s)
        .accessibilityElement()
        .accessibilityLabel("\(Int(hud.progress * 100)) percent to the beacon")
    }

    private func hudBackground(radius: CGFloat) -> some View {
        StorybookShape(radius: radius)
    }
}

private struct HUDPill: ViewModifier {
    var tint: Color?

    func body(content: Content) -> some View {
        content
            .font(.rounded(23, .heavy))
            .monospacedDigit()
            .foregroundStyle(tint ?? Palette.plum)
            .storybookPill(height: 52, horizontal: 18)
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

/// Background-only version of the storybook pill, for HUD cards whose content sets its own padding.
private struct StorybookShape: View {
    let radius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape.fill(Palette.parchment)
            .overlay(shape.inset(by: 1.5).stroke(Palette.plum, lineWidth: 3))
            .background(shape.fill(Palette.plum.opacity(0.35)).offset(y: 4))
    }
}
