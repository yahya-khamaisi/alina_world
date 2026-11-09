import SwiftUI

struct MissionMapView: View {
    let missions: [Mission]
    let onSelect: (Mission) -> Void
    let onBack: () -> Void

    @ObservedObject private var nav = MenuNavigationState.shared
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage(SettingsKey.reduceMotion) private var reduceMotion = false
    private let progress = GameProgress.shared

    private var selectedWorld: Int { max(0, min(GameProgress.worldCount - 1, nav.missionMapIndex / 3)) }
    private var selectedMission: Mission? { missions.first { $0.id == nav.missionMapIndex + 1 } }
    private var act: Int { selectedWorld / 3 }
    private var motion: Animation? { reduceMotion || accessibilityReduceMotion ? nil : .spring(duration: 0.35) }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                map(size: proxy.size)
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 0)
                    selectionPanel
                }
                .padding(.horizontal, Space.xl)
                .padding(.top, WindowChrome.titleBarHeight + Space.m)
                .padding(.bottom, Space.l)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .overlay { MenuKeyboardDriver { handleKeys() } }
        .onAppear { nav.resetMissionMapSelection() }
    }

    private var header: some View {
        HStack(spacing: Space.m) {
            Button(action: onBack) {
                Image(systemName: "chevron.left").font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(Palette.plum)
            }
            .buttonStyle(StorybookButtonStyle(width: 50, height: 50, round: true))
            .help("Back (Esc)")
            .accessibilityLabel("Back to menu")

            HStack(spacing: 10) {
                PixelImage(sprite: .flower, scale: 3)
                Text("World Map").font(.rounded(28, .black))
            }
            .foregroundStyle(Palette.plum)
            .storybookPill(height: 58, horizontal: 20)

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    let icons = ["sunrise.fill", "sunset.fill", "moon.stars.fill", "sparkles"]
                    Button { selectWorld(index * 3) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: icons[index])
                            Text(["I", "II", "III", "IV"][index])
                        }
                        .font(.rounded(14, .heavy))
                        .foregroundStyle(act == index ? .white : Palette.plum)
                        .frame(width: 68, height: 38)
                        .background(Capsule().fill(act == index ? Palette.pink : .clear))
                    }
                    .buttonStyle(.plain)
                    .help("Explore Act \(index + 1)")
                    .accessibilityLabel("Act \(index + 1)\(act == index ? ", selected" : "")")
                }
            }
            .storybookPill(height: 50, horizontal: 8)

            HStack(spacing: 8) {
                PixelImage(sprite: .crystal, scale: 2)
                Text("\(progress.crystalsRestored)/\(GameProgress.worldCount)")
            }
            .storybookPill(height: 50, horizontal: 14)
            .accessibilityLabel("\(progress.crystalsRestored) of \(GameProgress.worldCount) Heart Crystals")

            HStack(spacing: 6) {
                Image(systemName: "star.fill").foregroundStyle(Palette.goldText)
                Text("\(progress.totalStars)")
            }
            .storybookPill(height: 50, horizontal: 12)
            .accessibilityLabel("\(progress.totalStars) of \(GameProgress.missionCount * 3) stars")

            CompassRose().accessibilityHidden(true)
        }
        .font(.rounded(17, .heavy))
        .foregroundStyle(Palette.plum)
    }

    private func map(size: CGSize) -> some View {
        let sx = size.width / MapArt.size.width
        let sy = size.height / MapArt.size.height
        let unit = min(sx, sy)
        return ZStack(alignment: .topLeading) {
            Image(decorative: MapArt.backdrop, scale: 1)
                .resizable()
                .interpolation(.high)
                .frame(width: size.width, height: size.height)

            Canvas { context, _ in
                for leg in 0..<(MapArt.islands.count - 1) {
                    let points = MapArt.trail(leg: leg)
                    var path = Path()
                    path.move(to: CGPoint(x: points.0.x * sx, y: points.0.y * sy))
                    path.addQuadCurve(to: CGPoint(x: points.2.x * sx, y: points.2.y * sy),
                                      control: CGPoint(x: points.1.x * sx, y: points.1.y * sy))
                    let cleared = progress.isCompleted(missionID: leg * 3 + 3)
                    context.stroke(path, with: .color(Palette.plum.opacity(0.8)),
                                   style: StrokeStyle(lineWidth: 9 * unit, lineCap: .round, dash: [1, 14 * unit]))
                    context.stroke(path, with: .color(cleared ? Palette.gold : Palette.parchment),
                                   style: StrokeStyle(lineWidth: 5 * unit, lineCap: .round, dash: [1, 14 * unit]))
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            ForEach(0..<GameProgress.worldCount, id: \.self) { world in
                let island = MapArt.islands[world]
                worldPlaque(world, unit: unit)
                    .position(x: island.center.x * sx, y: (island.center.y + (world < 4 ? 38 : 46)) * sy)
            }

            let current = MapArt.islands[selectedWorld]
            VStack(spacing: -5) {
                PixelImage(sprite: .alinaIdle, scale: max(1.6, 2.2 * unit))
                    .padding(7)
                    .background(Circle().fill(Palette.parchment).overlay(Circle().stroke(Palette.plum, lineWidth: 3)))
                Image(systemName: "triangle.fill")
                    .font(.system(size: 16 * unit))
                    .rotationEffect(.degrees(180))
                    .foregroundStyle(Palette.plum)
            }
            .shadow(color: Palette.plum.opacity(0.35), radius: 0, y: 4)
            .position(x: current.center.x * sx, y: (current.center.y - 78) * sy)
            .animation(motion, value: selectedWorld)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func worldPlaque(_ world: Int, unit: CGFloat) -> some View {
        let firstID = world * 3 + 1
        let unlocked = progress.isUnlocked(missionID: firstID)
        let selected = world == selectedWorld
        let stars = (firstID...firstID + 2).reduce(0) { $0 + progress.starCount(for: $1) }
        return Button { selectWorld(world) } label: {
            HStack(spacing: 6) {
                Text("\(world + 1)")
                    .font(.rounded(18, .black))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(selected ? Palette.pinkSoft : Palette.parchmentShade))
                    .overlay(Circle().stroke(Palette.plum, lineWidth: 2))
                Text(WorldThemes.ordered[world].name)
                    .font(.rounded(14, .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 0)
                Image(systemName: unlocked ? "star.fill" : "lock.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(unlocked ? Palette.goldText : Palette.plum.opacity(0.7))
            }
            .foregroundStyle(Palette.plum)
            .frame(width: 190)
            .storybookPill(height: 42, horizontal: 8)
            .overlay(Capsule().inset(by: -4).stroke(selected ? Palette.gold : .clear, lineWidth: 3))
            .scaleEffect(max(0.78, min(1.15, unit)))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help("\(WorldThemes.ordered[world].name) · \(unlocked ? "\(stars)/9 stars" : "Locked")")
        .accessibilityLabel("World \(world + 1): \(WorldThemes.ordered[world].name), \(unlocked ? "\(stars) of 9 stars" : "locked")\(selected ? ", selected" : "")")
    }

    private var selectionPanel: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 3) {
                Text("ACT \(["I", "II", "III", "IV"][act]) · WORLD \(selectedWorld + 1) / 12")
                    .font(.rounded(10, .heavy)).tracking(1.2)
                    .foregroundStyle(Palette.pinkText)
                Text(WorldThemes.ordered[selectedWorld].name)
                    .font(.rounded(19, .black)).lineLimit(1).minimumScaleFactor(0.7)
                Text(selectedMission?.title ?? "Choose a mission")
                    .font(.rounded(12, .semibold)).foregroundStyle(Palette.body).lineLimit(1)
            }
            .frame(width: 220, alignment: .leading)

            ForEach(missions.filter { ($0.id - 1) / 3 == selectedWorld }) { mission in missionButton(mission) }
            Text(canPlay ? "← →  Worlds\n↑ ↓  Missions" : "Complete earlier missions\nto unlock this chapter")
                .font(.rounded(11, .semibold))
                .foregroundStyle(Palette.body)
                .lineSpacing(3)
            Spacer(minLength: 0)
            Button {
                if let mission = selectedMission, progress.isUnlocked(missionID: mission.id) { onSelect(mission) }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: canPlay ? "play.fill" : "lock.fill")
                    Text(canPlay ? "PLAY \(selectedMission?.code ?? "")" : "LOCKED")
                }
                .font(.rounded(18, .black))
            }
            .buttonStyle(StorybookButtonStyle(width: 164, height: 54, focused: canPlay))
            .disabled(!canPlay)
            .opacity(canPlay ? 1 : 0.6)
            .help(canPlay ? "Start mission (Enter)" : "Complete the preceding missions to unlock")
            .accessibilityLabel(canPlay ? "Play \(selectedMission?.title ?? "mission")" : "Mission locked. Complete preceding missions to unlock.")
        }
        .foregroundStyle(Palette.plum)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 24).fill(Palette.parchment)
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Palette.plum, lineWidth: 3))
                .shadow(color: Palette.plum.opacity(0.35), radius: 0, y: 5)
        }
    }

    private var canPlay: Bool { selectedMission.map { progress.isUnlocked(missionID: $0.id) } ?? false }

    private func missionButton(_ mission: Mission) -> some View {
        let unlocked = progress.isUnlocked(missionID: mission.id)
        let selected = mission.id == nav.missionMapIndex + 1
        return Button {
            nav.missionMapIndex = mission.id - 1
            ChiptuneEngine.shared.play(.select)
        } label: {
            VStack(spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: unlocked ? "flag.fill" : "lock.fill").font(.system(size: 11, weight: .heavy))
                    Text(mission.code).font(.rounded(15, .black))
                }
                StarsView(stars: progress.stars(for: mission.id), size: 10)
            }
            .foregroundStyle(selected ? Palette.pinkText : Palette.plum)
            .frame(width: 74, height: 54)
            .background(RoundedRectangle(cornerRadius: 14).fill(selected ? Palette.pinkSoft : Palette.parchmentShade.opacity(0.5)))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(selected ? Palette.pink : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .help("\(mission.title) · \(mission.objectiveLabel)\(unlocked ? "" : " · Locked")")
        .accessibilityLabel("\(mission.code), \(mission.title), \(mission.objectiveLabel)\(unlocked ? "" : ", locked")\(selected ? ", selected" : "")")
    }

    private func selectWorld(_ world: Int) {
        let firstID = world * 3 + 1
        let ids = firstID...(firstID + 2)
        let target = ids.first { progress.isUnlocked(missionID: $0) && !progress.isCompleted(missionID: $0) }
            ?? ids.last { progress.isUnlocked(missionID: $0) } ?? firstID
        nav.missionMapIndex = target - 1
        ChiptuneEngine.shared.play(.select)
    }

    private func handleKeys() {
        let input = InputController.shared
        if input.consumeEscape() { onBack(); return }
        if input.consumeLeft() { selectWorld(max(0, selectedWorld - 1)) }
        if input.consumeRight() { selectWorld(min(GameProgress.worldCount - 1, selectedWorld + 1)) }
        if input.consumeUp() { nav.missionMapIndex = max(selectedWorld * 3, nav.missionMapIndex - 1) }
        if input.consumeDown() { nav.missionMapIndex = min(selectedWorld * 3 + 2, nav.missionMapIndex + 1) }
        if input.consumeEnter(), let mission = selectedMission, canPlay { onSelect(mission) }
        if input.consumeFullscreen() { AppWindowController.toggleFullscreen() }
    }
}

