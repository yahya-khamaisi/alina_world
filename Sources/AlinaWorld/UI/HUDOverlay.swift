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
                objectiveCard
            }
            Spacer()
            HStack(alignment: .bottom) {
                if showHint {
                    hint.transition(.move(edge: .bottom).combined(with: .opacity))
                }
                Spacer()
                if mission.objective == .reachFlag {
                    beaconProgress
                }
            }
        }
        .padding(Space.xl)
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            PixelImage(sprite: .alinaIdle, scale: 2, overrides: hud.bloom ? ["K": 0xF6C343] : [:])
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.pinkSoft))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    ForEach(0..<hud.maxHearts, id: \.self) { i in
                        PixelImage(sprite: i < hud.hearts ? .heart : .heartEmpty, scale: 3)
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("Hearts \(hud.hearts) of \(hud.maxHearts)")
                Text(hud.hearts == 1 ? "Last heart!" : "Hearts")
                    .font(.rounded(12, .heavy))
                    .foregroundStyle(hud.hearts == 1 ? Palette.pinkText : Palette.muted)
            }

            Rectangle().fill(Palette.line).frame(width: 2, height: 36)

            HStack(spacing: Space.s) {
                powerSlot(.sunbloom, active: hud.bloom, label: "Sunbloom")
                powerSlot(.ribbon, active: hud.ribbon, label: "Glow Ribbon")
            }
        }
        .padding(.vertical, 10)
        .padding(.leading, 10)
        .padding(.trailing, Space.l)
        .background(hudBackground(radius: 18))
    }

    private func powerSlot(_ sprite: PixelSprite, active: Bool, label: String) -> some View {
        PixelImage(sprite: sprite, scale: 3)
            .opacity(active ? 1 : 0.25)
            .saturation(active ? 1 : 0)
            .frame(width: 48, height: 48)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(active ? Palette.goldSoft : Palette.sand))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(active ? Palette.gold : .clear, lineWidth: 2))
            .help(label)
            .accessibilityLabel("\(label) \(active ? "active" : "not collected")")
    }

    private var objectiveCard: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            HStack(spacing: Space.s) {
                switch mission.objective {
                case .collectN:
                    PixelImage(sprite: .crystal, scale: 2)
                    Text("Heart Shards").font(.rounded(14, .heavy))
                    Spacer()
                    Text("\(hud.shards) / \(hud.shardTarget ?? 0)").font(.rounded(14, .heavy)).foregroundStyle(Color(hex: 0xA86A00))
                case .defeatBoss:
                    PixelImage(sprite: .guardian, scale: 1)
                    Text("Guardian").font(.rounded(14, .heavy))
                    Spacer()
                    Text("\(hud.bossHits) / 3 stomps").font(.rounded(14, .heavy)).foregroundStyle(Palette.pinkText)
                case .reachFlag:
                    PixelImage(sprite: .beacon, scale: 1)
                    Text("Reach the beacon").font(.rounded(14, .heavy))
                    Spacer()
                    Text("\(Int(hud.progress * 100))%").font(.rounded(14, .heavy)).foregroundStyle(Palette.mintText)
                }
            }
            .foregroundStyle(Palette.ink)
            .monospacedDigit()
            ProgressBar(value: hud.progress, tint: mission.objective == .reachFlag ? Palette.mint : Palette.gold, height: 10)
        }
        .frame(width: 300)
        .padding(.horizontal, Space.l)
        .padding(.vertical, Space.m)
        .background(hudBackground(radius: 18))
    }

    private var rightCluster: some View {
        HStack(spacing: Space.s) {
            HStack(spacing: Space.s) {
                PixelImage(sprite: .petal, scale: 2)
                Text(String(format: "%03d", hud.petals))
            }
            .modifier(HUDPill())

            HStack(spacing: Space.s) {
                Image(systemName: hud.countdown ? "timer" : "clock").font(.system(size: 15, weight: .bold))
                Text(String(format: "%d:%02d", hud.seconds / 60, hud.seconds % 60))
            }
            .foregroundStyle(hud.countdown && hud.seconds <= 15 ? Palette.pinkText : Palette.ink)
            .modifier(HUDPill())

            Button(action: onPause) {
                Image(systemName: "pause.fill").font(.system(size: 16, weight: .heavy))
            }
            .buttonStyle(IconButtonStyle())
            .help("Pause (Esc)")
            .accessibilityLabel("Pause")
        }
    }

    private var hint: some View {
        HStack(spacing: Space.m) {
            KeyCap(text: "Space", dark: true)
            Text("Jump").font(.rounded(14, .bold))
            KeyCap(text: "Shift", dark: true)
            Text("Sprint").font(.rounded(14, .bold))
            Text("· Hold jump with the Glow Ribbon to glide").font(.rounded(14, .semibold)).foregroundStyle(Palette.muted)
        }
        .foregroundStyle(Palette.ink)
        .padding(.vertical, 10)
        .padding(.horizontal, Space.l)
        .background(hudBackground(radius: 16))
    }

    private var beaconProgress: some View {
        HStack(spacing: 10) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.line)
                    Capsule().fill(Palette.mint).frame(width: proxy.size.width * hud.progress)
                    Circle().fill(Palette.pink)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                        .offset(x: proxy.size.width * hud.progress - 8)
                }
            }
            .frame(width: 140, height: 8)
            PixelImage(sprite: .beacon, scale: 1)
        }
        .padding(.vertical, Space.m)
        .padding(.horizontal, Space.l)
        .background(hudBackground(radius: 16))
        .accessibilityLabel("\(Int(hud.progress * 100)) percent to the beacon")
    }

    private func hudBackground(radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(.white.opacity(0.95))
            .shadow(color: Palette.ink.opacity(0.15), radius: 0, y: 4)
    }
}

