import SpriteKit

final class LightingSystem {
    private let scene: SKScene
    private let cameraNode: SKCameraNode
    private var lightNodes: [SKLightNode] = []
    private var shadowCasters: [SKNode] = []
    private var ambientLight: SKLightNode?
    private var timeOfDay: TimeOfDay = .morning
    private var weatherIntensity: CGFloat = 0
    private var currentWeather: WeatherType = .none
    private var lightMask: UInt32 = 1

    init(scene: SKScene, cameraNode: SKCameraNode) {
        self.scene = scene
        self.cameraNode = cameraNode
        setupAmbientLight()
    }

    private func setupAmbientLight() {
        ambientLight = SKLightNode()
        ambientLight?.categoryBitMask = lightMask
        ambientLight?.falloff = 0
        ambientLight?.ambientColor = SKColor(white: 1, alpha: 1)
        ambientLight?.lightColor = SKColor(white: 1, alpha: 1)
        ambientLight?.shadowColor = SKColor(white: 0, alpha: 0)
        ambientLight?.zPosition = 100
        if let light = ambientLight {
            scene.addChild(light)
        }
    }

    func setTimeOfDay(_ timeOfDay: TimeOfDay) {
        self.timeOfDay = timeOfDay
        updateAmbientLight()
    }

    func setWeather(_ weather: WeatherType, intensity: CGFloat) {
        currentWeather = weather
        weatherIntensity = intensity
        updateAmbientLight()
    }

    private func updateAmbientLight() {
        guard let light = ambientLight else { return }
        let baseColor = timeOfDay.ambientColor
        let weatherModifier = weatherColorModifier(for: currentWeather, intensity: weatherIntensity)
        light.ambientColor = multiplyColors(baseColor, weatherModifier)
        light.lightColor = multiplyColors(baseColor, weatherModifier)
    }

    private func weatherColorModifier(for weather: WeatherType, intensity: CGFloat) -> SKColor {
        switch weather {
        case .rain, .storm:
            return SKColor(red: 0.85, green: 0.9, blue: 1.0, alpha: 1).interpolated(to: .white, amount: 1 - intensity)
        case .snow:
            return SKColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 1).interpolated(to: .white, amount: 1 - intensity)
        case .fog:
            return SKColor(red: 0.8, green: 0.85, blue: 0.9, alpha: 1).interpolated(to: .white, amount: 1 - intensity)
        case .heatHaze:
            return SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1).interpolated(to: .white, amount: 1 - intensity)
        default:
            return .white
        }
    }

    private func multiplyColors(_ a: SKColor, _ b: SKColor) -> SKColor {
        var ra: CGFloat = 0, ga: CGFloat = 0, ba: CGFloat = 0, aa: CGFloat = 0
        var rb: CGFloat = 0, gb: CGFloat = 0, bb: CGFloat = 0, ab: CGFloat = 0
        a.getRed(&ra, green: &ga, blue: &ba, alpha: &aa)
        b.getRed(&rb, green: &gb, blue: &bb, alpha: &ab)
        return SKColor(red: ra * rb, green: ga * gb, blue: ba * bb, alpha: aa * ab)
    }

    func addShadowCaster(_ node: SKNode) {
        if let sprite = node as? SKSpriteNode {
            sprite.lightingBitMask = lightMask
            sprite.shadowCastBitMask = lightMask
        }
        shadowCasters.append(node)
    }

    func addDynamicLight(at position: CGPoint, color: SKColor, radius: CGFloat, falloff: CGFloat = 1.5, castsShadow: Bool = false) -> SKLightNode {
        let light = SKLightNode()
        light.position = position
        light.lightColor = color
        light.ambientColor = .clear
        light.falloff = falloff
        light.categoryBitMask = lightMask
        light.shadowColor = castsShadow ? SKColor(white: 0, alpha: 0.5) : .clear
        light.zPosition = 50
        scene.addChild(light)
        lightNodes.append(light)
        return light
    }

    func addPlayerLight(to playerNode: SKNode) {
        let light = SKLightNode()
        light.lightColor = SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1)
        light.ambientColor = .clear
        light.falloff = 1.2
        light.categoryBitMask = lightMask
        light.shadowColor = SKColor(white: 0, alpha: 0.3)
        light.zPosition = 20
        playerNode.addChild(light)
        lightNodes.append(light)
    }

    func update(delta: TimeInterval, cameraX: CGFloat, playerPosition: CGPoint) {
        let viewWidth = scene.size.width
        let viewHeight = scene.size.height

        for light in lightNodes {
            if light.parent == cameraNode || light.parent == scene {
                let lightX = light.position.x
                if lightX < cameraX - viewWidth || lightX > cameraX + viewWidth * 2 {
                    light.removeFromParent()
                    lightNodes.removeAll { $0 === light }
                }
            }
        }

        if let ambientLight = ambientLight {
            ambientLight.position = CGPoint(x: cameraX + viewWidth / 2, y: viewHeight / 2)
        }
    }

    func cleanup() {
        for light in lightNodes { light.removeFromParent() }
        lightNodes.removeAll()
        ambientLight?.removeFromParent()
        ambientLight = nil
    }
}

extension SKColor {
    func interpolated(to color: SKColor, amount: CGFloat) -> SKColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return SKColor(
            red: r1 + (r2 - r1) * amount,
            green: g1 + (g2 - g1) * amount,
            blue: b1 + (b2 - b1) * amount,
            alpha: a1 + (a2 - a1) * amount
        )
    }
}