package app.jannat.alinaworld.game

object GameConstants {
    const val TILE = 32f
    const val GRAVITY = 2200f
    const val PLAYER_WIDTH = 22f
    const val PLAYER_HEIGHT = 28f
    const val STOMP_BOUNCE = 520f
    /** World units visible vertically; the camera scales so every screen frames the level the same way. */
    const val VIEW_HEIGHT = 560f
    /** Integer upscale applied to 16 px tile art so it fills a 32 unit tile. */
    const val TILE_PIXEL = 2f
}

enum class AmbientParticles { Petals, Rain, Leaves, Embers, Dust, Mist, Sparkles, Storm, Motes, Snow, Bubbles }

/** Per-world colors shared by the game renderer and the menus, as 0xRRGGBB. */
class WorldTheme(
    val key: String,
    val name: String,
    /** Five sky bands, top to horizon. */
    val sky: IntArray,
    /** Grass highlight, grass, grass shadow. */
    val grass: IntArray,
    /** Dirt, dirt speckle. */
    val dirt: IntArray,
    /** Leaf, leaf shadow. */
    val leaves: IntArray,
    /** Far hill highlight, body, shade. */
    val hills: IntArray,
    val particles: AmbientParticles
) {
    /** Palette overrides for world-tinted sprites. */
    val spritePalette: Map<Char, Int> = mapOf(
        'i' to grass[0], 'g' to grass[1], 'x' to grass[2],
        'u' to dirt[0], 's' to dirt[1],
        'v' to leaves[0], 'V' to leaves[1],
        'k' to hills[0], 'b' to hills[1], 'j' to hills[2]
    )

    val horizon: Int get() = sky[4]
}

object WorldThemes {
    private fun t(
        key: String, name: String, sky: IntArray, grass: IntArray, dirt: IntArray,
        leaves: IntArray, hills: IntArray, particles: AmbientParticles
    ) = WorldTheme(key, name, sky, grass, dirt, leaves, hills, particles)

