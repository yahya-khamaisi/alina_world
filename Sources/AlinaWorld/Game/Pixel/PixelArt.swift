import CoreGraphics
import Foundation
import SpriteKit

/// Turns `PixelCatalog` character maps into crisp images (SwiftUI) and nearest-filtered textures (SpriteKit).
enum PixelArt {
    private static var images: [String: CGImage] = [:]
    private static var textures: [String: SKTexture] = [:]
    private static let lock = NSLock()

    /// Size of the sprite in art pixels.
    static func size(of sprite: PixelSprite) -> CGSize {
        let rows = PixelCatalog.rows(for: sprite)
        return CGSize(width: rows.map(\.count).max() ?? 0, height: rows.count)
    }

    /// Image with `scale` device pixels per art pixel — upscaled here so SwiftUI never smooths it.
    static func image(
        _ sprite: PixelSprite,
        theme: WorldTheme? = nil,
        overrides: [Character: UInt32] = [:],
        scale: Int = 1
    ) -> CGImage {
        let key = cacheKey(sprite, theme: theme, overrides: overrides, scale: scale)
        lock.lock()
        defer { lock.unlock() }
        if let cached = images[key] { return cached }
        let rendered = render(PixelCatalog.rows(for: sprite), palette: palette(theme: theme, overrides: overrides), scale: scale)
        images[key] = rendered
        return rendered
    }

    /// One-pixel-per-cell texture with nearest filtering; size the sprite node to upscale it.
    static func texture(
        _ sprite: PixelSprite,
        theme: WorldTheme? = nil,
        overrides: [Character: UInt32] = [:]
    ) -> SKTexture {
        let key = cacheKey(sprite, theme: theme, overrides: overrides, scale: 1)
        if let cached = lock.withLock({ textures[key] }) { return cached }
        let texture = SKTexture(cgImage: image(sprite, theme: theme, overrides: overrides))
        texture.filteringMode = .nearest
        lock.withLock { textures[key] = texture }
        return texture
    }

    /// Sprite node sized at `scale` screen points per art pixel.
    static func node(
        _ sprite: PixelSprite,
        theme: WorldTheme? = nil,
        overrides: [Character: UInt32] = [:],
        scale: CGFloat
    ) -> SKSpriteNode {
        let texture = texture(sprite, theme: theme, overrides: overrides)
        let size = size(of: sprite)
        return SKSpriteNode(texture: texture, size: CGSize(width: size.width * scale, height: size.height * scale))
    }

    /// Solid square used by particle emitters so effects stay pixel-shaped.
    static let squareTexture: SKTexture = {
        let texture = SKTexture(cgImage: render(["O"], palette: ["O": 0xFFFFFF], scale: 4))
        texture.filteringMode = .nearest
        return texture
    }()

    private static func palette(theme: WorldTheme?, overrides: [Character: UInt32]) -> [Character: UInt32] {
        var palette = PixelCatalog.basePalette
        palette.merge((theme ?? WorldThemes.ordered[0]).spritePalette) { _, new in new }
        palette.merge(overrides) { _, new in new }
        return palette
    }

    private static func cacheKey(_ sprite: PixelSprite, theme: WorldTheme?, overrides: [Character: UInt32], scale: Int) -> String {
        let extra = overrides.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }.joined()
        return "\(sprite.rawValue)|\(theme?.key ?? "-")|\(extra)|\(scale)"
    }

    private static func render(_ rows: [String], palette: [Character: UInt32], scale: Int) -> CGImage {
        let width = (rows.map(\.count).max() ?? 1) * scale
        let height = max(1, rows.count) * scale
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.interpolationQuality = .none
        for (r, row) in rows.enumerated() {
            for (c, ch) in row.enumerated() {
                guard let hex = palette[ch] else { continue }
                context.setFillColor(
                    red: CGFloat((hex >> 16) & 0xFF) / 255,
                    green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255,
                    alpha: 1
                )
                context.fill(CGRect(x: c * scale, y: (rows.count - 1 - r) * scale, width: scale, height: scale))
            }
        }
        return context.makeImage()!
    }
}
