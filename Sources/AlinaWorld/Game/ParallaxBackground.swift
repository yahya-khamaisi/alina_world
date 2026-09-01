import SpriteKit

final class ParallaxBackground {
    private var layers: [ParallaxLayer] = []
    private var decorativeElements: [SKNode] = []
    private let factors: [CGFloat] = [0.08, 0.2, 0.35, 0.55]
    private var skyNode: SKSpriteNode?
    private var sunMoonNode: SKShapeNode?
    private var starField: [SKShapeNode] = []
    private var mapWidth: CGFloat = 0

    struct ParallaxLayer {
        let node: SKSpriteNode
        let factor: CGFloat
        let baseColor: SKColor
        var hills: [SKShapeNode] = []
    }

    func attach(to scene: SKScene, palette: WorldPalette, mapWidth: CGFloat, timeOfDay: TimeOfDay = .morning) {
        self.mapWidth = mapWidth
        let height = scene.size.height

        setupSky(scene: scene, palette: palette, timeOfDay: timeOfDay)
        setupLayers(scene: scene, palette: palette, height: height, timeOfDay: timeOfDay)
        setupDecorations(scene: scene, palette: palette, height: height, mapWidth: mapWidth, timeOfDay: timeOfDay)
        setupCelestialBodies(scene: scene, height: height, timeOfDay: timeOfDay)
    }

    private func setupSky(scene: SKScene, palette: WorldPalette, timeOfDay: TimeOfDay) {
        let sky = SKSpriteNode(color: timeOfDay.skyColor, size: CGSize(width: mapWidth + scene.size.width * 2, height: scene.size.height * 2))
        sky.anchorPoint = CGPoint(x: 0, y: 0)
        sky.position = CGPoint(x: -scene.size.width, y: 0)
        sky.zPosition = -50
        scene.addChild(sky)
        skyNode = sky

        let gradient = createSkyGradient(height: scene.size.height * 2, timeOfDay: timeOfDay)
        sky.texture = gradient
    }

