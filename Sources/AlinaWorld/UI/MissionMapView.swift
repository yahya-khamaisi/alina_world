import SwiftUI

struct MissionMapView: View {
    let missions: [Mission]
    let onSelect: (Mission) -> Void
    let onBack: () -> Void

    @ObservedObject private var nav = MenuNavigationState.shared
    private let progress = GameProgress.shared

    /// Node centers and islands in an 832 × 600 design space, scaled to the map card.
    private static let nodes: [CGPoint] = [
        CGPoint(x: 102, y: 500), CGPoint(x: 252, y: 420), CGPoint(x: 422, y: 480),
        CGPoint(x: 572, y: 380), CGPoint(x: 732, y: 280), CGPoint(x: 592, y: 170),
        CGPoint(x: 412, y: 200), CGPoint(x: 252, y: 100), CGPoint(x: 452, y: 40)
    ]
    private static let islands: [(CGRect, UInt32)] = [
        (CGRect(x: 10, y: 400, width: 340, height: 200), 0x7FD06B),
        (CGRect(x: 330, y: 380, width: 300, height: 210), 0x5DBB7A),
        (CGRect(x: 500, y: 250, width: 290, height: 220), 0xC9A27E),
        (CGRect(x: 190, y: 90, width: 470, height: 200), 0x9C86C9),
        (CGRect(x: 360, y: -20, width: 200, height: 120), 0x6E64A3)
    ]

    private var selectedWorld: Int { nav.missionMapIndex / 3 }
    private var selectedMission: Mission? { missions.first { $0.id == nav.missionMapIndex + 1 } }
    private var act: Int { selectedWorld / 3 }

