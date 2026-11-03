import SwiftUI

/// Native macOS Settings window (⌘,). Changes apply from the next mission you start.
struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("Gameplay", systemImage: "gamecontroller") { GameplaySettings() }
            Tab("Display", systemImage: "display") { DisplaySettings() }
            Tab("Progress", systemImage: "star") { ProgressSettings() }
        }
        .frame(width: 520)
        .tint(Palette.pink)
    }
}

private struct GameplaySettings: View {
    @AppStorage(SettingsKey.assistMode) private var assistMode = false
    @AppStorage(SettingsKey.showHints) private var showHints = true

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $assistMode) {
                    Text("Assist mode")
                    Text("One extra heart and 30% more time on timed missions.")
                }
                Toggle(isOn: $showHints) {
                    Text("Show control hints")
                    Text("Shows the jump and sprint keys for the first few seconds of a mission.")
                }
            }
            Section("Controls") {
                LabeledContent("Move", value: "← → or A D")
                LabeledContent("Jump · glide", value: "Space, W or ↑")
                LabeledContent("Sprint", value: "Shift")
                LabeledContent("Pause", value: "Esc")
                LabeledContent("Full screen", value: "F")
            }
        }
        .formStyle(.grouped)
    }
}

private struct DisplaySettings: View {
    @AppStorage(SettingsKey.frameRate) private var frameRate = 120
    @AppStorage(SettingsKey.ambientEffects) private var ambientEffects = true

    var body: some View {
        Form {
            Section {
                Picker("Frame rate", selection: $frameRate) {
                    Text("ProMotion (120 Hz)").tag(120)
                    Text("60 Hz").tag(60)
                }
                Toggle(isOn: $ambientEffects) {
                    Text("Weather and particles")
                    Text("Rain, drifting petals and embers in each world.")
                }
            }
            Section {
                LabeledContent("Pixel scaling", value: "Always crisp")
                LabeledContent("Window", value: "Use F or the green button for full screen")
            }
        }
        .formStyle(.grouped)
    }
}

private struct ProgressSettings: View {
    @State private var confirmReset = false
    @State private var refresh = 0

    var body: some View {
        let progress = GameProgress.shared
        Form {
            Section {
                LabeledContent("Missions unlocked", value: "\(min(GameProgress.missionCount, progress.unlockedMission)) of \(GameProgress.missionCount)")
                LabeledContent("Stars earned", value: "\(progress.totalStars) of 81")
                LabeledContent("Heart Crystals restored", value: "\(progress.crystalsRestored) of 9")
                LabeledContent("Petals collected", value: progress.totalPetals.formatted())
            }
            .id(refresh)
            Section {
                Button("Reset Progress…", role: .destructive) { confirmReset = true }
            } footer: {
                Text("Clears unlocked missions, stars and best times. Settings are kept.")
            }
        }
        .formStyle(.grouped)
        .confirmationDialog("Reset all progress?", isPresented: $confirmReset) {
            Button("Reset Progress", role: .destructive) {
                progress.reset()
                refresh += 1
                AppRouter.shared.route = .menu
            }
        } message: {
            Text("This can't be undone.")
        }
    }
}
