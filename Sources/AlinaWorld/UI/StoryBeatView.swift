import SwiftUI

struct StoryBeatView: View {
    let mission: Mission
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Mission \(mission.id): \(mission.title)")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text(StoryCatalog.beat(for: mission).actTitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))

                Text("World: \(mission.world)")
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 1.0))

                Text(mission.briefing)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 620)

                HStack(spacing: 16) {
                    Label(mission.objectiveLabel, systemImage: "target")
                    Label(mission.difficulty.rawValue.capitalized, systemImage: "bolt.fill")
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

                Text("Enter — Begin Mission    Esc — Back")
                    .font(.headline)
                    .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.45))
                    .padding(.top, 8)
            }
            .padding(40)

            MenuKeyboardDriver {
                if InputController.shared.consumeEnter() { onContinue() }
                if InputController.shared.consumeEscape() { onBack() }
                if InputController.shared.consumeFullscreen() { AppWindowController.toggleFullscreen() }
            }
        }
    }
}

private extension Mission {
    var objectiveLabel: String {
        switch objective {
        case .reachFlag: return "Reach the beacon"
        case .collectN: return "Collect \(collectRequired) crystals"
        case .defeatBoss: return "Defeat the guardian"
        }
    }
}