    var body: some View {
        ZStack {
            PixelBackdrop(theme: WorldThemes.ordered[0])
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header
                HStack(alignment: .top, spacing: Space.xl) {
                    map
                    sidePanel
                }
            }
            .padding(.horizontal, Space.xxl)
            .padding(.top, WindowChrome.titleBarHeight + Space.s)
            .padding(.bottom, Space.xxl)

            MenuKeyboardDriver { handleKeys() }
        }
        .onAppear { nav.resetMissionMapSelection() }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: Space.m) {
            Button(action: onBack) {
                Image(systemName: "chevron.left").font(.system(size: 17, weight: .heavy))
            }
            .buttonStyle(IconButtonStyle())
            .help("Back to menu (Esc)")
            .accessibilityLabel("Back to menu")

            Text("Lumen Isles")
                .font(.rounded(24, .bold))
                .foregroundStyle(Palette.ink)
                .pill(height: 48)

            HStack(spacing: Space.xs) {
                ForEach(0..<3, id: \.self) { index in
                    let titles = ["Act I · Dawn", "Act II · Dusk", "Act III · Night"]
                    let unlocked = progress.isUnlocked(missionID: index * 9 + 1)
                    Button(titles[index]) {
                        nav.missionMapIndex = firstPlayableIndex(inAct: index)
                    }
                    .buttonStyle(.plain)
                    .font(.rounded(14, .heavy))
                    .foregroundStyle(act == index ? .white : (unlocked ? Palette.ink : Palette.muted))
                    .padding(.horizontal, Space.l)
                    .frame(height: 40)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(act == index ? Palette.pink : .clear))
                    .disabled(!unlocked)
                }
            }
            .padding(Space.xs)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white).shadow(color: Palette.edge, radius: 0, y: 4))

            Spacer(minLength: 0)

            HStack(spacing: Space.s) {
                PixelImage(sprite: .crystal, scale: 2)
                Text("\(progress.crystalsRestored) / 9")
            }
            .pill(height: 48)
            HStack(spacing: Space.s) {
                Image(systemName: "star.fill").foregroundStyle(Palette.gold)
                Text("\(progress.totalStars) / 81")
            }
            .pill(height: 48)
        }
    }

    // MARK: Map

    private var map: some View {
        GeometryReader { proxy in
            let sx = proxy.size.width / 832
            let sy = proxy.size.height / 600
            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    let cell: CGFloat = 32
                    for row in 0...Int(size.height / cell) {
                        for col in 0...Int(size.width / cell) where (row + col) % 2 == 0 {
                            context.fill(Path(CGRect(x: CGFloat(col) * cell, y: CGFloat(row) * cell, width: cell, height: cell)),
                                         with: .color(Color(hex: 0x84CBEE)))
                        }
                    }
                }
                .background(Color(hex: 0x8ED2F2))

                ForEach(0..<Self.islands.count, id: \.self) { i in
                    let (rect, color) = Self.islands[i]
                    RoundedRectangle(cornerRadius: min(rect.width * sx, rect.height * sy) * 0.44, style: .continuous)
                        .fill(Color(hex: color))
                        .overlay(
                            RoundedRectangle(cornerRadius: min(rect.width * sx, rect.height * sy) * 0.44, style: .continuous)
                                .strokeBorder(Color(hex: 0xF6E3B4), lineWidth: 10)
                        )
                        .frame(width: rect.width * sx, height: rect.height * sy)
                        .offset(x: rect.minX * sx, y: rect.minY * sy)
                }

                Path { path in
                    path.addLines(Self.nodes.map { CGPoint(x: $0.x * sx, y: $0.y * sy) })
                }
                .stroke(.white, style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [2, 14]))

                ForEach(0..<9, id: \.self) { world in
                    worldNode(world)
                        .position(x: Self.nodes[world].x * sx, y: Self.nodes[world].y * sy + 24)
                }

                let current = Self.nodes[selectedWorld]
                PixelImage(sprite: .alinaIdle, scale: 3)
                    .position(x: current.x * sx - 48, y: current.y * sy - 6)
                    .animation(.spring(duration: 0.35), value: selectedWorld)
                    .allowsHitTesting(false)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white, lineWidth: 6))
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Palette.edge).offset(y: 10))
    }

    private func worldNode(_ world: Int) -> some View {
        let theme = WorldThemes.ordered[world]
        let firstID = world * 3 + 1
        let unlocked = progress.isUnlocked(missionID: firstID)
        let stars = (firstID...firstID + 2).reduce(0) { $0 + progress.starCount(for: $1) }
        let selected = world == selectedWorld

        return Button {
            if unlocked { nav.missionMapIndex = firstPlayableIndex(inWorld: world) }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(unlocked ? Color(hex: theme.grass.1) : Color(hex: 0xB9AFA3))
                    if unlocked {
                        Text("\(world + 1)").font(.rounded(22, .heavy)).foregroundStyle(.white)
                    } else {
                        Image(systemName: "lock.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                    }
                }
                .frame(width: 60, height: 60)
                .overlay(Circle().strokeBorder(.white, lineWidth: 5))
                .background(Circle().fill(selected ? Palette.pinkDeep : Palette.ink.opacity(0.2)).offset(y: 5))
                .overlay(Circle().inset(by: -7).strokeBorder(selected ? Palette.pink : .clear, lineWidth: 4))

                Text(theme.name)
                    .font(.rounded(12, .heavy))
                    .foregroundStyle(unlocked ? Palette.ink : Palette.muted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.white).shadow(color: Palette.edge, radius: 0, y: 2))
                    .fixedSize()
                Text(unlocked ? "★ \(stars)/9" : " ")
                    .font(.rounded(12, .heavy))
                    .foregroundStyle(Palette.goldText)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("World \(world + 1): \(theme.name)\(unlocked ? ", \(stars) of 9 stars" : ", locked")")
    }

    // MARK: Side panel

    private var sidePanel: some View {
        let theme = WorldThemes.ordered[selectedWorld]
        let worldMissions = missions.filter { WorldThemes.index(of: $0.world) == selectedWorld }

        return VStack(alignment: .leading, spacing: 18) {
            PixelBackdrop(theme: theme, dense: theme.key == "grove", groundHeight: 30, sunPosition: 0.72)
                .frame(width: 312, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "World \(selectedWorld + 1) · Act \(["I", "II", "III"][act])", color: Palette.mintText)
                Text(theme.name).font(.rounded(26, .bold)).foregroundStyle(Palette.ink)
                Text(theme.blurb)
                    .font(.rounded(14, .medium))
                    .foregroundStyle(Palette.body)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Space.s) {
                ForEach(worldMissions) { mission in
                    missionRow(mission)
                }
            }

            Spacer(minLength: 0)

            Button {
                if let mission = selectedMission, progress.isUnlocked(missionID: mission.id) { onSelect(mission) }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text(selectedMission.map { "Play Mission \($0.id)" } ?? "Play")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .primary, height: 56))
            .disabled(!(selectedMission.map { progress.isUnlocked(missionID: $0.id) } ?? false))
        }
        .frame(width: 312)
        .frame(maxHeight: .infinity, alignment: .top)
        .card()
    }

    private func missionRow(_ mission: Mission) -> some View {
        let unlocked = progress.isUnlocked(missionID: mission.id)
        let selected = mission.id == nav.missionMapIndex + 1
        let stars = progress.stars(for: mission.id)

        return Button {
            if unlocked { nav.missionMapIndex = mission.id - 1 }
        } label: {
            HStack(spacing: Space.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(!unlocked ? Color(hex: 0xE4DDD2) : (selected ? Palette.pink : (stars[0] ? Palette.mint : Palette.sky)))
                    if unlocked {
                        Text("\(mission.id)").font(.rounded(14, .heavy)).foregroundStyle(.white)
                    } else {
                        Image(systemName: "lock.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.muted)
                    }
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mission.title).font(.rounded(14, .heavy)).foregroundStyle(unlocked ? Palette.ink : Palette.muted)
                    Text(mission.objectiveLabel).font(.rounded(12, .semibold)).foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 0)
                if stars[0] {
                    HStack(spacing: 1) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: "star.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(stars[i] ? Palette.gold : Color(hex: 0xD9D0C3))
                        }
                    }
                } else if unlocked {
                    Text("New").font(.rounded(11, .heavy)).foregroundStyle(.white)
                        .padding(.horizontal, Space.s).padding(.vertical, 3)
                        .background(Capsule().fill(Palette.pink))
                }
            }
            .padding(.horizontal, Space.m)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(selected ? Palette.pinkSoft : Palette.sand))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(selected ? Palette.pink : .clear, lineWidth: 2))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }

    // MARK: Navigation

    private func firstPlayableIndex(inWorld world: Int) -> Int {
        let ids = (world * 3 + 1)...(world * 3 + 3)
        let target = ids.first { progress.isUnlocked(missionID: $0) && !progress.isCompleted(missionID: $0) }
            ?? ids.last { progress.isUnlocked(missionID: $0) } ?? ids.lowerBound
        return target - 1
    }

    private func firstPlayableIndex(inAct act: Int) -> Int {
        firstPlayableIndex(inWorld: act * 3)
    }

    private func handleKeys() {
        let input = InputController.shared
        if input.consumeEscape() { onBack(); return }
        if input.consumeLeft() { moveWorld(-1) }
        if input.consumeRight() { moveWorld(1) }
        if input.consumeUp() { moveMission(-1) }
        if input.consumeDown() { moveMission(1) }
        if input.consumeEnter(), let mission = selectedMission, progress.isUnlocked(missionID: mission.id) {
            onSelect(mission)
        }
        if input.consumeFullscreen() { AppWindowController.toggleFullscreen() }
    }

    private func moveWorld(_ delta: Int) {
        let world = max(0, min(8, selectedWorld + delta))
        guard progress.isUnlocked(missionID: world * 3 + 1) else { return }
        nav.missionMapIndex = firstPlayableIndex(inWorld: world)
    }

    private func moveMission(_ delta: Int) {
        let next = max(0, min(missions.count - 1, nav.missionMapIndex + delta))
        if progress.isUnlocked(missionID: next + 1) { nav.missionMapIndex = next }
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
