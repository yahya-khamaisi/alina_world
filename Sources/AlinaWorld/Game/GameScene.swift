import SpriteKit

enum GameOutcome {
    case playing
    case won
    case lost
    case paused
}

final class GameScene: SKScene, SKPhysicsContactDelegate {
    var mission: Mission!
    var onOutcome: ((GameOutcome, Int) -> Void)?
    var onTransitionComplete: (() -> Void)?

    private var alina = AlinaNode()
    private var builtLevel: BuiltLevel?
    private var solidRects: [CGRect] = []
    private var slopeRects: [(rect: CGRect, kind: TileKind)] = []
    private var platformRects: [CGRect] = []
    private var movingPlatforms: [MovingPlatform] = []
    private var questionBlocks: [BlockNode] = []
    private var brickBlocks: [BlockNode] = []

    private var lives = 3
    private var coins = 0
    private var crystals = 0
    private var elapsed: CGFloat = 0
    private var outcome: GameOutcome = .playing
    private var bossDefeated = false

    private let parallax = ParallaxBackground()
    private let cameraNode = SKCameraNode()
    private var weatherSystem: WeatherSystem?
    private var lightingSystem: LightingSystem?
    private var transitionManager: SceneTransitionManager?

    private var timeOfDay: TimeOfDay = .morning
    private var timeOfDayProgress: CGFloat = 0
    private let dayCycleDuration: CGFloat = 300.0
    private var lastUpdateTime: TimeInterval = 0

    override func didMove(to view: SKView) {
        guard let mission else { return }
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0, y: 0)

        camera = cameraNode
        addChild(cameraNode)

        weatherSystem = WeatherSystem(scene: self, cameraNode: cameraNode)
        lightingSystem = LightingSystem(scene: self, cameraNode: cameraNode)
        transitionManager = SceneTransitionManager(scene: self)

        builtLevel = LevelBuilder.build(mission: mission, in: self)
        guard let level = builtLevel else { return }

        solidRects = level.map.solidRects()
        slopeRects = level.map.slopeRects()
        platformRects = level.map.platformRects()
        movingPlatforms = level.movingPlatforms
        questionBlocks = level.worldNode.children.compactMap { node -> BlockNode? in
            guard let block = node as? BlockNode, block.blockKind == .question else { return nil }
            return block
        }
        brickBlocks = level.worldNode.children.compactMap { node -> BlockNode? in
            guard let block = node as? BlockNode, block.blockKind == .brick else { return nil }
            return block
        }

        alina.position = level.playerStart
        level.worldNode.addChild(alina)
        lightingSystem?.addPlayerLight(to: alina)

        setupWorldPalettes(level: level)
        setupWeatherAndLighting(level: level)

