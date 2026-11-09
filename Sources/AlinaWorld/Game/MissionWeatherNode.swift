import AppKit
import SpriteKit

/// A bounded, camera-relative weather simulation which stays active for the entire mission.
/// Particle lifetimes are finite, so effects never run out over a long level.
final class MissionWeatherNode {
    private var root: SKNode?
    private var emitters: [(node: SKEmitterNode, rising: Bool)] = []
    private var mist: SKSpriteNode?
    private var sunlight: SKSpriteNode?
    private var shade: SKSpriteNode?
    private var vignette: SKSpriteNode?
    private var bolt: SKShapeNode?
    private var weather = MissionWeather(kind: .sunny, seed: 0)
    private var elapsed: CGFloat = 0
    private var reducedMotion = false
    private var enabled = true
    private var warmedUp = false

    var wind: CGFloat { reducedMotion || !enabled ? 0 : weather.wind }
    var time: CGFloat { elapsed }

    func attach(to scene: SKScene, weather: MissionWeather, enabled: Bool) {
        self.weather = weather
        self.enabled = enabled
        reducedMotion = UserDefaults.standard.bool(forKey: SettingsKey.reduceMotion) || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let root = SKNode(); scene.addChild(root); self.root = root
        let shade = SKSpriteNode(color: SKColor(hex: 0x15233C), size: .zero)
        shade.zPosition = 65
        shade.alpha = weather.rain * 0.14 + (weather.kind == .blizzard ? 0.07 : 0)
        root.addChild(shade); self.shade = shade
        let vignette = SKSpriteNode(texture: EffectTextures.vignette)
        vignette.zPosition = 70; vignette.alpha = 0.3
        root.addChild(vignette); self.vignette = vignette
        let sunlight = SKSpriteNode(texture: EffectTextures.glow)
        sunlight.color = SKColor(hex: 0xFFE9B4); sunlight.colorBlendFactor = 1
        sunlight.blendMode = .add; sunlight.zPosition = -36
        sunlight.alpha = weather.sunshine * 0.04
        root.addChild(sunlight); self.sunlight = sunlight

        // No drifting cloud overlays: the painted skies already hold their clouds, and soft blobs read as smudges.
        if enabled {
            let mist = SKSpriteNode(texture: EffectTextures.glow)
            mist.color = SKColor(hex: weather.kind == .embers ? 0xFFC192 : 0xDEEBF6)
            mist.colorBlendFactor = 1; mist.alpha = weather.fog; mist.zPosition = -27
            root.addChild(mist); self.mist = mist
        }
        guard enabled, !reducedMotion else { return }
        if weather.rain > 0 {
            for depth in 0..<2 {
                let e = SKEmitterNode()
                e.particleTexture = EffectTextures.glow
                e.particleBirthRate = CGFloat(depth == 0 ? 95 : 65) * weather.rain
                e.particleLifetime = depth == 0 ? 1.8 : 1.25
                e.particleSize = CGSize(width: depth == 0 ? 0.85 : 1.3, height: depth == 0 ? 15 : 24)
                e.particleAlpha = depth == 0 ? 0.3 : 0.5
                e.particleAlphaSpeed = -0.12
                e.particleColor = SKColor(hex: 0xD5E7F8); e.particleColorBlendFactor = 1
                e.emissionAngle = -.pi / 2 - weather.wind * 0.33
                e.particleRotation = -weather.wind * 0.33
                e.particleSpeed = depth == 0 ? 390 : 560
                e.particleSpeedRange = 65
                e.zPosition = depth == 0 ? -24 : 24
                add(e, to: scene)
            }
        }
        if weather.snow > 0 {
            let e = SKEmitterNode()
            e.particleTexture = EffectTextures.snowflake
            e.particleBirthRate = 14 + weather.snow * 25
            e.particleLifetime = 14
            e.particleSize = CGSize(width: 3.5, height: 3.5)
            e.particleScaleRange = 0.5
            e.particleAlpha = 0.8
            e.particleAlphaSpeed = -0.025
            e.particleColor = .white; e.particleColorBlendFactor = 1
            e.emissionAngle = -.pi / 2 - weather.wind * 0.5
            e.emissionAngleRange = 0.3
            e.particleSpeed = 22 + weather.snow * 48; e.particleSpeedRange = 15
            e.particleRotationSpeed = 0.45; e.zPosition = 23
            add(e, to: scene)
        }
        if weather.kind == .storm {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0.69, y: 1.05)); path.addLine(to: CGPoint(x: 0.64, y: 0.84))
            path.addLine(to: CGPoint(x: 0.69, y: 0.85)); path.addLine(to: CGPoint(x: 0.61, y: 0.65))
            let bolt = SKShapeNode(path: path)
            bolt.strokeColor = SKColor(hex: 0xEAF1FF); bolt.lineWidth = 0.0018
            bolt.glowWidth = 0.001; bolt.zPosition = -33; bolt.alpha = 0
            root.addChild(bolt); self.bolt = bolt
        }
        // Ambient drift only where it is weather (rising embers); no decorative petals or sparkles.
        if weather.rain == 0 && weather.snow == 0 && weather.kind == .embers {
            let e = SKEmitterNode()
            let foliage = weather.kind == .breeze || weather.kind == .sunny
            e.particleTexture = foliage ? EffectTextures.leaf : EffectTextures.sparkle
            e.particleBirthRate = foliage ? 3 : 5
            e.particleLifetime = 10; e.particleAlpha = 0.6; e.particleAlphaSpeed = -0.04
            e.particleSize = CGSize(width: foliage ? 4.5 : 3.5, height: foliage ? 6 : 3.5)
            e.particleColor = SKColor(hex: weather.kind == .embers ? 0xFFC577 : foliage ? 0xFFB7CF : 0xFFF0C7)
            e.particleColorBlendFactor = 1
            e.particleRotationSpeed = foliage ? 1.2 : 0.35
            let rising = [.embers, .magic, .starlight, .mist].contains(weather.kind)
            e.emissionAngle = rising ? .pi / 2 - 0.4 : -.pi / 2 - weather.wind * 0.6
            e.particleSpeed = foliage ? 24 + weather.wind * 35 : 16
            e.particleSpeedRange = 12; e.zPosition = 22
            add(e, to: scene, rising: rising)
        }
    }

    private func add(_ emitter: SKEmitterNode, to scene: SKScene, rising: Bool = false) {
        emitter.targetNode = scene
        root?.addChild(emitter)
        emitters.append((emitter, rising))
        emitter.particlePositionRange = CGVector(dx: 1200, dy: rising ? 140 : 0)
    }

    func update(visible: CGRect, delta: TimeInterval) {
        if !reducedMotion { elapsed += CGFloat(delta) }
        shade?.position = CGPoint(x: visible.midX, y: visible.midY); shade?.size = visible.size
        vignette?.position = CGPoint(x: visible.midX, y: visible.midY); vignette?.size = visible.size
        sunlight?.position = CGPoint(x: visible.minX + visible.width * 0.77, y: visible.minY + visible.height * 0.83)
        sunlight?.size = CGSize(width: visible.width * 1.1, height: visible.height * 1.5)
        sunlight?.alpha = weather.sunshine * (0.04 + sin(elapsed * 0.3) * 0.01)
        mist?.position = CGPoint(x: visible.midX + sin(elapsed * 0.12) * 80, y: visible.minY + visible.height * 0.24)
        mist?.size = CGSize(width: visible.width * 1.9, height: visible.height * 0.35)
        for (e, rising) in emitters {
            e.position = CGPoint(x: visible.midX, y: rising ? visible.minY + visible.height * 0.12 : visible.maxY + 24)
            e.particlePositionRange = CGVector(dx: visible.width * 1.65, dy: rising ? visible.height * 0.45 : 0)
        }
        if !warmedUp {
            for (emitter, _) in emitters { emitter.advanceSimulationTime(min(emitter.particleLifetime, 12)) }
            warmedUp = true
        }
        if let bolt {
            bolt.position = visible.origin; bolt.xScale = visible.width; bolt.yScale = visible.height
            let phase = (elapsed + CGFloat(abs(weather.seed % 5))).truncatingRemainder(dividingBy: 12)
            bolt.alpha = phase < 0.35 ? 0.25 * (1 - phase / 0.35) : 0
        }
    }

    func cleanup() {
        // Particle targets are the scene, so clear them before detaching the emitter hierarchy.
        emitters.forEach { $0.node.resetSimulation() }
        root?.removeFromParent(); root = nil; emitters.removeAll()
        mist = nil; shade = nil; sunlight = nil; vignette = nil; bolt = nil; elapsed = 0; warmedUp = false
    }
}