    private func createSkyGradient(height: CGFloat, timeOfDay: TimeOfDay) -> SKTexture {
        let width = 256
        let heightInt = Int(height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(data: nil, width: width, height: heightInt, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return SKTexture(image: NSImage(size: CGSize(width: width, height: heightInt)))
        }

        let colors = skyGradientColors(for: timeOfDay)
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 0.3, 0.7, 1.0]) else {
            return SKTexture(image: NSImage(size: CGSize(width: width, height: heightInt)))
        }

        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: CGFloat(heightInt)), end: CGPoint(x: 0, y: 0), options: [])

        guard let cgImage = context.makeImage() else {
            return SKTexture(image: NSImage(size: CGSize(width: width, height: heightInt)))
        }

        let nsImage = NSImage(cgImage: cgImage, size: CGSize(width: width, height: heightInt))
        return SKTexture(image: nsImage)
    }

    private func skyGradientColors(for timeOfDay: TimeOfDay) -> [CGColor] {
        switch timeOfDay {
        case .dawn:
            return [
                SKColor(red: 0.3, green: 0.25, blue: 0.45, alpha: 1).cgColor,
                SKColor(red: 0.6, green: 0.4, blue: 0.6, alpha: 1).cgColor,
                SKColor(red: 0.95, green: 0.65, blue: 0.45, alpha: 1).cgColor,
                SKColor(red: 1.0, green: 0.85, blue: 0.6, alpha: 1).cgColor
            ]
        case .morning:
            return [
                SKColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1).cgColor,
                SKColor(red: 0.55, green: 0.75, blue: 0.95, alpha: 1).cgColor,
                SKColor(red: 0.7, green: 0.85, blue: 0.98, alpha: 1).cgColor,
                SKColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1).cgColor
            ]
        case .noon:
            return [
                SKColor(red: 0.35, green: 0.65, blue: 0.95, alpha: 1).cgColor,
                SKColor(red: 0.45, green: 0.7, blue: 0.95, alpha: 1).cgColor,
                SKColor(red: 0.6, green: 0.8, blue: 0.98, alpha: 1).cgColor,
                SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1).cgColor
            ]
        case .afternoon:
            return [
                SKColor(red: 0.4, green: 0.68, blue: 0.95, alpha: 1).cgColor,
                SKColor(red: 0.5, green: 0.72, blue: 0.95, alpha: 1).cgColor,
                SKColor(red: 0.7, green: 0.85, blue: 0.98, alpha: 1).cgColor,
                SKColor(red: 0.9, green: 0.95, blue: 0.98, alpha: 1).cgColor
            ]
        case .dusk:
            return [
                SKColor(red: 0.3, green: 0.25, blue: 0.4, alpha: 1).cgColor,
                SKColor(red: 0.55, green: 0.35, blue: 0.5, alpha: 1).cgColor,
                SKColor(red: 0.85, green: 0.5, blue: 0.4, alpha: 1).cgColor,
                SKColor(red: 1.0, green: 0.7, blue: 0.4, alpha: 1).cgColor
            ]
        case .night:
            return [
                SKColor(red: 0.03, green: 0.03, blue: 0.12, alpha: 1).cgColor,
                SKColor(red: 0.08, green: 0.08, blue: 0.2, alpha: 1).cgColor,
                SKColor(red: 0.15, green: 0.15, blue: 0.3, alpha: 1).cgColor,
                SKColor(red: 0.25, green: 0.25, blue: 0.4, alpha: 1).cgColor
            ]
        }
    }

    private func setupLayers(scene: SKScene, palette: WorldPalette, height: CGFloat, timeOfDay: TimeOfDay) {
        let layerConfigs: [(color: SKColor, heightMultiplier: CGFloat, hillCount: Int, hillSize: CGSize, yOffset: CGFloat)] = [
            (palette.block.withAlphaComponent(0.2), 0.6, 8, CGSize(width: 200, height: 80), height * 0.15),
            (palette.ground.withAlphaComponent(0.25), 0.5, 6, CGSize(width: 150, height: 60), height * 0.2),
            (palette.accent.withAlphaComponent(0.15), 0.4, 5, CGSize(width: 100, height: 40), height * 0.25),
            (palette.block.withAlphaComponent(0.1), 0.3, 4, CGSize(width: 80, height: 30), height * 0.3)
        ]

        for (index, config) in layerConfigs.enumerated() {
            let layer = SKSpriteNode(color: .clear, size: CGSize(width: mapWidth + scene.size.width * 2, height: height * config.heightMultiplier))
            layer.anchorPoint = CGPoint(x: 0, y: 0)
            layer.position = CGPoint(x: -scene.size.width, y: config.yOffset)
            layer.zPosition = -30 + CGFloat(index) * 2
            scene.addChild(layer)

            var hills: [SKShapeNode] = []
            let spacing = mapWidth / CGFloat(config.hillCount + 1)
            for i in 0..<config.hillCount + 2 {
                let hill = SKShapeNode(rectOf: config.hillSize, cornerRadius: config.hillSize.height / 2)
                hill.fillColor = config.color
                hill.strokeColor = .clear
                hill.position = CGPoint(x: -scene.size.width + CGFloat(i) * spacing + CGFloat.random(in: -20...20), y: CGFloat.random(in: 0...config.hillSize.height * 0.5))
                layer.addChild(hill)
                hills.append(hill)
            }

            layers.append(ParallaxLayer(node: layer, factor: factors[index % factors.count], baseColor: config.color, hills: hills))
        }
    }

    private func setupDecorations(scene: SKScene, palette: WorldPalette, height: CGFloat, mapWidth: CGFloat, timeOfDay: TimeOfDay) {
        let cloudCount = Int(mapWidth / 180)
        for i in 0..<cloudCount + 2 {
            let cloud = createCloud(palette: palette, timeOfDay: timeOfDay)
            cloud.position = CGPoint(x: -scene.size.width + CGFloat(i) * 180 + CGFloat.random(in: -30...30), y: height * CGFloat.random(in: 0.55...0.85))
            cloud.zPosition = -15
            scene.addChild(cloud)
            decorativeElements.append(cloud)

            let drift = SKAction.sequence([
                SKAction.moveBy(x: CGFloat.random(in: 30...60), y: 0, duration: CGFloat.random(in: 40...80)),
                SKAction.moveBy(x: CGFloat.random(in: -60 ... -30), y: 0, duration: CGFloat.random(in: 40...80))
            ])
            cloud.run(SKAction.repeatForever(drift))
        }

        if timeOfDay == .night {
            setupStars(scene: scene, height: height, mapWidth: mapWidth)
        }

        if timeOfDay == .dawn || timeOfDay == .dusk {
            setupFireflies(scene: scene, height: height, mapWidth: mapWidth)
        }
    }

    private func createCloud(palette: WorldPalette, timeOfDay: TimeOfDay) -> SKNode {
        let container = SKNode()
        let cloudColor = timeOfDay == .night ? SKColor(white: 0.3, alpha: 0.4) : SKColor(white: 1.0, alpha: 0.6)
        let parts = Int.random(in: 3...6)
        for j in 0..<parts {
            let radius = CGFloat.random(in: 15...35)
            let part = SKShapeNode(circleOfRadius: radius)
            part.fillColor = cloudColor
            part.strokeColor = .clear
            part.position = CGPoint(x: CGFloat(j) * radius * 0.7 + CGFloat.random(in: -5...5), y: CGFloat.random(in: -10...10))
            container.addChild(part)
        }
        return container
    }

    private func setupStars(scene: SKScene, height: CGFloat, mapWidth: CGFloat) {
        let starCount = Int(mapWidth / 40)
        for _ in 0..<starCount + 5 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2.0))
            star.fillColor = SKColor(white: 1.0, alpha: CGFloat.random(in: 0.3...0.9))
            star.strokeColor = .clear
            star.position = CGPoint(x: -scene.size.width + CGFloat.random(in: 0...mapWidth + scene.size.width * 2), y: height * CGFloat.random(in: 0.4...0.95))
            star.zPosition = -40
            scene.addChild(star)
            starField.append(star)

            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: CGFloat.random(in: 1...3)),
                SKAction.fadeAlpha(to: 1.0, duration: CGFloat.random(in: 1...3))
            ])
            star.run(SKAction.repeatForever(twinkle))
        }
    }

    private func setupFireflies(scene: SKScene, height: CGFloat, mapWidth: CGFloat) {
        let fireflyCount = Int(mapWidth / 100)
        for _ in 0..<fireflyCount {
            let firefly = SKShapeNode(circleOfRadius: 1.5)
            firefly.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.4, alpha: 1)
            firefly.strokeColor = .clear
            firefly.glowWidth = 3
            firefly.position = CGPoint(x: -scene.size.width + CGFloat.random(in: 0...mapWidth + scene.size.width * 2), y: height * CGFloat.random(in: 0.2...0.6))
            firefly.zPosition = -10
            scene.addChild(firefly)
            decorativeElements.append(firefly)

            let wander = SKAction.sequence([
                SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -15...15), duration: CGFloat.random(in: 2...4)),
                SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -15...15), duration: CGFloat.random(in: 2...4))
            ])
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.5),
                SKAction.fadeAlpha(to: 1.0, duration: 0.5)
            ])
            firefly.run(SKAction.repeatForever(SKAction.group([wander, pulse])))
        }
    }

    private func setupCelestialBodies(scene: SKScene, height: CGFloat, timeOfDay: TimeOfDay) {
        let body = SKShapeNode(circleOfRadius: 30)
        body.strokeColor = .clear
        body.zPosition = -35

        switch timeOfDay {
        case .dawn, .dusk:
            body.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.3, alpha: 1)
            body.glowWidth = 15
            body.position = CGPoint(x: mapWidth * 0.15, y: height * 0.85)
        case .morning, .noon, .afternoon:
            body.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1)
            body.glowWidth = 20
            let xPos = timeOfDay == .morning ? mapWidth * 0.25 : (timeOfDay == .noon ? mapWidth * 0.5 : mapWidth * 0.75)
            body.position = CGPoint(x: xPos, y: height * 0.8)
        case .night:
            body.fillColor = SKColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1)
            body.glowWidth = 10
            body.position = CGPoint(x: mapWidth * 0.7, y: height * 0.85)
        }

        scene.addChild(body)
        sunMoonNode = body

        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 10, duration: 20),
            SKAction.moveBy(x: 0, y: -10, duration: 20)
        ])
        body.run(SKAction.repeatForever(bob))
    }

    func update(cameraX: CGFloat, viewWidth: CGFloat, delta: TimeInterval, timeOfDay: TimeOfDay) {
        for layer in layers {
            layer.node.position.x = -cameraX * layer.factor - viewWidth
        }

        if let sky = skyNode {
            sky.position.x = -cameraX * 0.02 - viewWidth
        }

        if let sunMoon = sunMoonNode {
            sunMoon.position.x = sunMoon.position.x // Stays fixed in world space
        }

        for star in starField {
            star.position.x = -cameraX * 0.01 + star.position.x
        }

        for element in decorativeElements {
            element.position.x = element.position.x
        }
    }

    func updateTimeOfDay(_ timeOfDay: TimeOfDay) {
        if let sky = skyNode {
            let newTexture = createSkyGradient(height: sky.size.height, timeOfDay: timeOfDay)
            sky.run(SKAction.setTexture(newTexture))
        }

        if let sunMoon = sunMoonNode {
            let targetColor: SKColor
            let targetGlow: CGFloat

            switch timeOfDay {
            case .dawn, .dusk:
                targetColor = SKColor(red: 1.0, green: 0.6, blue: 0.3, alpha: 1)
                targetGlow = 15
            case .morning:
                targetColor = SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1)
                targetGlow = 20
            case .noon:
                targetColor = SKColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1)
                targetGlow = 25
            case .afternoon:
                targetColor = SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1)
                targetGlow = 20
            case .night:
                targetColor = SKColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1)
                targetGlow = 10
            }

            sunMoon.run(SKAction.group([
                SKAction.colorize(with: targetColor, colorBlendFactor: 1.0, duration: 2.0),
                SKAction.customAction(withDuration: 2.0) { [weak self] node, elapsed in
                    if let shape = node as? SKShapeNode, let self = self {
                        shape.glowWidth = self.lerp(shape.glowWidth, targetGlow, elapsed / 2.0)
                    }
                }
            ]))
        }

        for star in starField {
            let targetAlpha: CGFloat = timeOfDay == .night ? 1.0 : 0.0
            star.run(SKAction.fadeAlpha(to: targetAlpha, duration: 2.0))
        }
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    func cleanup() {
        for layer in layers { layer.node.removeFromParent() }
        for element in decorativeElements { element.removeFromParent() }
        for star in starField { star.removeFromParent() }
        skyNode?.removeFromParent()
        sunMoonNode?.removeFromParent()
        layers.removeAll()
        decorativeElements.removeAll()
        starField.removeAll()
    }
}
