import Foundation

enum MissionObjective: String, Codable {
    case reachFlag
    case collectN
    case defeatBoss
}

enum MissionDifficulty: String, Codable {
    case easy
    case normal
    case hard
}

struct MissionEnemyPlacement: Codable {
    let x: Int
    let y: Int
    let kind: String
    let patrol: Int?
}

struct Mission: Codable, Identifiable {
    let id: Int
    let world: String
    let act: Int
    let title: String
    let briefing: String
    let victoryText: String
    let difficulty: MissionDifficulty
    let objective: MissionObjective
    let collectTarget: Int?
    let timeLimit: Int?
    let layoutSeed: Int
    let rows: [String]
    let enemies: [MissionEnemyPlacement]

    var collectRequired: Int {
        collectTarget ?? 0
    }
}

struct MissionCatalog: Codable {
    let missions: [Mission]
}

enum MissionLoader {
    private static var cached: [Mission]?

    static func loadAll() -> [Mission] {
        if let cached { return cached }
        let missions: [Mission]
        if let url = locateMissionsJSON(),
           let data = try? Data(contentsOf: url),
           let catalog = try? JSONDecoder().decode(MissionCatalog.self, from: data) {
            missions = catalog.missions.sorted { $0.id < $1.id }
        } else {
            missions = fallbackMissions()
        }
        cached = missions
        return missions
    }

    static func mission(id: Int) -> Mission? {
        loadAll().first { $0.id == id }
    }

    /// Avoid `Bundle.module` — SPM's generated accessor aborts when the
    /// resource bundle is missing from a packaged .app.
    private static func locateMissionsJSON() -> URL? {
        let fileManager = FileManager.default
        var candidates: [URL] = []

        if let main = Bundle.main.url(forResource: "Missions", withExtension: "json") {
            candidates.append(main)
        }

        // Packaged SPM resource bundle inside Contents/Resources
        if let resourceURL = Bundle.main.resourceURL {
            candidates.append(
                resourceURL
                    .appendingPathComponent("AlinaWorld_AlinaWorld.bundle")
                    .appendingPathComponent("Contents/Resources/Missions.json")
            )
            candidates.append(resourceURL.appendingPathComponent("Missions.json"))
        }

        // Next to the executable (swift run / debug)
        let executableDir = URL(fileURLWithPath: CommandLine.arguments[0])
            .resolvingSymlinksInPath()
            .deletingLastPathComponent()
        candidates.append(
            executableDir
                .appendingPathComponent("AlinaWorld_AlinaWorld.bundle")
                .appendingPathComponent("Contents/Resources/Missions.json")
        )
        candidates.append(executableDir.appendingPathComponent("Missions.json"))

        // Source tree fallback during development
        candidates.append(
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/Missions.json")
        )

        return candidates.first { fileManager.fileExists(atPath: $0.path) }
    }

    private static func fallbackMissions() -> [Mission] {
        [
            Mission(
                id: 1,
                world: "Meadow",
                act: 1,
                title: "First Light",
                briefing: "The Heart Crystals are fading. Run to the beacon and prove the path is still open.",
                victoryText: "Alina feels the meadow breathe again.",
                difficulty: .easy,
                objective: .reachFlag,
                collectTarget: nil,
                timeLimit: nil,
                layoutSeed: 1,
                rows: [
                    "................................................",
                    "................................................",
                    "................................................",
                    "................................................",
                    "................................................",
                    "................................................",
                    "................................................",
                    ".............................................F..",
                    "############################################....",
                    "############################################...."
                ],
                enemies: []
            )
        ]
    }
}
