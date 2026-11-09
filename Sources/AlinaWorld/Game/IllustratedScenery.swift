import CoreGraphics

/// Antialiased environment layers for all twelve world palettes, rendered at four times their logical size.
enum IllustratedScenery {
    private static var images: [String: CGImage] = [:]

    static func size(_ layer: Scenery.Layer) -> CGSize {
        switch layer {
        case .sky: return CGSize(width: 1024, height: 280)
        case .clouds: return CGSize(width: 512, height: 110)
        case .mountains: return CGSize(width: 512, height: 104)
        case .farHills: return CGSize(width: 512, height: 84)
        case .nearHills: return CGSize(width: 512, height: 80)
        }
    }

    static func image(_ layer: Scenery.Layer, theme: WorldTheme) -> CGImage {
        let key = "\(layer.rawValue)|\(theme.key)"
        if let cached = images[key] { return cached }
        let palette = BackdropPalette.forTheme(theme)
        let image = Drawing.image(size: size(layer), scale: 4) { p in
            switch layer {
            case .sky:
                p.rounded(-1, -1, 102, 102, 0, palette.sky, outline: nil)
                p.ellipse(65, 43, 4, 14, [palette.sun, palette.sunGlow], outline: nil)
            case .clouds:
                for (x, y, scale) in [(4.0, 29.0, 0.7), (29, 8, 1.0), (61, 38, 0.8), (84, 18, 1.1)] {
                    p.c.saveGState(); p.c.translateBy(x: x, y: y); p.c.scaleBy(x: 0.18 * scale, y: 0.46 * scale)
                    p.cloud(); p.c.restoreGState()
                }
            case .mountains:
                for layerIndex in 0..<2 {
                    let path = CGMutablePath(); path.move(to: CGPoint(x: -2, y: 102))
                    path.addLine(to: CGPoint(x: -2, y: 70))
                    for i in 0...8 {
                        let x = Double(i) * 14 - 6
                        let y = 18 + Double((i * 17 + layerIndex * 13) % 37)
                        path.addLine(to: CGPoint(x: x, y: y)); path.addLine(to: CGPoint(x: x + 7, y: 75))
                    }
                    path.addLine(to: CGPoint(x: 102, y: 102)); path.closeSubpath()
                    p.shape(path, [layerIndex == 0 ? palette.mountain.0 : palette.mountain.1, palette.haze], outline: nil)
                }
            case .farHills, .nearHills:
                let near = layer == .nearHills
                let colors = near ? palette.nearHill : palette.farHill
                let path = CGMutablePath(); path.move(to: CGPoint(x: -1, y: 102))
                func surface(_ x: Double) -> Double { 43 + sin(x / 100 * .pi * 4) * 13 + cos(x / 100 * .pi * 6) * 5 }
                for i in -1...201 {
                    let x = Double(i) / 2
                    path.addLine(to: CGPoint(x: x, y: surface(x)))
                }
                path.addLine(to: CGPoint(x: 101, y: 102)); path.closeSubpath()
                p.shape(path, [colors.0, colors.1, colors.2], outline: nil)
                for i in 0..<35 {
                    let x = Double(i) * 3 + 0.4
                    let y = surface(x)
                    p.ellipse(x - 0.6, y - 9, 1.8, 11, [colors.1, colors.3], outline: nil)
                    p.ellipse(x - 1.1, y - 13, 2.6, 9, [colors.0, colors.3], outline: nil)
                }
                if near, theme.key == "meadow" {
                    for i in 0..<30 { p.ellipse(Double((i * 23) % 100), 70 + Double((i * 11) % 24), 0.7, 1.8, [0xFFE4DD], outline: nil) }
                }
            }
        }
        images[key] = image
        return image
    }
}
