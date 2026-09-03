import XCTest
@testable import Dobbel

/// De spelvorm "In volgorde": het blad gaat van boven naar onder, één vakje
/// tegelijk, en de computer speelt gewoon mee.
@MainActor
final class GameVariantTests: XCTestCase {
    func testInOrderOpensOnlyTheNextBox() {
        var card = Scorecard()
        card.place(category: .ones, score: 3, dobbelBonus: 0)
        card.place(category: .twos, score: 6, dobbelBonus: 0)

        let open = DobbelScorer.availableCategories(dice: [6, 6, 6, 6, 6], scorecard: card, variant: .inOrder)

        XCTAssertEqual(open, [.threes])
        // Klassiek blijft ongemoeid: daar mag alles wat nog leeg is.
        XCTAssertGreaterThan(DobbelScorer.availableCategories(dice: [6, 6, 6, 6, 6], scorecard: card).count, 1)
    }

    func testInOrderEngineRejectsOtherBoxes() async throws {
        let engine = GameEngine(
            mode: .versusFriends,
            variant: .inOrder,
            profiles: [PlayerProfile(name: "A"), PlayerProfile(name: "B")],
            seed: 11
        )
        await engine.rollDice()

        XCTAssertFalse(engine.score(in: .chance))
        XCTAssertFalse(engine.score(in: .twos))
        XCTAssertTrue(engine.score(in: .ones))
        XCTAssertEqual(engine.players[0].scorecard.filledCount, 1)
        XCTAssertNotNil(engine.players[0].scorecard.scores[.ones])
    }

    func testInOrderTurnMessageNamesTheNextBox() {
        let engine = GameEngine(
            mode: .versusFriends,
            variant: .inOrder,
            profiles: [PlayerProfile(name: "Lene"), PlayerProfile(name: "Ellis")],
            seed: 1
        )

        XCTAssertTrue(engine.turnMessage.contains(ScoreCategory.ones.title))
    }

    func testInOrderComputerFillsTopToBottom() async {
        let human = GamePlayer(profile: PlayerProfile(name: "Kind"))
        let robot = GamePlayer(profile: .computer(level: .hard))
        let snapshot = GameSnapshot(
            mode: .versusComputer,
            variant: .inOrder,
            players: [human, robot],
            currentPlayerIndex: 1,
            dice: (0..<5).map { _ in Die(value: 1) },
            rollsRemaining: 3,
            hasRolledThisTurn: false,
            turnMessage: "",
            savedAt: .now
        )
        let engine = GameEngine(snapshot: snapshot, seed: 5)

        await engine.playComputerTurnIfNeeded()

        let card = engine.players[1].scorecard
        XCTAssertEqual(card.filledCount, 1)
        XCTAssertNotNil(card.scores[.ones])
    }

    func testInOrderComputerHoldsTheTargetFace() {
        let ai = ComputerAI()
        var card = Scorecard()
        for category in [ScoreCategory.ones, .twos, .threes] {
            card.place(category: category, score: 0, dobbelBonus: 0)
        }
        let dice = [4, 4, 2, 5, 6].map { Die(value: $0) }

        let decision = ai.decide(dice: dice, rollsRemaining: 2, scorecard: card, variant: .inOrder)

        XCTAssertFalse(decision.shouldScore)
        XCTAssertEqual(decision.holdMask, [true, true, false, false, false])
    }

    func testInOrderComputerScoresAFinishedFixedBox() {
        let ai = ComputerAI()
        var card = Scorecard()
        for category in ScoreCategory.allCases.prefix(8) {
            card.place(category: category, score: 0, dobbelBonus: 0)
        }
        // Het volgende vakje is Vol huis, en die ligt er al.
        let dice = [3, 3, 3, 5, 5].map { Die(value: $0) }

        let decision = ai.decide(dice: dice, rollsRemaining: 2, scorecard: card, variant: .inOrder)

        XCTAssertTrue(decision.shouldScore)
        XCTAssertEqual(decision.category, .fullHouse)
    }

    /// Bewaarde spellen van vóór de spelvormen laden als klassiek.
    func testSnapshotWithoutVariantIsClassic() {
        let snapshot = GameSnapshot(
            mode: .versusFriends,
            players: [GamePlayer(profile: PlayerProfile(name: "A")), GamePlayer(profile: PlayerProfile(name: "B"))],
            currentPlayerIndex: 0,
            dice: (0..<5).map { _ in Die(value: 1) },
            rollsRemaining: 3,
            hasRolledThisTurn: false,
            turnMessage: "",
            savedAt: .now
        )

        XCTAssertEqual(GameEngine(snapshot: snapshot).variant, .classic)
    }

    func testSnapshotRoundTripKeepsVariant() throws {
        let engine = GameEngine(
            mode: .versusFriends,
            variant: .inOrder,
            profiles: [PlayerProfile(name: "A"), PlayerProfile(name: "B")],
            seed: 2
        )

        let data = try JSONEncoder().encode(engine.snapshot)
        let decoded = try JSONDecoder().decode(GameSnapshot.self, from: data)

        XCTAssertEqual(decoded.variant, .inOrder)
        XCTAssertEqual(GameEngine(snapshot: decoded).variant, .inOrder)
        XCTAssertTrue(decoded.summaryTitle.contains(GameVariant.inOrder.title))
    }
}
