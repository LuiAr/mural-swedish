import XCTest
@testable import MuralCore

final class AppReleaseNotesTests: XCTestCase {
    func testCurrentReleaseRequiresExactRunningVersionAndBuild() throws {
        let release = try XCTUnwrap(AppReleaseNotes.all.first)
        XCTAssertEqual(AppReleaseNotes.current(version: release.version, build: String(release.build)), release)
        XCTAssertNil(AppReleaseNotes.current(version: "unreleased", build: String(release.build)))
        XCTAssertNil(AppReleaseNotes.current(version: release.version, build: "unknown"))
        XCTAssertNil(AppReleaseNotes.current(version: release.version, build: String(release.build + 1)))
    }

    func testHistoryNeverIncludesCurrentOrFutureBuilds() throws {
        let newest = try XCTUnwrap(AppReleaseNotes.all.first)
        let history = AppReleaseNotes.history(beforeBuild: String(newest.build))
        XCTAssertTrue(history.allSatisfy { $0.build < newest.build })
        XCTAssertEqual(history.map(\.build), history.map(\.build).sorted(by: >))
        XCTAssertTrue(AppReleaseNotes.history(beforeBuild: "unknown").isEmpty)
        XCTAssertEqual(AppReleaseNotes.history(beforeBuild: String(newest.build + 1)), AppReleaseNotes.all)
    }

    func testCatalogHasStableUniqueIdentitiesAndReadableContent() {
        let releases = AppReleaseNotes.all
        XCTAssertEqual(Set(releases.map(\.id)).count, releases.count)
        XCTAssertEqual(releases.map(\.build), releases.map(\.build).sorted(by: >))
        for release in releases {
            XCTAssertGreaterThan(release.build, 0)
            XCTAssertFalse(release.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            XCTAssertFalse(release.date.isEmpty)
            XCTAssertFalse(release.highlights.isEmpty)
            XCTAssertEqual(Set(release.highlights.map(\.id)).count, release.highlights.count)
            for item in release.highlights {
                XCTAssertFalse(item.title.isEmpty)
                XCTAssertFalse(item.detail.isEmpty)
                XCTAssertFalse(item.symbol.isEmpty)
            }
        }
    }

    func testShippingBuildMustHaveMatchingNotesAndGeneratorMetadata() throws {
        let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let project = try String(contentsOf: package.appendingPathComponent("Mural.xcodeproj/project.pbxproj"), encoding: .utf8)
        let repo = package.deletingLastPathComponent().deletingLastPathComponent()
        let generator = try String(contentsOf: repo.appendingPathComponent("scripts/generate_project.py"), encoding: .utf8)
        func values(_ pattern: String, in source: String) throws -> [String] {
            let regex = try NSRegularExpression(pattern: pattern)
            return regex.matches(in: source, range: NSRange(source.startIndex..., in: source)).compactMap {
                Range($0.range(at: 1), in: source).map { String(source[$0]) }
            }
        }
        let builds = try values(#"CURRENT_PROJECT_VERSION\s*=\s*"([0-9]+)""#, in: project)
        let versions = try values(#"MARKETING_VERSION\s*=\s*"([^"]+)""#, in: project)
        let build = try XCTUnwrap(builds.first), version = try XCTUnwrap(versions.first)
        XCTAssertEqual(Set(builds), [build])
        XCTAssertEqual(Set(versions), [version])
        XCTAssertEqual(try values(#"'CURRENT_PROJECT_VERSION':'([0-9]+)'"#, in: generator), [build])
        let release = try XCTUnwrap(AppReleaseNotes.current(version: version, build: build),
            "Every delivery build needs a named What’s New entry before shipping.")
        XCTAssertEqual(AppReleaseNotes.all.first, release, "Keep the shipping release first, with no future notes bundled.")
    }
}
