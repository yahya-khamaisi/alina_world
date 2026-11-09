import SpriteKit

/// Alina as a cut-out puppet: painted parts from `AlinaRig.png` on a bone hierarchy, posed procedurally every frame.
/// Poses blend smoothly instead of popping between frames; hair, bow, front lock and skirt follow through on springs;
/// the whole body squashes and stretches with vertical speed and on landing.
///
/// Bones (facing right; positive rotation swings a hanging limb forward):
/// hips ─ thigh(far) ─ shin(far) · skirt · thigh(near) ─ shin(near)
///      └ torso ─ upperArm(far) ─ forearm(far) · head ─ backHair, bow, frontLock · upperArm(near) ─ forearm(near)
final class AlinaRig: SKNode {
    enum Part: Int, CaseIterable {
        case head, headBlink, headShout, bow, backHair, torso, skirt, frontLock, upperArm, forearm, thigh, shin
    }

    struct Motion {
        var state: PlayerState
        var velocity: CGVector
        var onGround: Bool
        var bloom: Bool
        /// 0…1 through the double-jump flip, nil when not flipping.
        var flip: CGFloat?
        var dt: CGFloat
    }

    // MARK: Loading

    private static let frames: [[Int]] = {
        guard let url = Bundle.module.url(forResource: "AlinaRigFrames", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let values = try? JSONDecoder().decode([[Int]].self, from: data),
              values.count == Part.allCases.count, values.allSatisfy({ $0.count == 4 }) else { return [] }
        return values
    }()

    private static let textures: [Part: SKTexture] = {
        guard !frames.isEmpty, let sheet = StorybookArt.image(.alinaRig) else { return [:] }
        var result: [Part: SKTexture] = [:]
        for part in Part.allCases {
            let b = frames[part.rawValue]
            guard let crop = sheet.cropping(to: CGRect(x: b[0], y: b[1], width: b[2], height: b[3])) else { return [:] }
            let texture = SKTexture(cgImage: crop)
            texture.filteringMode = .linear
            result[part] = texture
        }
        return result
    }()

    /// True once Codex's parts sheet is in the bundle; until then `AlinaNode` keeps its painted frames.
    static var isAvailable: Bool { textures.count == Part.allCases.count }

    // MARK: Bones

    private let hips = SKNode()
    private let torso: SKSpriteNode
    private let head: SKSpriteNode
    private let backHair: SKSpriteNode
    private let bow: SKSpriteNode
    private let frontLock: SKSpriteNode
    private let skirt: SKSpriteNode
    private let arms: [(upper: SKSpriteNode, fore: SKSpriteNode)]
    private let legs: [(thigh: SKSpriteNode, shin: SKSpriteNode)]
    /// The glide streamer: a smooth glowing curve trailing from the near hand.
    private let streamer = SKShapeNode()
    private let streamerGlow = SKShapeNode()

    private var hipsRest = CGPoint.zero
    private var scaleFactor: CGFloat = 1

    // MARK: Animation state

    private var time: CGFloat = 0
    private var gait: CGFloat = 0
    private var blinkTimer: CGFloat = 2
    private var lastOnGround = true
    /// Landing / take-off squash: positive stretches, negative squashes; settles on a spring.
    private var squash = Spring(stiffness: 260, damping: 16)
    private var hairSwing = Spring(stiffness: 70, damping: 7)
    private var lockSwing = Spring(stiffness: 110, damping: 8)
    private var bowSwing = Spring(stiffness: 150, damping: 9)
    private var skirtSwing = Spring(stiffness: 140, damping: 10)
    private var streamerPoints: [CGPoint] = []

    /// Assembled height in world units, boots to bow.
    init(height: CGFloat, feetY: CGFloat) {
        func sprite(_ part: Part) -> SKSpriteNode {
            let texture = Self.textures[part]!
            return SKSpriteNode(texture: texture)
        }
        torso = sprite(.torso)
        head = sprite(.head)
        backHair = sprite(.backHair)
        bow = sprite(.bow)
        frontLock = sprite(.frontLock)
        skirt = sprite(.skirt)
        arms = [(sprite(.upperArm), sprite(.forearm)), (sprite(.upperArm), sprite(.forearm))]
        legs = [(sprite(.thigh), sprite(.shin)), (sprite(.thigh), sprite(.shin))]
        super.init()
        assemble(height: height, feetY: feetY)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func assemble(height: CGFloat, feetY: CGFloat) {
        let size = { (part: Part) -> CGSize in Self.textures[part]!.size() }
        let headH = size(.head).height, torsoH = size(.torso).height
        let thighH = size(.thigh).height, shinH = size(.shin).height
        // Parts overlap at the joints, so the stacked height is less than the sum of the parts.
        let stacked = headH * 0.92 + torsoH * 0.82 + thighH * 0.86 + shinH * 0.94
        scaleFactor = height / stacked
        let s = scaleFactor
        for node in [torso, head, backHair, bow, frontLock, skirt] + arms.flatMap({ [$0.upper, $0.fore] }) + legs.flatMap({ [$0.thigh, $0.shin] }) {
            node.size = CGSize(width: node.size.width * s, height: node.size.height * s)
        }

        addChild(hips)
        hipsRest = CGPoint(x: 0, y: feetY + (thighH * 0.86 + shinH * 0.94) * s)
        hips.position = hipsRest

        // Torso stands on the waist; the skirt hangs from it and covers the tops of the legs.
        torso.anchorPoint = CGPoint(x: 0.5, y: 0.08)
        torso.zPosition = 3
        hips.addChild(torso)
        skirt.anchorPoint = CGPoint(x: 0.5, y: 0.93)
        skirt.position = CGPoint(x: 0, y: torsoH * 0.12 * s)
        skirt.zPosition = 4
        hips.addChild(skirt)

        // Legs: far leg behind everything and a little darker, near leg in front of the far one but under the skirt.
        for (i, leg) in legs.enumerated() {
            let near = i == 0
            leg.thigh.anchorPoint = CGPoint(x: 0.5, y: 0.94)
            leg.thigh.position = CGPoint(x: (near ? 0.12 : -0.1) * size(.torso).width * s, y: 0)
            leg.thigh.zPosition = near ? 2 : 1
            leg.shin.anchorPoint = CGPoint(x: 0.42, y: 0.96)
            leg.shin.position = CGPoint(x: 0, y: -thighH * 0.86 * s)
            leg.shin.zPosition = -0.1
            leg.thigh.addChild(leg.shin)
            hips.addChild(leg.thigh)
            if !near { shade(leg.thigh); shade(leg.shin) }
        }

        // Head on the neck, back hair behind it, bow and front lock over it.
        head.anchorPoint = CGPoint(x: 0.45, y: 0.06)
        head.position = CGPoint(x: 0, y: torsoH * 0.8 * s)
        head.zPosition = 2
        torso.addChild(head)
        backHair.anchorPoint = CGPoint(x: 0.5, y: 0.9)
        backHair.position = CGPoint(x: -0.16 * size(.head).width * s, y: headH * 0.78 * s)
        backHair.zPosition = -3
        head.addChild(backHair)
        bow.anchorPoint = CGPoint(x: 0.5, y: 0.35)
        bow.position = CGPoint(x: -0.2 * size(.head).width * s, y: headH * 0.86 * s)
        bow.zPosition = 1
        head.addChild(bow)
        frontLock.anchorPoint = CGPoint(x: 0.5, y: 0.95)
        frontLock.position = CGPoint(x: -0.1 * size(.head).width * s, y: headH * 0.62 * s)
        frontLock.zPosition = 0.5
        head.addChild(frontLock)

        // Arms hang from the shoulders: far arm behind the torso, near arm in front of it.
        for (i, arm) in arms.enumerated() {
            let near = i == 0
            arm.upper.anchorPoint = CGPoint(x: 0.5, y: 0.92)
            arm.upper.position = CGPoint(x: (near ? 0.06 : -0.16) * size(.torso).width * s, y: torsoH * 0.74 * s)
            arm.upper.zPosition = near ? 3 : -2
            arm.fore.anchorPoint = CGPoint(x: 0.5, y: 0.93)
            arm.fore.position = CGPoint(x: 0, y: -size(.upperArm).height * 0.84 * s)
            arm.fore.zPosition = -0.1
            arm.upper.addChild(arm.fore)
            torso.addChild(arm.upper)
            if !near { shade(arm.upper); shade(arm.fore) }
        }

        for (node, width, color) in [(streamerGlow, 7.0, SKColor(hex: 0xFFD3E8, alpha: 0.45)), (streamer, 3.2, SKColor(hex: 0xFF6FAE))] {
            node.strokeColor = color
            node.lineWidth = width
            node.lineCap = .round
            node.lineJoin = .round
            node.zPosition = -4
            node.isHidden = true
            addChild(node)
        }
        streamer.glowWidth = 2
    }

    private func shade(_ node: SKSpriteNode) {
        node.color = SKColor(hex: 0x5A3550)
        node.colorBlendFactor = 0.22
    }

    // MARK: Posing

    private struct Pose {
        var lean: CGFloat = 0, headTilt: CGFloat = 0, bob: CGFloat = 0
        var upperArm: (CGFloat, CGFloat) = (0.08, -0.06), forearm: (CGFloat, CGFloat) = (0.25, 0.2)
        var thigh: (CGFloat, CGFloat) = (0.03, -0.03), shin: (CGFloat, CGFloat) = (-0.04, -0.02)
    }

    func update(_ m: Motion) {
        let dt = max(0.0001, m.dt)
        time += dt
        var pose = Pose()
        var face: Part = .head

        switch m.state {
        case .idle, .land, .hurt:
            let breathe = sin(time * 2.4)
            pose.bob = breathe * 0.6
            pose.headTilt = sin(time * 1.2) * 0.04
            pose.upperArm = (0.1 + breathe * 0.04, -0.08 - breathe * 0.04)
            if m.state == .hurt {
                pose.upperArm = (1.6 + sin(time * 30) * 0.4, -1.6 - sin(time * 30) * 0.4)
                pose.lean = 0.18
                face = .headBlink
            }
        case .walk, .run, .skid:
            let speed = abs(m.velocity.dx)
            gait += dt * (4 + speed * 0.034)
            let swing = min(1, 0.35 + speed / 320)
            let s = sin(gait), c = cos(gait)
            pose.thigh = (0.75 * swing * s, -0.75 * swing * s)
            // Knees fold as each leg swings back and lifts for the next stride.
            pose.shin = (-1.25 * swing * max(0, -c) - 0.12, -1.25 * swing * max(0, c) - 0.12)
            pose.upperArm = (-0.85 * swing * s, 0.85 * swing * s)
            pose.forearm = (0.9, 0.8)
            pose.bob = abs(c) * 3.2 * swing - 1.2
            pose.lean = -0.16 * swing
            pose.headTilt = 0.08 * swing
            if m.state == .skid {
                pose.lean = 0.22
                pose.thigh = (0.7, 0.45)
                pose.shin = (-0.2, -0.3)
                pose.upperArm = (1.3, 0.9)
            }
        case .jump, .bounce:
            face = .headShout
            pose.thigh = (1.05, 0.45)
            pose.shin = (-1.45, -1.0)
            // Arms flung up and out, clear of the face: near arm forward, far arm back behind the hair.
            pose.upperArm = (1.85, -2.2)
            pose.forearm = (0.55, -0.4)
            pose.lean = -0.06
        case .fall:
            pose.thigh = (0.35, -0.15)
            pose.shin = (-0.55, -0.3)
            pose.upperArm = (1.45, -1.6)
            pose.forearm = (0.45, -0.3)
            pose.headTilt = -0.06
        case .glide:
            pose.thigh = (-0.35, -0.15)
            pose.shin = (-0.75, -0.45)
            // Near hand holds the streamer up and forward; far arm balances out behind.
            pose.upperArm = (2.05, -1.4)
            pose.forearm = (0.35, -0.3)
            pose.lean = -0.1
            pose.bob = sin(time * 3.2) * 1.5
        }
        if let flip = m.flip {
            // Double jump: tuck into a forward somersault.
            pose.thigh = (1.6, 1.4)
            pose.shin = (-2.1, -2.0)
            pose.upperArm = (1.2, 1.0)
            pose.forearm = (1.4, 1.3)
            face = .headShout
            hips.zRotation = -2 * .pi * easeOut(flip)
        } else {
            hips.zRotation = approach(hips.zRotation, 0, dt, rate: 30)
        }

        // Blink now and then when the face is relaxed.
        blinkTimer -= dt
        if blinkTimer < 0 { blinkTimer = .random(in: 2.4...4.2) }
        if face == .head && blinkTimer < 0.11 { face = .headBlink }
        if let texture = Self.textures[face], head.texture !== texture { head.texture = texture }

        // Blend every bone toward the pose instead of snapping.
        let rate: CGFloat = (m.state == .run || m.state == .walk) ? 28 : 16
        torso.zRotation = approach(torso.zRotation, pose.lean, dt, rate: rate)
        head.zRotation = approach(head.zRotation, pose.headTilt - pose.lean * 0.4, dt, rate: rate)
        for (i, arm) in arms.enumerated() {
            arm.upper.zRotation = approach(arm.upper.zRotation, i == 0 ? pose.upperArm.0 : pose.upperArm.1, dt, rate: rate)
            arm.fore.zRotation = approach(arm.fore.zRotation, i == 0 ? pose.forearm.0 : pose.forearm.1, dt, rate: rate)
        }
        for (i, leg) in legs.enumerated() {
            leg.thigh.zRotation = approach(leg.thigh.zRotation, i == 0 ? pose.thigh.0 : pose.thigh.1, dt, rate: rate)
            leg.shin.zRotation = approach(leg.shin.zRotation, i == 0 ? pose.shin.0 : pose.shin.1, dt, rate: rate)
        }

        // Squash and stretch: stretch with vertical speed, squash on landing, pop on take-off.
        if m.onGround && !lastOnGround { squash.velocity -= 6 + min(10, abs(m.velocity.dy) * 0.004) }
        if !m.onGround && lastOnGround && m.velocity.dy > 0 { squash.velocity += 5 }
        lastOnGround = m.onGround
        let airStretch = m.onGround ? 0 : max(-0.1, min(0.12, m.velocity.dy / 3600))
        squash.step(target: airStretch, dt: dt)
        let sy = 1 + max(-0.28, min(0.25, squash.value))
        hips.yScale = sy
        hips.xScale = 1 / sqrt(sy)
        hips.position = CGPoint(x: hipsRest.x, y: hipsRest.y + pose.bob * scaleFactor * 6 - max(0, 1 - sy) * 8)

        // Follow-through: hair, front lock, bow and skirt lag behind motion and settle on springs.
        let drag = max(-1, min(1, m.velocity.dx / 360)) * (m.state == .idle ? 0 : 1)
        let lift = max(-1, min(1, m.velocity.dy / 700))
        hairSwing.step(target: 0.35 * abs(drag) + 0.25 * lift - torso.zRotation * 0.5, dt: dt)
        lockSwing.step(target: 0.3 * abs(drag) + 0.3 * lift, dt: dt)
        bowSwing.step(target: 0.18 * abs(drag) + 0.15 * lift + sin(time * 5) * 0.03, dt: dt)
        skirtSwing.step(target: 0.12 * abs(drag) + 0.06 * lift, dt: dt)
        backHair.zRotation = -hairSwing.value
        frontLock.zRotation = -lockSwing.value
        bow.zRotation = -bowSwing.value
        skirt.zRotation = skirtSwing.value * 0.5
        skirt.xScale = 1 + max(0, lift) * 0.12 + abs(skirtSwing.velocity) * 0.004
        skirt.yScale = 1 - max(0, lift) * 0.1

        bow.color = SKColor(hex: 0xF6C343)
        bow.colorBlendFactor = m.bloom ? 0.55 : 0

        updateStreamer(visible: m.state == .glide, dt: dt)
    }

    /// The glowing glide streamer: points trail from the near hand and wave as she floats.
    private func updateStreamer(visible: Bool, dt: CGFloat) {
        streamer.isHidden = !visible
        streamerGlow.isHidden = !visible
        guard visible, let hand = arms.first?.fore else { streamerPoints.removeAll(); return }
        let tip = hand.convert(CGPoint(x: 0, y: -hand.size.height * 0.8), to: self)
        let count = 14
        if streamerPoints.count != count { streamerPoints = Array(repeating: tip, count: count) }
        streamerPoints[0] = tip
        for i in 1..<count {
            let t = CGFloat(i) / CGFloat(count - 1)
            // Each point eases toward a spot trailing up and back from the one before, with a travelling wave.
            let rest = CGPoint(
                x: streamerPoints[i - 1].x - 4.2,
                y: streamerPoints[i - 1].y + 1.6 + sin(time * 9 - t * 6) * 2.4 * t
            )
            streamerPoints[i].x += (rest.x - streamerPoints[i].x) * min(1, dt * 22)
            streamerPoints[i].y += (rest.y - streamerPoints[i].y) * min(1, dt * 22)
        }
        let path = CGMutablePath()
        path.move(to: streamerPoints[0])
        for i in stride(from: 1, to: count - 1, by: 1) {
            let mid = CGPoint(x: (streamerPoints[i].x + streamerPoints[i + 1].x) / 2, y: (streamerPoints[i].y + streamerPoints[i + 1].y) / 2)
            path.addQuadCurve(to: mid, control: streamerPoints[i])
        }
        streamer.path = path
        streamerGlow.path = path
    }

    private func approach(_ value: CGFloat, _ target: CGFloat, _ dt: CGFloat, rate: CGFloat) -> CGFloat {
        value + (target - value) * (1 - exp(-rate * dt))
    }

    private func easeOut(_ t: CGFloat) -> CGFloat { 1 - pow(1 - min(1, max(0, t)), 2.2) }
}

/// Damped spring used for secondary motion.
private struct Spring {
    let stiffness: CGFloat
    let damping: CGFloat
    var value: CGFloat = 0
    var velocity: CGFloat = 0

    init(stiffness: CGFloat, damping: CGFloat) {
        self.stiffness = stiffness
        self.damping = damping
    }

    mutating func step(target: CGFloat, dt: CGFloat) {
        // Sub-step so a long frame never makes the spring explode.
        let steps = max(1, Int(ceil(dt / (1.0 / 120))))
        let h = dt / CGFloat(steps)
        for _ in 0..<steps {
            velocity += (-stiffness * (value - target) - damping * velocity) * h
            value += velocity * h
        }
    }
}
