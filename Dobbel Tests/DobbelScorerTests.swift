import XCTest
@testable import Dobbel

final class DobbelScorerTests: XCTestCase {
    func testUpperScores() {
        XCTAssertEqual(DobbelScorer.score(category: .fives, dice: [5, 5, 1, 2, 5]), 15)
        XCTAssertEqual(DobbelScorer.score(category: .ones, dice: [2, 3, 4, 5, 6]), 0)
    }

    func testFullHouseAndStraights() {
        XCTAssertEqual(DobbelScorer.score(category: .fullHouse, dice: [2, 2, 3, 3, 3]), 25)
        XCTAssertEqual(DobbelScorer.score(category: .fullHouse, dice: [2, 2, 2, 2, 3]), 0)
        XCTAssertEqual(DobbelScorer.score(category: .smallStraight, dice: [1, 2, 3, 4, 4]), 30)
        XCTAssertEqual(DobbelScorer.score(category: .largeStraight, dice: [2, 3, 4, 5, 6]), 40)
    }

    func testDobbelAndChance() {
        XCTAssertEqual(DobbelScorer.score(category: .dobbel, dice: [6, 6, 6, 6, 6]), 50)
        XCTAssertEqual(DobbelScorer.score(category: .dobbel, dice: [6, 6, 6, 6, 5]), 0)
        XCTAssertEqual(DobbelScorer.score(category: .chance, dice: [1, 2, 3, 4, 5]), 15)
    }

    func testThreeAndFourOfAKind() {
        XCTAssertEqual(DobbelScorer.score(category: .threeOfAKind, dice: [4, 4, 4, 2, 1]), 15)
        XCTAssertEqual(DobbelScorer.score(category: .fourOfAKind, dice: [4, 4, 4, 4, 1]), 17)
        XCTAssertEqual(DobbelScorer.score(category: .fourOfAKind, dice: [4, 4, 4, 2, 1]), 0)
    }

    func testDobbelBonusOnSecondDobbel() {
        var card = Scorecard()
        card.place(category: .dobbel, score: 50, dobbelBonus: 0)

        let result = DobbelScorer.pointsForPlacing(
            category: .sixes,
            dice: [6, 6, 6, 6, 6],
            scorecard: card
        )
        XCTAssertEqual(result.score, 30)
        XCTAssertEqual(result.dobbelBonus, 100)
    }

    func testNoBonusWhenDobbelBoxIsZero() {
        var card = Scorecard()
        card.place(category: .dobbel, score: 0, dobbelBonus: 0)

        let result = DobbelScorer.pointsForPlacing(
            category: .chance,
            dice: [3, 3, 3, 3, 3],
            scorecard: card
        )
        XCTAssertEqual(result.dobbelBonus, 0)
    }

    func testJokerForcesOpenUpperFace() {
        var card = Scorecard()
        card.place(category: .dobbel, score: 50, dobbelBonus: 0)

        let open = DobbelScorer.availableCategories(dice: [4, 4, 4, 4, 4], scorecard: card)
        XCTAssertEqual(open, [.fours])
    }

    func testUpperBonusThreshold() {
        var card = Scorecard()
        card.place(category: .sixes, score: 30, dobbelBonus: 0)
        card.place(category: .fives, score: 25, dobbelBonus: 0)
        card.place(category: .fours, score: 8, dobbelBonus: 0)
        XCTAssertEqual(card.upperSubtotal, 63)
        XCTAssertEqual(card.upperBonus, 35)
    }

    /// Regressie voor "ik kon Chance niet kiezen": zolang Chance leeg is,
    /// hoort hij open te staan — met één uitzondering, de jokerregel, die bij
    /// een tweede Dobbel eerst het eigen vakje bovenin afdwingt.
    func testChanceStaysAvailableUntilFilled() {
        var scorecard = Scorecard()
        scorecard.place(category: .fullHouse, score: 25, dobbelBonus: 0)
        scorecard.place(category: .largeStraight, score: 40, dobbelBonus: 0)
        scorecard.place(category: .fours, score: 16, dobbelBonus: 0)

        let open = DobbelScorer.availableCategories(dice: [2, 3, 4, 6, 6], scorecard: scorecard)
        XCTAssertTrue(open.contains(.chance))

        scorecard.place(category: .chance, score: 21, dobbelBonus: 0)
        let after = DobbelScorer.availableCategories(dice: [2, 3, 4, 6, 6], scorecard: scorecard)
        XCTAssertFalse(after.contains(.chance))
    }
}


extension DobbelScorerTests {
    /// De jokerregel geldt ook als het Dobbel-vakje met een nul is
    /// afgestreept: vaste punten voor vol huis en straten, en het
    /// bijpassende vakje bovenin wordt eerst afgedwongen.
    func testJokerAppliesAfterZeroedDobbel() {
        var card = Scorecard()
        card.place(category: .dobbel, score: 0, dobbelBonus: 0)
        let dice = [4, 4, 4, 4, 4]

        XCTAssertTrue(DobbelScorer.canUseJoker(dice: dice, scorecard: card))
        XCTAssertEqual(DobbelScorer.availableCategories(dice: dice, scorecard: card), [.fours])

        card.place(category: .fours, score: 20, dobbelBonus: 0)
        let fullHouse = DobbelScorer.pointsForPlacing(category: .fullHouse, dice: dice, scorecard: card)
        XCTAssertEqual(fullHouse.score, 25)
        // Maar de 100-puntenbonus blijft voorbehouden aan een echte 50.
        XCTAssertEqual(fullHouse.dobbelBonus, 0)
    }
}
