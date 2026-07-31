import XCTest
import SwiftUI
@testable import Yahtzee

@MainActor
final class ProfileStoreTests: XCTestCase {
    func testAddAndRecordWins() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("yahtzee-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        let store = ProfileStore(fileURL: url)
        store.addProfile(name: "Mila")
        store.addProfile(name: "Noah")

        let mila = try XCTUnwrap(store.humanProfiles.first(where: { $0.name == "Mila" }))
        let noah = try XCTUnwrap(store.humanProfiles.first(where: { $0.name == "Noah" }))

        var milaPlayer = GamePlayer(profile: mila)
        milaPlayer.scorecard.place(category: .yahtzee, score: 50, yahtzeeBonus: 0)
        milaPlayer.scorecard.place(category: .ones, score: 3, yahtzeeBonus: 0)
        let noahPlayer = GamePlayer(profile: noah)

        store.recordGameResult(
            players: [milaPlayer, noahPlayer],
            winnerProfileIDs: [mila.id]
        )

        let updatedMila = try XCTUnwrap(store.humanProfiles.first(where: { $0.id == mila.id }))
        let updatedNoah = try XCTUnwrap(store.humanProfiles.first(where: { $0.id == noah.id }))
        XCTAssertEqual(updatedMila.wins, 1)
        XCTAssertEqual(updatedMila.gamesPlayed, 1)
        XCTAssertEqual(updatedMila.bestScore, 53)
        XCTAssertEqual(updatedMila.totalPoints, 53)
        XCTAssertEqual(updatedMila.dobbelCount, 1)
        XCTAssertEqual(updatedMila.bonusCount, 0)
        XCTAssertEqual(updatedMila.currentStreak, 1)
        XCTAssertEqual(updatedMila.bestStreak, 1)
        XCTAssertEqual(updatedNoah.currentStreak, 0)
        XCTAssertEqual(updatedNoah.wins, 0)
        XCTAssertEqual(updatedNoah.gamesPlayed, 1)

        let reloaded = ProfileStore(fileURL: url)
        XCTAssertEqual(reloaded.humanProfiles.count, 2)
        XCTAssertEqual(reloaded.humanProfiles.first(where: { $0.id == mila.id })?.wins, 1)
    }

    func testTieDoesNotAwardWin() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("yahtzee-tie-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        let store = ProfileStore(fileURL: url)
        store.addProfile(name: "A")
        store.addProfile(name: "B")
        let ids = store.humanProfiles.map(\.id)
        let players = store.humanProfiles.map(GamePlayer.init)

        store.recordGameResult(players: players, winnerProfileIDs: ids)
        XCTAssertTrue(store.humanProfiles.allSatisfy { $0.wins == 0 })
        XCTAssertTrue(store.humanProfiles.allSatisfy { $0.gamesPlayed == 1 })
    }
}

extension ProfileStoreTests {
    /// De kleurtoewijzing in de store en het palet in de badge moeten
    /// dezelfde lengte delen.
    func testAvatarPaletteCountMatchesBadge() {
        XCTAssertEqual(AvatarBadge.palette.count, PlayerProfile.avatarPaletteCount)
    }
}
