import XCTest
@testable import Yahtzee

@MainActor
final class GameEngineTests: XCTestCase {
    func testHumanCanRollAndScore() async throws {
        let profiles = [
            PlayerProfile(name: "Kind"),
            PlayerProfile.computer(level: .medium)
        ]
        let engine = GameEngine(mode: .versusComputer, profiles: profiles, seed: 42)

        XCTAssertTrue(engine.canRoll)
        await engine.rollDice()
        XCTAssertTrue(engine.hasRolledThisTurn)
        XCTAssertEqual(engine.rollsRemaining, 2)
        XCTAssertTrue(engine.canScore)

        let open = YahtzeeScorer.availableCategories(
            dice: engine.diceValues,
            scorecard: engine.currentPlayer.scorecard
        )
        let category = try XCTUnwrap(open.first)
        engine.score(in: category)
        XCTAssertEqual(engine.currentPlayerIndex, 1)
        XCTAssertTrue(engine.currentPlayer.isComputer)
    }
}

@MainActor
final class GameEngineRobustnessTests: XCTestCase {
    func testHeldDiceSurviveReroll() async throws {
        let engine = GameEngine(
            mode: .versusFriends,
            profiles: [PlayerProfile(name: "A"), PlayerProfile(name: "B")],
            seed: 3
        )
        await engine.rollDice()

        let held = Array(engine.dice.prefix(2))
        for die in held {
            engine.toggleHold(dieID: die.id)
        }
        await engine.rollDice()

        XCTAssertEqual(engine.rollsRemaining, 1)
        for die in held {
            let after = try XCTUnwrap(engine.dice.first { $0.id == die.id })
            XCTAssertEqual(after.value, die.value)
            XCTAssertTrue(after.isHeld)
        }
    }

    func testThreeRollsMaximum() async {
        let engine = GameEngine(
            mode: .versusFriends,
            profiles: [PlayerProfile(name: "A"), PlayerProfile(name: "B")],
            seed: 4
        )
        await engine.rollDice()
        await engine.rollDice()
        await engine.rollDice()

        XCTAssertEqual(engine.rollsRemaining, 0)
        XCTAssertFalse(engine.canRoll)
        XCTAssertTrue(engine.canScore)
    }

    /// Regressie: een hervat spel midden in de computerbeurt mag een
    /// klaarliggende Dobbel niet zomaar opnieuw gooien.
    func testResumedComputerTurnScoresReadyDobbel() async throws {
        let human = GamePlayer(profile: PlayerProfile(name: "Kind"))
        let robot = GamePlayer(profile: .computer(level: .medium))
        let snapshot = GameSnapshot(
            mode: .versusComputer,
            players: [human, robot],
            currentPlayerIndex: 1,
            dice: (0..<5).map { _ in Die(value: 6) },
            rollsRemaining: 2,
            hasRolledThisTurn: true,
            turnMessage: "",
            savedAt: .now
        )
        let engine = GameEngine(snapshot: snapshot, seed: 9)

        await engine.playComputerTurnIfNeeded()

        XCTAssertEqual(engine.players[1].scorecard.scores[.yahtzee], 50)
    }

    /// Een geannuleerde computerlus speelt niet stiekem door.
    func testCancelledComputerLoopStops() async {
        let human = GamePlayer(profile: PlayerProfile(name: "Kind"))
        let robot = GamePlayer(profile: .computer(level: .medium))
        let snapshot = GameSnapshot(
            mode: .versusComputer,
            players: [human, robot],
            currentPlayerIndex: 1,
            dice: (0..<5).map { _ in Die(value: 6) },
            rollsRemaining: 2,
            hasRolledThisTurn: true,
            turnMessage: "",
            savedAt: .now
        )
        let engine = GameEngine(snapshot: snapshot, seed: 9)

        let task = Task { await engine.playComputerTurnIfNeeded() }
        task.cancel()
        await task.value

        XCTAssertNil(engine.players[1].scorecard.scores[.yahtzee])
        XCTAssertFalse(engine.isFinished)
    }

    func testRematchProfilesKeepIdentityAndLevel() {
        let kind = PlayerProfile(name: "Kind")
        let engine = GameEngine(
            mode: .versusComputer,
            profiles: [kind, .computer(level: .hard)],
            seed: 1
        )

        let profiles = engine.rematchProfiles()
        XCTAssertEqual(profiles.map(\.id), [kind.id, PlayerProfile.computerIDs[.hard]!])
        XCTAssertEqual(profiles[1].computerLevel, .hard)
        XCTAssertEqual(profiles[1].name, ComputerLevel.hard.personaName)
    }

    /// Het laatste vakje sluit het spel af en wijst de winnaar aan.
    func testFinalScoreEndsGameWithWinner() async throws {
        var strong = GamePlayer(profile: PlayerProfile(name: "Sterk"))
        for category in ScoreCategory.allCases {
            strong.scorecard.place(category: category, score: 20, yahtzeeBonus: 0)
        }
        var almost = GamePlayer(profile: PlayerProfile(name: "Bijna"))
        for category in ScoreCategory.allCases where category != .chance {
            almost.scorecard.place(category: category, score: 5, yahtzeeBonus: 0)
        }
        let snapshot = GameSnapshot(
            mode: .versusFriends,
            players: [almost, strong],
            currentPlayerIndex: 0,
            dice: (0..<5).map { _ in Die(value: 2) },
            rollsRemaining: 2,
            hasRolledThisTurn: true,
            turnMessage: "",
            savedAt: .now
        )
        let engine = GameEngine(snapshot: snapshot, seed: 2)

        engine.score(in: .chance)

        XCTAssertTrue(engine.isFinished)
        XCTAssertEqual(engine.winnerProfileIDs, [strong.profileID])
    }
}

@MainActor
final class GameEngineUndoTests: XCTestCase {
    func testUndoRestoresPreviousTurn() async throws {
        let engine = GameEngine(
            mode: .versusFriends,
            profiles: [PlayerProfile(name: "A"), PlayerProfile(name: "B")],
            seed: 6
        )
        await engine.rollDice()
        let diceBefore = engine.dice
        let category = try XCTUnwrap(YahtzeeScorer.availableCategories(
            dice: engine.diceValues, scorecard: engine.currentPlayer.scorecard
        ).first)

        XCTAssertTrue(engine.score(in: category))
        XCTAssertEqual(engine.currentPlayerIndex, 1)
        XCTAssertTrue(engine.canUndoScore)

        engine.undoLastScore()

        XCTAssertEqual(engine.currentPlayerIndex, 0)
        XCTAssertNil(engine.players[0].scorecard.scores[category])
        XCTAssertEqual(engine.dice, diceBefore)
        XCTAssertTrue(engine.canScore)
        XCTAssertFalse(engine.canUndoScore)
    }

    /// Zodra de volgende speler gooit of vasthoudt, is de terugweg dicht.
    func testUndoWindowClosesAfterNextRoll() async throws {
        let engine = GameEngine(
            mode: .versusFriends,
            profiles: [PlayerProfile(name: "A"), PlayerProfile(name: "B")],
            seed: 6
        )
        await engine.rollDice()
        let category = try XCTUnwrap(YahtzeeScorer.availableCategories(
            dice: engine.diceValues, scorecard: engine.currentPlayer.scorecard
        ).first)
        engine.score(in: category)
        XCTAssertTrue(engine.canUndoScore)

        await engine.rollDice()
        XCTAssertFalse(engine.canUndoScore)

        engine.undoLastScore()
        XCTAssertEqual(engine.players[0].scorecard.filledCount, 1)
    }
}
