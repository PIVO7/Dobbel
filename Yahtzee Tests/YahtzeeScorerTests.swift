import XCTest
@testable import Yahtzee

final class YahtzeeScorerTests: XCTestCase {
    func testUpperScores() {
        XCTAssertEqual(YahtzeeScorer.score(category: .fives, dice: [5, 5, 1, 2, 5]), 15)
        XCTAssertEqual(YahtzeeScorer.score(category: .ones, dice: [2, 3, 4, 5, 6]), 0)
    }

    func testFullHouseAndStraights() {
        XCTAssertEqual(YahtzeeScorer.score(category: .fullHouse, dice: [2, 2, 3, 3, 3]), 25)
        XCTAssertEqual(YahtzeeScorer.score(category: .fullHouse, dice: [2, 2, 2, 2, 3]), 0)
        XCTAssertEqual(YahtzeeScorer.score(category: .smallStraight, dice: [1, 2, 3, 4, 4]), 30)
        XCTAssertEqual(YahtzeeScorer.score(category: .largeStraight, dice: [2, 3, 4, 5, 6]), 40)
    }

    func testYahtzeeAndChance() {
        XCTAssertEqual(YahtzeeScorer.score(category: .yahtzee, dice: [6, 6, 6, 6, 6]), 50)
        XCTAssertEqual(YahtzeeScorer.score(category: .yahtzee, dice: [6, 6, 6, 6, 5]), 0)
        XCTAssertEqual(YahtzeeScorer.score(category: .chance, dice: [1, 2, 3, 4, 5]), 15)
    }

    func testThreeAndFourOfAKind() {
        XCTAssertEqual(YahtzeeScorer.score(category: .threeOfAKind, dice: [4, 4, 4, 2, 1]), 15)
        XCTAssertEqual(YahtzeeScorer.score(category: .fourOfAKind, dice: [4, 4, 4, 4, 1]), 17)
        XCTAssertEqual(YahtzeeScorer.score(category: .fourOfAKind, dice: [4, 4, 4, 2, 1]), 0)
    }

    func testYahtzeeBonusOnSecondYahtzee() {
        var card = Scorecard()
        card.place(category: .yahtzee, score: 50, yahtzeeBonus: 0)

        let result = YahtzeeScorer.pointsForPlacing(
            category: .sixes,
            dice: [6, 6, 6, 6, 6],
            scorecard: card
        )
        XCTAssertEqual(result.score, 30)
        XCTAssertEqual(result.yahtzeeBonus, 100)
    }

    func testNoBonusWhenYahtzeeBoxIsZero() {
        var card = Scorecard()
        card.place(category: .yahtzee, score: 0, yahtzeeBonus: 0)

        let result = YahtzeeScorer.pointsForPlacing(
            category: .chance,
            dice: [3, 3, 3, 3, 3],
            scorecard: card
        )
        XCTAssertEqual(result.yahtzeeBonus, 0)
    }

    func testJokerForcesOpenUpperFace() {
        var card = Scorecard()
        card.place(category: .yahtzee, score: 50, yahtzeeBonus: 0)

        let open = YahtzeeScorer.availableCategories(dice: [4, 4, 4, 4, 4], scorecard: card)
        XCTAssertEqual(open, [.fours])
    }

    func testUpperBonusThreshold() {
        var card = Scorecard()
        card.place(category: .sixes, score: 30, yahtzeeBonus: 0)
        card.place(category: .fives, score: 25, yahtzeeBonus: 0)
        card.place(category: .fours, score: 8, yahtzeeBonus: 0)
        XCTAssertEqual(card.upperSubtotal, 63)
        XCTAssertEqual(card.upperBonus, 35)
    }

    /// Regressie voor "ik kon Chance niet kiezen": zolang Chance leeg is,
    /// hoort hij open te staan — met één uitzondering, de jokerregel, die bij
    /// een tweede Yahtzee eerst het eigen vakje bovenin afdwingt.
    func testChanceStaysAvailableUntilFilled() {
        var scorecard = Scorecard()
        scorecard.place(category: .fullHouse, score: 25, yahtzeeBonus: 0)
        scorecard.place(category: .largeStraight, score: 40, yahtzeeBonus: 0)
        scorecard.place(category: .fours, score: 16, yahtzeeBonus: 0)

        let open = YahtzeeScorer.availableCategories(dice: [2, 3, 4, 6, 6], scorecard: scorecard)
        XCTAssertTrue(open.contains(.chance))

        scorecard.place(category: .chance, score: 21, yahtzeeBonus: 0)
        let after = YahtzeeScorer.availableCategories(dice: [2, 3, 4, 6, 6], scorecard: scorecard)
        XCTAssertFalse(after.contains(.chance))
    }
}


extension YahtzeeScorerTests {
    /// De jokerregel geldt ook als het Dobbel-vakje met een nul is
    /// afgestreept: vaste punten voor vol huis en straten, en het
    /// bijpassende vakje bovenin wordt eerst afgedwongen.
    func testJokerAppliesAfterZeroedYahtzee() {
        var card = Scorecard()
        card.place(category: .yahtzee, score: 0, yahtzeeBonus: 0)
        let dice = [4, 4, 4, 4, 4]

        XCTAssertTrue(YahtzeeScorer.canUseJoker(dice: dice, scorecard: card))
        XCTAssertEqual(YahtzeeScorer.availableCategories(dice: dice, scorecard: card), [.fours])

        card.place(category: .fours, score: 20, yahtzeeBonus: 0)
        let fullHouse = YahtzeeScorer.pointsForPlacing(category: .fullHouse, dice: dice, scorecard: card)
        XCTAssertEqual(fullHouse.score, 25)
        // Maar de 100-puntenbonus blijft voorbehouden aan een echte 50.
        XCTAssertEqual(fullHouse.yahtzeeBonus, 0)
    }
}
