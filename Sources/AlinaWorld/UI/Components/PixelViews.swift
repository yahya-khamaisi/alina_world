import SwiftUI

/// Resolution-independent sprite sizing shared by the illustrated UI and gameplay.
struct PixelImage: View {
    let sprite: PixelSprite
    var scale: CGFloat = 4
    var theme: WorldTheme?
    var overrides: [Character: UInt32] = [:]

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        let pixelScale = max(1, Int((scale * displayScale).rounded()))
        let size = PixelArt.size(of: sprite)
        Image(
            decorative: PixelArt.image(sprite, theme: theme, overrides: overrides, scale: pixelScale),
            scale: 1
        )
        .resizable()
        .interpolation(.high)
        .frame(width: size.width * scale, height: size.height * scale)
        .accessibilityHidden(true)
    }
}

/// The shared painted environment — the same golden-hour sky, mountains, hills, props and cobbled ground as the
/// in-game parallax (`Scenery`, `Props`, `TileArt`), so menus and levels feel like one place.
struct PixelBackdrop: View {
    var theme: WorldTheme = WorldThemes.ordered[0]
    /// Extra trees for forest worlds.
    var dense = false
    /// Ground strip height; previews pass a small value so scenery, not dirt, fills the frame.
    var groundHeight: CGFloat?
    /// Kept for callers; the sun is painted into the sky.
    var sunPosition: CGFloat = 0.62
    /// Big blossom tree framing the left edge, as on the title screen.
    var framingTree = false
    var weather: MissionWeather? = nil

    var body: some View {
        GeometryReader { proxy in
            if framingTree, let image = StorybookArt.image(.title) {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            } else {
                paintedLayers(size: proxy.size)
            }
        }
        .overlay { WeatherOverlay(weather: weather ?? MissionWeather(kind: theme.key == "cavern" ? .embers : .sunny, seed: 17)) }
        .accessibilityHidden(true)
    }

    private func paintedLayers(size: CGSize) -> some View {
        let proxy = size
        return Group {
            let w = proxy.width
            let h = proxy.height
            let groundHeight = self.groundHeight ?? max(96, h * 0.16)
            let groundTop = h - groundHeight
            // Points per art pixel: the painted sky (280 px) fills the view height.
            let u = max(1, h / 250)
            let palette = BackdropPalette.forTheme(theme)

            ZStack(alignment: .topLeading) {
                Color(hex: palette.sky.last ?? 0xFFFFFF)
                if let painting = StorybookArt.image(.environment(for: theme.key)) {
                    Image(decorative: painting, scale: 1).resizable().interpolation(.high)
                        .scaledToFill()
                        .frame(width: w, height: h)
                        .clipped()
                } else {
                    pixelImage(IllustratedScenery.image(.sky, theme: theme), u: u)
                    .frame(width: CGFloat(Scenery.skySize.width) * u, height: CGFloat(Scenery.skySize.height) * u)
                    .offset(x: (w - CGFloat(Scenery.skySize.width) * u) / 2, y: min(0, groundTop - 236 * u))

                    strip(.clouds, baseY: groundTop - 125 * u, u: u, width: w, fill: nil, shift: 0.31)
                    strip(.mountains, baseY: groundTop - 58 * u, u: u, width: w, fill: palette.haze, shift: 0.12)
                    strip(.farHills, baseY: groundTop - 18 * u, u: u, width: w, fill: palette.farHill.2, shift: 0.53)
                }
                if StorybookArt.image(.environment(for: theme.key)) == nil {
                    strip(.nearHills, baseY: groundTop + 3 * u, u: u, width: w, fill: palette.nearHill.2, shift: 0.2)
                }

                props(width: w, groundTop: groundTop, u: u)
                ground(width: w, height: groundHeight, u: u)
                    .offset(y: groundTop)
            }
            .frame(width: w, height: h, alignment: .topLeading)
            .clipped()
        }
    }

    private func pixelImage(_ image: CGImage, u: CGFloat) -> some View {
        Image(decorative: image, scale: 1).resizable().interpolation(.high)
    }

    /// One seamless layer tiled across the width with its bottom on `baseY`, plus a solid fill below it.
    private func strip(_ layer: Scenery.Layer, baseY: CGFloat, u: CGFloat, width: CGFloat, fill: UInt32?, shift: CGFloat) -> some View {
        let image = IllustratedScenery.image(layer, theme: theme)
        let logical = IllustratedScenery.size(layer)
        let tileW = logical.width * u, tileH = logical.height * u
        let count = Int(width / tileW) + 2
        return ZStack(alignment: .topLeading) {
            if let fill {
                Rectangle().fill(Color(hex: fill)).frame(width: width, height: 2000).offset(y: baseY - 1)
            }
            ForEach(0..<count, id: \.self) { i in
                pixelImage(image, u: u)
                    .frame(width: tileW, height: tileH)
                    .offset(x: CGFloat(i) * tileW - tileW * shift, y: baseY - tileH)
            }
        }
    }

    @ViewBuilder
    private func props(width w: CGFloat, groundTop: CGFloat, u: CGFloat) -> some View {
        let items: [(Props.Kind, CGFloat, Int, Bool)] = [
            (.bush, 0.30, 0, false), (.rock, 0.42, 1, false), (.flowers, 0.52, 2, false), (.bush, 0.63, 1, true),
            (.fence, 0.86, 0, false), (.flowers, 0.95, 0, true), (.rock, 0.76, 2, true), (.flowers, 0.22, 1, false)
        ] + (dense ? [(.tree, 0.55, 1, false), (.tree, 0.8, 2, true)] : [])
        if framingTree {
            prop(.tree, x: w * 0.04, groundTop: groundTop, u: u * 1.9, variant: 0, flip: false)
        } else {
            prop(.tree, x: w * 0.08, groundTop: groundTop, u: u * 1.2, variant: 0, flip: false)
            prop(.tree, x: w * 0.93, groundTop: groundTop, u: u, variant: 2, flip: true)
        }
        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
            prop(item.0, x: w * item.1, groundTop: groundTop, u: u, variant: item.2, flip: item.3)
        }
    }

    private func prop(_ kind: Props.Kind, x: CGFloat, groundTop: CGFloat, u: CGFloat, variant: Int, flip: Bool) -> some View {
        let image = IllustratedArt.prop(kind, theme: theme, variant: variant)
        let logical = IllustratedArt.propSize(kind)
        let size = CGSize(width: logical.width * u, height: logical.height * u)
        return pixelImage(image, u: u)
            .frame(width: size.width, height: size.height)
            .scaleEffect(x: flip ? -1 : 1)
            .offset(x: x - size.width / 2, y: groundTop - size.height + 2 * u)
    }

    private func ground(width: CGFloat, height: CGFloat, u: CGFloat) -> some View {
        let tile = 16 * u
        let top = PixelArt.image(.groundTop, theme: theme)
        let fill = PixelArt.image(.groundFill, theme: theme)
        let columns = Int(width / tile) + 1
        let rows = Int(height / tile) + 1
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<columns, id: \.self) { _ in pixelImage(top, u: u).frame(width: tile, height: tile) }
            }
            ForEach(0..<max(0, rows - 1), id: \.self) { _ in
                HStack(spacing: 0) {
                    ForEach(0..<columns, id: \.self) { _ in pixelImage(fill, u: u).frame(width: tile, height: tile) }
                }
            }
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .clipped()
    }
}
