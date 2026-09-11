import XCTest
@testable import Dobbel

final class ComputerAITests: XCTestCase {
    func testScoresDobbelWhenAvailable() {
        let ai = ComputerAI()
        let dice = (0..<5).map { _ in Die(value: 6) }
        let card = Scorecard()

        let decision = ai.decide(dice: dice, rollsRemaining: 2, scorecard: card)
        XCTAssertTrue(decision.shouldScore)
        XCTAssertEqual(decision.category, .dobbel)
    }

    func testChoosesCategoryWhenNoRollsLeft() {
        let ai = ComputerAI()
        let dice = [1, 2, 3, 4, 6].map { Die(value: $0) }
        let decision = ai.decide(dice: dice, rollsRemaining: 0, scorecard: Scorecard())
        XCTAssertTrue(decision.shouldScore)
        XCTAssertNotNil(decision.category)
    }
}

extension ComputerAITests {
    /// Dommel ziet geen paren: bij twee drieën houdt hij niets vast.
    func testEasyIgnoresPairs() {
        let ai = ComputerAI()
        let dice = [3, 3, 1, 2, 5].map { Die(value: $0) }
        let decision = ai.decide(dice: dice, rollsRemaining: 2, scorecard: Scorecard(), level: .easy)
        XCTAssertFalse(decision.shouldScore)
        XCTAssertEqual(decision.holdMask, [false, false, false, false, false])
    }

    /// De professor weegt de bonus mee: drie zessen gaan bovenin, waar het
    /// gewone niveau voor "3 dezelfde" kiest omdat dat nu meer punten geeft.
    func testHardPrefersUpperTowardBonus() {
        let ai = ComputerAI()
        let dice = [6, 6, 6, 2, 3].map { Die(value: $0) }

        let medium = ai.decide(dice: dice, rollsRemaining: 0, scorecard: Scorecard(), level: .medium)
        let hard = ai.decide(dice: dice, rollsRemaining: 0, scorecard: Scorecard(), level: .hard)

        XCTAssertEqual(medium.category, .threeOfAKind)
        XCTAssertEqual(hard.category, .sixes)
    }
}

extension ComputerAITests {
    /// In volgorde, doelvakje enen met twee enen op tafel: Dommel pakt die
    /// paar punten meteen, de professor houdt de enen vast en gooit door.
    func testInOrderEasySettlesWhereHardKeepsRolling() {
        let ai = ComputerAI()
        let dice = [1, 1, 3, 4, 6].map { Die(value: $0) }

        let easy = ai.decide(dice: dice, rollsRemaining: 2, scorecard: Scorecard(), level: .easy, variant: .inOrder)
        let hard = ai.decide(dice: dice, rollsRemaining: 2, scorecard: Scorecard(), level: .hard, variant: .inOrder)

        XCTAssertTrue(easy.shouldScore)
        XCTAssertEqual(easy.category, .ones)
        XCTAssertFalse(hard.shouldScore)
        XCTAssertEqual(hard.holdMask, [true, true, false, false, false])
    }

    /// Vier enen en een losse zes: Robbie legt tevreden vast, terwijl de
    /// professor de laatste steen nog omgooit voor het maximum.
    func testInOrderHardChasesTheFifthDieWhereMediumSettles() {
        let ai = ComputerAI()
        let dice = [1, 1, 1, 1, 6].map { Die(value: $0) }

        let medium = ai.decide(dice: dice, rollsRemaining: 1, scorecard: Scorecard(), level: .medium, variant: .inOrder)
        let hard = ai.decide(dice: dice, rollsRemaining: 1, scorecard: Scorecard(), level: .hard, variant: .inOrder)

        XCTAssertTrue(medium.shouldScore)
        XCTAssertFalse(hard.shouldScore)
        XCTAssertEqual(hard.holdMask, [true, true, true, true, false])
    }
}
