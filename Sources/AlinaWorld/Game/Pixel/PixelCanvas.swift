import CoreGraphics
import SpriteKit

/// A small pixel buffer for procedurally painted art (parallax layers, the world map).
/// Every primitive lands on whole pixels, so the result stays crisp when upscaled with nearest filtering.
/// Coordinates are top-down: (0, 0) is the top-left pixel.
struct PixelCanvas {
    let width: Int
    let height: Int
    /// 0xAARRGGBB; alpha 0 is transparent.
    private(set) var pixels: [UInt32]
    /// Wrap x so layers tile seamlessly when repeated side by side.
    var wrapX = false

    init(width: Int, height: Int, fill: UInt32? = nil) {
        self.width = width
        self.height = height
        pixels = Array(repeating: fill.map { 0xFF00_0000 | $0 } ?? 0, count: width * height)
    }

    // MARK: Pixels

    func get(_ x: Int, _ y: Int) -> UInt32? {
        guard let i = index(x, y) else { return nil }
        let value = pixels[i]
        return value >> 24 == 0 ? nil : value & 0xFFFFFF
    }

    /// Opaque pixel in 0xRRGGBB.
    mutating func set(_ x: Int, _ y: Int, _ hex: UInt32) {
        guard let i = index(x, y) else { return }
        pixels[i] = 0xFF00_0000 | hex
    }

    /// Mixes `hex` over whatever is there; on a transparent pixel it writes a translucent one.
    mutating func blend(_ x: Int, _ y: Int, _ hex: UInt32, _ alpha: Double) {
        guard let i = index(x, y) else { return }
        let old = pixels[i]
        let oldAlpha = Double(old >> 24) / 255
        if oldAlpha == 0 {
            pixels[i] = UInt32(alpha * 255) << 24 | hex
            return
        }
        let mixed = Self.mix(old & 0xFFFFFF, hex, alpha)
        let a = min(1, oldAlpha + alpha * (1 - oldAlpha))
        pixels[i] = UInt32(a * 255) << 24 | mixed
    }

    /// Paints only where the pixel is already opaque (shading inside a silhouette).
    mutating func tint(_ x: Int, _ y: Int, _ hex: UInt32) {
        guard get(x, y) != nil else { return }
        set(x, y, hex)
    }

    private func index(_ x: Int, _ y: Int) -> Int? {
        guard y >= 0, y < height else { return nil }
        var x = x
        if wrapX { x = ((x % width) + width) % width } else if x < 0 || x >= width { return nil }
        return y * width + x
    }

    // MARK: Shapes

    mutating func fillRect(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ hex: UInt32) {
        for yy in y..<(y + max(0, h)) { for xx in x..<(x + max(0, w)) { set(xx, yy, hex) } }
    }

    mutating func clearRect(_ x: Int, _ y: Int, _ w: Int, _ h: Int) {
        for yy in y..<(y + max(0, h)) { for xx in x..<(x + max(0, w)) { if let i = index(xx, yy) { pixels[i] = 0 } } }
    }

    mutating func fillEllipse(cx: Double, cy: Double, rx: Double, ry: Double, _ hex: UInt32) {
        let y0 = Int((cy - ry).rounded(.down)), y1 = Int((cy + ry).rounded(.up))
        let x0 = Int((cx - rx).rounded(.down)), x1 = Int((cx + rx).rounded(.up))
        for y in y0...y1 {
            for x in x0...x1 {
                let dx = (Double(x) + 0.5 - cx) / rx, dy = (Double(y) + 0.5 - cy) / ry
                if dx * dx + dy * dy <= 1 { set(x, y, hex) }
            }
        }
    }

    /// A character-map sprite stamped at (x, y); `.` and unknown letters are skipped.
    mutating func stamp(_ rows: [String], x: Int, y: Int, palette: [Character: UInt32], flip: Bool = false) {
        for (r, row) in rows.enumerated() {
            let chars = Array(row)
            for (c, ch) in chars.enumerated() {
                guard let hex = palette[ch] else { continue }
                set(x + (flip ? chars.count - 1 - c : c), y + r, hex)
            }
        }
    }

