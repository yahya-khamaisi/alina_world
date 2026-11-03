import SpriteKit

/// Builds the pixel-art nodes and pixel-shaped effects used by the level.
enum GameGraphics {
    static let popFont = "AvenirNext-Heavy"

    static func makeBlockNode(kind: BlockKind, theme: WorldTheme, topExposed: Bool) -> SKSpriteNode {
        let sprite: PixelSprite
        switch kind {
        case .solid: sprite = .stone
        case .ground: sprite = topExposed ? .groundTop : .groundFill
        case .brick: sprite = .mossbrick
        case .question: sprite = .bloomBlock
        case .pipe: sprite = .log
        case .spring: sprite = .springShell
        }
        return PixelArt.node(sprite, theme: theme, scale: GameConstants.tilePixel)
    }

    static func makeBeacon() -> SKNode {
        let container = SKNode()
        let glow = SKShapeNode(circleOfRadius: 26)
        glow.fillColor = SKColor(hex: 0xFFE98A, alpha: 0.35)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: 0, y: 46)
        glow.run(.repeatForever(.sequence([
            .scale(to: 1.15, duration: 0.8),
            .scale(to: 0.9, duration: 0.8)
        ])))
        container.addChild(glow)

        let lantern = PixelArt.node(.beacon, scale: 4)
        lantern.anchorPoint = CGPoint(x: 0.5, y: 0)
        lantern.position = CGPoint(x: 0, y: -16)
        container.addChild(lantern)
        return container
    }

    static func makeThorns(theme: WorldTheme) -> SKSpriteNode {
        PixelArt.node(.thorns, theme: theme, scale: GameConstants.tilePixel)
    }

    static func makeLeafPad(theme: WorldTheme) -> SKSpriteNode {
        let node = PixelArt.node(.leafPad, theme: theme, scale: GameConstants.tilePixel)
        node.anchorPoint = CGPoint(x: 0.5, y: 1)
        return node
    }

    static func makeCloudPad() -> SKSpriteNode {
        PixelArt.node(.cloudPad, scale: 4)
    }

    /// Floating score text with a white pill behind it, matching the HUD.
    static func popText(_ text: String, color: SKColor, at position: CGPoint, in parent: SKNode) {
        let label = SKLabelNode(fontNamed: popFont)
        label.text = text
        label.fontSize = 16
        label.fontColor = color
        label.verticalAlignmentMode = .center

        let width = label.frame.width + 14
        let pill = SKShapeNode(rectOf: CGSize(width: width, height: 22), cornerRadius: 7)
        pill.fillColor = .white
        pill.strokeColor = .clear
        pill.position = position
        pill.zPosition = 40
        pill.addChild(label)
        parent.addChild(pill)
        pill.run(.sequence([
            .group([.moveBy(x: 0, y: 34, duration: 0.6), .sequence([.wait(forDuration: 0.35), .fadeOut(withDuration: 0.25)])]),
            .removeFromParent()
        ]))
    }

    /// Square pixel particles flying outward — stomps, collects and brick breaks.
    static func burst(at position: CGPoint, in parent: SKNode, colors: [SKColor], count: Int = 10, speed: CGFloat = 140) {
        for i in 0..<count {
            let pixel = SKSpriteNode(texture: PixelArt.squareTexture, size: CGSize(width: 6, height: 6))
            pixel.color = colors[i % colors.count]
            pixel.colorBlendFactor = 1
            pixel.position = position
            pixel.zPosition = 30
            parent.addChild(pixel)
            let angle = CGFloat(i) / CGFloat(count) * .pi * 2 + .random(in: -0.3...0.3)
            let distance = speed * .random(in: 0.5...1)
            pixel.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance * 0.5, y: sin(angle) * distance * 0.5 + 20, duration: 0.45),
                    .fadeOut(withDuration: 0.45)
                ]),
                .removeFromParent()
            ]))
        }
    }

    static func ambientEmitter(for particles: WorldTheme.AmbientParticles, width: CGFloat, height: CGFloat) -> SKEmitterNode? {
        let emitter = SKEmitterNode()
        emitter.particleTexture = PixelArt.squareTexture
        emitter.particleColorBlendFactor = 1
        emitter.particlePositionRange = CGVector(dx: width * 1.4, dy: 0)
        emitter.particleLifetime = 9
        emitter.particleAlphaSpeed = -0.05
        emitter.zPosition = 25
        switch particles {
        case .petals:
            emitter.particleBirthRate = 1.6
            emitter.particleColor = SKColor(hex: 0xFF8DBE)
            emitter.particleSize = CGSize(width: 6, height: 6)
            emitter.emissionAngle = -.pi / 2 - 0.5
            emitter.particleSpeed = 50
            emitter.particleRotationSpeed = 1.5
        case .leaves:
            emitter.particleBirthRate = 1.8
            emitter.particleColor = SKColor(hex: 0x62BF55)
            emitter.particleSize = CGSize(width: 6, height: 6)
            emitter.emissionAngle = -.pi / 2 - 0.4
            emitter.particleSpeed = 45
            emitter.particleRotationSpeed = 2
        case .rain, .storm:
            emitter.particleBirthRate = particles == .storm ? 70 : 40
            emitter.particleColor = SKColor(hex: 0xFFFFFF)
            emitter.particleAlpha = 0.55
            emitter.particleSize = CGSize(width: 2, height: 12)
            emitter.emissionAngle = -.pi / 2 - (particles == .storm ? 0.25 : 0.1)
            emitter.particleSpeed = 520
            emitter.particleLifetime = 1.6
        case .embers:
            emitter.particleBirthRate = 3
            emitter.particleColor = SKColor(hex: 0xFFB347)
            emitter.particleSize = CGSize(width: 4, height: 4)
            emitter.emissionAngle = .pi / 2
            emitter.particleSpeed = 30
            emitter.particlePositionRange = CGVector(dx: width * 1.4, dy: height)
        case .dust, .mist:
            emitter.particleBirthRate = 2
            emitter.particleColor = SKColor(white: 1, alpha: 1)
            emitter.particleAlpha = 0.5
            emitter.particleSize = CGSize(width: 4, height: 4)
            emitter.emissionAngle = 0
            emitter.particleSpeed = 40
            emitter.particlePositionRange = CGVector(dx: width * 1.4, dy: height)
        case .snow:
            emitter.particleBirthRate = 6
            emitter.particleColor = SKColor(hex: 0xFFFFFF)
            emitter.particleSize = CGSize(width: 5, height: 5)
            emitter.emissionAngle = -.pi / 2 - 0.2
            emitter.particleSpeed = 40
            emitter.particleSpeedRange = 15
        case .bubbles:
            emitter.particleBirthRate = 2.5
            emitter.particleColor = SKColor(hex: 0xE8FBFF)
            emitter.particleAlpha = 0.7
            emitter.particleSize = CGSize(width: 6, height: 6)
            emitter.emissionAngle = .pi / 2
            emitter.particleSpeed = 24
            emitter.particleAlphaSpeed = -0.1
            emitter.particlePositionRange = CGVector(dx: width * 1.4, dy: height)
        case .sparkles, .motes:
            emitter.particleBirthRate = 3
            emitter.particleColor = SKColor(hex: particles == .sparkles ? 0xFFFFFF : 0xFFE98A)
            emitter.particleSize = CGSize(width: 4, height: 4)
            emitter.emissionAngle = .pi / 2
            emitter.particleSpeed = 14
            emitter.particleAlphaSpeed = -0.15
            emitter.particlePositionRange = CGVector(dx: width * 1.4, dy: height)
        }
        return emitter
    }
}
