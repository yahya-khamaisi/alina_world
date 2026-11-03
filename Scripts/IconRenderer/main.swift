// Renders the 1024 px app icon from the game's own pixel sprites.
// Built and run by Scripts/make-icon.sh together with the Pixel sources.
import AppKit
import CoreGraphics

let size = 1024
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let theme = WorldThemes.ordered[0]

let context = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
context.interpolationQuality = .none

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: alpha
    )
}

/// Draws a sprite with its top-left corner at (x, top) in top-down coordinates.
func draw(_ sprite: PixelSprite, scale: Int, x: CGFloat, top: CGFloat, overrides: [Character: UInt32] = [:]) {
    let image = PixelArt.image(sprite, theme: theme, overrides: overrides, scale: scale)
    let rect = CGRect(x: x, y: CGFloat(size) - top - CGFloat(image.height), width: CGFloat(image.width), height: CGFloat(image.height))
    context.draw(image, in: rect)
}

func fill(_ hex: UInt32, top: CGFloat, height: CGFloat) {
    context.setFillColor(color(hex))
    context.fill(CGRect(x: 0, y: CGFloat(size) - top - height, width: CGFloat(size), height: height))
}

let squircle = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

// Drop shadow under the icon body.
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: color(0x2B2148, 0.35))
context.addPath(squircle)
context.setFillColor(color(theme.sky[0]))
context.fillPath()
context.restoreGState()

context.saveGState()
context.addPath(squircle)
context.clip()

// Banded sky, as in the game.
let groundTop: CGFloat = 790
let bands: [CGFloat] = [0.2, 0.17, 0.15, 0.14]
var bandTop: CGFloat = 100
for (i, fraction) in bands.enumerated() {
    let height = (groundTop - 100) * fraction
    fill(theme.sky[i], top: bandTop, height: height + 1)
    bandTop += height
}
fill(theme.sky[4], top: bandTop, height: groundTop - bandTop)

draw(.sun, scale: 9, x: 740, top: 150)
draw(.cloud, scale: 8, x: 150, top: 210)
draw(.cloud, scale: 5, x: 560, top: 300)

// Far and near hills on their own color bands.
fill(theme.hills.1, top: groundTop - 90, height: 90)
for i in 0..<4 { draw(.hillFar, scale: 14, x: CGFloat(i) * 320 - 80, top: groundTop - 90 - 112) }
fill(theme.grass.1, top: groundTop - 20, height: 20)
for i in 0..<3 { draw(.hillNear, scale: 16, x: CGFloat(i) * 420 - 140, top: groundTop + 4 - 128) }

draw(.tree, scale: 9, x: 120, top: groundTop - 135)
draw(.bush, scale: 7, x: 760, top: groundTop - 35)
draw(.flower, scale: 6, x: 690, top: groundTop - 36)

// Ground strip with the same grass teeth and dirt tile as the levels.
fill(theme.grass.0, top: groundTop, height: 10)
fill(theme.grass.1, top: groundTop + 10, height: 32)
for x in stride(from: 0, to: size, by: 36) {
    context.setFillColor(color(theme.grass.2))
    context.fill(CGRect(x: CGFloat(x), y: CGFloat(size) - groundTop - 42, width: 24, height: 12))
}
let dirt = PixelArt.image(.groundFill, theme: theme, scale: 6)
for x in stride(from: 0, to: size, by: dirt.width) {
    context.draw(dirt, in: CGRect(x: CGFloat(x), y: CGFloat(size) - groundTop - 42 - CGFloat(dirt.height), width: CGFloat(dirt.width), height: CGFloat(dirt.height)))
}

// Glow, Heart Crystal and petals around Alina.
let glow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [color(0xFFE98A, 0.75), color(0xFFE98A, 0)] as CFArray, locations: [0, 1])!
let glowCenter = CGPoint(x: 735, y: CGFloat(size) - 395)
context.drawRadialGradient(glow, startCenter: glowCenter, startRadius: 0, endCenter: glowCenter, endRadius: 150, options: [])
draw(.crystal, scale: 13, x: 670, top: 336)
draw(.petal, scale: 7, x: 214, top: 470)
draw(.petal, scale: 6, x: 610, top: 560)

// Alina, center stage, boots on the grass.
draw(.alinaIdle, scale: 22, x: 300, top: groundTop + 10 - 18 * 22)

context.restoreGState()

// Soft inner rim so the icon reads on dark docks.
context.addPath(squircle)
context.setStrokeColor(color(0xFFFFFF, 0.35))
context.setLineWidth(4)
context.strokePath()

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
try rep.representation(using: .png, properties: [:])!.write(to: output)
print("Rendered \(output.path)")
