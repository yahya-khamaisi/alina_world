import CoreGraphics
import SpriteKit
import Foundation

/// Eight matching high-resolution poses, cropped from one transparent production sheet.
/// All frames share a canvas and foot baseline so changing animation never shifts the collision geometry.
enum CharacterAtlas {
    private static let sprites: [PixelSprite] = [.alinaIdle, .alinaBlink, .alinaRun, .alinaRunB, .alinaJump, .alinaDoubleJump, .alinaFall, .alinaGlide]
    private static var cache: [PixelSprite: CGImage] = [:]
    private static let bounds: [[Int]] = {
        guard let url = Bundle.module.url(forResource: "AlinaFrames", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let values = try? JSONDecoder().decode([[Int]].self, from: data) else { return [] }
        return values
    }()

    static func image(_ sprite: PixelSprite) -> CGImage? {
        guard let index = sprites.firstIndex(of: sprite) else { return nil }
        if let image = cache[sprite] { return image }
        guard bounds.count == sprites.count, let sheet = StorybookArt.image(.alina) else { return nil }
        let b = bounds[index]
        guard b.count == 4, let crop = sheet.cropping(to: CGRect(x: b[0], y: b[1], width: b[2], height: b[3])) else { return nil }
        let width = sprite == .alinaGlide ? 480 : 384
        let height = 528
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.interpolationQuality = .high
        // One source scale for the whole sheet: tucked knees must not make Alina's head grow mid-jump.
        let scale = CGFloat(height - 8) / CGFloat(bounds[0][3])
        let target = CGSize(width: CGFloat(crop.width) * scale, height: CGFloat(crop.height) * scale)
        let cellTop = index < 4 ? 0 : sheet.height / 2
        let sourceFeet = b[1] - cellTop + b[3]
        let baseline = bounds[0][1] + bounds[0][3]
        let y = 4 + CGFloat(baseline - sourceFeet) * scale
        context.draw(crop, in: CGRect(x: (CGFloat(width) - target.width) / 2, y: y, width: target.width, height: target.height))
        let image = context.makeImage()!
        cache[sprite] = image
        return image
    }

    /// A complete six-pose stride, using one scale and a common source baseline for every frame.
    static let runFrames: [SKTexture] = {
        guard let sheet = StorybookArt.image(.runCycle),
              let url = Bundle.module.url(forResource: "AlinaRunCycleFrames", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let frames = try? JSONDecoder().decode([[Int]].self, from: data), frames.count == 6,
              frames.allSatisfy({ $0.count == 4 && $0[2] > 0 && $0[3] > 0 }) else { return [] }
        let scale = min(374 / CGFloat(frames.map { $0[2] }.max()!), 520 / CGFloat(frames.map { $0[3] }.max()!))
        let baseline = frames.enumerated().map { index, b in b[1] - (index < 3 ? 0 : sheet.height / 2) + b[3] }.max()!
        return frames.enumerated().compactMap { index, b in
            guard let crop = sheet.cropping(to: CGRect(x: b[0], y: b[1], width: b[2], height: b[3])),
                  let context = CGContext(data: nil, width: 384, height: 528, bitsPerComponent: 8, bytesPerRow: 0,
                                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
            context.interpolationQuality = .high
            let cellTop = index < 3 ? 0 : sheet.height / 2
            let foot = b[1] - cellTop + b[3]
            let width = CGFloat(crop.width) * scale, height = CGFloat(crop.height) * scale
            context.draw(crop, in: CGRect(x: (384 - width) / 2, y: 4 + CGFloat(baseline - foot) * scale, width: width, height: height))
            let texture = SKTexture(cgImage: context.makeImage()!); texture.filteringMode = .linear
            return texture
        }
    }()

}
