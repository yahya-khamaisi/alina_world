import SpriteKit

enum GameGraphics {
    static func goldColor() -> SKColor {
        SKColor(red: 1.0, green: 0.84, blue: 0.28, alpha: 1)
    }

    static func goldHighlight() -> SKColor {
        SKColor(red: 1.0, green: 0.95, blue: 0.55, alpha: 1)
    }

    static func crystalColor() -> SKColor {
        SKColor(red: 0.45, green: 0.85, blue: 1.0, alpha: 1)
    }

    static func skinTone() -> SKColor {
        SKColor(red: 0.98, green: 0.86, blue: 0.72, alpha: 1)
    }

    static func hairColor() -> SKColor {
        SKColor(red: 0.32, green: 0.20, blue: 0.14, alpha: 1)
    }

    static func dressColor() -> SKColor {
        SKColor(red: 0.88, green: 0.32, blue: 0.58, alpha: 1)
    }

    static func dressShadow() -> SKColor {
        SKColor(red: 0.62, green: 0.18, blue: 0.42, alpha: 1)
    }

    static func makeCoinNode() -> SKNode {
        let container = SKNode()
        let outer = SKShapeNode(circleOfRadius: 11)
        outer.fillColor = goldColor()
        outer.strokeColor = SKColor(red: 0.75, green: 0.55, blue: 0.1, alpha: 1)
        outer.lineWidth = 2
        outer.zPosition = 1

        let inner = SKShapeNode(circleOfRadius: 7)
        inner.fillColor = goldHighlight()
        inner.strokeColor = .clear
        inner.zPosition = 2

        let symbol = SKLabelNode(fontNamed: "Helvetica-Bold")
        symbol.text = "¢"
        symbol.fontSize = 10
        symbol.fontColor = SKColor(red: 0.7, green: 0.45, blue: 0.05, alpha: 1)
        symbol.verticalAlignmentMode = .center
        symbol.horizontalAlignmentMode = .center
        symbol.zPosition = 3

        let sparkle = SKShapeNode(circleOfRadius: 3)
        sparkle.fillColor = SKColor.white.withAlphaComponent(0.9)
        sparkle.strokeColor = .clear
        sparkle.position = CGPoint(x: 6, y: 6)
        sparkle.zPosition = 4
        sparkle.run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.35),
                SKAction.fadeIn(withDuration: 0.35)
            ])
        ))

        let shineEmitter = createCoinShineEmitter()
        shineEmitter.position = CGPoint(x: 0, y: 0)
        container.addChild(shineEmitter)

        container.addChild(outer)
        container.addChild(inner)
        container.addChild(symbol)
        container.addChild(sparkle)

        let spin = SKAction.sequence([
            SKAction.scaleX(to: 0.75, duration: 0.25),
            SKAction.scaleX(to: 1.0, duration: 0.25)
        ])
        container.run(SKAction.repeatForever(spin))

        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 4, duration: 0.6),
            SKAction.moveBy(x: 0, y: -4, duration: 0.6)
        ])
        container.run(SKAction.repeatForever(bob))

        return container
    }

    static func makeCrystalNode(palette: WorldPalette) -> SKNode {
        let container = SKNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 12))
        path.addLine(to: CGPoint(x: 10, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -10))
        path.addLine(to: CGPoint(x: -10, y: 0))
        path.closeSubpath()

        let gem = SKShapeNode(path: path)
        gem.fillColor = crystalColor()
        gem.strokeColor = palette.accent
        gem.lineWidth = 2
        gem.zPosition = 1

        let glow = SKShapeNode(circleOfRadius: 14)
        glow.fillColor = crystalColor().withAlphaComponent(0.25)
        glow.strokeColor = .clear
        glow.zPosition = 0
        glow.run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
        ))

        let particleEmitter = createCrystalParticleEmitter()
        particleEmitter.position = CGPoint(x: 0, y: 0)
        container.addChild(particleEmitter)

        container.addChild(glow)
        container.addChild(gem)

        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 4.0)
        container.run(SKAction.repeatForever(rotate))

        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 6, duration: 1.0),
            SKAction.moveBy(x: 0, y: -6, duration: 1.0)
        ])
        container.run(SKAction.repeatForever(bob))

        return container
    }

    static func makeEnemyNode(kind: EnemyNode.EnemyKind, palette: WorldPalette) -> SKNode {
        let container = SKNode()

        switch kind {
        case .crawler:
            let body = SKShapeNode(rectOf: CGSize(width: 32, height: 20), cornerRadius: 5)
            body.fillColor = palette.hazard.withAlphaComponent(0.9)
            body.strokeColor = SKColor(red: 0.5, green: 0.1, blue: 0.1, alpha: 1)
            body.lineWidth = 2
            body.zPosition = 1
            container.addChild(body)

            let bodyHighlight = SKShapeNode(rectOf: CGSize(width: 28, height: 6), cornerRadius: 3)
            bodyHighlight.fillColor = SKColor(white: 1.0, alpha: 0.2)
            bodyHighlight.strokeColor = .clear
            bodyHighlight.position = CGPoint(x: 0, y: 6)
            bodyHighlight.zPosition = 2
            container.addChild(bodyHighlight)

            let eye1 = SKShapeNode(circleOfRadius: 4)
            eye1.fillColor = .white
            eye1.strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
            eye1.lineWidth = 1
            eye1.position = CGPoint(x: -7, y: 4)
            eye1.zPosition = 2

            let eye2 = SKShapeNode(circleOfRadius: 4)
            eye2.fillColor = .white
            eye2.strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
            eye2.lineWidth = 1
            eye2.position = CGPoint(x: 7, y: 4)
            eye2.zPosition = 2

            let pupil1 = SKShapeNode(circleOfRadius: 2)
            pupil1.fillColor = .black
            pupil1.strokeColor = .clear
            pupil1.position = CGPoint(x: -7, y: 4)
            pupil1.zPosition = 3

            let pupil2 = SKShapeNode(circleOfRadius: 2)
            pupil2.fillColor = .black
            pupil2.strokeColor = .clear
            pupil2.position = CGPoint(x: 7, y: 4)
            pupil2.zPosition = 3

            container.addChild(eye1)
            container.addChild(eye2)
            container.addChild(pupil1)
            container.addChild(pupil2)

            let walk = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 2, duration: 0.3),
                SKAction.moveBy(x: 0, y: -2, duration: 0.3)
            ])
            container.run(SKAction.repeatForever(walk))

            let dustEmitter = SKEmitterNode()
            dustEmitter.numParticlesToEmit = 0
            dustEmitter.particleBirthRate = 2
            dustEmitter.particleLifetime = 0.4
            dustEmitter.particlePositionRange = CGVector(dx: 12, dy: 4)
            dustEmitter.emissionAngle = .pi / 2
            dustEmitter.emissionAngleRange = .pi / 4
            dustEmitter.particleSpeed = 20
            dustEmitter.particleAlpha = 0.4
            dustEmitter.particleAlphaSpeed = -1.0
            dustEmitter.particleScale = 0.1
            dustEmitter.particleColor = SKColor(white: 0.5, alpha: 1)
            dustEmitter.position = CGPoint(x: 0, y: -12)
            dustEmitter.zPosition = 0
            container.addChild(dustEmitter)

        case .flyer:
            let body = SKShapeNode(rectOf: CGSize(width: 28, height: 18), cornerRadius: 4)
            body.fillColor = palette.accent.withAlphaComponent(0.85)
            body.strokeColor = SKColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1)
            body.lineWidth = 2
            body.zPosition = 1
            container.addChild(body)

            let wing1 = SKShapeNode()
            let wingPath1 = CGMutablePath()
            wingPath1.move(to: CGPoint(x: -20, y: 0))
            wingPath1.addLine(to: CGPoint(x: -4, y: 4))
            wingPath1.addLine(to: CGPoint(x: -4, y: -4))
            wingPath1.closeSubpath()
            wing1.path = wingPath1
            wing1.fillColor = palette.accent.withAlphaComponent(0.6)
            wing1.strokeColor = .clear
            wing1.position = CGPoint(x: -8, y: 0)
            wing1.zPosition = 0

            let wing2 = SKShapeNode()
            let wingPath2 = CGMutablePath()
            wingPath2.move(to: CGPoint(x: 20, y: 0))
            wingPath2.addLine(to: CGPoint(x: 4, y: 4))
            wingPath2.addLine(to: CGPoint(x: 4, y: -4))
            wingPath2.closeSubpath()
            wing2.path = wingPath2
            wing2.fillColor = palette.accent.withAlphaComponent(0.6)
            wing2.strokeColor = .clear
            wing2.position = CGPoint(x: 8, y: 0)
            wing2.zPosition = 0

            container.addChild(wing1)
            container.addChild(wing2)

            let flap = SKAction.sequence([
                SKAction.scaleY(to: 0.3, duration: 0.1),
                SKAction.scaleY(to: 1.0, duration: 0.1)
            ])
            wing1.run(SKAction.repeatForever(flap))
            wing2.run(SKAction.repeatForever(flap))

            let hover = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 8, duration: 0.8),
                SKAction.moveBy(x: 0, y: -8, duration: 0.8)
            ])
            container.run(SKAction.repeatForever(hover))

            let eye1 = SKShapeNode(circleOfRadius: 3)
            eye1.fillColor = SKColor(red: 1, green: 0.9, blue: 0.3, alpha: 1)
            eye1.strokeColor = .clear
            eye1.position = CGPoint(x: -5, y: 3)
            eye1.zPosition = 2

            let eye2 = SKShapeNode(circleOfRadius: 3)
            eye2.fillColor = SKColor(red: 1, green: 0.9, blue: 0.3, alpha: 1)
            eye2.strokeColor = .clear
            eye2.position = CGPoint(x: 5, y: 3)
            eye2.zPosition = 2

            container.addChild(eye1)
            container.addChild(eye2)

        case .boss:
            let body = SKShapeNode(rectOf: CGSize(width: 56, height: 44), cornerRadius: 10)
            body.fillColor = palette.hazard
            body.strokeColor = SKColor(red: 0.5, green: 0.05, blue: 0.05, alpha: 1)
            body.lineWidth = 4
            body.zPosition = 1
            container.addChild(body)

            let bodyGlow = SKShapeNode(rectOf: CGSize(width: 50, height: 12), cornerRadius: 6)
            bodyGlow.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 0.3)
            bodyGlow.strokeColor = .clear
            bodyGlow.position = CGPoint(x: 0, y: 10)
            bodyGlow.zPosition = 2
            container.addChild(bodyGlow)

            let eye1 = SKShapeNode(circleOfRadius: 7)
            eye1.fillColor = SKColor(red: 1, green: 0.2, blue: 0.1, alpha: 1)
            eye1.strokeColor = SKColor(red: 1, green: 0.5, blue: 0.3, alpha: 1)
            eye1.lineWidth = 2
            eye1.position = CGPoint(x: -14, y: 8)
            eye1.zPosition = 2

            let eye2 = SKShapeNode(circleOfRadius: 7)
            eye2.fillColor = SKColor(red: 1, green: 0.2, blue: 0.1, alpha: 1)
            eye2.strokeColor = SKColor(red: 1, green: 0.5, blue: 0.3, alpha: 1)
            eye2.lineWidth = 2
            eye2.position = CGPoint(x: 14, y: 8)
            eye2.zPosition = 2

            let pupil1 = SKShapeNode(circleOfRadius: 3)
            pupil1.fillColor = .black
            pupil1.strokeColor = .clear
            pupil1.position = CGPoint(x: -14, y: 8)
            pupil1.zPosition = 3

            let pupil2 = SKShapeNode(circleOfRadius: 3)
            pupil2.fillColor = .black
            pupil2.strokeColor = .clear
            pupil2.position = CGPoint(x: 14, y: 8)
            pupil2.zPosition = 3

            container.addChild(eye1)
            container.addChild(eye2)
            container.addChild(pupil1)
            container.addChild(pupil2)

            let crown = SKShapeNode()
            let crownPath = CGMutablePath()
            crownPath.move(to: CGPoint(x: -20, y: 0))
            crownPath.addLine(to: CGPoint(x: -15, y: 14))
            crownPath.addLine(to: CGPoint(x: -10, y: 4))
            crownPath.addLine(to: CGPoint(x: -5, y: 14))
            crownPath.addLine(to: CGPoint(x: 0, y: 4))
            crownPath.addLine(to: CGPoint(x: 5, y: 14))
            crownPath.addLine(to: CGPoint(x: 10, y: 4))
            crownPath.addLine(to: CGPoint(x: 15, y: 14))
            crownPath.addLine(to: CGPoint(x: 20, y: 0))
            crownPath.closeSubpath()
            crown.path = crownPath
            crown.fillColor = goldColor()
            crown.strokeColor = goldHighlight()
            crown.lineWidth = 2
            crown.position = CGPoint(x: 0, y: 26)
            crown.zPosition = 3
            container.addChild(crown)

            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
            body.run(SKAction.repeatForever(pulse))

            let warningEmitter = createBossWarningEmitter()
            warningEmitter.position = CGPoint(x: 0, y: 24)
            container.addChild(warningEmitter)
        }

        return container
    }

    static func makeBlockNode(kind: BlockKind, palette: WorldPalette) -> SKNode {
        let size = CGSize(width: 32, height: 32)
        let container = SKNode()

        switch kind {
        case .solid:
            let base = SKShapeNode(rectOf: size, cornerRadius: 3)
            base.fillColor = palette.block
            base.strokeColor = SKColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 1)
            base.lineWidth = 2
            base.zPosition = 1
            container.addChild(base)

            let highlight = SKShapeNode(rectOf: CGSize(width: 28, height: 4), cornerRadius: 2)
            highlight.fillColor = SKColor(white: 1.0, alpha: 0.25)
            highlight.strokeColor = .clear
            highlight.position = CGPoint(x: 0, y: 11)
            highlight.zPosition = 2
            container.addChild(highlight)

            let shadow = SKShapeNode(rectOf: CGSize(width: 28, height: 4), cornerRadius: 2)
            shadow.fillColor = SKColor(white: 0, alpha: 0.3)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: 0, y: -11)
            shadow.zPosition = 2
            container.addChild(shadow)

            for i in 0..<3 {
                let crack = SKShapeNode(rectOf: CGSize(width: 20, height: 1), cornerRadius: 0.5)
                crack.fillColor = SKColor(white: 0, alpha: 0.15)
                crack.strokeColor = .clear
                crack.position = CGPoint(x: CGFloat.random(in: -6...6), y: CGFloat(-8 + i * 8))
                crack.zPosition = 2
                container.addChild(crack)
            }

        case .ground:
            let base = SKShapeNode(rectOf: size, cornerRadius: 3)
            base.fillColor = palette.ground
            base.strokeColor = SKColor(red: 0.2, green: 0.35, blue: 0.15, alpha: 1)
            base.lineWidth = 2
            base.zPosition = 1
            container.addChild(base)

            let dirtLayer = SKShapeNode(rectOf: CGSize(width: 30, height: 14), cornerRadius: 2)
            dirtLayer.fillColor = SKColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1)
            dirtLayer.strokeColor = .clear
            dirtLayer.position = CGPoint(x: 0, y: -5)
            dirtLayer.zPosition = 2
            container.addChild(dirtLayer)

            let highlight = SKShapeNode(rectOf: CGSize(width: 28, height: 3), cornerRadius: 1.5)
            highlight.fillColor = SKColor(white: 1.0, alpha: 0.2)
            highlight.strokeColor = .clear
            highlight.position = CGPoint(x: 0, y: 11)
            highlight.zPosition = 3
            container.addChild(highlight)

            for i in 0..<8 {
                let blade = SKShapeNode(rectOf: CGSize(width: 3, height: 8), cornerRadius: 1.5)
                blade.fillColor = palette.accent.withAlphaComponent(0.9)
                blade.strokeColor = .clear
                blade.position = CGPoint(x: -13 + CGFloat(i) * 4 + CGFloat.random(in: -1...1), y: 10)
                blade.zPosition = 4
                container.addChild(blade)

                let blade2 = SKShapeNode(rectOf: CGSize(width: 2, height: 6), cornerRadius: 1)
                blade2.fillColor = palette.ground.withAlphaComponent(0.8)
                blade2.strokeColor = .clear
                blade2.position = CGPoint(x: -13 + CGFloat(i) * 4 + CGFloat.random(in: -1...1), y: 9)
                blade2.zPosition = 3
                container.addChild(blade2)
            }

            let flower = SKShapeNode(circleOfRadius: 2)
            flower.fillColor = SKColor(red: 1.0, green: 0.4, blue: 0.5, alpha: 1)
            flower.strokeColor = .clear
            flower.position = CGPoint(x: CGFloat.random(in: -8...8), y: 14)
            flower.zPosition = 5
            container.addChild(flower)

        case .brick:
            let base = SKShapeNode(rectOf: size, cornerRadius: 3)
            base.fillColor = SKColor(red: 0.45, green: 0.3, blue: 0.18, alpha: 1)
            base.strokeColor = SKColor(red: 0.25, green: 0.15, blue: 0.08, alpha: 1)
            base.lineWidth = 2
            base.zPosition = 1
            container.addChild(base)

            let mortarColor = SKColor(red: 0.55, green: 0.5, blue: 0.4, alpha: 1)
            for row in 0..<4 {
                for col in 0..<4 {
                    let offsetX: CGFloat = (row % 2 == 1) ? 4 : 0
                    let brick = SKShapeNode(rectOf: CGSize(width: 13, height: 5), cornerRadius: 1)
                    let variation = CGFloat.random(in: -0.05...0.05)
                    brick.fillColor = SKColor(red: 0.5 + variation, green: 0.3 + variation, blue: 0.15 + variation, alpha: 1)
                    brick.strokeColor = mortarColor
                    brick.lineWidth = 1
                    let bx = -12 + CGFloat(col) * 8 + offsetX
                    let by = 10 - CGFloat(row) * 8
                    brick.position = CGPoint(x: bx, y: by)
                    brick.zPosition = 2
                    container.addChild(brick)

                    let hi = SKShapeNode(rectOf: CGSize(width: 11, height: 1), cornerRadius: 0.5)
                    hi.fillColor = SKColor(white: 1.0, alpha: 0.15)
                    hi.strokeColor = .clear
                    hi.position = CGPoint(x: bx, y: by + 2)
                    hi.zPosition = 3
                    container.addChild(hi)
                }
            }

        case .question:
            let base = SKShapeNode(rectOf: size, cornerRadius: 4)
            base.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.15, alpha: 1)
            base.strokeColor = SKColor(red: 0.85, green: 0.6, blue: 0.05, alpha: 1)
            base.lineWidth = 2.5
            base.zPosition = 1
            container.addChild(base)

            let innerGlow = SKShapeNode(rectOf: CGSize(width: 24, height: 24), cornerRadius: 3)
            innerGlow.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 0.3)
            innerGlow.strokeColor = .clear
            innerGlow.zPosition = 2
            container.addChild(innerGlow)

            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.08, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
            base.run(SKAction.repeatForever(pulse))
            innerGlow.run(SKAction.repeatForever(pulse))

            let mark = SKLabelNode(fontNamed: "Helvetica-Bold")
            mark.text = "?"
            mark.fontSize = 24
            mark.fontColor = SKColor(red: 0.4, green: 0.25, blue: 0.05, alpha: 1)
            mark.verticalAlignmentMode = .center
            mark.horizontalAlignmentMode = .center
            mark.zPosition = 4
            container.addChild(mark)

            let bounce = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 3, duration: 0.4),
                SKAction.moveBy(x: 0, y: -3, duration: 0.4)
            ])
            mark.run(SKAction.repeatForever(bounce))

            let shineEmitter = SKEmitterNode()
            shineEmitter.numParticlesToEmit = 0
            shineEmitter.particleBirthRate = 5
            shineEmitter.particleLifetime = 0.8
            shineEmitter.particleLifetimeRange = 0.3
            shineEmitter.particlePositionRange = CGVector(dx: 10, dy: 10)
            shineEmitter.emissionAngle = .pi / 2
            shineEmitter.emissionAngleRange = .pi * 2
            shineEmitter.particleSpeed = 20
            shineEmitter.particleSpeedRange = 10
            shineEmitter.particleAlpha = 0.8
            shineEmitter.particleAlphaSpeed = -1.0
            shineEmitter.particleScale = 0.15
            shineEmitter.particleScaleRange = 0.05
            shineEmitter.particleScaleSpeed = -0.15
            shineEmitter.particleColor = SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1)
            shineEmitter.particleColorBlendFactor = 1.0
            shineEmitter.zPosition = 5
            container.addChild(shineEmitter)

        case .pipe:
            let pipeBody = SKShapeNode(rectOf: CGSize(width: 30, height: 64), cornerRadius: 4)
            pipeBody.fillColor = SKColor(red: 0.15, green: 0.55, blue: 0.2, alpha: 1)
            pipeBody.strokeColor = SKColor(red: 0.08, green: 0.35, blue: 0.12, alpha: 1)
            pipeBody.lineWidth = 2
            pipeBody.position = CGPoint(x: 0, y: 16)
            pipeBody.zPosition = 1
            container.addChild(pipeBody)

            let pipeHighlight = SKShapeNode(rectOf: CGSize(width: 6, height: 60), cornerRadius: 2)
            pipeHighlight.fillColor = SKColor(red: 0.3, green: 0.75, blue: 0.35, alpha: 0.5)
            pipeHighlight.strokeColor = .clear
            pipeHighlight.position = CGPoint(x: -10, y: 16)
            pipeHighlight.zPosition = 2
            container.addChild(pipeHighlight)

            let pipeRim = SKShapeNode(rectOf: CGSize(width: 36, height: 10), cornerRadius: 4)
            pipeRim.fillColor = SKColor(red: 0.2, green: 0.7, blue: 0.25, alpha: 1)
            pipeRim.strokeColor = SKColor(red: 0.1, green: 0.5, blue: 0.15, alpha: 1)
            pipeRim.lineWidth = 2
            pipeRim.position = CGPoint(x: 0, y: 48)
            pipeRim.zPosition = 3
            container.addChild(pipeRim)

            let rimInner = SKShapeNode(rectOf: CGSize(width: 28, height: 4), cornerRadius: 2)
            rimInner.fillColor = SKColor(red: 0.3, green: 0.8, blue: 0.35, alpha: 0.6)
            rimInner.strokeColor = .clear
            rimInner.position = CGPoint(x: 0, y: 50)
            rimInner.zPosition = 4
            container.addChild(rimInner)

            for i in 0..<3 {
                let bolt = SKShapeNode(circleOfRadius: 2)
                bolt.fillColor = SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1)
                bolt.strokeColor = SKColor(red: 0.3, green: 0.25, blue: 0.15, alpha: 1)
                bolt.lineWidth = 0.5
                bolt.position = CGPoint(x: -12, y: 8 + CGFloat(i) * 20)
                bolt.zPosition = 3
                container.addChild(bolt)

                let bolt2 = SKShapeNode(circleOfRadius: 2)
                bolt2.fillColor = SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1)
                bolt2.strokeColor = SKColor(red: 0.3, green: 0.25, blue: 0.15, alpha: 1)
                bolt2.lineWidth = 0.5
                bolt2.position = CGPoint(x: 12, y: 8 + CGFloat(i) * 20)
                bolt2.zPosition = 3
                container.addChild(bolt2)
            }

        default:
            break
        }

        return container
    }

    static func makeFlagPole(height: CGFloat) -> SKNode {
        let container = SKNode()

        let pole = SKShapeNode(rectOf: CGSize(width: 6, height: height), cornerRadius: 3)
        pole.fillColor = SKColor(red: 0.85, green: 0.85, blue: 0.9, alpha: 1)
        pole.strokeColor = SKColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 1)
        pole.lineWidth = 1
        pole.position = CGPoint(x: 0, y: height / 2)
        pole.zPosition = 1
        container.addChild(pole)

        let poleHighlight = SKShapeNode(rectOf: CGSize(width: 2, height: height - 4), cornerRadius: 1)
        poleHighlight.fillColor = SKColor(white: 1.0, alpha: 0.4)
        poleHighlight.strokeColor = .clear
        poleHighlight.position = CGPoint(x: -2, y: height / 2)
        poleHighlight.zPosition = 2
        container.addChild(poleHighlight)

        let base = SKShapeNode(rectOf: CGSize(width: 16, height: 10), cornerRadius: 3)
        base.fillColor = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1)
        base.strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1)
        base.lineWidth = 1.5
        base.position = CGPoint(x: 0, y: 5)
        base.zPosition = 2
        container.addChild(base)

        let baseDetail = SKShapeNode(rectOf: CGSize(width: 12, height: 4), cornerRadius: 2)
        baseDetail.fillColor = SKColor(red: 0.7, green: 0.7, blue: 0.75, alpha: 1)
        baseDetail.strokeColor = .clear
        baseDetail.position = CGPoint(x: 0, y: 7)
        baseDetail.zPosition = 3
        container.addChild(baseDetail)

        let flag = SKShapeNode()
        let flagPath = CGMutablePath()
        flagPath.move(to: CGPoint(x: 0, y: 0))
        flagPath.addLine(to: CGPoint(x: 30, y: 8))
        flagPath.addLine(to: CGPoint(x: 0, y: 16))
        flagPath.closeSubpath()
        flag.path = flagPath
        flag.fillColor = goldColor()
        flag.strokeColor = goldHighlight()
        flag.lineWidth = 2
        flag.position = CGPoint(x: 3, y: height - 8)
        flag.zPosition = 3
        container.addChild(flag)

        let flagPole = SKShapeNode(rectOf: CGSize(width: 4, height: 20), cornerRadius: 2)
        flagPole.fillColor = SKColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1)
        flagPole.strokeColor = SKColor(red: 0.5, green: 0.35, blue: 0.1, alpha: 1)
        flagPole.lineWidth = 1
        flagPole.position = CGPoint(x: 3, y: height - 18)
        flagPole.zPosition = 2
        container.addChild(flagPole)

        let flagEmblem = SKShapeNode(circleOfRadius: 6)
        flagEmblem.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.3, alpha: 1)
        flagEmblem.strokeColor = SKColor(red: 0.8, green: 0.6, blue: 0.1, alpha: 1)
        flagEmblem.lineWidth = 1.5
        flagEmblem.position = CGPoint(x: 12, y: height - 8)
        flagEmblem.zPosition = 4
        container.addChild(flagEmblem)

        let star = SKLabelNode(fontNamed: "Helvetica-Bold")
        star.text = "★"
        star.fontSize = 10
        star.fontColor = SKColor(red: 0.8, green: 0.6, blue: 0.1, alpha: 1)
        star.position = CGPoint(x: 12, y: height - 8)
        star.zPosition = 5
        star.verticalAlignmentMode = .center
        star.horizontalAlignmentMode = .center
        container.addChild(star)

        let wave = SKAction.sequence([
            SKAction.rotate(byAngle: 0.08, duration: 0.6),
            SKAction.rotate(byAngle: -0.16, duration: 1.2),
            SKAction.rotate(byAngle: 0.08, duration: 0.6)
        ])
        flag.run(SKAction.repeatForever(wave))
        flagEmblem.run(SKAction.repeatForever(wave))
        star.run(SKAction.repeatForever(wave))

        let sparkleEmitter = SKEmitterNode()
        sparkleEmitter.numParticlesToEmit = 0
        sparkleEmitter.particleBirthRate = 3
        sparkleEmitter.particleLifetime = 1.0
        sparkleEmitter.particleLifetimeRange = 0.3
        sparkleEmitter.particlePositionRange = CGVector(dx: 20, dy: 12)
        sparkleEmitter.emissionAngle = .pi / 2
        sparkleEmitter.emissionAngleRange = .pi / 3
        sparkleEmitter.particleSpeed = 30
        sparkleEmitter.particleSpeedRange = 15
        sparkleEmitter.particleAlpha = 0.8
        sparkleEmitter.particleAlphaSpeed = -0.8
        sparkleEmitter.particleScale = 0.15
        sparkleEmitter.particleScaleRange = 0.05
        sparkleEmitter.particleScaleSpeed = -0.1
        sparkleEmitter.particleColor = goldHighlight()
        sparkleEmitter.particleColorBlendFactor = 1.0
        sparkleEmitter.position = CGPoint(x: 18, y: height - 8)
        sparkleEmitter.zPosition = 4
        container.addChild(sparkleEmitter)

        return container
    }

    static func createSparkleEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.numParticlesToEmit = 0
        emitter.particleBirthRate = 3
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3
        emitter.particlePositionRange = CGVector(dx: 12, dy: 12)
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 10
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -1.0
        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.05
        emitter.particleScaleSpeed = -0.15
        emitter.particleColor = SKColor.white
        emitter.particleColorBlendFactor = 1.0
        emitter.zPosition = 4
        return emitter
    }

    static func createCoinShineEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.numParticlesToEmit = 0
        emitter.particleBirthRate = 8
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2
        emitter.particlePositionRange = CGVector(dx: 8, dy: 8)
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 30
        emitter.particleSpeedRange = 15
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -1.5
        emitter.particleScale = 0.12
        emitter.particleScaleRange = 0.05
        emitter.particleScaleSpeed = -0.2
        emitter.particleColor = goldHighlight()
        emitter.particleColorBlendFactor = 1.0
        emitter.zPosition = 5
        return emitter
    }

    static func createCrystalParticleEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.numParticlesToEmit = 0
        emitter.particleBirthRate = 5
        emitter.particleLifetime = 1.0
        emitter.particleLifetimeRange = 0.3
        emitter.particlePositionRange = CGVector(dx: 10, dy: 10)
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 25
        emitter.particleSpeedRange = 15
        emitter.particleAlpha = 0.7
        emitter.particleAlphaSpeed = -0.7
        emitter.particleScale = 0.1
        emitter.particleScaleRange = 0.05
        emitter.particleScaleSpeed = -0.1
        emitter.particleColor = crystalColor()
        emitter.particleColorBlendFactor = 1.0
        emitter.zPosition = 2
        return emitter
    }

    static func createQuestionShineEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.numParticlesToEmit = 0
        emitter.particleBirthRate = 4
        emitter.particleLifetime = 0.7
        emitter.particleLifetimeRange = 0.2
        emitter.particlePositionRange = CGVector(dx: 10, dy: 10)
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 15
        emitter.particleSpeedRange = 10
        emitter.particleAlpha = 0.6
        emitter.particleAlphaSpeed = -0.8
        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.05
        emitter.particleScaleSpeed = -0.15
        emitter.particleColor = SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1)
        emitter.particleColorBlendFactor = 1.0
        emitter.zPosition = 4
        return emitter
    }

    static func createBossWarningEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.numParticlesToEmit = 0
        emitter.particleBirthRate = 2
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.2
        emitter.particlePositionRange = CGVector(dx: 20, dy: 5)
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi / 4
        emitter.particleSpeed = 40
        emitter.particleSpeedRange = 20
        emitter.particleAlpha = 0.7
        emitter.particleAlphaSpeed = -0.9
        emitter.particleScale = 0.2
        emitter.particleScaleRange = 0.1
        emitter.particleScaleSpeed = -0.2
        emitter.particleColor = SKColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 1)
        emitter.particleColorBlendFactor = 1.0
        emitter.zPosition = 3
        return emitter
    }

    static func createHitSpark(at position: CGPoint, in scene: SKScene) {
        let emitter = SKEmitterNode()
        emitter.numParticlesToEmit = 12
        emitter.particleBirthRate = 1200
        emitter.particleLifetime = 0.4
        emitter.particleLifetimeRange = 0.15
        emitter.particlePositionRange = CGVector(dx: 8, dy: 8)
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 120
        emitter.particleSpeedRange = 60
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -2.5
        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.08
        emitter.particleScaleSpeed = -0.3
        emitter.particleColor = SKColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1)
        emitter.particleColorBlendFactor = 1.0
        emitter.zPosition = 20
        emitter.position = position
        scene.addChild(emitter)
        emitter.run(SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.removeFromParent()]))
    }

    static func createExplosion(at position: CGPoint, in scene: SKScene, color: SKColor = SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1)) {
        let emitter = SKEmitterNode()
        emitter.numParticlesToEmit = 30
        emitter.particleBirthRate = 2000
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3
        emitter.particlePositionRange = CGVector(dx: 20, dy: 20)
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 200
        emitter.particleSpeedRange = 100
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -1.2
        emitter.particleScale = 0.3
        emitter.particleScaleRange = 0.15
        emitter.particleScaleSpeed = -0.3
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = SKKeyframeSequence(keyframeValues: [color, SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1), SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1)], times: [0, 0.5, 1.0])
        emitter.zPosition = 25
        emitter.position = position
        scene.addChild(emitter)

        let shockwave = SKShapeNode(circleOfRadius: 10)
        shockwave.strokeColor = color
        shockwave.lineWidth = 3
        shockwave.fillColor = .clear
        shockwave.position = position
        shockwave.zPosition = 24
        scene.addChild(shockwave)
        shockwave.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 5.0, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))

        emitter.run(SKAction.sequence([SKAction.wait(forDuration: 1.0), SKAction.removeFromParent()]))
    }

    static func createLevelCompleteEffect(in scene: SKScene, at position: CGPoint) {
        for _ in 0..<5 {
            let emitter = SKEmitterNode()
            emitter.numParticlesToEmit = 20
            emitter.particleBirthRate = 2000
            emitter.particleLifetime = 1.2
            emitter.particleLifetimeRange = 0.4
            emitter.particlePositionRange = CGVector(dx: 50, dy: 10)
            emitter.emissionAngle = .pi / 2
            emitter.emissionAngleRange = .pi / 3
            emitter.particleSpeed = 150
            emitter.particleSpeedRange = 80
            emitter.particleAlpha = 0.9
            emitter.particleAlphaSpeed = -0.8
            emitter.particleScale = 0.25
            emitter.particleScaleRange = 0.1
            emitter.particleScaleSpeed = -0.2
            emitter.particleColor = [goldColor(), goldHighlight(), crystalColor()].randomElement()!
            emitter.particleColorBlendFactor = 1.0
            emitter.zPosition = 30
            emitter.position = CGPoint(x: position.x + CGFloat.random(in: -60...60), y: position.y)
            scene.addChild(emitter)
            emitter.run(SKAction.sequence([SKAction.wait(forDuration: 1.5), SKAction.removeFromParent()]))
        }

        let text = SKLabelNode(fontNamed: "Helvetica-Bold")
        text.text = "MISSION COMPLETE"
        text.fontSize = 32
        text.fontColor = goldHighlight()
        text.position = CGPoint(x: position.x, y: position.y + 100)
        text.zPosition = 35
        text.setScale(0.1)
        scene.addChild(text)
        text.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.2, duration: 0.3),
                SKAction.fadeIn(withDuration: 0.3)
            ]),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
}