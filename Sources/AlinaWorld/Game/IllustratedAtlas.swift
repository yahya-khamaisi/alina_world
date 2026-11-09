import CoreGraphics
import Foundation

/// Production prop and creature paintings, kept in atlases for consistent style and efficient loading.
enum IllustratedAtlas {
    private static var images: [String: CGImage] = [:]
    private static var bounds: [StorybookArt.Plate: [[Int]]] = [:]

    static func sprite(_ sprite: PixelSprite) -> CGImage? {
        let entries: [PixelSprite] = [.gloomling, .gloomlingStep, .thornbeetle, .mothwisp, .mothwispFlap, .guardian, .frostpuff, .shellcrab, .starwisp]
        if let index = entries.firstIndex(of: sprite) {
            return image(.enemies, index: index, size: PixelArt.size(of: sprite))
        }
        if sprite == .beacon { return image(.props, index: 5, size: PixelArt.size(of: sprite)) }
        return levelObject(sprite)
    }

    /// Painted blocks, hazards, platforms and pick-ups from `LevelObjects.png` (4 × 3 grid, see design/art-v3/README.md).
    /// Returns nil until that sheet exists, so the drawn fallbacks in `IllustratedArt` keep working.
    private static func levelObject(_ sprite: PixelSprite) -> CGImage? {
        let size = PixelArt.size(of: sprite)
        switch sprite {
        // Square blocks fill their tile exactly so neighbours meet edge to edge.
        case .bloomBlock: return image(.levelObjects, index: 0, size: size, fill: true)
        case .bloomBlockUsed: return image(.levelObjects, index: 1, size: size, fill: true)
        case .mossbrick: return image(.levelObjects, index: 2, size: size, fill: true)
        case .log: return image(.levelObjects, index: 3, size: size, fill: true)
        case .thorns: return image(.levelObjects, index: 4, size: size)
        case .springShell: return image(.levelObjects, index: 5, size: size)
        // A run of island tiles shows the painting's left end, middle and right end; a lone tile shows all of it.
        case .leafPadSingle: return image(.levelObjects, index: 6, size: size, fill: true)
        case .leafPadLeft: return image(.levelObjects, index: 6, size: size, fill: true, slice: 0)
        case .leafPad: return image(.levelObjects, index: 6, size: size, fill: true, slice: 1)
        case .leafPadRight: return image(.levelObjects, index: 6, size: size, fill: true, slice: 2)
        case .cloudPad: return image(.levelObjects, index: 7, size: size, fill: true)
        case .petal, .petalTurn: return image(.levelObjects, index: 8, size: size)
        case .crystal: return image(.levelObjects, index: 9, size: size)
        case .sunbloom: return image(.levelObjects, index: 10, size: size)
        case .ribbon: return image(.levelObjects, index: 11, size: size)
        default: return nil
        }
    }

    static func prop(_ kind: Props.Kind, theme: WorldTheme) -> CGImage? {
        if kind == .tree {
            let keys = ["brook", "grove", "cavern", "ridge", "marsh", "spire", "storm", "throne", "frost", "coral", "starfall", "meadow"]
            if let index = keys.firstIndex(of: theme.key),
               let painting = image(.biomeProps, index: index, size: IllustratedArt.propSize(kind)) { return painting }
        }
        let index: Int
        switch kind {
        case .tree: index = 0
        case .bush: index = 1
        case .rock: index = 2
        case .fence: index = 3
        case .flowers: index = 4
        }
        guard let raw = image(.props, index: index, size: IllustratedArt.propSize(kind)) else { return nil }
        guard theme.key != "meadow", kind != .fence else { return raw }
        let key = "tint|\(kind)|\(theme.key)"
        if let cached = images[key] { return cached }
        let context = CGContext(data: nil, width: raw.width, height: raw.height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let rect = CGRect(x: 0, y: 0, width: raw.width, height: raw.height)
        context.draw(raw, in: rect)
        context.clip(to: rect, mask: raw)
        context.setBlendMode(.color)
        context.setFillColor(Drawing.color(kind == .rock ? theme.dirt.1 : theme.leaves.0, alpha: 0.65))
        context.fill(rect)
        let result = context.makeImage()!
        images[key] = result
        return result
    }

    /// `fill` stretches the frame over the whole canvas (tiling blocks); otherwise it is fitted and stood on the bottom edge.
    /// `slice` 0, 1 or 2 takes the left, middle or right third of the frame.
    private static func image(_ plate: StorybookArt.Plate, index: Int, size: CGSize, fill: Bool = false, slice: Int? = nil) -> CGImage? {
        let key = "\(plate.rawValue)|\(index)|\(size)|\(fill)|\(slice ?? -1)"
        if let cached = images[key] { return cached }
        if bounds[plate] == nil,
           let url = Bundle.module.url(forResource: plate.rawValue + "Frames", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            bounds[plate] = try? JSONDecoder().decode([[Int]].self, from: data)
        }
        guard let values = bounds[plate], index < values.count, values[index].count == 4,
              let sheet = StorybookArt.image(plate) else { return nil }
        var b = values[index]
        if let slice {
            let third = b[2] / 3
            b = [b[0] + third * slice, b[1], slice == 2 ? b[2] - third * 2 : third, b[3]]
        }
        guard let crop = sheet.cropping(to: CGRect(x: b[0], y: b[1], width: b[2], height: b[3])) else { return nil }
        let width = max(1, Int(size.width * 8)), height = max(1, Int(size.height * 8))
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.interpolationQuality = .high
        if fill {
            context.draw(crop, in: CGRect(x: 0, y: 0, width: width, height: height))
            let image = context.makeImage()!
            images[key] = image
            return image
        }
        let scale = min(CGFloat(width - 4) / CGFloat(crop.width), CGFloat(height - 4) / CGFloat(crop.height))
        let target = CGSize(width: CGFloat(crop.width) * scale, height: CGFloat(crop.height) * scale)
        context.draw(crop, in: CGRect(x: (CGFloat(width) - target.width) / 2, y: 1, width: target.width, height: target.height))
        let image = context.makeImage()!
        images[key] = image
        return image
    }
}
