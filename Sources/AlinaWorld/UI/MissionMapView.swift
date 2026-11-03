import SwiftUI

struct MissionMapView: View {
    let missions: [Mission]
    let onSelect: (Mission) -> Void
    let onBack: () -> Void

    @ObservedObject private var nav = MenuNavigationState.shared
    private let progress = GameProgress.shared

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
            .buttonStyle(IconButtonStyle(size: 52))
            .help("Back (Esc)")
            .accessibilityLabel("Back to menu")

            HStack(spacing: Space.xs) {
                ForEach(0..<4, id: \.self) { index in
                    let acts: [(icon: String, label: String, tint: Color)] = [
                        ("sunrise.fill", "Act I, dawn", Palette.goldText),
                        ("sunset.fill", "Act II, dusk", Color(hex: 0xC9601F)),
                        ("moon.stars.fill", "Act III, night", Palette.violet),
                        ("sparkles", "Act IV, beyond the isles", Palette.sky)
                    ]
                    let unlocked = progress.isUnlocked(missionID: index * 9 + 1)
                    Button {
                        nav.missionMapIndex = firstPlayableIndex(inAct: index)
                    } label: {
                        Image(systemName: unlocked ? acts[index].icon : "lock.fill")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(act == index ? .white : (unlocked ? acts[index].tint : Palette.muted))
                            .frame(width: 56, height: 44)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(act == index ? Palette.pink : .clear))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!unlocked)
                    .help(acts[index].label)
                    .accessibilityLabel(acts[index].label + (unlocked ? "" : ", locked"))
                }
            }
            .padding(Space.xs)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white).shadow(color: Palette.edge, radius: 0, y: 4))

            Spacer(minLength: 0)

            HStack(spacing: Space.s) {
                PixelImage(sprite: .crystal, scale: 2)
                Text("\(progress.crystalsRestored)/\(GameProgress.worldCount)")
            }
            .pill(height: 52)
            .accessibilityLabel("\(progress.crystalsRestored) of \(GameProgress.worldCount) Heart Crystals")
            HStack(spacing: Space.s) {
                Image(systemName: "star.fill").foregroundStyle(Palette.gold)
                Text("\(progress.totalStars)")
            }
            .pill(height: 52)
            .accessibilityLabel("\(progress.totalStars) of \(GameProgress.missionCount * 3) stars")
        }
        .font(.rounded(17, .bold))
    }

    // MARK: Map

    /// The illustrated isles; each island's landmark shows what the world holds.
    private var map: some View {
        let cleared = (0..<GameProgress.worldCount).filter { progress.isCompleted(missionID: $0 * 3 + 3) }.count
        let unlocked = (0..<GameProgress.worldCount).filter { progress.isUnlocked(missionID: $0 * 3 + 1) }.count
        return GeometryReader { proxy in
            let s = min(proxy.size.width / MapArt.size.width, proxy.size.height / MapArt.size.height)
            ZStack(alignment: .topLeading) {
                Image(decorative: MapArt.image(cleared: cleared, unlocked: unlocked, current: selectedWorld), scale: 2)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: MapArt.size.width * s, height: MapArt.size.height * s)

                ForEach(0..<GameProgress.worldCount, id: \.self) { world in
                    let island = MapArt.islands[world]
                    worldPin(world)
                        .position(x: island.center.x * s, y: (island.center.y - island.radius.height - 26) * s)
                }

                let current = MapArt.islands[selectedWorld]
                Text(WorldThemes.ordered[selectedWorld].name)
                    .font(.rounded(17, .bold))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white).shadow(color: Palette.edge, radius: 0, y: 4))
                    .fixedSize()
                    .position(x: current.center.x * s, y: (current.center.y + current.radius.height + 34) * s)
                    .animation(.spring(duration: 0.35), value: selectedWorld)
                    .allowsHitTesting(false)

                PixelImage(sprite: .alinaIdle, scale: 3)
                    .position(x: (current.center.x - current.radius.width * 0.62) * s, y: (current.center.y - 26) * s)
                    .animation(.spring(duration: 0.35), value: selectedWorld)
                    .allowsHitTesting(false)
            }
            .frame(width: MapArt.size.width * s, height: MapArt.size.height * s)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white, lineWidth: 6))
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Palette.edge).offset(y: 10))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// World number with its stars, or a lock; tap to jump there.
    private func worldPin(_ world: Int) -> some View {
        let theme = WorldThemes.ordered[world]
        let firstID = world * 3 + 1
        let unlocked = progress.isUnlocked(missionID: firstID)
        let stars = (firstID...firstID + 2).reduce(0) { $0 + progress.starCount(for: $1) }
        let selected = world == selectedWorld
        let cleared = progress.isCompleted(missionID: firstID + 2)

        return Button {
            if unlocked { nav.missionMapIndex = firstPlayableIndex(inWorld: world) }
        } label: {
            Group {
                if unlocked {
                    HStack(spacing: 6) {
                        Text("\(world + 1)").font(.rounded(17, .heavy))
                        HStack(spacing: 1) {
                            ForEach(0..<3, id: \.self) { i in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(i < (stars + 2) / 3 ? Palette.gold : .white.opacity(0.45))
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selected ? Palette.pink : (cleared ? Palette.mint : Palette.sky))
                            .shadow(color: selected ? Palette.pinkDeep : Palette.ink.opacity(0.25), radius: 0, y: 4)
                    )
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Palette.muted)
                        .frame(width: 32, height: 32)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white.opacity(0.9)))
                }
            }
            .scaleEffect(selected ? 1.12 : 1)
        }
        .buttonStyle(.plain)
        .help(theme.name)
        .accessibilityLabel("World \(world + 1): \(theme.name)\(unlocked ? ", \(stars) of 9 stars" : ", locked")")
    }

    // MARK: Side panel

    private var sidePanel: some View {
        let theme = WorldThemes.ordered[selectedWorld]
        let worldMissions = missions.filter { WorldThemes.index(of: $0.world) == selectedWorld }

        return VStack(alignment: .leading, spacing: 18) {
            ZStack(alignment: .bottomLeading) {
                PixelBackdrop(theme: theme, dense: theme.key == "grove", groundHeight: 30, sunPosition: 0.72)
                    .frame(width: 280, height: 150)
                Text(theme.name)
                    .font(.rounded(19, .bold))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, Space.m)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white))
                    .padding(Space.m)
            }
            .frame(width: 280, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(spacing: 10) {
                ForEach(worldMissions) { mission in
                    missionRow(mission)
                }
            }

            Spacer(minLength: 0)

            Button {
                if let mission = selectedMission, progress.isUnlocked(missionID: mission.id) { onSelect(mission) }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill").font(.system(size: 22, weight: .bold))
                    Text(selectedMission?.code ?? "")
                }
            }
            .buttonStyle(TileButtonStyle(kind: .primary, size: 64))
            .disabled(!(selectedMission.map { progress.isUnlocked(missionID: $0.id) } ?? false))
            .accessibilityLabel(selectedMission.map { "Play \($0.code), \($0.title)" } ?? "Play")
        }
        .frame(width: 280)
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
                        Text(mission.code).font(.rounded(15, .heavy)).foregroundStyle(.white)
                    } else {
                        Image(systemName: "lock.fill").font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.muted)
                    }
                }
                .frame(width: 44, height: 40)

                PixelImage(sprite: mission.goalSprite, scale: 2)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white))
                    .opacity(unlocked ? 1 : 0.45)
                    .saturation(unlocked ? 1 : 0)

                Spacer(minLength: 0)
                if unlocked {
                    StarsView(stars: stars, size: 15)
                }
            }
            .padding(.horizontal, Space.m)
            .frame(height: 64)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(selected ? Palette.pinkSoft : Palette.sand))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(selected ? Palette.pink : .clear, lineWidth: 3))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .help("\(mission.title) · \(mission.objectiveLabel)")
        .accessibilityLabel("\(mission.code), \(mission.title), \(mission.objectiveLabel)\(unlocked ? "" : ", locked")")
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
        let world = max(0, min(GameProgress.worldCount - 1, selectedWorld + delta))
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
