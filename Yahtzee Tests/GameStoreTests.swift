import XCTest
@testable import Yahtzee

final class GameStoreTests: XCTestCase {
    func testSaveLoadAndClear() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("yahtzee-saved-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        let mila = PlayerProfile(name: "Mila")
        let engine = GameEngine(mode: .versusFriends, profiles: [mila, PlayerProfile(name: "Noah")], seed: 7)
        var snapshot = engine.snapshot
        snapshot.players[0].scorecard.place(category: .ones, score: 3, yahtzeeBonus: 0)
        snapshot.currentPlayerIndex = 1
        snapshot.turnMessage = "Noah is aan de beurt"

        let store = GameStore(fileURL: url)
        store.save(snapshot)
        XCTAssertTrue(store.hasSavedGame)
        XCTAssertEqual(store.savedGame?.players[0].scorecard.scores[.ones], 3)

        let reloaded = GameStore(fileURL: url)
        XCTAssertEqual(reloaded.savedGame?.summaryTitle, "Mila · Noah")
        XCTAssertEqual(reloaded.savedGame?.currentPlayerIndex, 1)

        let resumed = GameEngine(snapshot: try XCTUnwrap(reloaded.savedGame))
        XCTAssertEqual(resumed.players[0].scorecard.scores[.ones], 3)
        XCTAssertEqual(resumed.currentPlayerIndex, 1)

        reloaded.clear()
        XCTAssertFalse(reloaded.hasSavedGame)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }
}

@MainActor
final class GameEngineRoundTests: XCTestCase {
    func testRoundNumberStableAcrossPlayers() async {
        let profiles = [PlayerProfile(name: "A"), PlayerProfile(name: "B")]
        let engine = GameEngine(mode: .versusFriends, profiles: profiles, seed: 1)
        XCTAssertEqual(engine.roundNumber, 1)

        await engine.rollDice()
        let open = YahtzeeScorer.availableCategories(
            dice: engine.diceValues,
            scorecard: engine.currentPlayer.scorecard
        )
        engine.score(in: open[0])

        // Speler B is aan de beurt maar ronde blijft 1 tot beide een vak hebben.
        XCTAssertEqual(engine.currentPlayerIndex, 1)
        XCTAssertEqual(engine.roundNumber, 1)
    }
}
