#if DEBUG
import SpriteKit

/// Development aid: `ALINA_RIG_PREVIEW=1` pins six large copies of the rig to the camera, one per pose,
/// so joints and poses can be tuned from a single screenshot.
final class RigPreview {
    private let root = SKNode()
    private var rigs: [(AlinaRig, AlinaRig.Motion)] = []
    private var creatures: [CreatureRig] = []
    private var flipTime: CGFloat = 0

    static var enabled: Bool { !(ProcessInfo.processInfo.environment["ALINA_RIG_PREVIEW"] ?? "").isEmpty }

    func attach(to camera: SKNode) {
        guard AlinaRig.isAvailable else { return }
        root.zPosition = 500
        camera.addChild(root)
        let backdrop = SKSpriteNode(color: SKColor(hex: 0xFFF4E6, alpha: 0.92), size: CGSize(width: 2000, height: 520))
        if CreatureRig.isAvailable {
            let species: [(CreatureRig.Species, CGFloat)] = [
                (.gloomling, 31), (.guardian, 43), (.thornbeetle, 34), (.mothwisp, 20), (.frostpuff, 31), (.shellcrab, 26), (.starwisp, 34)
            ]
            for (i, entry) in species.enumerated() {
                let rig = CreatureRig(species: entry.0, width: entry.1, floorY: -15)
                rig.setScale(3)
                rig.position = CGPoint(x: CGFloat(i - 3) * 130, y: 140)
                root.addChild(rig)
                creatures.append(rig)
            }
        }
        backdrop.position = CGPoint(x: 0, y: 40)
        backdrop.zPosition = -10
        root.addChild(backdrop)
        let poses: [(PlayerState, CGVector, Bool)] = [
            (.idle, .zero, true), (.run, CGVector(dx: 300, dy: 0), true), (.jump, CGVector(dx: 200, dy: 500), false),
            (.fall, CGVector(dx: 150, dy: -400), false), (.glide, CGVector(dx: 200, dy: -110), false), (.fall, CGVector(dx: 100, dy: 200), false)
        ]
        for (i, pose) in poses.enumerated() {
            let rig = AlinaRig(height: 52, feetY: -14)
            rig.setScale(4.2)
            rig.position = CGPoint(x: CGFloat(i - 2) * 150 - 80, y: -110)
            root.addChild(rig)
            rigs.append((rig, AlinaRig.Motion(state: pose.0, velocity: pose.1, onGround: pose.2, bloom: false, flip: nil, dt: 0)))
        }
    }

    func update(dt: CGFloat) {
        flipTime = (flipTime + dt / 1.2).truncatingRemainder(dividingBy: 1)
        creatures.forEach { $0.update(dt: dt, speed: 55) }
        for (i, entry) in rigs.enumerated() {
            var motion = entry.1
            motion.dt = dt
            if i == 5 { motion.flip = flipTime }
            entry.0.update(motion)
        }
    }
}
#endif
