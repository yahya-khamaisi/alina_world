// Renders the 320 × 180 Android TV launcher banner at 2x from the game's own pixel sprites.
// Built and run by tools/make-banner.sh together with the Mac app's Pixel sources.
import AppKit
import CoreGraphics

let width = 640, height = 360
let theme = WorldThemes.ordered[0]
let context = CGContext(
    data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
context.interpolationQuality = .none

func color(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

/// Draws a sprite with its top-left corner at (x, top) in top-down coordinates.
func draw(_ sprite: PixelSprite, scale: Int, x: CGFloat, top: CGFloat) {
    let image = PixelArt.image(sprite, theme: theme, scale: scale)
    context.draw(image, in: CGRect(x: x, y: CGFloat(height) - top - CGFloat(image.height), width: CGFloat(image.width), height: CGFloat(image.height)))
}

func band(_ hex: UInt32, top: CGFloat, height h: CGFloat) {
    context.setFillColor(color(hex))
    context.fill(CGRect(x: 0, y: CGFloat(height) - top - h, width: CGFloat(width), height: h))
}

let groundTop: CGFloat = 290
var top: CGFloat = 0
for (i, fraction) in [0.21, 0.17, 0.145, 0.13, 1.0].enumerated() {
    let h = i < 4 ? groundTop * fraction : groundTop - top
    band(theme.sky[i], top: top, height: h + 1)
    top += h
}
draw(.sun, scale: 5, x: 520, top: 18)
draw(.cloud, scale: 5, x: 250, top: 30)
draw(.cloud, scale: 3, x: 430, top: 90)
band(theme.hills.1, top: groundTop - 40, height: 40)
for i in 0..<6 { draw(.hillFar, scale: 6, x: CGFloat(i) * 136 - 40, top: groundTop - 36 - 48) }
for i in 0..<4 { draw(.hillNear, scale: 7, x: CGFloat(i) * 238 - 60, top: groundTop + 2 - 56) }
draw(.tree, scale: 6, x: 560, top: groundTop - 90)
draw(.flower, scale: 4, x: 200, top: groundTop - 24)
band(theme.grass.0, top: groundTop, height: 6)
band(theme.grass.1, top: groundTop + 6, height: 14)
for ty in stride(from: groundTop + 20, to: CGFloat(height), by: 48) {
    for tx in stride(from: 0, to: CGFloat(width), by: 48) { draw(.groundFill, scale: 3, x: tx, top: ty) }
}
draw(.alinaIdle, scale: 9, x: 52, top: groundTop - 162)
draw(.crystal, scale: 5, x: 196, top: 70)

// Title with the menu's warm drop edge.
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
let font = NSFont.systemFont(ofSize: 76, weight: .black)
let rounded = NSFont(descriptor: font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor, size: 76) ?? font
func title(_ dy: CGFloat, _ ink: NSColor, _ pink: NSColor) {
    let text = NSMutableAttributedString(string: "Alina\n", attributes: [.font: rounded, .foregroundColor: ink])
    text.append(NSAttributedString(string: "World", attributes: [.font: rounded, .foregroundColor: pink]))
    let style = NSMutableParagraphStyle()
    style.lineHeightMultiple = 0.82
    text.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: text.length))
    text.draw(at: NSPoint(x: 268, y: 118 - dy))
}
let edge = NSColor(srgbRed: 0xE5 / 255.0, green: 0xD3 / 255.0, blue: 0xBC / 255.0, alpha: 1)
title(7, edge, edge)
title(3, .white, .white)
title(0, NSColor(srgbRed: 0x2B / 255.0, green: 0x21 / 255.0, blue: 0x48 / 255.0, alpha: 1),
      NSColor(srgbRed: 0xE8 / 255.0, green: 0x4E / 255.0, blue: 0x8A / 255.0, alpha: 1))

let image = context.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
