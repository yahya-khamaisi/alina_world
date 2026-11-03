import SpriteKit

/// Pixel-art scenery behind the level: banded sky, sun, drifting clouds, two hill layers and ambient particles.
final class ParallaxBackground {
    private struct Layer {
        let node: SKNode
        let factor: CGFloat
    }

    private var skyBands: [SKSpriteNode] = []
    private var sun: SKSpriteNode?
    private var layers: [Layer] = []
    private var emitter: SKEmitterNode?
    private var cloudDrift: CGFloat = 0
    private var cloudLayer: SKNode?
    private var pitShade: SKSpriteNode?

    /// Fraction of the visible height taken by each sky band, top first; the last band fills the rest.
    private let bandFractions: [CGFloat] = [0.2, 0.16, 0.14, 0.13]

    func attach(to scene: SKScene, theme: WorldTheme, mapWidth: CGFloat, groundTop: CGFloat, ambientParticles: Bool) {
        for color in theme.sky {
            let band = SKSpriteNode(color: SKColor(hex: color), size: .zero)
            band.anchorPoint = CGPoint(x: 0, y: 1)
            band.zPosition = -60
            scene.addChild(band)
            skyBands.append(band)
        }

        let sun = PixelArt.node(.sun, scale: 7)
        sun.zPosition = -55
        scene.addChild(sun)
        self.sun = sun

        let viewSpan: CGFloat = 1800
        var rng = SeededRNG(seed: UInt64(mapWidth) &+ 7)

        let clouds = makeLayer(in: scene, factor: 0.08, z: -50)
        var x: CGFloat = 40
        while x < mapWidth * 0.08 + viewSpan + 2400 {
            let scale = CGFloat([3, 4, 5, 6][Int(rng.next() % 4)])
            let cloud = PixelArt.node(.cloud, scale: scale)
            cloud.position = CGPoint(x: x, y: groundTop + 300 + CGFloat(rng.next() % 170))
            cloud.alpha = scale < 4 ? 0.8 : 1
            clouds.addChild(cloud)
            x += 220 + CGFloat(rng.next() % 220)
        }
        cloudLayer = clouds

        addHills(.hillFar, theme: theme, in: scene, factor: 0.22, z: -45, scale: 10, spacing: 200,
                 baseY: groundTop + 40, fill: theme.hills.1, span: mapWidth * 0.22 + viewSpan, rng: &rng)
        addHills(.hillNear, theme: theme, in: scene, factor: 0.45, z: -40, scale: 9, spacing: 250,
                 baseY: groundTop - 4, fill: theme.grass.1, span: mapWidth * 0.45 + viewSpan, rng: &rng)

        // Shadowed floor seen through pits, so gaps read as drops rather than more grass.
        let pitShade = SKSpriteNode(color: SKColor(hex: theme.leaves.1), size: CGSize(width: mapWidth + 4000, height: 900))
        pitShade.anchorPoint = CGPoint(x: 0, y: 1)
        pitShade.position = CGPoint(x: -2000, y: groundTop - 24)
        pitShade.zPosition = -30
        scene.addChild(pitShade)
        self.pitShade = pitShade

        if ambientParticles, let emitter = GameGraphics.ambientEmitter(for: theme.particles, width: 1200, height: 500) {
            emitter.targetNode = scene
            scene.addChild(emitter)
            emitter.advanceSimulationTime(8)
            self.emitter = emitter
        }
    }

    private func makeLayer(in scene: SKScene, factor: CGFloat, z: CGFloat) -> SKNode {
        let node = SKNode()
        node.zPosition = z
        scene.addChild(node)
        layers.append(Layer(node: node, factor: factor))
        return node
    }

    private func addHills(
        _ sprite: PixelSprite, theme: WorldTheme, in scene: SKScene, factor: CGFloat, z: CGFloat,
        scale: CGFloat, spacing: CGFloat, baseY: CGFloat, fill: UInt32, span: CGFloat, rng: inout SeededRNG
    ) {
        let layer = makeLayer(in: scene, factor: factor, z: z)
        let base = SKSpriteNode(color: SKColor(hex: fill), size: CGSize(width: span + 400, height: 800))
        base.anchorPoint = CGPoint(x: 0, y: 1)
        base.position = CGPoint(x: -200, y: baseY + 1)
        layer.addChild(base)

        var x: CGFloat = -120
        while x < span + 200 {
            let hill = PixelArt.node(sprite, theme: theme, scale: scale)
            hill.anchorPoint = CGPoint(x: 0, y: 0)
            hill.position = CGPoint(x: x, y: baseY)
            layer.addChild(hill)
            x += spacing + CGFloat(rng.next() % UInt64(spacing / 2))
        }
    }

    /// `visible` is the camera's view rectangle in world coordinates.
    func update(visible: CGRect, delta: TimeInterval) {
        var top = visible.maxY
        for (i, band) in skyBands.enumerated() {
            let height = i < bandFractions.count ? visible.height * bandFractions[i] : top - visible.minY + 2
            band.size = CGSize(width: visible.width + 4, height: height + 1)
            band.position = CGPoint(x: visible.minX - 2, y: top)
            top -= height
        }

        sun?.position = CGPoint(x: visible.maxX - 300, y: visible.maxY - 150)

        cloudDrift += CGFloat(delta) * 4
        for layer in layers {
            layer.node.position.x = visible.minX * (1 - layer.factor)
        }
        cloudLayer?.position.x -= cloudDrift

        emitter?.position = CGPoint(x: visible.midX, y: visible.maxY + 20)
    }

    func cleanup() {
        skyBands.forEach { $0.removeFromParent() }
        layers.forEach { $0.node.removeFromParent() }
        sun?.removeFromParent()
        emitter?.removeFromParent()
        pitShade?.removeFromParent()
        skyBands.removeAll()
        layers.removeAll()
    }
}
