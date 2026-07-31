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
