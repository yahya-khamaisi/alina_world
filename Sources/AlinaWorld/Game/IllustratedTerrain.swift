import CoreGraphics

/// Adjacent tiles sample adjacent regions of one painting, rather than repeating the same tiny square.
enum IllustratedTerrain {
    static func image(_ sprite: PixelSprite, theme: WorldTheme, variant: Int) -> CGImage? {
        let top = sprite == .groundTop || sprite == .stoneTop
        guard top || sprite == .groundFill || sprite == .stone,
              let sheet = StorybookArt.image(.terrain) else { return nil }
        let column = variant % 8
        let row = top ? 0 : 1 + ((variant / 8) % 3)
        let x = column * sheet.width / 8, nextX = (column + 1) * sheet.width / 8
        let y = row * sheet.height / 4, nextY = (row + 1) * sheet.height / 4
        guard let crop = sheet.cropping(to: CGRect(x: x, y: y, width: nextX - x, height: nextY - y)) else { return nil }
        guard theme.key != "meadow" else { return crop }
        let context = CGContext(data: nil, width: crop.width, height: crop.height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(crop, in: CGRect(x: 0, y: 0, width: crop.width, height: crop.height))
        context.setBlendMode(.color)
        context.setFillColor(Drawing.color(theme.dirt.0, alpha: 0.72))
        context.fill(CGRect(x: 0, y: 0, width: crop.width, height: crop.height))
        if top {
            context.saveGState()
            context.clip(to: CGRect(x: 0, y: CGFloat(crop.height) * 0.54, width: CGFloat(crop.width), height: CGFloat(crop.height) * 0.46))
            context.setBlendMode(.color)
            context.setFillColor(Drawing.color(theme.grass.1, alpha: 0.92))
            context.fill(CGRect(x: 0, y: 0, width: crop.width, height: crop.height))
            if theme.key == "frost" || theme.key == "coral" {
                context.setBlendMode(.screen)
                context.setFillColor(Drawing.color(theme.grass.0, alpha: theme.key == "frost" ? 0.64 : 0.26))
                context.fill(CGRect(x: 0, y: 0, width: crop.width, height: crop.height))
            }
            context.restoreGState()
        }
        return context.makeImage()
    }
}
