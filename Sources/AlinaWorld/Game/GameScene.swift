import SpriteKit

struct MissionResult: Equatable {
    let missionID: Int
    let petals: Int
    let time: CGFloat
    let hits: Int
    let parTime: CGFloat
    /// Completed, under par time, no damage.
    let stars: [Bool]
    let newBestTime: Bool

    var starCount: Int { stars.filter { $0 }.count }
}

enum GameOutcome {
    case won(MissionResult)
    case lost(reason: String)
}

/// Values the SwiftUI HUD renders; compared before publishing so the HUD only redraws on change.
struct HUDSnapshot: Equatable {
    var hearts = 3
    var maxHearts = 3
    var petals = 0
    var shards = 0
    var shardTarget: Int?
    var bossHits = 0
    var seconds = 0
    var countdown = false
    var bloom = false
    var ribbon = false
    var progress: CGFloat = 0
}

final class GameScene: SKScene {
    var mission: Mission!
    var onOutcome: ((GameOutcome) -> Void)?
    var onPauseRequested: (() -> Void)?
    var assistMode = false
    var ambientParticles = true

    private let alina = AlinaNode()
    private var builtLevel: BuiltLevel?
    private var solidRects: [CGRect] = []
    private var slopeRects: [(rect: CGRect, kind: TileKind)] = []
    private var platformRects: [CGRect] = []
    private var movingPlatforms: [MovingPlatform] = []
    private var questionBlocks: [BlockNode] = []
    private var brickBlocks: [BlockNode] = []
    private var collectibles: [CollectibleNode] = []
    private var springRects: [CGRect] = []
    private var bloomBlocksOpened = 0

    private var hearts = 3
    private var maxHearts = 3
    private var petals = 0
    private var shards = 0
    private var hits = 0
    private var elapsed: CGFloat = 0
    private var finished = false
    private(set) var gamePaused = false
    private var bossDefeated = false
    private var checkpoint: CGPoint = .zero

    private let parallax = ParallaxBackground()
    private let foreground = ForegroundLayer()
    /// Where the camera follows to; shake is added on top so smoothing never eats it.
    private var cameraBase: CGPoint?
    private var shakeAmount: CGFloat = 0
    /// Hit-stop: gameplay freezes for a few frames on big impacts so they land with weight.
    private var hitStop: CGFloat = 0
    #if DEBUG
    private let rigPreview = RigPreview()
    #endif
    private let cameraNode = SKCameraNode()
    private var lastUpdateTime: TimeInterval = 0

    private var timeLimit: CGFloat? {
        guard let limit = mission?.timeLimit else { return nil }
        return CGFloat(limit) * (assistMode ? 1.3 : 1)
    }

    private var mapWidth: CGFloat { builtLevel?.map.worldSize().width ?? size.width }

    private var parTime: CGFloat {
        if let limit = mission.timeLimit { return CGFloat(limit) * 0.75 }
        return CGFloat(builtLevel?.map.width ?? 100) * 0.3 + 10
    }

    // MARK: Setup

    override func didMove(to view: SKView) {
        guard let mission, builtLevel == nil else { return }
        scaleMode = .resizeFill
        anchorPoint = .zero

        camera = cameraNode
        addChild(cameraNode)
        updateCameraScale()

        let level = LevelBuilder.build(mission: mission, in: self)
        builtLevel = level

        solidRects = level.map.solidRects()
        slopeRects = level.map.slopeRects()
        platformRects = level.map.platformRects()
        movingPlatforms = level.movingPlatforms
        collectibles = level.collectibles
        let blocks = level.worldNode.children.compactMap { $0 as? BlockNode }
        questionBlocks = blocks.filter { $0.blockKind == .question }.sorted { $0.position.x < $1.position.x }
        brickBlocks = blocks.filter { $0.blockKind == .brick }
        springRects = blocks.filter { $0.blockKind == .spring }.map {
            CGRect(x: $0.position.x - 16, y: $0.position.y - 16, width: 32, height: 32)
        }
        alina.slippery = level.theme.key == "frost"
        #if DEBUG
        // Development shortcut for checking power-up art: ALINA_POWERUPS=ribbon,bloom
        let powerUps = ProcessInfo.processInfo.environment["ALINA_POWERUPS"] ?? ""
        if powerUps.contains("ribbon") { alina.grantRibbon() }
        if powerUps.contains("bloom") { alina.grantBloom() }
        #endif

        maxHearts = assistMode ? 4 : 3
        hearts = maxHearts
        checkpoint = level.playerStart
        alina.position = level.playerStart
        level.worldNode.addChild(alina)

        #if DEBUG
        if RigPreview.enabled { rigPreview.attach(to: cameraNode) }
        #endif
        foreground.attach(to: self, theme: level.theme, mapWidth: level.map.worldSize().width)
        parallax.attach(
            to: self,
            theme: level.theme,
            weather: mission.weather,
            mapWidth: level.map.worldSize().width,
            groundTop: level.groundTop,
            ambientParticles: ambientParticles
        )

        let visible = visibleRect
        cameraNode.position = CGPoint(x: max(visible.width / 2, alina.position.x + 80), y: visible.height / 2)

        InputController.shared.mode = .gameplay
        InputController.shared.startMonitoring()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        updateCameraScale()
    }