    /// Ring of `outline` around every opaque pixel (4-neighbour), drawn into transparent pixels only.
    mutating func outline(_ hex: UInt32) {
        let snapshot = pixels
        for y in 0..<height {
            for x in 0..<width where snapshot[y * width + x] >> 24 == 0 {
                let neighbours = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
                if neighbours.contains(where: { nx, ny in
                    guard ny >= 0, ny < height else { return false }
                    let wx = wrapX ? ((nx % width) + width) % width : nx
                    guard wx >= 0, wx < width else { return false }
                    return snapshot[ny * width + wx] >> 24 == 0xFF
                }) {
                    set(x, y, hex)
                }
            }
        }
    }

    // MARK: Output

    func cgImage(scale: Int = 1) -> CGImage {
        let w = width * scale, h = height * scale
        var bytes = [UInt8](repeating: 0, count: w * h * 4)
        for y in 0..<h {
            for x in 0..<w {
                let p = pixels[(y / scale) * width + x / scale]
                let a = Double(p >> 24) / 255
                let o = (y * w + x) * 4
                bytes[o] = UInt8(Double((p >> 16) & 0xFF) * a)
                bytes[o + 1] = UInt8(Double((p >> 8) & 0xFF) * a)
                bytes[o + 2] = UInt8(Double(p & 0xFF) * a)
                bytes[o + 3] = UInt8(p >> 24)
            }
        }
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        return CGImage(
            width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )!
    }

    func texture() -> SKTexture {
        let texture = SKTexture(cgImage: cgImage())
        texture.filteringMode = .nearest
        return texture
    }

    // MARK: Colour helpers

    static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
        func channel(_ shift: UInt32) -> UInt32 {
            let ca = Double((a >> shift) & 0xFF), cb = Double((b >> shift) & 0xFF)
            return UInt32(max(0, min(255, (ca + (cb - ca) * t).rounded()))) << shift
        }
        return channel(16) | channel(8) | channel(0)
    }

    /// 4 × 4 ordered-dither threshold in 0..<1, for banded gradients with a pixel texture.
    static func bayer(_ x: Int, _ y: Int) -> Double {
        let m = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
        return (Double(m[(y & 3) * 4 + (x & 3)]) + 0.5) / 16
    }

    /// Colour at `t` along evenly spaced stops, quantised to the stops with ordered dithering.
    static func ditheredRamp(_ stops: [UInt32], _ t: Double, x: Int, y: Int, seam: Double = 0.4) -> UInt32 {
        guard stops.count > 1 else { return stops.first ?? 0 }
        let pos = max(0, min(0.9999, t)) * Double(stops.count - 1)
        let i = Int(pos)
        // Dither only across a narrow seam between bands, so most of each band stays a flat colour.
        let frac = max(0, min(1, (pos - Double(i) - (1 - seam) / 2) / seam))
        return frac > bayer(x, y) ? stops[min(i + 1, stops.count - 1)] : stops[i]
    }
}

/// Seamless 1-D noise built from sines with whole periods across `period` pixels.
struct LoopNoise {
    private var waves: [(k: Double, amp: Double, phase: Double)] = []
    let period: Double

    init(period: Int, seed: UInt64, harmonics: [Int], falloff: Double = 0.6) {
        self.period = Double(period)
        var rng = SeededRNG(seed: seed)
        var amp = 1.0
        for k in harmonics {
            waves.append((Double(k), amp, Double(rng.next() % 6283) / 1000))
            amp *= falloff
        }
        let total = waves.reduce(0) { $0 + $1.amp }
        waves = waves.map { ($0.k, $0.amp / total, $0.phase) }
    }

    /// Roughly -1…1.
    func value(_ x: Double) -> Double {
        waves.reduce(0) { $0 + $1.amp * sin(2 * .pi * $1.k * x / period + $1.phase) }
    }
}
