import SwiftUI

/// Native macOS Settings window (⌘,). Changes apply from the next mission you start.
struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("Gameplay", systemImage: "gamecontroller") { GameplaySettings() }
            Tab("Audio", systemImage: "speaker.wave.2") { AudioSettings() }
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
    @AppStorage(SettingsKey.manualRun) private var manualRun = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $assistMode) {
                    Text("Assist mode")
                    Text("One extra heart and 30% more time on timed missions.")
                }
                Toggle(isOn: $showHints) {
                    Text("Show control hints")
                    Text("Shows the punch, kick and jump keys for the first few seconds of a mission.")
                }
            }
            Section("Controls") {
                Toggle(isOn: $manualRun) {
                    Text("Steer Alina by hand")
                    Text("Off: Alina runs on her own. On: A and D move her left and right.")
                }
                LabeledContent("Punch", value: "← or Z")
                LabeledContent("Kick", value: "→ or X")
                LabeledContent("Jump · glide", value: "Space, W or ↑")
                LabeledContent("Brake", value: "↓ or S")
                LabeledContent("Sprint", value: "Shift")
                LabeledContent("Pause", value: "Esc")
                LabeledContent("Full screen", value: "F")
            }
        }
        .formStyle(.grouped)
    }
}

private struct AudioSettings: View {
    @AppStorage(SettingsKey.musicVolume) private var music = 0.6
    @AppStorage(SettingsKey.effectsVolume) private var effects = 0.8

    var body: some View {
        Form {
            Section {
                volumeRow("Music", value: $music, icon: "music.note")
                volumeRow("Sound effects", value: $effects, icon: "sparkles")
                    .onChange(of: effects) { ChiptuneEngine.shared.play(.petal) }
            } footer: {
                Text("Original chiptune soundtrack, synthesized live: a theme for the isles and one for each act.")
            }
        }
        .formStyle(.grouped)
    }

    private func volumeRow(_ title: String, value: Binding<Double>, icon: String) -> some View {
        LabeledContent {
            HStack(spacing: 10) {
                Slider(value: value, in: 0...1)
                Text(value.wrappedValue, format: .percent.precision(.fractionLength(0)))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
        } label: {
            Label(title, systemImage: icon)
        }
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
                LabeledContent("Heart Crystals restored", value: "\(progress.crystalsRestored) of \(GameProgress.worldCount)")
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
