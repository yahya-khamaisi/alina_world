import SpriteKit

/// Cut-out creatures from `CreatureRig.png`: each species is a body with moving feet, legs, wings or claws,
/// animated procedurally every frame (walk cycles, wing beats, claw snaps, blinks) with squash and stretch.
/// The art faces left, the way creatures start walking; `EnemyNode` mirrors the whole rig to turn around.
final class CreatureRig: SKNode {
    enum Species {
        case gloomling, guardian, thornbeetle, mothwisp, frostpuff, shellcrab, starwisp
    }

    private enum Part: Int, CaseIterable {
        case gloomBody, gloomBlink, gloomFoot, crown, guardianBody, beetleShell, beetleLeg, mothBody
        case mothWing, frostBody, frostFoot, crabBody, crabClaw, crabLeg, star, starBlink
    }

    // MARK: Loading

    private static let textures: [Part: SKTexture] = {
        guard let url = Bundle.module.url(forResource: "CreatureRigFrames", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let frames = try? JSONDecoder().decode([[Int]].self, from: data),
              frames.count == Part.allCases.count,
              let sheet = StorybookArt.image(.creatureRig) else { return [:] }
        var result: [Part: SKTexture] = [:]
        for part in Part.allCases {
            let b = frames[part.rawValue]
            guard b.count == 4, let crop = sheet.cropping(to: CGRect(x: b[0], y: b[1], width: b[2], height: b[3])) else { return [:] }
            let texture = SKTexture(cgImage: crop)
            texture.filteringMode = .linear
            result[part] = texture
        }
        return result
    }()

    static var isAvailable: Bool { textures.count == Part.allCases.count }

    // MARK: Nodes

    let species: Species
    private let body: SKSpriteNode
    private var openTexture: SKTexture?
    private var blinkTexture: SKTexture?
    /// Feet, legs, wings or claws, with the near-side ones first.
    private var limbs: [SKSpriteNode] = []
    private var crown: SKSpriteNode?
    private var glow: SKSpriteNode?
    private var bodyRest = CGPoint.zero
    private var limbRest: [CGPoint] = []

    private var time = CGFloat.random(in: 0...10)
    private var phase = CGFloat.random(in: 0...6)
    private var blinkTimer = CGFloat.random(in: 1...3)
    private var crownSwing = CGFloat(0), crownVelocity = CGFloat(0)
    private var flinch = CGFloat(0)

    /// `width` is the body's width in world units; `floorY` is where feet touch the ground (ignored for flyers).
    init(species: Species, width: CGFloat, floorY: CGFloat) {
        self.species = species
        let t = Self.textures
        func sprite(_ part: Part) -> SKSpriteNode { SKSpriteNode(texture: t[part]) }

        let bodyPart: Part
        switch species {
        case .gloomling: bodyPart = .gloomBody
        case .guardian: bodyPart = .guardianBody
        case .thornbeetle: bodyPart = .beetleShell
        case .mothwisp: bodyPart = .mothBody
        case .frostpuff: bodyPart = .frostBody
        case .shellcrab: bodyPart = .crabBody
        case .starwisp: bodyPart = .star
        }
        body = sprite(bodyPart)
        super.init()

        let s = width / max(1, body.size.width)
        func fit(_ node: SKSpriteNode) { node.size = CGSize(width: node.size.width * s, height: node.size.height * s) }
        fit(body)
        openTexture = body.texture
        if species == .gloomling { blinkTexture = t[.gloomBlink] }
        if species == .starwisp { blinkTexture = t[.starBlink] }
        body.zPosition = 2
        addChild(body)
        let w = body.size.width, h = body.size.height

        func shade(_ node: SKSpriteNode) {
            node.color = SKColor(hex: 0x2A1838)
            node.colorBlendFactor = 0.28
        }

        switch species {
        case .gloomling, .guardian, .frostpuff:
            // Fuzzy blob on two stubby feet.
            let footPart: Part = species == .frostpuff ? .frostFoot : .gloomFoot
            for (i, x) in [-0.2, 0.22].enumerated() {
                let foot = sprite(footPart)
                fit(foot)
                if species == .guardian { foot.size = CGSize(width: foot.size.width * 1.3, height: foot.size.height * 1.3) }
                foot.anchorPoint = CGPoint(x: 0.5, y: 0.1)
                foot.position = CGPoint(x: CGFloat(x) * w, y: floorY)
                foot.zPosition = i == 0 ? 3 : 1
                if i == 1 { shade(foot) }
                addChild(foot)
                limbs.append(foot)
            }
            body.anchorPoint = CGPoint(x: 0.5, y: 0.04)
            bodyRest = CGPoint(x: 0, y: floorY + (limbs.first?.size.height ?? 0) * 0.45)
            if species == .guardian {
                let crown = sprite(.crown)
                fit(crown)
                crown.anchorPoint = CGPoint(x: 0.5, y: 0.12)
                crown.position = CGPoint(x: -0.02 * w, y: h * 0.86)
                crown.zPosition = 1
                body.addChild(crown)
                self.crown = crown
            }
        case .thornbeetle:
            // Spiked shell on six legs: three near (in front), three far (behind, shaded).
            let leg = sprite(.beetleLeg)
            fit(leg)
            body.anchorPoint = CGPoint(x: 0.5, y: 0.12)
            bodyRest = CGPoint(x: 0, y: floorY + leg.size.height * 0.62)
            for i in 0..<6 {
                let node = i == 0 ? leg : sprite(.beetleLeg)
                if i > 0 { fit(node) }
                let near = i < 3
                node.anchorPoint = CGPoint(x: 0.5, y: 0.92)
                node.position = CGPoint(x: (CGFloat(i % 3) - 1) * 0.3 * w + (near ? 0 : 0.06 * w), y: bodyRest.y + h * 0.18)
                node.zPosition = near ? 3 : 1
                if !near { shade(node) }
                addChild(node)
                limbs.append(node)
            }
        case .mothwisp:
            // Fuzzy body between two wings hinged at their roots.
            body.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            for i in 0..<2 {
                let wing = sprite(.mothWing)
                fit(wing)
                wing.anchorPoint = CGPoint(x: 0.04, y: 0.45)
                wing.position = CGPoint(x: 0.08 * w, y: 0.05 * h)
                wing.zPosition = i == 0 ? 3 : 1
                if i == 1 { shade(wing) }
                addChild(wing)
                limbs.append(wing)
            }
        case .shellcrab:
            // Shell and face on six side-stepping legs, with two claws at the front.
            let leg = sprite(.crabLeg)
            fit(leg)
            body.anchorPoint = CGPoint(x: 0.5, y: 0.1)
            bodyRest = CGPoint(x: 0, y: floorY + leg.size.height * 0.55)
            for i in 0..<2 {
                let claw = sprite(.crabClaw)
                fit(claw)
                claw.anchorPoint = CGPoint(x: 0.85, y: 0.3)
                claw.position = CGPoint(x: -0.32 * w, y: bodyRest.y + h * 0.25)
                claw.zPosition = i == 0 ? 3 : 1
                if i == 1 { shade(claw); claw.position.x += 0.1 * w }
                addChild(claw)
                limbs.append(claw)
            }
            for i in 0..<6 {
                let node = i == 0 ? leg : sprite(.crabLeg)
                if i > 0 { fit(node) }
                let near = i < 3
                node.anchorPoint = CGPoint(x: 0.5, y: 0.92)
                node.position = CGPoint(x: (CGFloat(i % 3) - 0.8) * 0.26 * w, y: bodyRest.y + h * 0.12)
                node.zPosition = near ? 2.5 : 1
                if !near { shade(node) }
                addChild(node)
                limbs.append(node)
            }
        case .starwisp:
            body.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            let glow = SKSpriteNode(texture: Self.softGlow, size: CGSize(width: w * 2, height: w * 2))
            glow.alpha = 0.7
            glow.zPosition = 0
            addChild(glow)
            self.glow = glow
        }
        body.position = bodyRest
        limbRest = limbs.map(\.position)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    /// Warm round halo that fades fully to transparent, for the Starwisp.
    private static let softGlow: SKTexture = {
        let size = 128
        let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [
            CGColor(srgbRed: 1, green: 0.93, blue: 0.6, alpha: 0.55), CGColor(srgbRed: 1, green: 0.85, blue: 0.5, alpha: 0)
        ] as CFArray, locations: [0, 1])!
        let c = CGPoint(x: size / 2, y: size / 2)
        context.drawRadialGradient(gradient, startCenter: c, startRadius: 0, endCenter: c, endRadius: CGFloat(size) / 2, options: [])
        return SKTexture(cgImage: context.makeImage()!)
    }()

    // MARK: Animation

    /// `speed` is the creature's current walking or flying speed in world units per second.
    func update(dt: CGFloat, speed: CGFloat) {
        time += dt
        phase += dt * (3 + speed * 0.09)
        let p = phase

        blinkTimer -= dt
        if blinkTimer < 0 { blinkTimer = .random(in: 2...4.5) }
        if let open = openTexture, let blink = blinkTexture {
            let target = blinkTimer < 0.12 || flinch > 0.3 ? blink : open
            if body.texture !== target { body.texture = target }
        }

        flinch = max(0, flinch - dt * 3)
        var squashY = 1 - flinch * 0.3

        switch species {
        case .gloomling, .guardian, .frostpuff:
            // Waddle: feet lift in turn, the body bobs, squashes on each step and rocks side to side.
            for (i, foot) in limbs.enumerated() {
                let q = p + CGFloat(i) * .pi
                foot.position = CGPoint(x: limbRest[i].x - sin(q) * body.size.width * 0.05,
                                        y: limbRest[i].y + max(0, sin(q)) * body.size.height * 0.1)
                foot.zRotation = max(0, sin(q)) * 0.25
            }
            let step = abs(cos(p))
            body.position = CGPoint(x: bodyRest.x, y: bodyRest.y + (1 - step) * body.size.height * 0.06)
            squashY *= 1 - step * 0.06
            body.zRotation = sin(p) * 0.05
            if let crown {
                // The crown lags the bob on a spring and wobbles.
                let target = -body.zRotation * 1.5 + (1 - step) * 0.08
                crownVelocity += (-140 * (crownSwing - target) - 9 * crownVelocity) * dt
                crownSwing += crownVelocity * dt
                crown.zRotation = crownSwing
            }
        case .thornbeetle:
            // Tripod gait: alternate legs swing together; the shell jitters with each scuttle.
            for (i, leg) in limbs.enumerated() {
                let group = (i % 3 + (i < 3 ? 0 : 1)) % 2
                leg.zRotation = sin(p * 1.6 + CGFloat(group) * .pi) * 0.45
            }
            body.position = CGPoint(x: bodyRest.x, y: bodyRest.y + abs(sin(p * 1.6)) * body.size.height * 0.04)
            body.zRotation = sin(p * 1.6) * 0.03
        case .mothwisp:
            // Wing beats: hinge and fore-shorten, body bobs between strokes.
            let beat = sin(time * 15)
            for (i, wing) in limbs.enumerated() {
                // The far wing beats a little ahead and higher so both wings read.
                wing.zRotation = 0.55 + beat * 0.55 + (i == 1 ? 0.55 : 0)
                wing.yScale = 0.55 + 0.45 * abs(beat)
            }
            body.position = CGPoint(x: 0, y: -beat * body.size.height * 0.05)
            body.zRotation = sin(time * 2) * 0.08
        case .shellcrab:
            // Claws snap open and shut; legs side-step in pairs; the shell sways.
            for (i, limb) in limbs.enumerated() {
                if i < 2 {
                    let snap = max(0, sin(time * 3.2 + CGFloat(i) * 1.7))
                    limb.zRotation = -0.15 + pow(snap, 4) * 0.5
                } else {
                    let leg = i - 2
                    limb.zRotation = sin(p * 1.8 + CGFloat(leg % 2) * .pi) * 0.35
                }
            }
            body.position = CGPoint(x: bodyRest.x + sin(p * 1.8) * body.size.width * 0.02, y: bodyRest.y)
            body.zRotation = sin(p * 0.9) * 0.04
        case .starwisp:
            body.zRotation = sin(time * 1.4) * 0.35
            body.setScale(1 + sin(time * 4) * 0.04)
            glow?.alpha = 0.45 + 0.2 * sin(time * 3)
        }

        if species != .starwisp {
            body.yScale = squashY
            body.xScale = 1 / sqrt(max(0.5, squashY))
        }
    }

    /// Hit but not defeated: a sharp squash and a wince.
    func hit() {
        flinch = 1
        body.run(.sequence([
            .colorize(with: .white, colorBlendFactor: 0.7, duration: 0.05),
            .colorize(withColorBlendFactor: 0, duration: 0.15)
        ]))
    }

    /// Stomped flat: eyes shut, squashed, limbs splayed.
    func squashFlat() {
        flinch = 1
        if let blink = blinkTexture { body.texture = blink }
        for (i, limb) in limbs.enumerated() { limb.zRotation = i.isMultiple(of: 2) ? 0.9 : -0.9 }
    }
}
