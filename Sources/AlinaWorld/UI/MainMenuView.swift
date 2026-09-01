import SwiftUI

struct MainMenuView: View {
    let onPlay: () -> Void

    @ObservedObject private var nav = MenuNavigationState.shared

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("AlinaWorld")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("A Lumen Isles Adventure")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.82))

                AlinaArtView()
                    .padding(.vertical, 8)

                Button(action: play) {
                    Text("Play")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 200)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.95, green: 0.42, blue: 0.62),
                                            Color(red: 0.78, green: 0.28, blue: 0.52)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(nav.playHighlighted ? 0.9 : 0.25), lineWidth: 2)
                        )
                        .scaleEffect(nav.playHighlighted ? 1.05 : 1.0)
                        .shadow(color: Color(red: 0.9, green: 0.3, blue: 0.5).opacity(0.45), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    nav.playHighlighted = hovering
                }

                Text("Click Play · Enter · Space · F fullscreen")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 4)
            }
            .padding(32)

            KeyFocusView { keyCode in
                handleKey(keyCode)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            InputController.shared.mode = .menu
            InputController.shared.startMonitoring()
            nav.playHighlighted = false
        }
    }

    private func play() {
        onPlay()
    }

    private func handleKey(_ keyCode: UInt16) {
        switch keyCode {
        case 36, 49: // Return, Space
            play()
        case 3: // F
            AppWindowController.toggleFullscreen()
        default:
            break
        }
    }
}

struct MenuButtonStyle: ButtonStyle {
    var secondary = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(secondary ? Color.white.opacity(0.15) : Color(red: 0.85, green: 0.35, blue: 0.55))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
