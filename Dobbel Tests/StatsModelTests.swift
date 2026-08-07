import XCTest
@testable import Dobbel

/// De statistiekmodellen achter de trofeeënkast en de gezinsrecords.
@MainActor
final class StatsModelTests: XCTestCase {
    private func profile(
        name: String,
        wins: Int = 0,
        games: Int = 0,
        bestScore: Int = 0,
        dobbels: Int = 0,
        bonussen: Int = 0,
        bestStreak: Int = 0
    ) -> PlayerProfile {
        PlayerProfile(
            name: name,
            wins: wins,
            gamesPlayed: games,
            bestScore: bestScore,
            dobbelCount: dobbels,
            bonusCount: bonussen,
            currentStreak: 0,
            bestStreak: bestStreak
        )
    }

    // MARK: - Trofeeën

    func testFreshProfileEarnsNothing() {
        let badges = ProfileBadge.collection(for: profile(name: "Lene"))
        XCTAssertFalse(badges.isEmpty)
        XCTAssertTrue(badges.allSatisfy { !$0.isEarned })
    }

    func testBadgeThresholds() {
        let speler = profile(
            name: "Lene",
            wins: 1, games: 10, bestScore: 150,
            dobbels: 1, bonussen: 1, bestStreak: 3
        )
        let earned = Set(ProfileBadge.collection(for: speler).filter(\.isEarned).map(\.id))
        XCTAssertTrue(earned.isSuperset(of: [
            "eerste-potje", "winnaar", "eerste-dobbel", "bonusjager",
            "honderdklapper", "dobbelfan", "topvorm", "hattrick"
        ]))
        // Nét niet gehaald: 5 dobbels, 5 bonussen, 200 punten, 25 potjes.
        XCTAssertTrue(earned.isDisjoint(with: [
            "sterrenregen", "bonusbaas", "recordbreker", "dobbelkampioen"
        ]))
    }

    // MARK: - Gezinsrecords

    func testHighestValueWinsAndTiesShareTheRecord() {
        let lene = profile(name: "Lene", wins: 4, games: 6)
        let ellis = profile(name: "Ellis", wins: 4, games: 5)
        let noah = profile(name: "Noah", wins: 2, games: 4)

        let record = FamilyRecordMath.record(in: [lene, ellis, noah], value: { $0.wins })
        XCTAssertEqual(record?.value, 4)
        XCTAssertEqual(record?.holders.map(\.name), ["Lene", "Ellis"])
    }

    func testProfilesWithoutGamesDoNotCompete() {
        let spook = profile(name: "Spook", wins: 99, games: 0)
        let lene = profile(name: "Lene", wins: 1, games: 1)

        let record = FamilyRecordMath.record(in: [spook, lene], value: { $0.wins })
        XCTAssertEqual(record?.holders.map(\.name), ["Lene"])
        XCTAssertEqual(record?.value, 1)
    }

    func testZeroIsNoRecord() {
        let lene = profile(name: "Lene", games: 2)
        XCTAssertNil(FamilyRecordMath.record(in: [lene], value: { $0.wins }))
    }

    func testBestScoreRecord() {
        let lene = profile(name: "Lene", games: 3, bestScore: 180)
        let ellis = profile(name: "Ellis", games: 3, bestScore: 240)

        let record = FamilyRecordMath.record(in: [lene, ellis], value: { $0.bestScore })
        XCTAssertEqual(record?.value, 240)
        XCTAssertEqual(record?.holders.map(\.name), ["Ellis"])
    }
}
