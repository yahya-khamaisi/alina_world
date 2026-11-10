import Foundation

final class GameProgress {
    static let shared = GameProgress()

    private let unlockedKey = "alinaWorld.unlockedMission"
    private let bestCoinsKey = "alinaWorld.bestCoins"
    private let starsKey = "alinaWorld.stars"
    private let bestTimeKey = "alinaWorld.bestTime"
    private let petalsKey = "alinaWorld.totalPetals"
    private let playTimeKey = "alinaWorld.playTime"
    private let defaults = UserDefaults.standard

    static let missionCount = 36
    static let worldCount = 12

    var unlockedMission: Int {
        get { max(1, defaults.integer(forKey: unlockedKey).nonZeroOr(1)) }
        set { defaults.set(max(1, newValue), forKey: unlockedKey) }
    }

    /// Next mission to play: the furthest unlocked one, capped at the finale.
    var continueMission: Int { min(Self.missionCount, unlockedMission) }

    var totalPetals: Int { defaults.integer(forKey: petalsKey) }
    var totalPlayTime: TimeInterval { defaults.double(forKey: playTimeKey) }

    func bestCoins(for missionID: Int) -> Int {
        defaults.integer(forKey: "\(bestCoinsKey).\(missionID)")
    }

    /// Stars earned on a mission as [completed, under par, no damage]; best run per slot is kept.
    func stars(for missionID: Int) -> [Bool] {
        let mask = defaults.integer(forKey: "\(starsKey).\(missionID)")
        return (0..<3).map { mask & (1 << $0) != 0 }
    }

    func starCount(for missionID: Int) -> Int {
        stars(for: missionID).filter { $0 }.count
    }

    var totalStars: Int {
        (1...Self.missionCount).reduce(0) { $0 + starCount(for: $1) }
    }

    func bestTime(for missionID: Int) -> CGFloat? {
        let value = defaults.double(forKey: "\(bestTimeKey).\(missionID)")
        return value > 0 ? CGFloat(value) : nil
    }

    func isCompleted(missionID: Int) -> Bool {
        stars(for: missionID)[0]
    }

    /// Heart Crystals restored: one per world whose guardian mission is complete.
    var crystalsRestored: Int {
        (0..<Self.worldCount).filter { isCompleted(missionID: $0 * 3 + 3) }.count
    }

    /// 0…1 share of all available stars.
    var completion: Double {
        Double(totalStars) / Double(Self.missionCount * 3)
    }

    func recordCompletion(_ result: MissionResult) {
        let id = result.missionID
        if id >= unlockedMission {
            unlockedMission = min(Self.missionCount + 1, id + 1)
        }
        if result.petals > bestCoins(for: id) {
            defaults.set(result.petals, forKey: "\(bestCoinsKey).\(id)")
        }
        let previous = defaults.integer(forKey: "\(starsKey).\(id)")
        let mask = result.stars.enumerated().reduce(0) { $0 | ($1.element ? 1 << $1.offset : 0) }
        defaults.set(previous | mask, forKey: "\(starsKey).\(id)")
        if bestTime(for: id).map({ result.time < $0 }) ?? true {
            defaults.set(Double(result.time), forKey: "\(bestTimeKey).\(id)")
        }
        defaults.set(totalPetals + result.petals, forKey: petalsKey)
        defaults.set(totalPlayTime + Double(result.time), forKey: playTimeKey)
    }

    func isUnlocked(missionID: Int) -> Bool {
        missionID <= unlockedMission
    }

    func reset() {
        defaults.removeObject(forKey: unlockedKey)
        defaults.removeObject(forKey: petalsKey)
        defaults.removeObject(forKey: playTimeKey)
        for id in 1...Self.missionCount {
            defaults.removeObject(forKey: "\(bestCoinsKey).\(id)")
            defaults.removeObject(forKey: "\(starsKey).\(id)")
            defaults.removeObject(forKey: "\(bestTimeKey).\(id)")
        }
    }
}

/// Keys for preferences shown in the Settings window; read by the game scene at launch of each mission.
enum SettingsKey {
    static let assistMode = "settings.assistMode"
    static let ambientEffects = "settings.ambientEffects"
    static let showHints = "settings.showHints"
    static let frameRate = "settings.frameRate"
    static let reduceMotion = "settings.reduceMotion"
    static let musicVolume = "settings.musicVolume"
    static let effectsVolume = "settings.effectsVolume"
}

private extension Int {
    func nonZeroOr(_ fallback: Int) -> Int {
        self == 0 ? fallback : self
    }
}
