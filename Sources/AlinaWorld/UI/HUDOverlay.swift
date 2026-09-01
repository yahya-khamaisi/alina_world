import SwiftUI

struct HUDOverlay: View {
    let lives: Int
    let coins: Int
    let crystals: Int
    let title: String
    let elapsed: CGFloat
    let timeLimit: Int?
    let collectTarget: Int?

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 16) {
                    Label("\(lives)", systemImage: "heart.fill")
                    Label("\(coins)", systemImage: "bitcoinsign.circle.fill")
                    if let collectTarget {
                        Label("\(crystals)/\(collectTarget)", systemImage: "sparkles")
                    }
                    if let timeLimit {
                        let remaining = max(0, Int(timeLimit) - Int(elapsed))
                        Label("\(remaining)s", systemImage: "clock")
                    }
                    Text("F fullscreen · Esc pause")
                        .font(.caption2)
                }
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.45))
            Spacer()
        }
    }
}

struct VictoryView: View {
    let mission: Mission
    let coins: Int
    let onContinue: () -> Void
    let onNextMission: (Int) -> Void
    let onMenu: () -> Void

    @ObservedObject private var nav = MenuNavigationState.shared
    private var hasNext: Bool { mission.id < 27 }

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text(mission.id == 27 ? "Campaign Complete!" : "Mission Complete!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text(mission.victoryText)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 620)

                if mission.id == 27 {
                    Text(StoryCatalog.finaleText)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 620)
                }

                Text("Coins collected: \(coins)")
                    .foregroundStyle(.white.opacity(0.8))

                VStack(spacing: 12) {
                    if hasNext {
                        Text("Next Mission")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(hasNext && nav.victoryFocusNext ? Color(red: 0.85, green: 0.35, blue: 0.55) : Color.white.opacity(0.15))
                            )
                    }
                    Text("Mission Map")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(!hasNext || !nav.victoryFocusNext ? Color(red: 0.85, green: 0.35, blue: 0.55) : Color.white.opacity(0.15))
                        )
                }

                Text("Enter confirm · ↑↓ switch · Esc menu")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(40)

            MenuKeyboardDriver {
                if hasNext {
                    if InputController.shared.consumeUp() { nav.victoryFocusNext = true }
                    if InputController.shared.consumeDown() { nav.victoryFocusNext = false }
                }
                if InputController.shared.consumeEnter() {
                    if hasNext && nav.victoryFocusNext {
                        onNextMission(mission.id + 1)
                    } else {
                        onContinue()
                    }
                }
                if InputController.shared.consumeEscape() { onMenu() }
                if InputController.shared.consumeFullscreen() { AppWindowController.toggleFullscreen() }
            }
        }
    }
}
