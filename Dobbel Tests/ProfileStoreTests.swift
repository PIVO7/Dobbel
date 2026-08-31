import XCTest
import SwiftUI
@testable import Dobbel

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
        milaPlayer.scorecard.place(category: .dobbel, score: 50, dobbelBonus: 0)
        milaPlayer.scorecard.place(category: .ones, score: 3, dobbelBonus: 0)
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

    func testSharedTopScoreCountsAsDraw() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("yahtzee-draw-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        let store = ProfileStore(fileURL: url)
        store.addProfile(name: "Mila")
        store.addProfile(name: "Noah")
        let mila = try XCTUnwrap(store.humanProfiles.first(where: { $0.name == "Mila" }))
        let noah = try XCTUnwrap(store.humanProfiles.first(where: { $0.name == "Noah" }))

        // Gedeelde topscore: beide spelers staan in winnerProfileIDs.
        store.recordGameResult(
            players: [GamePlayer(profile: mila), GamePlayer(profile: noah)],
            winnerProfileIDs: [mila.id, noah.id]
        )

        let updatedMila = try XCTUnwrap(store.humanProfiles.first(where: { $0.id == mila.id }))
        let updatedNoah = try XCTUnwrap(store.humanProfiles.first(where: { $0.id == noah.id }))
        XCTAssertEqual(updatedMila.draws, 1)
        XCTAssertEqual(updatedNoah.draws, 1)
        XCTAssertEqual(updatedMila.wins, 0)
        XCTAssertEqual(updatedMila.currentStreak, 0)
    }

    func testRecordsHistoryAndCapsIt() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("yahtzee-history-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        let store = ProfileStore(fileURL: url)
        store.addProfile(name: "Mila")
        store.addProfile(name: "Noah")
        let mila = try XCTUnwrap(store.humanProfiles.first(where: { $0.name == "Mila" }))
        let noah = try XCTUnwrap(store.humanProfiles.first(where: { $0.name == "Noah" }))

        // Eén potje meer dan de limiet: het oudste record moet eruit vallen.
        for round in 0...ProfileStore.maxHistoryLength {
            var milaPlayer = GamePlayer(profile: mila)
            milaPlayer.scorecard.place(category: .ones, score: round, dobbelBonus: 0)
            let noahPlayer = GamePlayer(profile: noah)
            store.recordGameResult(players: [milaPlayer, noahPlayer], winnerProfileIDs: [mila.id])
        }

        let updated = try XCTUnwrap(store.humanProfiles.first(where: { $0.id == mila.id }))
        XCTAssertEqual(updated.history.count, ProfileStore.maxHistoryLength)
        // Nieuwste achteraan, en de eerste (score 0) is weggevallen.
        XCTAssertEqual(updated.history.last?.score, ProfileStore.maxHistoryLength)
        XCTAssertEqual(updated.history.first?.score, 1)
        XCTAssertTrue(updated.history.allSatisfy(\.won))

        let loser = try XCTUnwrap(store.humanProfiles.first(where: { $0.id == noah.id }))
        XCTAssertFalse(loser.history.isEmpty)
        XCTAssertTrue(loser.history.allSatisfy { !$0.won })

        // Herladen bewaart de geschiedenis; oude bestanden zonder het veld
        // laden als leeg (gedekt doordat decodeIfPresent op [] terugvalt).
        let reloaded = ProfileStore(fileURL: url)
        XCTAssertEqual(
            reloaded.humanProfiles.first(where: { $0.id == mila.id })?.history.count,
            ProfileStore.maxHistoryLength
        )
    }

    func testBadgeCollectionMarksEarned() {
        let starter = PlayerProfile(name: "Nieuw")
        XCTAssertTrue(ProfileBadge.collection(for: starter).allSatisfy { !$0.isEarned })

        let kampioen = PlayerProfile(
            name: "Kampioen", wins: 12, gamesPlayed: 25,
            bestScore: 201, totalPoints: 3000, dobbelCount: 5, bonusCount: 5,
            currentStreak: 3, bestStreak: 3
        )
        XCTAssertTrue(ProfileBadge.collection(for: kampioen).allSatisfy(\.isEarned))

        let beginner = PlayerProfile(name: "Beginner", wins: 0, gamesPlayed: 1, bestScore: 99)
        let badges = ProfileBadge.collection(for: beginner)
        XCTAssertTrue(badges.first { $0.id == "eerste-potje" }!.isEarned)
        XCTAssertFalse(badges.first { $0.id == "winnaar" }!.isEarned)
        XCTAssertFalse(badges.first { $0.id == "honderdklapper" }!.isEarned)
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
