import SpriteKit

/// Continuously animated, infinitely recycled panoramic layers and mission-authored weather.
final class ParallaxBackground {
    private var root: SKNode?
    private var sprites: [SKSpriteNode] = []
    private var panorama: SKTexture?
    private var shader: SKShader?
    private var phaseUniform: SKUniform?
    private var tileSize = CGSize(width: 1600, height: 800)
    private var groundTop: CGFloat = 0
    private let weatherNode = MissionWeatherNode()
    private var pitShade: SKSpriteNode?

    func attach(to scene: SKScene, theme: WorldTheme, weather: MissionWeather, mapWidth: CGFloat, groundTop: CGFloat, ambientParticles: Bool) {
        self.groundTop = groundTop
        let root = SKNode(); root.zPosition = -49; scene.addChild(root); self.root = root
        panorama = StorybookArt.texture(.environment(for: theme.key))
            ?? SKTexture(cgImage: IllustratedScenery.image(.sky, theme: theme))
        if let panorama { tileSize.width = tileSize.height * panorama.size().width / panorama.size().height }
        let phase = SKUniform(name: "u_phase", float: 0)
        phaseUniform = phase
        let flowing = ["meadow", "brook", "grove", "cavern", "marsh", "spire", "throne", "coral"].contains(theme.key)
        // Cloud and water displacement are deliberately small, keeping the painting sharp and landmarks stable.
        let shader = SKShader(source: """
        void main() {
            vec2 uv = v_tex_coord;
            float water = smoothstep(0.20, 0.31, uv.y) * (1.0 - smoothstep(0.48, 0.59, uv.y)) * u_water;
            float cloud = smoothstep(0.64, 0.88, uv.y);
            uv.x += cloud * sin(u_phase * 0.12 + uv.y * 3.0) * 0.003;
            uv.x += water * sin(uv.y * 100.0 - u_phase * 1.7) * 0.0011;
            uv.y += water * sin(uv.x * 110.0 + u_phase * 1.3) * 0.0008;
            vec4 color = texture2D(u_texture, clamp(uv, vec2(0.001), vec2(0.999)));
            // The paintings are dehazed and upscaled offline (Scripts/enhance-backdrops.py). Here they are only
            // set back behind the action: a little less saturation and contrast, a touch darker, no veil.
            float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
            vec3 c = mix(vec3(luma), color.rgb, 0.78);
            c = mix(vec3(0.5), c, 0.86) * 0.95;
            color.rgb = clamp(c, 0.0, 1.0);
            gl_FragColor = color;
        }
        """)
        shader.uniforms = [phase, SKUniform(name: "u_water", float: flowing ? 1 : 0.05)]
        self.shader = shader
        // Pits fade from the painting into deep earth, so gaps read as drops rather than a flat fill.
        let pitShade = SKSpriteNode(texture: Self.pitTexture(theme), size: CGSize(width: mapWidth + 4000, height: 900))
        pitShade.anchorPoint = CGPoint(x: 0, y: 1)
        pitShade.position = CGPoint(x: -2000, y: groundTop + 8)
        pitShade.zPosition = -30; scene.addChild(pitShade); self.pitShade = pitShade
        weatherNode.attach(to: scene, weather: weather, enabled: ambientParticles)
    }

    /// Vertical gradient: clear at the ground line, the world's dark soil a little below, near-black plum at the bottom.
    private static func pitTexture(_ theme: WorldTheme) -> SKTexture {
        let height = 256
        let context = CGContext(data: nil, width: 1, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        func color(_ hex: UInt32, _ alpha: CGFloat) -> CGColor {
            CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
        }
        let soil = PixelCanvas.mix(theme.dirt.1, 0x2A1424, 0.45)
        let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [
            color(soil, 0), color(soil, 0.9), color(0x2A1424, 1)
        ] as CFArray, locations: [0, 0.07, 0.45])!
        // CoreGraphics y runs up: the top of the texture (ground line) is y = height.
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: height), end: CGPoint(x: 0, y: 0), options: [.drawsAfterEndLocation])
        return SKTexture(cgImage: context.makeImage()!)
    }

    func update(visible: CGRect, delta: TimeInterval) {
        weatherNode.update(visible: visible, delta: delta)
        phaseUniform?.floatValue = Float(weatherNode.time)
        // Two-image mirrored period: identical pixels meet at each edge. The modulo never exhausts the strip.
        let centers = BackgroundTiling.centers(visible: visible, tileWidth: tileSize.width, time: weatherNode.time)
        let needed = centers.count
        while sprites.count < needed {
            let node = SKSpriteNode(texture: panorama, size: tileSize)
            node.shader = shader; root?.addChild(node); sprites.append(node)
        }
        for (slot, node) in sprites.enumerated() {
            node.isHidden = slot >= needed
            guard slot < centers.count else { continue }
            let index = slot - 1
            // Sink the painting so its flat misty bottom band sits behind the ground.
            node.position = CGPoint(x: centers[slot], y: groundTop - 230 + tileSize.height / 2)
            node.xScale = index.isMultiple(of: 2) ? 1 : -1
        }
    }

    func cleanup() {
        root?.removeFromParent(); pitShade?.removeFromParent(); weatherNode.cleanup()
        sprites.removeAll(); root = nil; panorama = nil; shader = nil; phaseUniform = nil; pitShade = nil
    }
}