    private func updateCameraScale() {
        guard size.height > 0 else { return }
        cameraNode.setScale(GameConstants.viewHeight / size.height)
    }

    /// Camera view in world coordinates.
    private var visibleRect: CGRect {
        let scale = cameraNode.xScale
        let w = size.width * scale
        let h = size.height * scale
        return CGRect(x: cameraNode.position.x - w / 2, y: cameraNode.position.y - h / 2, width: w, height: h)
    }

    override func willMove(from view: SKView) {
        InputController.shared.mode = .menu
        parallax.cleanup()
        foreground.cleanup()
    }

    // MARK: Pause

    func pauseGame() {
        guard !gamePaused, !finished else { return }
        gamePaused = true
        isPaused = true
        InputController.shared.mode = .menu
        // Esc sets both pause and escape; drop the escape too, or the pause menu reads it as "resume" at once.
        InputController.shared.clearPresses()
    }

    func resumeGame() {
        gamePaused = false
        isPaused = false
        lastUpdateTime = 0
        InputController.shared.mode = .gameplay
        _ = InputController.shared.consumePause()
    }

    func restartFromCheckpoint() {
        alina.resetForRespawn(at: checkpoint)
        resumeGame()
    }

    // MARK: Loop

    override func update(_ currentTime: TimeInterval) {
        guard !finished, !gamePaused, let mission, let level = builtLevel else { return }

        let delta = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 1.0 / 60.0
        lastUpdateTime = currentTime
        let clamped = min(delta, 1.0 / 30.0)
        let dt = CGFloat(clamped)
        if hitStop > 0 {
            hitStop -= dt
            updateCamera(delta: dt)
            return
        }
        elapsed += dt

        if InputController.shared.consumePause() {
            pauseGame()
            onPauseRequested?()
            return
        }
        if InputController.shared.consumeFullscreen() {
            AppWindowController.toggleFullscreen()
        }
        if let timeLimit, elapsed > timeLimit {
            fail(reason: "The light faded before Alina reached it.")
            return
        }

        updateMovingPlatforms(dt: dt)
        alina.update(input: InputController.shared, delta: clamped, difficulty: mission.difficulty)
        if alina.didAirJump {
            GameGraphics.sparklePuff(at: CGPoint(x: alina.position.x, y: alina.position.y - 18), in: level.worldNode)
        }
        moveAndCollide(delta: clamped)
        if alina.attackSerial != lastAttackSerial {
            lastAttackSerial = alina.attackSerial
            struckThisSwing.removeAll()
            swoosh(in: level.worldNode)
        }

        for enemy in level.enemies where enemy.alive {
            enemy.update(delta: clamped, target: alina.position)
            handleAttack(on: enemy)
            if enemy.alive { handleEnemyCollision(enemy) }
        }

        checkCollectibles()
        checkFlag(level)
        checkHazards(level)
        checkFallDeath()
        updateCheckpoint()
        updateCamera(delta: dt)
        parallax.update(visible: visibleRect, delta: clamped)
        foreground.update(visible: visibleRect, delta: clamped)
        #if DEBUG
        rigPreview.update(dt: dt)
        #endif

        if mission.objective == .defeatBoss && bossDefeated {
            win()
        } else if mission.objective == .collectN && shards >= mission.collectRequired {
            win()
        }
    }

