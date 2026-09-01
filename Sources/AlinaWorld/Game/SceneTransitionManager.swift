import SpriteKit
import SwiftUI

enum TransitionType {
    case fade(duration: CGFloat = 0.5)
    case slide(direction: SlideDirection, duration: CGFloat = 0.6)
    case iris(duration: CGFloat = 0.7)
    case crossFade(duration: CGFloat = 0.5)
    case pixelDissolve(duration: CGFloat = 0.8)

    enum SlideDirection {
        case left, right, up, down
    }
}

final class SceneTransitionManager {
    private let scene: SKScene
    private var transitionNode: SKNode?
    private var snapshotTexture: SKTexture?
    private var isTransitioning = false
    private var onComplete: (() -> Void)?

    init(scene: SKScene) {
        self.scene = scene
    }

    func transition(to newScene: SKScene, type: TransitionType = .fade(), completion: @escaping () -> Void) {
        guard !isTransitioning else { return }
        isTransitioning = true
        onComplete = completion

        switch type {
        case .fade(let duration):
            performFadeTransition(to: newScene, duration: duration)
        case .slide(let direction, let duration):
            performSlideTransition(to: newScene, direction: direction, duration: duration)
        case .iris(let duration):
            performIrisTransition(to: newScene, duration: duration)
        case .crossFade(let duration):
            performCrossFadeTransition(to: newScene, duration: duration)
        case .pixelDissolve(let duration):
            performPixelDissolveTransition(to: newScene, duration: duration)
        }
    }

    private func performFadeTransition(to newScene: SKScene, duration: CGFloat) {
        let overlay = SKSpriteNode(color: .black, size: scene.size)
        overlay.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        overlay.zPosition = 1000
        overlay.alpha = 0
        scene.addChild(overlay)

        let fadeIn = SKAction.fadeAlpha(to: 1, duration: duration * 0.5)
        let switchScene = SKAction.run { [weak self] in
            self?.scene.view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 0))
        }
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: duration * 0.5)
        let cleanup = SKAction.run { [weak self] in
            overlay.removeFromParent()
            self?.isTransitioning = false
            self?.onComplete?()
        }

        overlay.run(SKAction.sequence([fadeIn, switchScene, fadeOut, cleanup]))
    }

    private func performSlideTransition(to newScene: SKScene, direction: TransitionType.SlideDirection, duration: CGFloat) {
        guard let view = scene.view else { return }

        let currentSnapshot = view.texture(from: scene)
        let currentImage = SKSpriteNode(texture: currentSnapshot)
        currentImage.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        currentImage.zPosition = 999
        scene.addChild(currentImage)

        let newSceneHolder = SKNode()
        newSceneHolder.zPosition = 998

        let offset: CGVector
        switch direction {
        case .left: offset = CGVector(dx: -scene.size.width, dy: 0)
        case .right: offset = CGVector(dx: scene.size.width, dy: 0)
        case .up: offset = CGVector(dx: 0, dy: scene.size.height)
        case .down: offset = CGVector(dx: 0, dy: -scene.size.height)
        }

        currentImage.run(SKAction.move(by: offset, duration: duration))

        let slideIn = SKAction.move(by: CGVector(dx: -offset.dx, dy: -offset.dy), duration: duration)
        slideIn.timingMode = .easeOut

        let switchScene = SKAction.run { [weak self] in
            self?.scene.view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 0))
        }

        let cleanup = SKAction.run { [weak self] in
            currentImage.removeFromParent()
            newSceneHolder.removeFromParent()
            self?.isTransitioning = false
            self?.onComplete?()
        }

        currentImage.run(SKAction.sequence([slideIn, switchScene, SKAction.wait(forDuration: 0.1), cleanup]))
    }

    private func performIrisTransition(to newScene: SKScene, duration: CGFloat) {
        let shape = SKShapeNode(circleOfRadius: 0)
        shape.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        shape.fillColor = .black
        shape.strokeColor = .clear
        shape.zPosition = 1000
        scene.addChild(shape)

        let maxRadius = hypot(scene.size.width, scene.size.height)
        let expand = SKAction.resize(toWidth: maxRadius * 2, height: maxRadius * 2, duration: duration * 0.5)
        expand.timingMode = .easeInEaseOut

        let switchScene = SKAction.run { [weak self] in
            self?.scene.view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 0))
        }

        let contract = SKAction.resize(toWidth: 0, height: 0, duration: duration * 0.5)
        contract.timingMode = .easeInEaseOut

        let cleanup = SKAction.run { [weak self] in
            shape.removeFromParent()
            self?.isTransitioning = false
            self?.onComplete?()
        }

        shape.run(SKAction.sequence([expand, switchScene, contract, cleanup]))
    }

    private func performCrossFadeTransition(to newScene: SKScene, duration: CGFloat) {
        guard let view = scene.view else { return }

        let currentSnapshot = view.texture(from: scene)
        let currentImage = SKSpriteNode(texture: currentSnapshot)
        currentImage.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        currentImage.zPosition = 999
        scene.addChild(currentImage)

        let newSceneHolder = SKNode()
        newSceneHolder.zPosition = 998

        let fadeOut = SKAction.fadeOut(withDuration: duration)
        let switchScene = SKAction.run { [weak self] in
            self?.scene.view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 0))
        }
        let cleanup = SKAction.run { [weak self] in
            currentImage.removeFromParent()
            newSceneHolder.removeFromParent()
            self?.isTransitioning = false
            self?.onComplete?()
        }

        currentImage.run(SKAction.sequence([fadeOut, switchScene, cleanup]))
    }

    private func performPixelDissolveTransition(to newScene: SKScene, duration: CGFloat) {
        let shader = SKShader(source: """
            void main() {
                float noise = fract(sin(dot(v_tex_coord.xy, vec2(12.9898, 78.233))) * 43758.5453);
                float threshold = u_time;
                if (noise < threshold) {
                    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
                } else {
                    gl_FragColor = texture2D(u_texture, v_tex_coord);
                }
            }
        """)
        shader.uniforms = [SKUniform(name: "u_time", float: 0)]

        let overlay = SKSpriteNode(color: .clear, size: scene.size)
        overlay.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        overlay.shader = shader
        overlay.zPosition = 1000
        scene.addChild(overlay)

        let animate = SKAction.customAction(withDuration: duration) { node, elapsed in
            let progress = elapsed / CGFloat(duration)
            shader.uniforms = [SKUniform(name: "u_time", float: Float(progress))]
        }

        let switchScene = SKAction.run { [weak self] in
            self?.scene.view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 0))
        }

        let cleanup = SKAction.run { [weak self] in
            overlay.removeFromParent()
            self?.isTransitioning = false
            self?.onComplete?()
        }

        overlay.run(SKAction.sequence([animate, switchScene, cleanup]))
    }

    func cancel() {
        transitionNode?.removeAllActions()
        transitionNode?.removeFromParent()
        transitionNode = nil
        isTransitioning = false
    }
}