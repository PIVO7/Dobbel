import XCTest
@testable import Yahtzee

final class AdviceExplainerTests: XCTestCase {
    func testUpperMentionsBonusWhileReachable() {
        let text = AdviceExplainer.explain(
            category: .fives,
            dice: [5, 5, 5, 2, 3],
            scorecard: Scorecard()
        )
        XCTAssertTrue(text.contains("3 vijven"))
        XCTAssertTrue(text.contains("15 punten"))
        XCTAssertTrue(text.contains("bonus"))
    }

    func testUpperSkipsBonusWhenOutOfReach() {
        // Bovenin bijna vol met nullen: de drempel van 63 is onhaalbaar.
        var card = Scorecard()
        for category in [ScoreCategory.ones, .twos, .threes, .fours] {
            card.place(category: category, score: 0, yahtzeeBonus: 0)
        }
        let text = AdviceExplainer.explain(category: .fives, dice: [5, 5, 5, 2, 3], scorecard: card)
        XCTAssertFalse(text.contains("bonus"))
    }

    /// Bij een tweede Dobbel via de jokerregel mag de uitleg niet doen alsof
    /// er een echt vol huis ligt.
    func testJokerExplanationForFullHouse() {
        var card = Scorecard()
        card.place(category: .yahtzee, score: 50, yahtzeeBonus: 0)
        card.place(category: .fours, score: 16, yahtzeeBonus: 0)
        let text = AdviceExplainer.explain(category: .fullHouse, dice: [4, 4, 4, 4, 4], scorecard: card)
        XCTAssertTrue(text.contains("jokerregel"))
        XCTAssertFalse(text.contains("Twee én drie"))
    }

    func testFixedCategories() {
        XCTAssertTrue(
            AdviceExplainer.explain(category: .largeStraight, dice: [1, 2, 3, 4, 5], scorecard: Scorecard())
                .contains("40")
        )
        XCTAssertTrue(
            AdviceExplainer.explain(category: .chance, dice: [6, 6, 5, 4, 2], scorecard: Scorecard())
                .contains("23 punten")
        )
    }
}