    private func updateMovingPlatforms(dt: CGFloat) {
        for i in movingPlatforms.indices {
            var platform = movingPlatforms[i]
            guard platform.path.count >= 2 else { continue }
            let current = platform.path[platform.currentIndex]
            let nextIndex = (platform.currentIndex + 1) % platform.path.count
            let next = platform.path[nextIndex]
            let distance = max(1, hypot(next.x - current.x, next.y - current.y))
            platform.progress += dt / (distance / platform.speed)
            if platform.progress >= 1.0 {
                platform.progress = 0
                platform.currentIndex = nextIndex
            }
            platform.node.position = CGPoint(
                x: current.x + (next.x - current.x) * platform.progress,
                y: current.y + (next.y - current.y) * platform.progress
            )
            movingPlatforms[i] = platform
        }
    }

    // MARK: Collision

    private func moveAndCollide(delta: TimeInterval) {
        let dt = CGFloat(delta)
        var rect = alina.collisionRect
        let previousFeet = rect.minY

        rect.origin.x += alina.velocityX * dt
        rect.origin.x = max(0, min(mapWidth - rect.width, rect.origin.x))
        resolveAxis(&rect, axis: .horizontal)

        rect.origin.y += alina.velocityY * dt
        alina.onGround = false
        resolveAxis(&rect, axis: .vertical)
        checkSlopeCollisionVertical(&rect)
        checkPlatformCollision(&rect, previousFeet: previousFeet)
        checkSprings(rect)

        alina.position = CGPoint(x: rect.midX, y: rect.midY)
        checkHeadBonk()
    }

    private enum Axis { case horizontal, vertical }

