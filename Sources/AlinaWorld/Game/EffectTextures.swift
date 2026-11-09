import SpriteKit

/// Soft light and distinct silhouettes shared by the weather simulation and visual feedback.
enum EffectTextures {
    /// Round soft light that fades to fully clear at the texture's edge (no square corners).
    static let glow = radial([Drawing.color(0xFFFFFF, alpha: 0.9), Drawing.color(0xFFFFFF, alpha: 0)], radius: 128)
    /// Small soft dot for dust and bursts: a solid core with a feathered edge.
    static let softDot = radial([Drawing.color(0xFFFFFF, alpha: 1), Drawing.color(0xFFFFFF, alpha: 0.85), Drawing.color(0xFFFFFF, alpha: 0)],
                                locations: [0, 0.45, 1], radius: 128)
    /// Thin bright ring for shockwaves.
    static let ring = radial([Drawing.color(0xFFFFFF, alpha: 0), Drawing.color(0xFFFFFF, alpha: 0), Drawing.color(0xFFFFFF, alpha: 0.95),
                              Drawing.color(0xFFFFFF, alpha: 0)], locations: [0, 0.72, 0.86, 1], radius: 128)
    static let vignette = radial([Drawing.color(0x17102F, alpha: 0), Drawing.color(0x17102F, alpha: 0), Drawing.color(0x17102F, alpha: 0.5)], locations: [0, 0.6, 1])
    static let sparkle = make { p in
        p.shape(p.path([(50, 3), (60, 38), (96, 50), (60, 61), (50, 97), (39, 61), (4, 50), (39, 38)]), [0xFFFFFF], outline: nil)
    }
    static let leaf = make { p in
        let path = CGMutablePath(); path.move(to: CGPoint(x: 11, y: 87))
        path.addCurve(to: CGPoint(x: 83, y: 9), control1: CGPoint(x: 0, y: 33), control2: CGPoint(x: 49, y: 13))
        path.addCurve(to: CGPoint(x: 11, y: 87), control1: CGPoint(x: 105, y: 65), control2: CGPoint(x: 55, y: 89))
        p.shape(path, [0xFFFFFF], outline: nil)
    }
    static let snowflake = make { p in
        for i in 0..<3 {
            let a = Double(i) * .pi / 3
            p.stroke(p.path([(50 - cos(a) * 42, 50 - sin(a) * 42), (50 + cos(a) * 42, 50 + sin(a) * 42)], close: false), 0xFFFFFF, 5)
        }
    }
    static let cloud: SKTexture = {
        let image = Drawing.image(size: CGSize(width: 160, height: 56), scale: 4) { p in
            p.c.setShadow(offset: .zero, blur: 4, color: Drawing.color(0xFFFFFF, alpha: 0.35))
            for (x, y, w, h) in [(0.0, 43.0, 40.0, 45.0), (14, 24, 38, 66), (34, 5, 40, 83), (56, 30, 36, 58), (75, 50, 25, 38)] {
                p.ellipse(x, y, w, h, [0xFFFFFF, 0xEEEAF7], outline: nil)
            }
        }
        let result = SKTexture(cgImage: image); result.filteringMode = .linear; return result
    }()

    /// `radius` 181 reaches the corners (vignettes); 128 stops at the edges so the shape stays round.
    static func radial(_ colors: [CGColor], locations: [CGFloat]? = nil, radius: CGFloat = 181) -> SKTexture {
        let context = CGContext(data: nil, width: 256, height: 256, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: locations)!
        context.drawRadialGradient(gradient, startCenter: CGPoint(x: 128, y: 128), startRadius: 0,
                                   endCenter: CGPoint(x: 128, y: 128), endRadius: radius, options: radius > 128 ? [.drawsAfterEndLocation] : [])
        let result = SKTexture(cgImage: context.makeImage()!); result.filteringMode = .linear; return result
    }

    private static func make(_ paint: (Drawing) -> Void) -> SKTexture {
        let result = SKTexture(cgImage: Drawing.image(size: CGSize(width: 32, height: 32), scale: 4, paint: paint))
        result.filteringMode = .linear
        return result
    }
}
