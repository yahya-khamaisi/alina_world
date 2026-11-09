import CoreImage
import SpriteKit

/// Depth in front of the action: soft, out-of-focus foliage that sweeps past faster than the level along the bottom
/// edge, and slow warm light shafts across the sky. Both stay sparse so they frame play without hiding it.
final class ForegroundLayer {
    private let foliage = SKNode()
    private let shafts = SKNode()
    /// Foreground moves faster than the camera (1 = level speed).
    private let factor: CGFloat = 1.45
    private var time: CGFloat = 0

    func attach(to scene: SKScene, theme: WorldTheme, mapWidth: CGFloat) {
        foliage.zPosition = 60
        scene.addChild(foliage)
        shafts.zPosition = -20
        scene.addChild(shafts)

        // Painted bushes, flowers and trees from the prop art, scaled up, blurred and darkened so they read as close
        // to the camera and out of focus.
        var rng = SeededRNG(seed: UInt64(WorldThemes.index(of: theme.key) + 1) &* 104_729)
        var x: CGFloat = 420
        let kinds: [Props.Kind] = [.bush, .flowers, .bush, .tree, .flowers]
        while x < mapWidth * factor + 2000 {
            let kind = kinds[Int(rng.next() % UInt64(kinds.count))]
            let image = IllustratedArt.prop(kind, theme: theme, variant: Int(rng.next() % 3))
            let logical = IllustratedArt.propSize(kind)
            let scale: CGFloat = kind == .tree ? 4.2 : 7 + CGFloat(rng.next() % 30) / 10
            let sprite = SKSpriteNode(texture: SKTexture(cgImage: image),
                                      size: CGSize(width: logical.width * scale, height: logical.height * scale))
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0)
            sprite.color = SKColor(hex: 0x1E1428)
            sprite.colorBlendFactor = 0.82
            sprite.alpha = 1
            sprite.xScale = rng.next() % 2 == 0 ? 1 : -1

            // Crisp, dark silhouettes (no blur: blurred foliage read as haze).
            let blur = SKNode()
            blur.addChild(sprite)
            blur.position = CGPoint(x: x, y: kind == .tree ? -sprite.size.height * 0.42 : -sprite.size.height * 0.18)
            foliage.addChild(blur)
            x += 900 + CGFloat(rng.next() % 1400)
        }

    }

    /// `visible` is the camera's view rectangle in world coordinates.
    func update(visible: CGRect, delta: TimeInterval) {
        time += CGFloat(delta)
        // A parent offset makes children at world x appear to scroll at `factor` times the camera speed.
        foliage.position = CGPoint(x: -visible.minX * (factor - 1), y: visible.minY)
        for case let shaft as SKSpriteNode in shafts.children {
            let i = CGFloat(Int(shaft.name ?? "0") ?? 0)
            shaft.position = CGPoint(x: visible.minX + visible.width * (0.25 + i * 0.28) + sin(time * 0.12 + i) * 40,
                                     y: visible.maxY - 140)
            shaft.alpha = 0.08 + 0.05 * (0.5 + 0.5 * sin(time * 0.4 + i * 2))
        }
    }

    func cleanup() {
        foliage.removeFromParent()
        shafts.removeFromParent()
    }
}
