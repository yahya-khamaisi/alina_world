import SpriteKit

enum WeatherType {
    case none
    case rain
    case storm
    case snow
    case fog
    case wind
    case heatHaze
}

enum TimeOfDay {
    case dawn
    case morning
    case noon
    case afternoon
    case dusk
    case night

    var ambientColor: SKColor {
        switch self {
        case .dawn: return SKColor(red: 0.95, green: 0.65, blue: 0.45, alpha: 1)
        case .morning: return SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1)
        case .noon: return SKColor(red: 1.0, green: 1.0, blue: 0.98, alpha: 1)
        case .afternoon: return SKColor(red: 1.0, green: 0.98, blue: 0.9, alpha: 1)
        case .dusk: return SKColor(red: 1.0, green: 0.7, blue: 0.4, alpha: 1)
        case .night: return SKColor(red: 0.25, green: 0.25, blue: 0.4, alpha: 1)
        }
    }

    var skyColor: SKColor {
        switch self {
        case .dawn: return SKColor(red: 0.55, green: 0.45, blue: 0.65, alpha: 1)
        case .morning: return SKColor(red: 0.6, green: 0.75, blue: 0.95, alpha: 1)
        case .noon: return SKColor(red: 0.45, green: 0.7, blue: 0.95, alpha: 1)
        case .afternoon: return SKColor(red: 0.5, green: 0.72, blue: 0.95, alpha: 1)
        case .dusk: return SKColor(red: 0.65, green: 0.4, blue: 0.55, alpha: 1)
        case .night: return SKColor(red: 0.08, green: 0.08, blue: 0.2, alpha: 1)
        }
    }

    var shadowAlpha: CGFloat {
        switch self {
        case .dawn: return 0.3
        case .morning: return 0.4
        case .noon: return 0.5
        case .afternoon: return 0.45
        case .dusk: return 0.35
        case .night: return 0.15
        }
    }

    var lightDirection: CGVector {
        switch self {
        case .dawn: return CGVector(dx: 0.3, dy: 0.95)
        case .morning: return CGVector(dx: 0.6, dy: 0.8)
        case .noon: return CGVector(dx: 0, dy: 1)
        case .afternoon: return CGVector(dx: -0.6, dy: 0.8)
        case .dusk: return CGVector(dx: -0.3, dy: 0.95)
        case .night: return CGVector(dx: 0, dy: 0.5)
        }
    }
}

final class WeatherSystem {
    private var currentWeather: WeatherType = .none
    private var currentTimeOfDay: TimeOfDay = .morning
    private var weatherEmitter: SKEmitterNode?
    private var fogLayers: [SKSpriteNode] = []
    private var windParticles: SKEmitterNode?
    private let scene: SKScene
    private let cameraNode: SKCameraNode
    private var timeOfDayTimer: CGFloat = 0
    private var weatherTransitionTimer: CGFloat = 0
    private var targetWeather: WeatherType = .none
    private var weatherIntensity: CGFloat = 0
    private var targetIntensity: CGFloat = 0

    init(scene: SKScene, cameraNode: SKCameraNode) {
        self.scene = scene
        self.cameraNode = cameraNode
        setupFogLayers()
    }

    private func setupFogLayers() {
        for i in 0..<3 {
            let fog = SKSpriteNode(color: .white, size: CGSize(width: scene.size.width * 1.5, height: scene.size.height * 0.8))
            fog.anchorPoint = CGPoint(x: 0.5, y: 0)
            fog.position = CGPoint(x: 0, y: scene.size.height * CGFloat(i) * 0.3)
            fog.zPosition = -8 + CGFloat(i) * 0.5
            fog.alpha = 0
            fog.blendMode = .alpha
            scene.addChild(fog)
            fogLayers.append(fog)
        }
    }

    func setWeather(_ weather: WeatherType, intensity: CGFloat = 1.0, transitionDuration: CGFloat = 2.0) {
        targetWeather = weather
        targetIntensity = intensity
        weatherTransitionTimer = transitionDuration
    }

