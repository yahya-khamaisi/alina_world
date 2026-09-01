import Foundation

final class GameProgress {
    static let shared = GameProgress()

    private let unlockedKey = "alinaWorld.unlockedMission"
    private let bestCoinsKey = "alinaWorld.bestCoins"
    private let defaults = UserDefaults.standard

    var unlockedMission: Int {
        get { max(1, defaults.integer(forKey: unlockedKey).nonZeroOr(1)) }
        set { defaults.set(max(1, newValue), forKey: unlockedKey) }
    }

    func bestCoins(for missionID: Int) -> Int {
        defaults.integer(forKey: "\(bestCoinsKey).\(missionID)")
    }

    func recordCompletion(missionID: Int, coins: Int) {
        if missionID >= unlockedMission {
            unlockedMission = min(28, missionID + 1)
        }
        let prior = bestCoins(for: missionID)
        if coins > prior {
            defaults.set(coins, forKey: "\(bestCoinsKey).\(missionID)")
        }
    }

    func isUnlocked(missionID: Int) -> Bool {
        missionID <= unlockedMission
    }

    func reset() {
        defaults.removeObject(forKey: unlockedKey)
        for id in 1...27 {
            defaults.removeObject(forKey: "\(bestCoinsKey).\(id)")
        }
    }
}

private extension Int {
    func nonZeroOr(_ fallback: Int) -> Int {
        self == 0 ? fallback : self
    }
}