    private func resolveAxis(_ rect: inout CGRect, axis: Axis) {
        for tile in solidRects where rect.intersects(tile) {
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

    private func checkSlopeCollisionVertical(_ rect: inout CGRect) {
        guard alina.velocityY <= 0 else { return }
        for (slopeRect, kind) in slopeRects where rect.midX > slopeRect.minX && rect.midX < slopeRect.maxX {
            let t = (rect.midX - slopeRect.minX) / slopeRect.width
            let rising = kind == .slopeUpRight || kind == .slopeDownLeft
            let surface = slopeRect.minY + slopeRect.height * (rising ? t : 1 - t)
            if rect.minY <= surface + 4 && rect.minY >= surface - 10 {
                rect.origin.y = surface
                alina.onGround = true
                alina.velocityY = 0
            }
        }
    }

    /// One-way leaf-pads: Alina lands when her feet cross the top this frame, however fast she falls.
    private func checkPlatformCollision(_ rect: inout CGRect, previousFeet: CGFloat) {
        guard alina.velocityY <= 0 else { return }
        let feetY = rect.minY

        for platformRect in platformRects where rect.maxX > platformRect.minX + 2 && rect.minX < platformRect.maxX - 2 {
            if feetY <= platformRect.maxY && previousFeet >= platformRect.maxY - 2 {
                rect.origin.y = platformRect.maxY
                alina.onGround = true
                alina.velocityY = 0
            }
        }

        for platform in movingPlatforms {
            let top = platform.node.position.y + 10
            let minX = platform.node.position.x - 64
            let maxX = platform.node.position.x + 64
            if rect.maxX > minX && rect.minX < maxX && feetY <= top && feetY >= top - 12 {
                rect.origin.y = top
                alina.onGround = true
                alina.velocityY = 0
            }
        }
    }

    /// Coral shells launch Alina when she runs into one or lands on it, so auto-run can ride them.
    private func checkSprings(_ rect: CGRect) {
        guard alina.velocityY <= 0 else { return }
        let touch = rect.insetBy(dx: -3, dy: -2)
        for spring in springRects where touch.intersects(spring) && rect.minY >= spring.minY - 2 {
            alina.applyBounce(velocity: 980)
            ChiptuneEngine.shared.play(.spring)
            return
        }
    }

    private func checkHeadBonk() {
        guard alina.velocityY > 0 || alina.onGround == false else { return }
        let head = CGRect(x: alina.position.x - 8, y: alina.position.y + 12, width: 16, height: 6)

        for block in questionBlocks where !block.revealed {
            let blockRect = CGRect(x: block.position.x - 16, y: block.position.y - 16, width: 32, height: 32)
            guard head.intersects(blockRect) && alina.velocityY >= 0 else { continue }
            block.bump()
            block.revealed = true
            block.markUsed()
            alina.velocityY = 0
            ChiptuneEngine.shared.play(.bump)
            openBloomBlock(block)
        }

        for block in brickBlocks {
            let blockRect = CGRect(x: block.position.x - 16, y: block.position.y - 16, width: 32, height: 32)
            guard head.intersects(blockRect) && alina.velocityY >= 0 else { continue }
            alina.velocityY = 0
            block.hitCount += 1
            if block.hitCount >= 2 || alina.bloom {
                GameGraphics.burst(
                    at: block.position, in: builtLevel?.worldNode ?? self,
                    colors: [SKColor(hex: 0xE09466), SKColor(hex: 0xB0643F), SKColor(hex: 0x76CF63)], count: 8, speed: 200
                )
                ChiptuneEngine.shared.play(.brickBreak)
                block.removeFromParent()
                brickBlocks.removeAll { $0 == block }
                solidRects.removeAll { $0 == blockRect }
            } else {
                ChiptuneEngine.shared.play(.bump)
                block.bump()
            }
        }
    }

    /// The first bloom block and every third one after it hold a power-up; the rest pop petals.
    private func openBloomBlock(_ block: BlockNode) {
        defer { bloomBlocksOpened += 1 }
        let world = builtLevel?.worldNode ?? self
        let holdsPowerUp = bloomBlocksOpened % 3 == 0
        let kind: CollectibleKind? = holdsPowerUp ? (!alina.bloom ? .sunbloom : (!alina.hasRibbon ? .ribbon : nil)) : nil

        if let kind, let theme = builtLevel?.theme {
            let item = CollectibleNode(kind: kind, theme: theme)
            item.position = CGPoint(x: block.position.x, y: block.position.y + 32)
            world.addChild(item)
            item.emerge()
            collectibles.append(item)
        } else {
            petals += 1
            ChiptuneEngine.shared.play(.petal)
            GameGraphics.popText("+1", color: SKColor(hex: 0xC13B73), at: CGPoint(x: block.position.x, y: block.position.y + 30), in: world)
        }
    }

    private func handleEnemyCollision(_ enemy: EnemyNode) {
        let enemyRect = CGRect(
            x: enemy.position.x - enemy.size.width / 2, y: enemy.position.y - enemy.size.height / 2,
            width: enemy.size.width, height: enemy.size.height
        )
        let playerRect = alina.collisionRect
        guard playerRect.intersects(enemyRect) else { return }

        let stomping = alina.velocityY < 0 && playerRect.minY >= enemyRect.maxY - 12
        if stomping && enemy.enemyKind != .spiky {
            let defeated = enemy.stomp()
            alina.applyBounce()
            ChiptuneEngine.shared.play(.stomp)
            let world = builtLevel?.worldNode ?? self
            let top = CGPoint(x: enemy.position.x, y: enemy.position.y + enemy.size.height / 2)
            GameGraphics.impact(at: top, in: world)
            GameGraphics.ring(at: top, in: world, color: .white, size: 70)
            GameGraphics.burst(at: top, in: world, colors: [SKColor(hex: 0x8E72D6), .white, SKColor(hex: 0xFFE9AB)], count: 12)
            punch(stop: defeated ? 0.07 : 0.05, shake: enemy.enemyKind == .boss ? 7 : 3.5)
            if defeated {
                petals += enemy.enemyKind == .boss ? 10 : 2
                GameGraphics.popText(
                    enemy.enemyKind == .boss ? "+10" : "+2", color: SKColor(hex: 0xC13B73),
                    at: CGPoint(x: enemy.position.x, y: enemy.position.y + 24), in: builtLevel?.worldNode ?? self
                )
            }
            if enemy.enemyKind == .boss && defeated {
                bossDefeated = true
            }
        } else if alina.stompGraceTimer <= 0 {
            takeHit(fromX: enemy.position.x)
        }
    }

    // MARK: Combat

    private var lastAttackSerial = 0
    private var struckThisSwing: Set<ObjectIdentifier> = []

    /// A punch or kick that reaches an enemy defeats it (bosses take three), with the same weight as a stomp.
    private func handleAttack(on enemy: EnemyNode) {
        guard let box = alina.attackHitbox, !struckThisSwing.contains(ObjectIdentifier(enemy)) else { return }
        let enemyRect = CGRect(x: enemy.position.x - enemy.size.width / 2, y: enemy.position.y - enemy.size.height / 2,
                               width: enemy.size.width, height: enemy.size.height)
        guard box.intersects(enemyRect) else { return }
        struckThisSwing.insert(ObjectIdentifier(enemy))
        let kick = alina.attack == .kick
        let defeated = enemy.strike(fromX: alina.position.x, power: kick ? 1.4 : 1)
        alina.stompGraceTimer = max(alina.stompGraceTimer, 0.3)
        ChiptuneEngine.shared.play(.stomp)
        let world = builtLevel?.worldNode ?? self
        let point = CGPoint(x: box.midX + (alina.facingRight ? 10 : -10), y: box.midY)
        GameGraphics.impact(at: point, in: world, size: kick ? 58 : 46)
        GameGraphics.ring(at: point, in: world, color: .white, size: kick ? 80 : 62)
        GameGraphics.burst(at: point, in: world, colors: [SKColor(hex: 0xFF8FB8), .white, SKColor(hex: 0xFFE9AB)], count: kick ? 14 : 10)
        punch(stop: defeated ? 0.08 : 0.05, shake: enemy.enemyKind == .boss ? 7 : (kick ? 4.5 : 3))
        if defeated {
            petals += enemy.enemyKind == .boss ? 10 : 2
            GameGraphics.popText(enemy.enemyKind == .boss ? "+10" : "+2", color: SKColor(hex: 0xC13B73),
                                 at: CGPoint(x: enemy.position.x, y: enemy.position.y + 24), in: world)
            if enemy.enemyKind == .boss { bossDefeated = true }
        }
    }

    /// A quick bright arc in front of Alina as she swings.
    private func swoosh(in world: SKNode) {
        guard let attack = alina.attack else { return }
        let kick = attack == .kick
        let radius: CGFloat = kick ? 30 : 24
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: radius, startAngle: kick ? -1.3 : -0.5, endAngle: kick ? 0.5 : 0.9, clockwise: false)
        let arc = SKShapeNode(path: path)
        arc.strokeColor = SKColor(hex: kick ? 0xFFE9AB : 0xFFD3E8)
        arc.lineWidth = kick ? 7 : 5
        arc.lineCap = .round
        arc.glowWidth = 3
        arc.alpha = 0
        arc.zPosition = 12
        arc.xScale = alina.facingRight ? 1 : -1
        arc.position = CGPoint(x: alina.position.x + (alina.facingRight ? 14 : -14), y: alina.position.y + (kick ? -4 : 4))
        world.addChild(arc)
        arc.run(.sequence([.wait(forDuration: kick ? 0.07 : 0.05), .fadeAlpha(to: 0.95, duration: 0.03),
                           .group([.fadeOut(withDuration: 0.16), .scale(by: 1.25, duration: 0.16)]), .removeFromParent()]))
    }

    /// Impact weight: freeze for `stop` seconds and shake the camera by `shake` world units.
    private func punch(stop: CGFloat, shake: CGFloat) {
        hitStop = max(hitStop, stop)
        shakeAmount = max(shakeAmount, shake)
    }

    /// A collected petal's ghost flies from the pickup up to the petal counter in the HUD.
    private func flyToHUD(from position: CGPoint, texture: SKTexture?) {
        guard let world = builtLevel?.worldNode else { return }
        let visible = visibleRect
        let start = convert(world.convert(position, to: self), to: cameraNode)
        let ghost = SKSpriteNode(texture: texture, size: CGSize(width: 22, height: 22))
        ghost.position = start
        ghost.zPosition = 400
        cameraNode.addChild(ghost)
        // The petal pill sits near the top right of the window.
        let target = CGPoint(x: visible.width * 0.31, y: visible.height * 0.37)
        let path = CGMutablePath()
        path.move(to: start)
        path.addQuadCurve(to: target, control: CGPoint(x: (start.x + target.x) / 2 - 60, y: max(start.y, target.y) + 80))
        let fly = SKAction.follow(path, asOffset: false, orientToPath: false, duration: 0.55)
        fly.timingMode = .easeIn
        ghost.run(.sequence([.group([fly, .rotate(byAngle: 6, duration: 0.55), .scale(to: 0.6, duration: 0.55)]),
                             .fadeOut(withDuration: 0.08), .removeFromParent()]))
    }

    private func takeHit(fromX x: CGFloat) {
        guard alina.hurtCooldown <= 0 else { return }
        hits += 1
        ChiptuneEngine.shared.play(.hurt)
        let shielded = alina.absorbHit()
        alina.knockback(from: x)
        punch(stop: 0.09, shake: 7)
        GameGraphics.impact(at: alina.position, in: builtLevel?.worldNode ?? self, size: 46)
        if !shielded {
            loseHeart()
        }
    }

    private func loseHeart() {
        hearts -= 1
        if hearts <= 0 {
            fail(reason: "Alina ran out of hearts.")
        }
    }

    private func checkCollectibles() {
        let playerRect = alina.collisionRect.insetBy(dx: -4, dy: -4)
        let world = builtLevel?.worldNode ?? self
        for item in collectibles where item.parent != nil && !item.collected && item.alpha > 0.5 {
            let itemRect = CGRect(x: item.position.x - 12, y: item.position.y - 12, width: 24, height: 24)
            guard playerRect.intersects(itemRect) else { continue }
            item.collect()
            switch item.kind {
            case .coin:
                petals += 1
                ChiptuneEngine.shared.play(.petal)
                GameGraphics.ring(at: item.position, in: world, color: SKColor(hex: 0xFFC2DE), size: 40, duration: 0.25)
                GameGraphics.twinkles(at: item.position, in: world, color: SKColor(hex: 0xFFE9AB), count: 2, spread: 12)
                flyToHUD(from: item.position, texture: PixelArt.texture(.petal))
            case .crystal:
                shards += 1
                ChiptuneEngine.shared.play(.shard)
                GameGraphics.burst(at: item.position, in: world, colors: [SKColor(hex: 0xF6C343), .white, SKColor(hex: 0xC3A8FF)], count: 16)
                GameGraphics.ring(at: item.position, in: world, color: SKColor(hex: 0xFFE9AB), size: 90, duration: 0.4)
                punch(stop: 0.05, shake: 2)
                GameGraphics.popText("Shard \(shards)", color: SKColor(hex: 0xA86A00), at: CGPoint(x: item.position.x, y: item.position.y + 26), in: world)
            case .sunbloom:
                alina.grantBloom()
                ChiptuneEngine.shared.play(.powerUp)
                GameGraphics.ring(at: item.position, in: world, color: SKColor(hex: 0xFFE9AB), size: 100, duration: 0.45)
                GameGraphics.twinkles(at: item.position, in: world, color: SKColor(hex: 0xFFE9AB), count: 5, spread: 30)
                GameGraphics.popText("Sunbloom!", color: SKColor(hex: 0xA86A00), at: CGPoint(x: item.position.x, y: item.position.y + 26), in: world)
            case .ribbon:
                alina.grantRibbon()
                ChiptuneEngine.shared.play(.powerUp)
                GameGraphics.ring(at: item.position, in: world, color: SKColor(hex: 0xFFB3D6), size: 100, duration: 0.45)
                GameGraphics.twinkles(at: item.position, in: world, color: SKColor(hex: 0xFFC2DE), count: 5, spread: 30)
                GameGraphics.popText("Glow Ribbon!", color: SKColor(hex: 0xC13B73), at: CGPoint(x: item.position.x, y: item.position.y + 26), in: world)
            }
        }
        collectibles.removeAll { $0.parent == nil }
    }

    private func checkFlag(_ level: BuiltLevel) {
        guard mission.objective == .reachFlag, let flag = level.flagNode else { return }
        let flagRect = CGRect(x: flag.position.x - 16, y: flag.position.y - 16, width: 32, height: 64)
        if alina.collisionRect.intersects(flagRect) {
            win()
        }
    }

    private func checkHazards(_ level: BuiltLevel) {
        let playerRect = alina.collisionRect
        for hazard in level.hazards {
            let hazardRect = CGRect(x: hazard.position.x - 13, y: hazard.position.y - 16, width: 26, height: 14)
            if playerRect.intersects(hazardRect) {
                takeHit(fromX: hazard.position.x)
                if alina.hurtCooldown > 0 && alina.velocityY < 300 { alina.velocityY = 420 }
                return
            }
        }
    }

    private func checkFallDeath() {
        guard alina.position.y < -48 else { return }
        hits += 1
        ChiptuneEngine.shared.play(.hurt)
        loseHeart()
        if !finished {
            alina.resetForRespawn(at: checkpoint)
        }
    }

    /// Halfway through the level, the next safe landing becomes the respawn point.
    private func updateCheckpoint() {
        guard alina.onGround, alina.position.x > mapWidth * 0.5, checkpoint.x < mapWidth * 0.5 else { return }
        checkpoint = alina.position
        ChiptuneEngine.shared.play(.checkpoint)
        GameGraphics.popText("Checkpoint", color: SKColor(hex: 0x1F7A50), at: CGPoint(x: alina.position.x, y: alina.position.y + 40), in: builtLevel?.worldNode ?? self)
    }

    // MARK: Outcome

    private func win() {
        guard !finished else { return }
        finished = true
        let previousBest = GameProgress.shared.bestTime(for: mission.id)
        let result = MissionResult(
            missionID: mission.id,
            petals: petals,
            time: elapsed,
            hits: hits,
            parTime: parTime,
            stars: [true, elapsed <= parTime, hits == 0],
            newBestTime: previousBest.map { elapsed < $0 } ?? true
        )
        GameProgress.shared.recordCompletion(result)
        GameGraphics.burst(
            at: alina.position, in: builtLevel?.worldNode ?? self,
            colors: [SKColor(hex: 0xF6C343), SKColor(hex: 0xFF8DBE), .white], count: 24, speed: 260
        )
        run(.sequence([.wait(forDuration: 0.9), .run { [weak self] in self?.onOutcome?(.won(result)) }]))
    }

    private func fail(reason: String) {
        guard !finished else { return }
        finished = true
        alina.run(.sequence([.moveBy(x: 0, y: 30, duration: 0.2), .fadeOut(withDuration: 0.3)]))
        run(.sequence([.wait(forDuration: 0.7), .run { [weak self] in self?.onOutcome?(.lost(reason: reason)) }]))
    }

    private func updateCamera(delta: CGFloat) {
        let visible = visibleRect
        var targetX = alina.position.x + 80
        targetX = mapWidth <= visible.width ? mapWidth / 2 : max(visible.width / 2, min(mapWidth - visible.width / 2, targetX))
        let targetY = max(visible.height / 2, alina.position.y + 60)
        let factor = 1.0 - exp(-10.0 * delta)
        var base = cameraBase ?? cameraNode.position
        base = CGPoint(x: base.x + (targetX - base.x) * factor, y: base.y + (targetY - base.y) * factor)
        cameraBase = base
        // Shake decays quickly; a little rotation sells it.
        shakeAmount = max(0, shakeAmount - delta * 40)
        let reduced = UserDefaults.standard.bool(forKey: SettingsKey.reduceMotion)
        let s = reduced ? 0 : shakeAmount
        cameraNode.position = CGPoint(x: base.x + .random(in: -s...max(-s, s)), y: base.y + .random(in: -s...max(-s, s)))
        cameraNode.zRotation = s > 0 ? .random(in: -0.004...0.004) * s : 0
    }

    // MARK: HUD

    var hudSnapshot: HUDSnapshot {
        guard let mission else { return HUDSnapshot() }
        let progress: CGFloat
        switch mission.objective {
        case .reachFlag:
            let goal = builtLevel?.flagNode?.position.x ?? mapWidth
            progress = min(1, max(0, alina.position.x / max(1, goal)))
        case .collectN:
            progress = CGFloat(shards) / CGFloat(max(1, mission.collectRequired))
        case .defeatBoss:
            let boss = builtLevel?.enemies.first { $0.enemyKind == .boss }
            progress = CGFloat(boss?.stompHits ?? 0) / 3
        }
        let seconds: Int
        if let timeLimit {
            seconds = max(0, Int(ceil(timeLimit - elapsed)))
        } else {
            seconds = Int(elapsed)
        }
        return HUDSnapshot(
            hearts: max(0, hearts),
            maxHearts: maxHearts,
            petals: petals,
            shards: shards,
            shardTarget: mission.objective == .collectN ? mission.collectRequired : nil,
            bossHits: builtLevel?.enemies.first { $0.enemyKind == .boss }?.stompHits ?? 0,
            seconds: seconds,
            countdown: timeLimit != nil,
            bloom: alina.bloom,
            ribbon: alina.hasRibbon,
            progress: progress
        )
    }
}