    func setTimeOfDay(_ timeOfDay: TimeOfDay) {
        currentTimeOfDay = timeOfDay
    }

    func update(delta: TimeInterval, cameraX: CGFloat) {
        let dt = CGFloat(delta)
        timeOfDayTimer += dt

        updateWeatherTransition(dt: dt)
        updateWeatherParticles(dt: dt, cameraX: cameraX)
        updateFog(dt: dt, cameraX: cameraX)
        updateWind(dt: dt, cameraX: cameraX)
    }

    private func updateWeatherTransition(dt: CGFloat) {
        guard weatherTransitionTimer > 0 else {
            currentWeather = targetWeather
            weatherIntensity = targetIntensity
            return
        }
        weatherTransitionTimer -= dt
        let progress = 1.0 - weatherTransitionTimer / 2.0
        weatherIntensity = lerp(0, targetIntensity, progress)
        if weatherTransitionTimer <= 0 {
            currentWeather = targetWeather
        }
    }

    private func updateWeatherParticles(dt: CGFloat, cameraX: CGFloat) {
        guard weatherIntensity > 0.01 else {
            weatherEmitter?.particleBirthRate = 0
            return
        }

        if weatherEmitter == nil {
            weatherEmitter = createWeatherEmitter(for: currentWeather)
            if let emitter = weatherEmitter {
                emitter.targetNode = scene
                emitter.position = CGPoint(x: cameraX + scene.size.width / 2, y: scene.size.height + 50)
                scene.addChild(emitter)
            }
        }

        weatherEmitter?.position.x = cameraX + scene.size.width / 2
        weatherEmitter?.particleBirthRate = baseBirthRate(for: currentWeather) * weatherIntensity
        weatherEmitter?.particleSpeed = baseSpeed(for: currentWeather) * (0.8 + weatherIntensity * 0.4)
    }

    private func createWeatherEmitter(for weather: WeatherType) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 2.0
        emitter.particleLifetimeRange = 0.5
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 12
        emitter.particleAlpha = 0.6
        emitter.particleAlphaRange = 0.2
        emitter.particleAlphaSpeed = -0.3
        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.05
        emitter.particleScaleSpeed = -0.05
        emitter.zPosition = 20