private struct HUDPill: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.rounded(17, .heavy))
            .monospacedDigit()
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, Space.l)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.95))
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

    var body: some View {
        ZStack {
            Palette.ink.opacity(0.45).ignoresSafeArea()

            HStack(alignment: .center, spacing: Space.xl) {
                VStack(alignment: .leading, spacing: Space.xl) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Paused").font(.rounded(36, .bold)).foregroundStyle(Palette.ink)
                            Text("\(mission.id) · \(mission.title)").font(.rounded(14, .bold)).foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        PixelImage(sprite: .sun, scale: 4)
                    }

                    HStack(spacing: Space.s) {
                        stat(mission.objective == .collectN ? "Shards" : "Progress",
                             mission.objective == .collectN ? "\(hud.shards) / \(hud.shardTarget ?? 0)" : "\(Int(hud.progress * 100))%",
                             Palette.goldSoft, Color(hex: 0xA86A00))
                        stat("Petals", "\(hud.petals)", Palette.pinkSoft, Palette.pinkText)
                        stat(hud.countdown ? "Time left" : "Time", String(format: "%d:%02d", hud.seconds / 60, hud.seconds % 60), Palette.skySoft, Palette.skyText)
                    }

                    VStack(spacing: 10) {
                        Button(action: onResume) {
                            HStack(spacing: Space.m) {
                                Image(systemName: "play.fill")
                                Text("Resume")
                                Spacer()
                                KeyCap(text: "Esc", dark: true)
                            }
                        }
                        .buttonStyle(ChunkyButtonStyle(kind: .primary, height: 56, focused: nav.overlayFocus == 0))
                        .onHover { if $0 { nav.overlayFocus = 0 } }

                        row(1, "Restart from checkpoint", icon: "arrow.counterclockwise", action: onCheckpoint)
                        row(2, "Restart mission", icon: "arrow.uturn.backward", action: onRestart)
                        row(3, "Settings", icon: "gearshape.fill", action: { openSettings() })

                        Button(action: onQuit) {
                            HStack(spacing: Space.m) {
                                Image(systemName: "map.fill")
                                Text("Quit to World Map")
                            }
                        }
                        .buttonStyle(ChunkyButtonStyle(kind: .quiet, height: 50, focused: nav.overlayFocus == 4))
                        .onHover { if $0 { nav.overlayFocus = 4 } }
                    }
                }
                .frame(width: 400)
                .card(padding: Space.xxl)

                VStack(alignment: .leading, spacing: Space.m) {
                    Text("Controls").font(.rounded(20, .bold)).foregroundStyle(Palette.ink)
                    ControlsList()
                    Text("Game controllers are not supported yet — keyboard only.")
                        .font(.rounded(12, .semibold))
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 280)
                .card()
            }

            MenuKeyboardDriver { handleKeys() }
        }
    }

    private func row(_ index: Int, _ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Space.m) {
                Image(systemName: icon).foregroundStyle(Palette.violet)
                Text(title)
            }
        }
        .buttonStyle(ChunkyButtonStyle(kind: .secondary, height: 50, focused: nav.overlayFocus == index))
        .onHover { if $0 { nav.overlayFocus = index } }
    }

    private func stat(_ label: String, _ value: String, _ fill: Color, _ text: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.rounded(12, .heavy)).foregroundStyle(text)
            Text(value).font(.rounded(22, .bold)).foregroundStyle(text).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.m)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(fill))
    }

    private func handleKeys() {
        let input = InputController.shared
        if input.consumeEscape() { _ = input.consumePause(); onResume(); return }
        if input.consumeUp() { nav.overlayFocus = max(0, nav.overlayFocus - 1) }
        if input.consumeDown() { nav.overlayFocus = min(4, nav.overlayFocus + 1) }
        if input.consumeEnter() {
            switch nav.overlayFocus {
            case 0: onResume()
            case 1: onCheckpoint()
            case 2: onRestart()
            case 3: openSettings()
            default: onQuit()
            }
        }
        if input.consumeFullscreen() { AppWindowController.toggleFullscreen() }
    }
}