    val ordered: List<WorldTheme> = listOf(
        t("meadow", "Sunpetal Meadow",
            intArrayOf(0x6EC1F2, 0x86CCF4, 0x9FD7F6, 0xB9E2F8, 0xD4EEFA),
            intArrayOf(0xA6E37E, 0x76CF63, 0x3E9147), intArrayOf(0xD9A86C, 0xA98563),
            intArrayOf(0x55B85C, 0x2F8A45), intArrayOf(0xBDE6D2, 0x9CD4BD, 0x86C2AA), AmbientParticles.Petals),
        t("brook", "Glimmer Brook",
            intArrayOf(0x5FB4EE, 0x79C2F2, 0x93CFF5, 0xAEDCF8, 0xCBEAFB),
            intArrayOf(0xA8E6B0, 0x6CCB84, 0x3C8F5A), intArrayOf(0xC9B79A, 0x9C8A70),
            intArrayOf(0x4FB07A, 0x2D7F55), intArrayOf(0xC4E4F2, 0xA3D2EA, 0x86BEDC), AmbientParticles.Rain),
        t("grove", "Whisper Grove",
            intArrayOf(0x74C9C4, 0x8BD4CB, 0xA3DED3, 0xBCE7DC, 0xD5F0E6),
            intArrayOf(0x9BE07A, 0x62BF55, 0x2F7F3F), intArrayOf(0xC08F5C, 0x8E6440),
            intArrayOf(0x3FA552, 0x1F6E38), intArrayOf(0xA8DCC4, 0x86C7AA, 0x6AB091), AmbientParticles.Leaves),
        t("cavern", "Ember Cavern",
            intArrayOf(0xF2B07A, 0xF5C08C, 0xF8CFA0, 0xFADDB6, 0xFCEACD),
            intArrayOf(0xF2C48A, 0xD99A5B, 0xA3633A), intArrayOf(0xB57A55, 0x7E4F35),
            intArrayOf(0xD9824A, 0xA3532E), intArrayOf(0xF4C9A6, 0xE3AE88, 0xCC9470), AmbientParticles.Embers),
        t("ridge", "Copper Ridge",
            intArrayOf(0xF4C48E, 0xF6CF9F, 0xF8D9B0, 0xFAE3C3, 0xFCEDD7),
            intArrayOf(0xD8E07A, 0xA8BE55, 0x6E8A35), intArrayOf(0xC79466, 0x956643),
            intArrayOf(0x9DB04C, 0x667A2E), intArrayOf(0xEBD3B4, 0xDCBC98, 0xC9A27E), AmbientParticles.Dust),
        t("marsh", "Mist Marsh",
            intArrayOf(0xA9CFC8, 0xB7D7D1, 0xC5DFDA, 0xD3E7E3, 0xE2F0EC),
            intArrayOf(0xA9D9A0, 0x79B87A, 0x4A855A), intArrayOf(0x9C9278, 0x6E6754),
            intArrayOf(0x5E9E6E, 0x3B6E4C), intArrayOf(0xC9DED8, 0xAFCFC6, 0x93BCB2), AmbientParticles.Mist),
        t("spire", "Violet Spire",
            intArrayOf(0xC3B1F0, 0xCDBEF3, 0xD7CBF6, 0xE2D9F9, 0xECE6FB),
            intArrayOf(0xC9B8F2, 0x9B86DA, 0x6B57AE), intArrayOf(0xA897C2, 0x7C6B98),
            intArrayOf(0x8E72D6, 0x5E47A6), intArrayOf(0xDCD0F6, 0xC6B6EE, 0xAE9CE0), AmbientParticles.Sparkles),
        t("storm", "Thunder Reach",
            intArrayOf(0x9FB4D6, 0xADBFDC, 0xBBCAE3, 0xCAD6EA, 0xD9E2F1),
            intArrayOf(0xA9C7D8, 0x7FA2BC, 0x527692), intArrayOf(0x8C93A6, 0x646A7C),
            intArrayOf(0x6C8FB0, 0x46637F), intArrayOf(0xC3CFE2, 0xA9B8D2, 0x8FA0C0), AmbientParticles.Storm),
        t("throne", "Night Crown Keep",
            intArrayOf(0xF49FA6, 0xF7B4AA, 0xF9C7B0, 0xFBD8BA, 0xFDE8C8),
            intArrayOf(0xE8A6C8, 0xC77AA5, 0x8E4C79), intArrayOf(0x8F6C8C, 0x5E4660),
            intArrayOf(0xB46A9E, 0x7C3F6C), intArrayOf(0xF2C6D2, 0xE2A9BC, 0xCC8EA6), AmbientParticles.Motes),
        t("frost", "Frostpeak Hollow",
            intArrayOf(0x9FC7EA, 0xB0D2EE, 0xC2DDF2, 0xD4E8F6, 0xE6F2FA),
            intArrayOf(0xF4FAFF, 0xD8EAF7, 0x9DBAD6), intArrayOf(0xA9C9E8, 0x86A9CC),
            intArrayOf(0x7FA7CF, 0x55799E), intArrayOf(0xE6F0FA, 0xCFE0F1, 0xB5CCE6), AmbientParticles.Snow),
        t("coral", "Coral Lagoon",
            intArrayOf(0x7FD3E6, 0x93DBEA, 0xA8E3EE, 0xBEEAF2, 0xD7F3F7),
            intArrayOf(0xFFF0C8, 0xF2DCA0, 0xD9B76E), intArrayOf(0xF2E3C0, 0xD9C29A),
            intArrayOf(0x4FB07A, 0x2D7F55), intArrayOf(0xC6F0EE, 0xA6E2E0, 0x86D0CF), AmbientParticles.Bubbles),
        t("starfall", "Starfall Sky",
            intArrayOf(0x5E52A0, 0x7466B5, 0x8C7DC8, 0xA898DA, 0xC6B8EA),
            intArrayOf(0xFFFFFF, 0xEDE6FF, 0xC3B1F0), intArrayOf(0xD7CBF6, 0xB9A6EC),
            intArrayOf(0xFFFFFF, 0xDCD0F6), intArrayOf(0xB9A6EC, 0x9B86DA, 0x8170C4), AmbientParticles.Sparkles)
    )

    fun theme(world: String): WorldTheme = ordered.firstOrNull { it.key == world.lowercase() } ?: ordered[0]

    fun index(world: String): Int = ordered.indexOfFirst { it.key == world.lowercase() }.coerceAtLeast(0)
}
