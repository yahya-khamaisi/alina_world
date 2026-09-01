import AppKit
import SwiftUI

enum MenuArtLoader {
    static func alinaImage() -> NSImage? {
        let names = ["AlinaArt", "AppIcon-1024", "icon"]
        for name in names {
            if let url = locateImage(named: name),
               let image = NSImage(contentsOf: url) {
                return image
            }
        }
        return nil
    }

    private static func locateImage(named name: String) -> URL? {
        let fm = FileManager.default
        var candidates: [URL] = []

        if let main = Bundle.main.url(forResource: name, withExtension: "png") {
            candidates.append(main)
        }
        if let resourceURL = Bundle.main.resourceURL {
            candidates.append(resourceURL.appendingPathComponent("\(name).png"))
            candidates.append(
                resourceURL
                    .appendingPathComponent("AlinaWorld_AlinaWorld.bundle")
                    .appendingPathComponent("Contents/Resources/\(name).png")
            )
        }

        let executableDir = URL(fileURLWithPath: CommandLine.arguments[0])
            .resolvingSymlinksInPath()
            .deletingLastPathComponent()
        candidates.append(
            executableDir
                .appendingPathComponent("AlinaWorld_AlinaWorld.bundle")
                .appendingPathComponent("Contents/Resources/\(name).png")
        )
        candidates.append(executableDir.appendingPathComponent("\(name).png"))

        candidates.append(
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/\(name).png")
        )

        return candidates.first { fm.fileExists(atPath: $0.path) }
    }
}

struct AlinaArtView: View {
    var body: some View {
        Group {
            if let image = MenuArtLoader.alinaImage() {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320, maxHeight: 320)
                    .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
            } else {
                AlinaVectorArt()
                    .frame(width: 220, height: 260)
            }
        }
    }
}

/// Fallback vector art when the PNG is not bundled.
struct AlinaVectorArt: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 1.0, green: 0.88, blue: 0.35).opacity(0.25))
                .frame(width: 200, height: 200)
                .blur(radius: 8)

            VStack(spacing: 0) {
                Circle()
                    .fill(Color(red: 0.98, green: 0.86, blue: 0.72))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle().stroke(Color(red: 0.85, green: 0.65, blue: 0.5), lineWidth: 2)
                    )
                    .offset(y: -20)

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.88, green: 0.32, blue: 0.58))
                    .frame(width: 72, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.62, green: 0.18, blue: 0.42), lineWidth: 2)
                    )

                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.25, green: 0.18, blue: 0.35))
                        .frame(width: 14, height: 22)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.25, green: 0.18, blue: 0.35))
                        .frame(width: 14, height: 22)
                }
                .offset(y: -4)
            }
        }
    }
}
