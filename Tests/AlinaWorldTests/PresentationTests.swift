import XCTest
@testable import AlinaWorld

final class PresentationTests: XCTestCase {
    func testMissionConditionsMatchTheirEnvironmentAndChapter() throws {
        let expected: [Int: MissionWeather.Kind] = [1: .sunny, 2: .breeze, 3: .sunshower, 4: .sunny, 5: .rain,
                                                     6: .storm, 10: .embers, 16: .mist, 17: .rain, 18: .storm,
                                                     28: .snow, 30: .blizzard, 31: .sunny, 36: .starlight]
        for (id, kind) in expected {
            let mission = try XCTUnwrap(MissionLoader.mission(id: id))
            XCTAssertEqual(mission.weather.kind, kind, "Mission \(id)")
        }
    }

    func testAllMissionsHaveDeterministicBoundedWeather() {
        let missions = MissionLoader.loadAll()
        XCTAssertEqual(missions.count, 36)
        for mission in missions {
            let weather = mission.weather
            XCTAssertEqual(weather, mission.weather)
            XCTAssertFalse(weather.label.isEmpty)
            XCTAssertFalse(weather.symbol.isEmpty)
            XCTAssertTrue((0...1).contains(weather.rain))
            XCTAssertTrue((0...1).contains(weather.snow))
            XCTAssertTrue((0...1).contains(weather.wind))
            if weather.kind == .embers { XCTAssertEqual(weather.rain, 0) }
        }
    }

    func testPanoramaCoversEntireViewportAtEveryPositionAndLongDuration() {
        let tileWidth: CGFloat = 1300
        for width: CGFloat in [420, 900, 3600, 8000] {
            for x: CGFloat in [-900, 0, 1_000, 10_000, 100_000_000] {
                for time: CGFloat in [0, 0.1, 60, 3600, 86_400] {
                    let visible = CGRect(x: x, y: 0, width: width, height: 420)
                    let centers = BackgroundTiling.centers(visible: visible, tileWidth: tileWidth, time: time)
                    XCTAssertLessThanOrEqual(centers.first! - tileWidth / 2, visible.minX)
                    XCTAssertGreaterThanOrEqual(centers.last! + tileWidth / 2, visible.maxX)
                    for pair in zip(centers, centers.dropFirst()) {
                        XCTAssertEqual(pair.1 - pair.0, tileWidth, accuracy: 0.0001)
                    }
                }
            }
        }
    }

    func testEveryWorldHasItsOwnPackagedPanorama() {
        for theme in WorldThemes.ordered {
            XCTAssertNotNil(StorybookArt.image(.environment(for: theme.key)), theme.name)
        }
        XCTAssertEqual(CharacterAtlas.runFrames.count, 6)
    }
}
