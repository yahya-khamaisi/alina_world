import SwiftUI

struct MissionMapView: View {
    let missions: [Mission]
    let onSelect: (Mission) -> Void
    let onBack: () -> Void

    @ObservedObject private var nav = MenuNavigationState.shared
    private let columns = 9

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                HStack {
                    Text("Esc — Menu")
                        .foregroundStyle(.white.opacity(0.7))
                        .font(.caption)
                    Spacer()
                    Text("Mission Map — 27 Quests")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Text("Unlocked: \(GameProgress.shared.unlockedMission)/27")
                        .foregroundStyle(.white.opacity(0.8))
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
                    ForEach(Array(missions.enumerated()), id: \.element.id) { index, mission in
                        let unlocked = GameProgress.shared.isUnlocked(missionID: mission.id)
                        let selected = index == nav.missionMapIndex
                        VStack(spacing: 4) {
                            Text("\(mission.id)")
                                .font(.headline)
                            Text(mission.world)
                                .font(.caption2)
                                .lineLimit(1)
                            Text(mission.difficulty.rawValue)
                                .font(.caption2)
                                .opacity(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(cellColor(unlocked: unlocked, selected: selected))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selected ? Color(red: 1.0, green: 0.85, blue: 0.4) : Color.clear, lineWidth: 2)
                        )
                        .foregroundStyle(.white)
                        .opacity(unlocked ? 1 : 0.45)
                        .scaleEffect(selected ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: nav.missionMapIndex)
                    }
                }
                .padding(.horizontal)

                if let mission = missions[safe: nav.missionMapIndex] {
                    Text("Mission \(mission.id): \(mission.title) — Enter to begin")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Text("Arrow keys navigate · Enter starts mission")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(24)

            MenuKeyboardDriver {
                handleKeys()
            }
        }
        .onAppear {
            nav.resetMissionMapSelection()
        }
    }

    private func cellColor(unlocked: Bool, selected: Bool) -> Color {
        if selected { return Color(red: 0.55, green: 0.38, blue: 0.75) }
        return unlocked ? Color(red: 0.35, green: 0.45, blue: 0.65) : Color.black.opacity(0.35)
    }

    private func handleKeys() {
        if InputController.shared.consumeEscape() {
            onBack()
            return
        }
        if InputController.shared.consumeLeft() {
            nav.missionMapIndex = max(0, nav.missionMapIndex - 1)
        }
        if InputController.shared.consumeRight() {
            nav.missionMapIndex = min(missions.count - 1, nav.missionMapIndex + 1)
        }
        if InputController.shared.consumeUp() {
            nav.missionMapIndex = max(0, nav.missionMapIndex - columns)
        }
        if InputController.shared.consumeDown() {
            nav.missionMapIndex = min(missions.count - 1, nav.missionMapIndex + columns)
        }
        if InputController.shared.consumeEnter() {
            let mission = missions[nav.missionMapIndex]
            if GameProgress.shared.isUnlocked(missionID: mission.id) {
                onSelect(mission)
            }
        }
        if InputController.shared.consumeFullscreen() {
            AppWindowController.toggleFullscreen()
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