        InputController.shared.mode = .gameplay
        InputController.shared.startMonitoring()
    }

    private func setupWorldPalettes(level: BuiltLevel) {
        let mapWidth = level.map.worldSize().width
        let palette = level.palette

        let timeOfDay = determineTimeOfDay(from: mission)
        self.timeOfDay = timeOfDay

        parallax.attach(to: self, palette: palette, mapWidth: mapWidth, timeOfDay: timeOfDay)

        for hazard in level.hazards {
            lightingSystem?.addShadowCaster(hazard)
        }
        for enemy in level.enemies {
            lightingSystem?.addShadowCaster(enemy)
        }
        for platform in level.movingPlatforms {
            lightingSystem?.addShadowCaster(platform.node)
        }
    }

    private func determineTimeOfDay(from mission: Mission) -> TimeOfDay {
        let act = mission.act
        switch act {
        case 1: return .dawn
        case 2: return .morning
        case 3: return .noon
        case 4: return .afternoon
        case 5: return .dusk
        case 6: return .night
        default: return .morning
        }
    }

    private func setupWeatherAndLighting(level: BuiltLevel) {
        let world = mission.world.lowercased()
        let weather: WeatherType
        let intensity: CGFloat

        switch world {
        case "brook":
            weather = .rain
            intensity = 0.6
        case "storm":
            weather = .storm
            intensity = 0.8
        case "grove":
            weather = .fog
            intensity = 0.4
        case "cavern":
            weather = .fog
            intensity = 0.5
        case "marsh":
            weather = .fog
            intensity = 0.3
        case "ridge":
            weather = .wind
            intensity = 0.5
        case "spire":
            weather = .wind
            intensity = 0.4
        case "throne":
            weather = .storm
            intensity = 0.7
        default:
            weather = .none
            intensity = 0
        }

        weatherSystem?.setWeather(weather, intensity: intensity)
        lightingSystem?.setWeather(weather, intensity: intensity)
        lightingSystem?.setTimeOfDay(timeOfDay)
    }

    override func willMove(from view: SKView) {
        InputController.shared.mode = .menu
        weatherSystem?.cleanup()
        lightingSystem?.cleanup()
        parallax.cleanup()
    }

    override func update(_ currentTime: TimeInterval) {
        guard outcome == .playing, let mission, let level = builtLevel else { return }

        let delta: TimeInterval
        if lastUpdateTime > 0 {
            delta = currentTime - lastUpdateTime
        } else {
            delta = 1.0 / 60.0
        }
        lastUpdateTime = currentTime
        let dt = CGFloat(min(delta, 1.0 / 30.0))
        elapsed += dt

        updateTimeOfDay(dt: dt)
        updateMovingPlatforms(dt: dt)

        if InputController.shared.consumePause() {
            outcome = .paused
            InputController.shared.mode = .menu
            onOutcome?(.paused, coins)
            return
        }

        if InputController.shared.consumeFullscreen() {
            AppWindowController.toggleFullscreen()
        }

        if let timeLimit = mission.timeLimit {
            if elapsed > CGFloat(timeLimit) {
                loseLife()
                return
            }
        }

        alina.update(input: InputController.shared, delta: delta, difficulty: mission.difficulty)
        moveAndCollide(delta: delta)

        for enemy in level.enemies where enemy.alive {
            enemy.update(delta: delta)
            handleEnemyCollision(enemy)
        }

        checkCollectibles(level)
        checkFlag(level)
        checkHazards(level)
        checkFallDeath()
        updateCamera(delta: dt)

        weatherSystem?.update(delta: delta, cameraX: cameraNode.position.x)
        lightingSystem?.update(delta: delta, cameraX: cameraNode.position.x, playerPosition: alina.position)
        parallax.update(cameraX: cameraNode.position.x - size.width / 2, viewWidth: size.width, delta: delta, timeOfDay: timeOfDay)

        if mission.objective == .defeatBoss && bossDefeated {
            win()
        } else if mission.objective == .collectN {
            let required = mission.collectRequired
            if crystals >= required {
                win()
            }
        }
    }

    private func updateTimeOfDay(dt: CGFloat) {
        timeOfDayProgress += dt / dayCycleDuration
        if timeOfDayProgress >= 1.0 {
            timeOfDayProgress = 0
        }
    }

    private func updateMovingPlatforms(dt: CGFloat) {
        for i in 0..<movingPlatforms.count {
            var platform = movingPlatforms[i]
            let path = platform.path
            guard path.count >= 2 else { continue }

            let currentPoint = path[platform.currentIndex]
            let nextIndex = (platform.currentIndex + 1) % path.count
            let nextPoint = path[nextIndex]

            let distance = hypot(nextPoint.x - currentPoint.x, nextPoint.y - currentPoint.y)
            let travelTime = distance / platform.speed
            platform.progress += dt / travelTime

            if platform.progress >= 1.0 {
                platform.progress = 0
                platform.currentIndex = nextIndex
            }

            let targetX = lerp(currentPoint.x, nextPoint.x, platform.progress)
            let targetY = lerp(currentPoint.y, nextPoint.y, platform.progress)
            platform.node.position = CGPoint(x: targetX, y: targetY)

            movingPlatforms[i] = platform
        }
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    private func moveAndCollide(delta: TimeInterval) {
        let dt = CGFloat(delta)
        var rect = alina.collisionRect

        rect.origin.x += alina.velocityX * dt
        resolveAxis(&rect, axis: .horizontal)
        checkSlopeCollisionHorizontal(&rect)

        rect.origin.y += alina.velocityY * dt
        let wasOnGround = alina.onGround
        alina.onGround = false
        resolveAxis(&rect, axis: .vertical)
        checkSlopeCollisionVertical(&rect)
        checkPlatformCollision(&rect)

        if !wasOnGround && alina.onGround && alina.velocityY < 0 {
            alina.velocityY = 0
        }

        alina.position = CGPoint(x: rect.midX, y: rect.midY)
        checkHeadBonk()
    }

    private enum Axis { case horizontal, vertical }

    private func resolveAxis(_ rect: inout CGRect, axis: Axis) {
        for tile in solidRects {
            guard rect.intersects(tile) else { continue }

            switch axis {
            case .horizontal:
                if alina.velocityX > 0 {
                    rect.origin.x = tile.minX - rect.width
                } else if alina.velocityX < 0 {
                    rect.origin.x = tile.maxX
                }
                alina.velocityX = 0
            case .vertical:
                if alina.velocityY < 0 {
                    rect.origin.y = tile.maxY
                    alina.onGround = true
                    alina.velocityY = 0
                } else if alina.velocityY > 0 {
                    rect.origin.y = tile.minY - rect.height
                    alina.velocityY = 0
                }
            }
        }
    }

    private func checkSlopeCollisionHorizontal(_ rect: inout CGRect) {
        let feetY = rect.minY + 2
        let leftX = rect.minX
        let rightX = rect.maxX

        for (slopeRect, kind) in slopeRects {
            if slopeRect.maxY > feetY && slopeRect.minY < feetY + 4 {
                if alina.velocityX > 0 && rightX >= slopeRect.minX - 2 && rightX <= slopeRect.minX + 4 {
                    let normal = slopeNormal(for: kind, at: CGPoint(x: rightX, y: feetY), in: slopeRect)
                    if let normal = normal, normal.dy > 0 {
                        let targetY = slopeRect.minY + (rightX - slopeRect.minX) * (normal.dy / max(abs(normal.dx), 0.001))
                        if targetY > feetY && targetY < feetY + 8 {
                            rect.origin.y = targetY - rect.height / 2
                            alina.onGround = true
                            alina.velocityY = 0
                        }
                    }
                } else if alina.velocityX < 0 && leftX <= slopeRect.maxX + 2 && leftX >= slopeRect.maxX - 4 {
                    let normal = slopeNormal(for: kind, at: CGPoint(x: leftX, y: feetY), in: slopeRect)
                    if let normal = normal, normal.dy > 0 {
                        let targetY = slopeRect.minY + (leftX - slopeRect.minX) * (normal.dy / max(abs(normal.dx), 0.001))
                        if targetY > feetY && targetY < feetY + 8 {
                            rect.origin.y = targetY - rect.height / 2
                            alina.onGround = true
                            alina.velocityY = 0
                        }
                    }
                }
            }
        }
    }

    private func checkSlopeCollisionVertical(_ rect: inout CGRect) {
        guard alina.velocityY < 0 else { return }

        let centerX = rect.midX
        let feetY = rect.minY

        for (slopeRect, kind) in slopeRects {
            if centerX > slopeRect.minX && centerX < slopeRect.maxX {
                if feetY <= slopeRect.maxY && feetY >= slopeRect.minY - 4 {
                    let normal = slopeNormal(for: kind, at: CGPoint(x: centerX, y: feetY), in: slopeRect)
                    if let normal = normal, normal.dy > 0 {
                        let t = (centerX - slopeRect.minX) / slopeRect.width
                        let slopeHeight = slopeRect.maxY - (slopeRect.maxY - slopeRect.minY) * abs(t - 0.5) * 2
                        if feetY <= slopeHeight + 4 && feetY >= slopeHeight - 2 {
                            rect.origin.y = slopeHeight
                            alina.onGround = true
                            alina.velocityY = 0

                            if abs(alina.velocityX) > 50 {
                                alina.velocityX += normal.dx * 200 * 0.016
                            }
                        }
                    }
                }
            }
        }
    }

    private func checkPlatformCollision(_ rect: inout CGRect) {
        guard alina.velocityY < 0 else { return }

        let centerX = rect.midX
        let feetY = rect.minY

        for platformRect in platformRects {
            if centerX > platformRect.minX + 4 && centerX < platformRect.maxX - 4 {
                if feetY <= platformRect.maxY + 4 && feetY >= platformRect.maxY - 4 {
                    rect.origin.y = platformRect.maxY
                    alina.onGround = true
                    alina.velocityY = 0
                }
            }
        }

        for platform in movingPlatforms {
            let platformRect = CGRect(x: platform.node.position.x - 64, y: platform.node.position.y - 7, width: 128, height: 14)
            if centerX > platformRect.minX + 4 && centerX < platformRect.maxX - 4 {
                if feetY <= platformRect.maxY + 4 && feetY >= platformRect.maxY - 4 {
                    rect.origin.y = platformRect.maxY
                    alina.onGround = true
                    alina.velocityY = 0
                    alina.velocityX += platform.node.position.x - platform.path[platform.currentIndex].x
                }
            }
        }
    }

    private func slopeNormal(for kind: TileKind, at point: CGPoint, in rect: CGRect) -> CGVector? {
        let localX = point.x - rect.minX
        let tileSize = GameConstants.tileSize
        let t = localX / tileSize

        switch kind {
        case .slopeUpRight:
            return CGVector(dx: -t, dy: 1 - t).normalized()
        case .slopeUpLeft:
            return CGVector(dx: t - 1, dy: 1 - t).normalized()
        case .slopeDownRight:
            return CGVector(dx: t, dy: t).normalized()
        case .slopeDownLeft:
            return CGVector(dx: 1 - t, dy: t).normalized()
        default:
            return nil
        }
    }

    private func checkHeadBonk() {
        let head = CGRect(x: alina.position.x - 8, y: alina.position.y + 8, width: 16, height: 8)
        for block in questionBlocks where !block.revealed {
            let blockRect = CGRect(x: block.position.x - 16, y: block.position.y - 16, width: 32, height: 32)
            if head.intersects(blockRect) && alina.velocityY > 0 {
                block.bump()
                block.revealed = true
                block.color = block.blockKind == .question ? SKColor.gray.withAlphaComponent(0.5) : block.color
                coins += 1
                spawnCoinPop(at: block.position)
                alina.velocityY = 0
            }
        }
        for block in brickBlocks {
            let blockRect = CGRect(x: block.position.x - 16, y: block.position.y - 16, width: 32, height: 32)
            if head.intersects(blockRect) && alina.velocityY > 0 {
                block.bump()
                block.hitCount += 1
                if block.hitCount >= 2 {
                    let blockRect = CGRect(x: block.position.x - 16, y: block.position.y - 16, width: 32, height: 32)
                    spawnBrickDebris(at: block.position)
                    block.removeFromParent()
                    brickBlocks.removeAll { $0 == block }
                    solidRects.removeAll { $0 == blockRect }
                }
                alina.velocityY = 0
            }
        }
    }

    private func spawnCoinPop(at position: CGPoint) {
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = "+1"
        label.fontSize = 18
        label.fontColor = GameGraphics.goldHighlight()
        label.position = position
        label.zPosition = 15
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 30, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func spawnBrickDebris(at position: CGPoint) {
        for _ in 0..<6 {
            let debris = SKShapeNode(rectOf: CGSize(width: 6, height: 6), cornerRadius: 1)
            debris.fillColor = SKColor(red: 0.55, green: 0.4, blue: 0.25, alpha: 1)
            debris.strokeColor = .clear
            debris.position = position
            debris.zPosition = 10
            addChild(debris)
            let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
            let speed = CGFloat.random(in: 100...200)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed + 150
            debris.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx * 0.5, y: dy * 0.5, duration: 0.5),
                    SKAction.rotate(byAngle: CGFloat.random(in: -2...2), duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func handleEnemyCollision(_ enemy: EnemyNode) {
        let enemyRect = CGRect(x: enemy.position.x - enemy.size.width / 2, y: enemy.position.y - enemy.size.height / 2, width: enemy.size.width, height: enemy.size.height)
        let playerRect = alina.collisionRect
        guard playerRect.intersects(enemyRect) else { return }

        let playerFeet = playerRect.minY
        let enemyTop = enemyRect.maxY
        let falling = alina.velocityY < 0
        let stompWindow = playerFeet >= enemyTop - 10

        if falling && stompWindow {
            let defeated = enemy.stomp()
            alina.applyBounce()
            spawnStompEffect(at: enemy.position)
            if enemy.enemyKind == .boss && defeated {
                bossDefeated = true
            }
        } else if alina.stompGraceTimer <= 0 && alina.hurtCooldown <= 0 {
            alina.knockback(from: enemy.position.x)
            loseLife()
        }
    }

    private func spawnStompEffect(at position: CGPoint) {
        let poof = SKEmitterNode()
        poof.numParticlesToEmit = 8
        poof.particleBirthRate = 200
        poof.particleLifetime = 0.3
        poof.particleLifetimeRange = 0.1
        poof.particlePositionRange = CGVector(dx: 16, dy: 8)
        poof.emissionAngle = .pi / 2
        poof.emissionAngleRange = .pi / 2
        poof.particleSpeed = 80
        poof.particleSpeedRange = 40
        poof.particleAlpha = 0.8
        poof.particleAlphaSpeed = -2.5
        poof.particleScale = 0.2
        poof.particleScaleRange = 0.1
        poof.particleScaleSpeed = -0.3
        poof.particleColor = SKColor(white: 0.8, alpha: 1)
        poof.zPosition = 15
        poof.position = position
        addChild(poof)
        poof.run(SKAction.sequence([SKAction.wait(forDuration: 0.4), SKAction.removeFromParent()]))
    }

    private func checkCollectibles(_ level: BuiltLevel) {
        let playerRect = alina.collisionRect
        for collectible in level.collectibles where collectible.parent != nil {
            let cRect = CGRect(x: collectible.position.x - 12, y: collectible.position.y - 12, width: 24, height: 24)
            if playerRect.intersects(cRect) {
                collectible.collect()
                if collectible.kind == .coin {
                    coins += 1
                    spawnCoinPop(at: collectible.position)
                } else {
                    crystals += 1
                    spawnCrystalPop(at: collectible.position)
                }
            }
        }
    }

    private func spawnCrystalPop(at position: CGPoint) {
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = "★"
        label.fontSize = 22
        label.fontColor = GameGraphics.crystalColor()
        label.position = position
        label.zPosition = 15
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 40, duration: 0.8),
                SKAction.scale(to: 1.5, duration: 0.4),
                SKAction.scale(to: 1.0, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.8)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func checkFlag(_ level: BuiltLevel) {
        guard mission.objective == .reachFlag, let flag = level.flagNode else { return }
        let flagVisualX = flag.position.x + 14
        let flagRect = CGRect(x: flagVisualX - 16, y: flag.position.y - 24, width: 32, height: 48)
        if alina.collisionRect.intersects(flagRect) {
            win()
        }
    }

    private func checkHazards(_ level: BuiltLevel) {
        let playerRect = alina.collisionRect
        for hazard in level.hazards {
            let hRect = CGRect(x: hazard.position.x - 12, y: hazard.position.y - 8, width: 24, height: 16)
            if playerRect.intersects(hRect) {
                loseLife()
                return
            }
        }
    }

    private func checkFallDeath() {
        if alina.position.y < -64 {
            loseLife()
        }
    }

    private func loseLife() {
        lives -= 1
        if lives <= 0 {
            outcome = .lost
            onOutcome?(.lost, coins)
        } else {
            alina.position = builtLevel?.playerStart ?? alina.position
            alina.velocityX = 0
            alina.velocityY = 0
            alina.hurtCooldown = 0
        }
    }

    private func win() {
        outcome = .won
        GameProgress.shared.recordCompletion(missionID: mission.id, coins: coins)
        onOutcome?(.won, coins)
    }

    private func updateCamera(delta: CGFloat) {
        guard let level = builtLevel else { return }
        let mapWidth = level.map.worldSize().width
        let viewWidth = size.width
        var targetX = alina.position.x + 100
        targetX = max(viewWidth / 2, min(mapWidth - viewWidth / 2, targetX))
        let targetY = max(size.height / 2, alina.position.y + 40)

        let currentX = cameraNode.position.x
        let currentY = cameraNode.position.y
        let lerpFactor: CGFloat = 1.0 - exp(-12.0 * delta)
        cameraNode.position = CGPoint(
            x: currentX + (targetX - currentX) * lerpFactor,
            y: currentY + (targetY - currentY) * lerpFactor
        )
    }

    func resume() {
        outcome = .playing
    }

    var hudState: (lives: Int, coins: Int, crystals: Int, missionTitle: String, elapsed: CGFloat, timeLimit: Int?) {
        (lives, coins, crystals, mission?.title ?? "", elapsed, mission?.timeLimit)
    }

    func transitionToNextMission(_ nextMission: Mission, completion: @escaping () -> Void) {
        let newScene = GameScene()
        newScene.mission = nextMission
        newScene.onOutcome = onOutcome
        newScene.onTransitionComplete = completion
        transitionManager?.transition(to: newScene, type: .slide(direction: .left, duration: 0.6), completion: completion)
    }

    private struct SeededRNG {
        private var state: UInt64
        init(seed: UInt64) { state = seed == 0 ? 1 : seed }
        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
    }
}
