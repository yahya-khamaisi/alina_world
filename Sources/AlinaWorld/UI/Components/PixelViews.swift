import SwiftUI

/// Crisp pixel sprite for SwiftUI, rendered at the display's backing scale so it never blurs.
struct PixelImage: View {
    let sprite: PixelSprite
    var scale: CGFloat = 4
    var theme: WorldTheme?
    var overrides: [Character: UInt32] = [:]

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        let pixelScale = max(1, Int((scale * displayScale).rounded()))
        Image(
            decorative: PixelArt.image(sprite, theme: theme, overrides: overrides, scale: pixelScale),
            scale: CGFloat(pixelScale) / scale
        )
        .interpolation(.none)
        .accessibilityHidden(true)
    }
}

/// The shared pixel environment — banded sky, sun, clouds, two hill layers, trees and textured ground.
/// Mirrors the in-game parallax so menus and levels feel like the same place.
struct PixelBackdrop: View {
    var theme: WorldTheme = WorldThemes.ordered[0]
    /// Extra trees for forest worlds.
    var dense = false
    /// Ground strip height; previews pass a small value so scenery, not dirt, fills the frame.
    var groundHeight: CGFloat?
    /// Horizontal sun position as a fraction of the width, clear of the stat pills on the right.
    var sunPosition: CGFloat = 0.62

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let groundHeight = self.groundHeight ?? max(96, h * 0.16)
            let groundTop = h - groundHeight
            // Shrink scenery in short previews so sky still shows above the hills.
            let k = min(1, h / 760)
            let farScale = px(12, k), nearScale = px(14, k)

            ZStack(alignment: .topLeading) {
                sky(height: groundTop)

                place(PixelImage(sprite: .sun, scale: px(8, k)), x: w * sunPosition, y: 56 * k)
                place(PixelImage(sprite: .cloud, scale: px(7, k)), x: w * 0.09, y: h * 0.1)
                place(PixelImage(sprite: .cloud, scale: px(5, k)), x: w * 0.44, y: h * 0.2)
                place(PixelImage(sprite: .cloud, scale: px(4, k)), x: w * 0.67, y: h * 0.08)
                place(PixelImage(sprite: .cloud, scale: px(3, k)), x: w * 0.26, y: h * 0.36)

                // Far hills sit on a band of their own color so the gaps read as distance, not sky.
                Rectangle()
                    .fill(Color(hex: theme.hills.1))
                    .frame(width: w, height: 112 * k)
                    .offset(y: groundTop - 112 * k)
                ForEach(0..<Int(w / (24 * farScale - 8)) + 2, id: \.self) { i in
                    place(PixelImage(sprite: .hillFar, scale: farScale, theme: theme),
                          x: CGFloat(i) * (24 * farScale - 8) - 60 * k, y: groundTop - 100 * k - 8 * farScale)
                }

                Rectangle()
                    .fill(Color(hex: theme.grass.1))
                    .frame(width: w, height: 18)
                    .offset(y: groundTop - 16)
                ForEach(0..<Int(w / (34 * nearScale)) + 2, id: \.self) { i in
                    place(PixelImage(sprite: .hillNear, scale: nearScale, theme: theme),
                          x: CGFloat(i) * 34 * nearScale - 100 * k, y: groundTop + 4 - 8 * nearScale)
                }

                scenery(width: w, groundTop: groundTop, k: k)
                ground(width: w, height: groundHeight)
                    .offset(y: groundTop)
            }
            .frame(width: w, height: h, alignment: .topLeading)
            .clipped()
        }
        .accessibilityHidden(true)
    }

    /// Integer pixel scale for a sprite, shrunk by `k` but never below 2.
    private func px(_ base: CGFloat, _ k: CGFloat) -> CGFloat {
        max(2, (base * k).rounded())
    }

    private func sky(height: CGFloat) -> some View {
        let fractions: [CGFloat] = [0.21, 0.17, 0.145, 0.13]
        return VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { i in
                Rectangle().fill(Color(hex: theme.sky[i])).frame(height: height * fractions[i])
            }
            Rectangle().fill(Color(hex: theme.sky[4]))
        }
        .frame(height: height + 2)
    }

    @ViewBuilder
    private func scenery(width w: CGFloat, groundTop: CGFloat, k: CGFloat) -> some View {
        let big = px(8, k), mid = px(6, k), bush = px(5, k), flower = px(4, k)
        place(PixelImage(sprite: .tree, scale: big, theme: theme), x: w * 0.03, y: groundTop - 15 * big)
        place(PixelImage(sprite: .tree, scale: mid, theme: theme), x: w * 0.135, y: groundTop - 15 * mid)
        place(PixelImage(sprite: .tree, scale: big, theme: theme), x: w * 0.87, y: groundTop - 15 * big)
        if dense {
            place(PixelImage(sprite: .tree, scale: px(7, k), theme: theme), x: w * 0.48, y: groundTop - 15 * px(7, k))
            place(PixelImage(sprite: .tree, scale: mid, theme: theme), x: w * 0.79, y: groundTop - 15 * mid)
        }
        ForEach([0.33, 0.58, 0.75], id: \.self) { fraction in
            place(PixelImage(sprite: .bush, scale: bush, theme: theme), x: w * fraction, y: groundTop - 5 * bush)
        }
        ForEach([0.235, 0.257, 0.44, 0.69, 0.712], id: \.self) { fraction in
            place(PixelImage(sprite: .flower, scale: flower, theme: theme), x: w * fraction, y: groundTop - 6 * flower)
        }
    }

    private func ground(width: CGFloat, height: CGFloat) -> some View {
        let pixelScale = max(1, Int((3 * displayScale).rounded()))
        let dirt = PixelArt.image(.groundFill, theme: theme, scale: pixelScale)
        return VStack(spacing: 0) {
            Rectangle().fill(Color(hex: theme.grass.0)).frame(height: 6)
            Rectangle().fill(Color(hex: theme.grass.1)).frame(height: 14)
            HStack(spacing: 0) {
                ForEach(0..<Int(width / 24) + 1, id: \.self) { _ in
                    Rectangle().fill(Color(hex: theme.grass.2)).frame(width: 16)
                    Rectangle().fill(Color(hex: theme.grass.1)).frame(width: 8)
                }
            }
            .frame(width: width, height: 8, alignment: .leading)
            .clipped()
            Image(decorative: dirt, scale: CGFloat(pixelScale) / 3)
                .resizable(resizingMode: .tile)
                .interpolation(.none)
        }
        .frame(width: width, height: height)
    }

    private func place<V: View>(_ view: V, x: CGFloat, y: CGFloat) -> some View {
        view.offset(x: x, y: y)
    }
}