private struct CompassRose: View {
    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Palette.parchment, Palette.parchmentShade], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().strokeBorder(Palette.plum, lineWidth: 2))
            ForEach(0..<4, id: \.self) { index in
                Image(systemName: "triangle.fill")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(index == 0 ? Palette.pink : Palette.goldText)
                    .offset(y: -8)
                    .rotationEffect(.degrees(Double(index) * 90))
            }
            Circle().fill(Palette.parchment).frame(width: 6, height: 6)
            Text("N").font(.rounded(8, .black)).foregroundStyle(Palette.plum).offset(y: -20)
        }
        .frame(width: 54, height: 54)
        .shadow(color: Palette.plum.opacity(0.3), radius: 0, y: 3)
    }
}

/// Square white icon button with the drop edge.
struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = 48

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Palette.ink)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white)
                    .shadow(color: Palette.edge, radius: 0, y: configuration.isPressed ? 1 : 4)
            )
            .offset(y: configuration.isPressed ? 3 : 0)
            .contentShape(Rectangle())
    }
}

extension Mission {
    var objectiveLabel: String {
        switch objective {
        case .reachFlag: return "Reach the beacon"
        case .collectN: return "Collect \(collectRequired) Heart Shards"
        case .defeatBoss: return "Defeat the guardian"
        }
    }
}
