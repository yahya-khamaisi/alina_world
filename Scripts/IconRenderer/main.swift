// Renders a sharp 1024 px icon from the production paintings, independently of the game target.
import AppKit
import CoreGraphics
import ImageIO

// Package existing PNG representations directly, so builds do not depend on iconutil's XPC service.
if CommandLine.arguments[1] == "--pack" {
    let directory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
    let destination = URL(fileURLWithPath: CommandLine.arguments[3])
    let entries = [("ic11", "icon_16x16@2x.png"), ("ic12", "icon_32x32@2x.png"),
                   ("ic07", "icon_128x128.png"), ("ic08", "icon_256x256.png"),
                   ("ic09", "icon_512x512.png"), ("ic10", "icon_512x512@2x.png"),
                   ("ic13", "icon_128x128@2x.png"), ("ic14", "icon_256x256@2x.png")]
    func bigEndian(_ number: Int) -> Data {
        var value = UInt32(number).bigEndian
        return withUnsafeBytes(of: &value) { Data($0) }
    }
    var chunks = Data()
    for (tag, name) in entries {
        let png = try Data(contentsOf: directory.appendingPathComponent(name))
        chunks.append(Data(tag.utf8)); chunks.append(bigEndian(png.count + 8)); chunks.append(png)
    }
    var archive = Data("icns".utf8)
    archive.append(bigEndian(chunks.count + 8)); archive.append(chunks)
    guard let source = CGImageSourceCreateWithData(archive as CFData, nil),
          CGImageSourceGetCount(source) >= 6,
          CGImageSourceCreateImageAtIndex(source, 0, nil) != nil else { fatalError("Invalid generated icon archive") }
    try archive.write(to: destination)
    print("Packaged \(destination.path)")
    exit(0)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let art = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
func image(_ name: String) -> CGImage {
    let url = art.appendingPathComponent(name)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let result = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fatalError("Missing icon art: \(url.path)") }
    return result
}
func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: alpha)
}

let size = 1024
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
context.interpolationQuality = .high
let shape = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: color(0x4B263F, 0.35))
context.addPath(shape); context.setFillColor(color(0xF4A1BC)); context.fillPath()
context.restoreGState()
context.saveGState(); context.addPath(shape); context.clip()

let background = image("TitleMeadow.png")
let backgroundScale = body.height / CGFloat(background.height)
let backgroundWidth = CGFloat(background.width) * backgroundScale
context.draw(background, in: CGRect(x: body.midX - backgroundWidth / 2, y: body.minY, width: backgroundWidth, height: body.height))
let glow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                      colors: [color(0xFFF4D1, 0.95), color(0xFFF4D1, 0)] as CFArray, locations: [0, 1])!
context.drawRadialGradient(glow, startCenter: CGPoint(x: 515, y: 540), startRadius: 10,
                           endCenter: CGPoint(x: 515, y: 540), endRadius: 490, options: [])

let frames = try JSONDecoder().decode([[Int]].self, from: Data(contentsOf: art.appendingPathComponent("AlinaFrames.json")))
let bounds = frames[0]
let sheet = image("AlinaIllustrated.png")
// A portrait crop keeps her face and bow legible at small Dock sizes.
let portrait = sheet.cropping(to: CGRect(x: bounds[0], y: bounds[1], width: bounds[2], height: Int(Double(bounds[3]) * 0.72)))!
let height: CGFloat = 805
let width = height * CGFloat(portrait.width) / CGFloat(portrait.height)
context.setShadow(offset: CGSize(width: 0, height: -6), blur: 14, color: color(0x4B263F, 0.3))
context.draw(portrait, in: CGRect(x: body.midX - width / 2, y: body.minY - 12, width: width, height: height))
context.restoreGState()
context.addPath(shape); context.setStrokeColor(color(0xFFFFFF, 0.6)); context.setLineWidth(4); context.strokePath()
let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
try rep.representation(using: .png, properties: [:])!.write(to: output)
print("Rendered \(output.path)")
