import XCTest
@testable import Yahtzee

/// De tip op het scoreblad: bovenin weegt zwaarder zolang de bonus haalbaar
/// is, en verder wint de hoogste opbrengst.
final class AdviceTests: XCTestCase {
    /// Drie vijven: "3 dezelfde" levert nu 20 op en de vijven 15, maar de
    /// vijven tellen mee voor de bonus en winnen dus als tip.
    func testPrefersUpperWhileBonusIsReachable() {
        let advice = YahtzeeScorer.adviceCategory(dice: [5, 5, 5, 2, 3], scorecard: Scorecard())
        XCTAssertEqual(advice, .fives)
    }

    /// Is de bonus al binnen, dan vervalt het streepje voor en wint de
    /// hoogste opbrengst weer.
    func testFallsBackToGreedyOnceBonusIsEarned() {
        var scorecard = Scorecard()
        scorecard.place(category: .sixes, score: 30, yahtzeeBonus: 0)
        scorecard.place(category: .fours, score: 20, yahtzeeBonus: 0)
        scorecard.place(category: .threes, score: 15, yahtzeeBonus: 0)
        XCTAssertEqual(scorecard.upperBonus, YahtzeeScorer.upperBonusPoints)

        let advice = YahtzeeScorer.adviceCategory(dice: [5, 5, 5, 2, 3], scorecard: scorecard)
        XCTAssertEqual(advice, .threeOfAKind)
    }

    /// Kan de bonus zelfs met maximale worpen niet meer gehaald worden, dan
    /// heeft bovenin geen streepje voor meer.
    func testFallsBackToGreedyOnceBonusIsOutOfReach() {
        var scorecard = Scorecard()
        for category in [ScoreCategory.twos, .threes, .fours, .sixes] {
            scorecard.place(category: category, score: 0, yahtzeeBonus: 0)
        }
        // Open bovenin: enen (max 5) en vijven (max 25) — samen 30, ver onder 63.
        XCTAssertFalse(YahtzeeScorer.upperBonusStillPossible(scorecard: scorecard))

        let advice = YahtzeeScorer.adviceCategory(dice: [5, 5, 5, 2, 3], scorecard: scorecard)
        XCTAssertEqual(advice, .threeOfAKind)
    }

    /// Een grote combinatie onderin wint het ook van gewogen punten bovenin:
    /// de full house (25) verslaat de gewogen tweeën en drieën (elk ±9).
    func testBigLowerComboStillBeatsWeightedUpper() {
        let advice = YahtzeeScorer.adviceCategory(dice: [2, 2, 2, 3, 3], scorecard: Scorecard())
        XCTAssertEqual(advice, .fullHouse)
    }

    /// Levert elk open vakje nul op, dan is er geen tip.
    func testNoAdviceWhenEverythingScoresZero() {
        var scorecard = Scorecard()
        for category in ScoreCategory.allCases where category != .largeStraight {
            scorecard.place(category: category, score: 0, yahtzeeBonus: 0)
        }
        let advice = YahtzeeScorer.adviceCategory(dice: [1, 1, 2, 2, 3], scorecard: scorecard)
        XCTAssertNil(advice)
    }
}
