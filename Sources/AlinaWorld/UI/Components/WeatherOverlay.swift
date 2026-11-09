import SwiftUI

/// The same mission conditions animate over menu/briefing paintings, independent of player movement.
struct WeatherOverlay: View {
    let weather: MissionWeather
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(SettingsKey.reduceMotion) private var reduceMotion = false
    @AppStorage(SettingsKey.ambientEffects) private var ambientEffects = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: reduceMotion || systemReduceMotion || !ambientEffects)) { timeline in
            Canvas { context, size in
                let time = reduceMotion || systemReduceMotion || !ambientEffects ? 0 : timeline.date.timeIntervalSinceReferenceDate
                draw(context: &context, size: size, time: time)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(context: inout GraphicsContext, size: CGSize, time: Double) {
        if weather.sunshine > 0 {
            for index in 0..<3 {
                let x = size.width * (0.67 + Double(index) * 0.065)
                var ray = Path()
                ray.move(to: CGPoint(x: x, y: -20))
                ray.addLine(to: CGPoint(x: x - size.width * 0.32, y: size.height))
                ray.addLine(to: CGPoint(x: x - size.width * 0.21, y: size.height))
                ray.closeSubpath()
                context.fill(ray, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFF0C4).opacity(0.09 * weather.sunshine), .clear]), startPoint: CGPoint(x: x, y: 0), endPoint: CGPoint(x: x, y: size.height)))
            }
        }
        let count = weather.rain > 0 ? Int(90 * weather.rain) : weather.snow > 0 ? Int(32 * weather.snow + 12) : 18
        for index in 0..<count {
            let seed = Double(index * 137 + abs(weather.seed % 101))
            let speed = weather.rain > 0 ? 320.0 : weather.snow > 0 ? 27.0 : 13.0
            let y = positive(seed * 37 + time * speed, size.height + 40) - 20
            let x = positive(seed * 71 + time * Double(weather.wind) * 30 + sin(time * 0.7 + seed) * 12, size.width + 40) - 20
            if weather.rain > 0 {
                var drop = Path(); drop.move(to: CGPoint(x: x, y: y))
                drop.addLine(to: CGPoint(x: x - 5 - weather.wind * 5, y: y + 18))
                context.stroke(drop, with: .color(Color(hex: 0xDDEEFF).opacity(0.38)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            } else if weather.snow > 0 {
                let radius = 1.2 + Double(index % 3) * 0.8
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(0.7)))
            } else {
                var particle = context
                particle.translateBy(x: x, y: y)
                particle.rotate(by: .radians(time * 0.4 + seed))
                var leaf = Path(); leaf.move(to: CGPoint(x: -3, y: 4))
                leaf.addQuadCurve(to: CGPoint(x: 3, y: -4), control: CGPoint(x: -5, y: -4))
                leaf.addQuadCurve(to: CGPoint(x: -3, y: 4), control: CGPoint(x: 5, y: 3))
                particle.fill(leaf, with: .color(Color(hex: weather.kind == .embers ? 0xFFD091 : 0xFFB7D3).opacity(0.45)))
            }
        }
        if weather.rain > 0 || weather.kind == .blizzard {
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x15233C).opacity(0.11 * weather.rain)))
        }
    }

    private func positive(_ value: Double, _ modulus: Double) -> Double {
        guard modulus > 0 else { return 0 }
        return (value.truncatingRemainder(dividingBy: modulus) + modulus).truncatingRemainder(dividingBy: modulus)
    }
}

struct WeatherBadge: View {
    let weather: MissionWeather
    var body: some View {
        Label(weather.label, systemImage: weather.symbol)
            .font(.rounded(12, .heavy))
            .foregroundStyle(weather.rain > 0 ? Palette.skyText : Palette.goldText)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(Palette.parchment.opacity(0.95)))
            .overlay(Capsule().strokeBorder(Palette.plum.opacity(0.25), lineWidth: 1))
            .accessibilityLabel("Weather: \(weather.label)")
    }
}
