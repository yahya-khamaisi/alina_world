import SpriteKit

/// Builds the pixel-art nodes and pixel-shaped effects used by the level.
enum GameGraphics {
    static let popFont = "AvenirNext-Heavy"

    static func makeBlockNode(kind: BlockKind, theme: WorldTheme, topExposed: Bool, artVariant: Int = 0) -> SKSpriteNode {
        let sprite: PixelSprite
        switch kind {
        case .solid: sprite = topExposed ? .groundTop : .groundFill
        case .ground: sprite = topExposed ? .groundTop : .groundFill
        case .brick: sprite = .mossbrick
        case .question: sprite = .bloomBlock
        case .pipe: sprite = .log
        case .spring: sprite = .springShell
        }
        return PixelArt.node(sprite, theme: theme, overrides: ["#": UInt32(artVariant)], scale: GameConstants.tilePixel)
    }

    static func makeBeacon() -> SKNode {
        let container = SKNode()
        let glow = SKShapeNode(circleOfRadius: 30)
        glow.fillColor = SKColor(hex: 0xFFE98A, alpha: 0.4)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: -7, y: 42)
        glow.run(.repeatForever(.sequence([
            .scale(to: 1.15, duration: 0.8),
            .scale(to: 0.9, duration: 0.8)
        ])))
        container.addChild(glow)