        switch weather {
        case .rain, .storm:
            emitter.particleBirthRate = 400
            emitter.particlePositionRange = CGVector(dx: scene.size.width * 1.2, dy: 10)
            emitter.particleSpeed = 600
            emitter.particleSpeedRange = 100
            emitter.particleColor = SKColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 1)
            emitter.particleColorBlendFactor = 1.0
            emitter.particleScale = 0.08
            emitter.particleScaleRange = 0.02
            emitter.particleRotationRange = .pi / 2
        case .snow:
            emitter.particleBirthRate = 80
            emitter.particlePositionRange = CGVector(dx: scene.size.width * 1.2, dy: 10)
            emitter.particleSpeed = 80
            emitter.particleSpeedRange = 40
            emitter.emissionAngleRange = .pi / 6
            emitter.particleLifetime = 4.0
            emitter.particleLifetimeRange = 1.0
            emitter.particleColor = SKColor(white: 1.0, alpha: 1)
            emitter.particleColorBlendFactor = 1.0
            emitter.particleScale = 0.2
            emitter.particleScaleRange = 0.1
            emitter.particleScaleSpeed = -0.01
            emitter.particleRotationRange = .pi * 2
            emitter.particleRotationSpeed = 0.5
        case .fog:
            emitter.particleBirthRate = 20
            emitter.particlePositionRange = CGVector(dx: scene.size.width * 1.2, dy: scene.size.height * 0.5)
            emitter.particleSpeed = 15
            emitter.particleSpeedRange = 10
            emitter.emissionAngle = 0
            emitter.emissionAngleRange = .pi
            emitter.particleLifetime = 6.0
            emitter.particleLifetimeRange = 2.0
            emitter.particleColor = SKColor(white: 0.9, alpha: 1)
            emitter.particleColorBlendFactor = 1.0
            emitter.particleScale = 2.0
            emitter.particleScaleRange = 0.5
            emitter.particleScaleSpeed = -0.05
            emitter.particleAlpha = 0.1
            emitter.particleAlphaRange = 0.05
            emitter.particleAlphaSpeed = -0.015
        default:
            break
        }
        return emitter
    }

    private func baseBirthRate(for weather: WeatherType) -> CGFloat {
        switch weather {
        case .rain: return 400
        case .storm: return 800
        case .snow: return 80
        case .fog: return 20
        default: return 0
        }
    }

    private func baseSpeed(for weather: WeatherType) -> CGFloat {
        switch weather {
        case .rain: return 600
        case .storm: return 800
        case .snow: return 80
        case .fog: return 15
        default: return 0
        }
    }

    private func updateFog(dt: CGFloat, cameraX: CGFloat) {
        let fogIntensity: CGFloat
        switch currentWeather {
        case .fog: fogIntensity = weatherIntensity * 0.6
        case .rain: fogIntensity = weatherIntensity * 0.2
        case .storm: fogIntensity = weatherIntensity * 0.35
        case .snow: fogIntensity = weatherIntensity * 0.15
        default: fogIntensity = 0
        }

        for (i, fog) in fogLayers.enumerated() {
            let targetAlpha = fogIntensity * (0.3 + CGFloat(i) * 0.15)
            fog.alpha = lerp(fog.alpha, targetAlpha, dt * 2)
            fog.position.x = cameraX - cameraNode.scene!.size.width * 0.25 + sin(timeOfDayTimer * 0.2 + CGFloat(i)) * 20
            fog.color = currentTimeOfDay == .night ? SKColor(white: 0.2, alpha: 1) : SKColor(white: 0.95, alpha: 1)
        }
    }

    private func updateWind(dt: CGFloat, cameraX: CGFloat) {
        let hasWind = currentWeather == .wind || currentWeather == .storm || currentWeather == .heatHaze
        guard hasWind else {
            windParticles?.particleBirthRate = 0
            return
        }

        if windParticles == nil {
            let emitter = SKEmitterNode()
            emitter.numParticlesToEmit = 0
            emitter.particleBirthRate = 15 * weatherIntensity
            emitter.particleLifetime = 3.0
            emitter.particleLifetimeRange = 1.0
            emitter.particlePositionRange = CGVector(dx: scene.size.width * 1.2, dy: scene.size.height)
            emitter.emissionAngle = 0
            emitter.emissionAngleRange = .pi / 8
            emitter.particleSpeed = 100
            emitter.particleSpeedRange = 50
            emitter.particleAlpha = 0.15
            emitter.particleAlphaRange = 0.05
            emitter.particleAlphaSpeed = -0.05
            emitter.particleScale = 0.5
            emitter.particleScaleRange = 0.2
            emitter.particleColor = currentWeather == .heatHaze ? SKColor(red: 1, green: 0.8, blue: 0.4, alpha: 1) : SKColor(white: 0.8, alpha: 1)
            emitter.particleColorBlendFactor = 1.0
            emitter.zPosition = 15
            emitter.targetNode = scene
            emitter.position = CGPoint(x: cameraX + scene.size.width / 2, y: scene.size.height / 2)
            scene.addChild(emitter)
            windParticles = emitter
        }

        windParticles?.position.x = cameraX + scene.size.width / 2
        windParticles?.particleBirthRate = 15 * weatherIntensity
        windParticles?.emissionAngle = currentWeather == .wind ? 0 : (currentWeather == .storm ? 0.3 : 0)
    }

    func getAmbientColor() -> SKColor {
        currentTimeOfDay.ambientColor
    }

    func getSkyColor() -> SKColor {
        currentTimeOfDay.skyColor
    }

    func getShadowAlpha() -> CGFloat {
        currentTimeOfDay.shadowAlpha
    }

    func getLightDirection() -> CGVector {
        currentTimeOfDay.lightDirection
    }

    func cleanup() {
        weatherEmitter?.removeFromParent()
        windParticles?.removeFromParent()
        for fog in fogLayers { fog.removeFromParent() }
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}