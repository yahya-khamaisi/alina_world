import Foundation

struct StoryBeat {
    let actTitle: String
    let worldName: String
    let intro: String
}

enum StoryCatalog {
    static let actIntros: [Int: String] = [
        1: "Act I — Awakening: The Lumen Isles dim as the Night Crown scatters nine Heart Crystals.",
        2: "Act II — Fracture: Broken bridges and restless shadows test Alina's courage.",
        3: "Act III — Night Crown: Storm and spire await before the throne of stolen light.",
        4: "Act IV — Beyond the Isles: Snow, sea and sky hide three last crystals."
    ]

    static func beat(for mission: Mission) -> StoryBeat {
        let intro = actIntros[mission.act] ?? "Alina runs toward the next crystal."
        return StoryBeat(actTitle: actIntros[mission.act] ?? "", worldName: mission.world, intro: intro)
    }

    static let openingNarration = """
    Alina lives in the Lumen Isles, where nine Heart Crystals keep the world awake.
    The Night Crown stole them all. As a girl who never feared the dark—only what it hides—
    Alina sets out to reclaim the light, one mission at a time.
    """

    static let finaleText =
        "The Night Crown shatters. All nine Heart Crystals orbit Alina, then settle across the isles. " +
        "The Lumen Isles blaze with dawn. Alina smiles—adventure always found her first."
}