        let lantern = PixelArt.node(.beacon, scale: 2)
        lantern.anchorPoint = CGPoint(x: 0.5, y: 0)
        lantern.position = CGPoint(x: 0, y: -16)
        container.addChild(lantern)
        return container
    }

    static func makeThorns(theme: WorldTheme) -> SKSpriteNode {
        PixelArt.node(.thorns, theme: theme, scale: GameConstants.tilePixel)
    }

    static func makeLeafPad(theme: WorldTheme, joinsLeft: Bool, joinsRight: Bool) -> SKSpriteNode {
        let sprite: PixelSprite = switch (joinsLeft, joinsRight) {
        case (true, true): .leafPad
        case (true, false): .leafPadRight
        case (false, true): .leafPadLeft
        case (false, false): .leafPadSingle
        }
        let node = PixelArt.node(sprite, theme: theme, scale: GameConstants.tilePixel)
        node.anchorPoint = CGPoint(x: 0.5, y: 1)
        return node
    }

    static func makeCloudPad() -> SKSpriteNode {
        PixelArt.node(.cloudPad, scale: 4)
    }

    /// Floating score text with a white pill behind it, matching the HUD.
    /// Floating score text on a plum-outlined cream pill: springs in with overshoot, drifts up, fades.
    static func popText(_ text: String, color: SKColor, at position: CGPoint, in parent: SKNode) {
        let label = SKLabelNode(fontNamed: popFont)
        label.text = text
        label.fontSize = 16
        label.fontColor = color
        label.verticalAlignmentMode = .center

        let width = label.frame.width + 18
        let pill = SKShapeNode(rectOf: CGSize(width: width, height: 24), cornerRadius: 12)
        pill.fillColor = SKColor(hex: 0xFFF4E6)
        pill.strokeColor = SKColor(hex: 0x4B1C3A)
        pill.lineWidth = 2
        pill.position = position
        pill.zPosition = 40
        pill.setScale(0.2)
        pill.addChild(label)
        parent.addChild(pill)
        let grow = SKAction.scale(to: 1.25, duration: 0.1)
        grow.timingMode = .easeOut
        let settle = SKAction.scale(to: 1, duration: 0.12)
        settle.timingMode = .easeInEaseOut
        let rise = SKAction.moveBy(x: 0, y: 38, duration: 0.75)
        rise.timingMode = .easeOut
        pill.run(.sequence([
            .group([.sequence([grow, settle]), rise, .sequence([.wait(forDuration: 0.5), .fadeOut(withDuration: 0.25)])]),
            .removeFromParent()
        ]))
    }

    /// Double jump: a ring of soft pink puffs that blooms under the boots, with a few twinkles.
    static func sparklePuff(at position: CGPoint, in parent: SKNode) {
        ring(at: position, in: parent, color: SKColor(hex: 0xFFB3D6), size: 46, duration: 0.35)
        for i in 0..<7 {
            let puff = SKSpriteNode(texture: EffectTextures.softDot, size: CGSize(width: 18, height: 18))
            puff.color = i.isMultiple(of: 2) ? SKColor(hex: 0xFFC2DE) : .white
            puff.colorBlendFactor = 1
            puff.position = position
            puff.zPosition = 9
            puff.setScale(0.4)
            parent.addChild(puff)
            let angle = CGFloat.pi + CGFloat(i) / 6 * .pi
            let out = SKAction.moveBy(x: cos(angle) * 22, y: sin(angle) * 10 - 6, duration: 0.4)
            out.timingMode = .easeOut
            puff.run(.sequence([
                .group([out, .scale(to: 1.2, duration: 0.4), .sequence([.wait(forDuration: 0.15), .fadeOut(withDuration: 0.25)])]),
                .removeFromParent()
            ]))
        }
        twinkles(at: position, in: parent, color: SKColor(hex: 0xFFE9AB), count: 3, spread: 26)
    }

    /// Soft dots and star sparkles thrown outward on a little arc, spinning and shrinking —
    /// stomps, collects and brick breaks.
    static func burst(at position: CGPoint, in parent: SKNode, colors: [SKColor], count: Int = 10, speed: CGFloat = 140) {
        for i in 0..<count {
            let star = i.isMultiple(of: 3)
            let size = star ? CGFloat.random(in: 9...14) : CGFloat.random(in: 6...11)
            let bit = SKSpriteNode(texture: star ? EffectTextures.sparkle : EffectTextures.softDot, size: CGSize(width: size, height: size))
            bit.color = colors[i % colors.count]
            bit.colorBlendFactor = 1
            bit.position = position
            bit.zPosition = 30
            bit.zRotation = .random(in: 0...(.pi))
            parent.addChild(bit)
            let angle = CGFloat(i) / CGFloat(count) * .pi * 2 + .random(in: -0.3...0.3)
            let distance = speed * .random(in: 0.45...0.8)
            let dx = cos(angle) * distance, dy = sin(angle) * distance
            // Arc: out fast, then sag under gravity.
            let path = CGMutablePath()
            path.move(to: position)
            path.addQuadCurve(to: CGPoint(x: position.x + dx, y: position.y + dy * 0.6 - 18),
                              control: CGPoint(x: position.x + dx * 0.6, y: position.y + dy * 0.9 + 22))
            let fly = SKAction.follow(path, asOffset: false, orientToPath: false, duration: 0.55)
            fly.timingMode = .easeOut
            bit.run(.sequence([
                .group([fly, .rotate(byAngle: .random(in: -4...4), duration: 0.55), .scale(to: 0.2, duration: 0.55),
                        .sequence([.wait(forDuration: 0.3), .fadeOut(withDuration: 0.25)])]),
                .removeFromParent()
            ]))
        }
    }

    /// Expanding shockwave ring.
    static func ring(at position: CGPoint, in parent: SKNode, color: SKColor, size: CGFloat, duration: TimeInterval = 0.3) {
        let ring = SKSpriteNode(texture: EffectTextures.ring, size: CGSize(width: size, height: size))
        ring.color = color
        ring.colorBlendFactor = 1
        ring.position = position
        ring.zPosition = 29
        ring.setScale(0.3)
        parent.addChild(ring)
        let grow = SKAction.scale(to: 1, duration: duration)
        grow.timingMode = .easeOut
        ring.run(.sequence([.group([grow, .fadeOut(withDuration: duration)]), .removeFromParent()]))
    }

    /// Bright star flash at an impact point, a few frames long.
    static func impact(at position: CGPoint, in parent: SKNode, size: CGFloat = 54) {
        let flash = SKSpriteNode(texture: EffectTextures.sparkle, size: CGSize(width: size, height: size))
        flash.position = position
        flash.zPosition = 31
        flash.setScale(0.3)
        flash.blendMode = .add
        parent.addChild(flash)
        let glow = SKSpriteNode(texture: EffectTextures.glow, size: CGSize(width: size * 1.4, height: size * 1.4))
        glow.position = position
        glow.zPosition = 30
        glow.alpha = 0.8
        parent.addChild(glow)
        flash.run(.sequence([.group([.scale(to: 1, duration: 0.07), .rotate(byAngle: 0.4, duration: 0.18)]),
                             .group([.scale(to: 1.3, duration: 0.11), .fadeOut(withDuration: 0.11)]), .removeFromParent()]))
        glow.run(.sequence([.group([.scale(to: 1.3, duration: 0.18), .fadeOut(withDuration: 0.18)]), .removeFromParent()]))
    }

    /// A few four-point twinkles that pop and fade around a point.
    static func twinkles(at position: CGPoint, in parent: SKNode, color: SKColor, count: Int, spread: CGFloat) {
        for i in 0..<count {
            let star = SKSpriteNode(texture: EffectTextures.sparkle, size: CGSize(width: 12, height: 12))
            star.color = color
            star.colorBlendFactor = 0.6
            star.position = CGPoint(x: position.x + .random(in: -spread...spread), y: position.y + .random(in: -spread * 0.4...spread))
            star.zPosition = 32
            star.setScale(0)
            parent.addChild(star)
            star.run(.sequence([
                .wait(forDuration: Double(i) * 0.06),
                .scale(to: 1.1, duration: 0.1), .scale(to: 0.8, duration: 0.08),
                .group([.fadeOut(withDuration: 0.25), .rotate(byAngle: 1, duration: 0.25)]),
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
