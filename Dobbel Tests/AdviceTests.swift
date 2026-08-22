import XCTest
@testable import Dobbel

/// De tip op het scoreblad: bovenin weegt zwaarder zolang de bonus haalbaar
/// is, en verder wint de hoogste opbrengst.
final class AdviceTests: XCTestCase {
    /// Drie vijven: "3 dezelfde" levert nu 20 op en de vijven 15, maar de
    /// vijven tellen mee voor de bonus en winnen dus als tip.
    func testPrefersUpperWhileBonusIsReachable() {
        let advice = DobbelScorer.adviceCategory(dice: [5, 5, 5, 2, 3], scorecard: Scorecard())
        XCTAssertEqual(advice, .fives)
    }

    /// Is de bonus al binnen, dan vervalt het streepje voor en wint de
    /// hoogste opbrengst weer.
    func testFallsBackToGreedyOnceBonusIsEarned() {
        var scorecard = Scorecard()
        scorecard.place(category: .sixes, score: 30, dobbelBonus: 0)
        scorecard.place(category: .fours, score: 20, dobbelBonus: 0)
        scorecard.place(category: .threes, score: 15, dobbelBonus: 0)
        XCTAssertEqual(scorecard.upperBonus, DobbelScorer.upperBonusPoints)

        let advice = DobbelScorer.adviceCategory(dice: [5, 5, 5, 2, 3], scorecard: scorecard)
        XCTAssertEqual(advice, .threeOfAKind)
    }

    /// Kan de bonus zelfs met maximale worpen niet meer gehaald worden, dan
    /// heeft bovenin geen streepje voor meer.
    func testFallsBackToGreedyOnceBonusIsOutOfReach() {
        var scorecard = Scorecard()
        for category in [ScoreCategory.twos, .threes, .fours, .sixes] {
            scorecard.place(category: category, score: 0, dobbelBonus: 0)
        }
        // Open bovenin: enen (max 5) en vijven (max 25) — samen 30, ver onder 63.
        XCTAssertFalse(DobbelScorer.upperBonusStillPossible(scorecard: scorecard))

        let advice = DobbelScorer.adviceCategory(dice: [5, 5, 5, 2, 3], scorecard: scorecard)
        XCTAssertEqual(advice, .threeOfAKind)
    }

    /// Een grote combinatie onderin wint het ook van gewogen punten bovenin:
    /// de full house (25) verslaat de gewogen tweeën en drieën (elk ±9).
    func testBigLowerComboStillBeatsWeightedUpper() {
        let advice = DobbelScorer.adviceCategory(dice: [2, 2, 2, 3, 3], scorecard: Scorecard())
        XCTAssertEqual(advice, .fullHouse)
    }

    /// Vier vijven terwijl de vijven al gevuld zijn: "3 dezelfde" en
    /// "4 dezelfde" zijn dan evenveel waard, maar het carré is zeldzamer en
    /// wint dus de tip — drie dezelfde gooi je later veel makkelijker nog eens.
    func testFourOfAKindWinsTieOverThreeOfAKind() {
        var scorecard = Scorecard()
        scorecard.place(category: .fives, score: 15, dobbelBonus: 0)

        let advice = DobbelScorer.adviceCategory(dice: [1, 5, 5, 5, 5], scorecard: scorecard)
        XCTAssertEqual(advice, .fourOfAKind)
    }

    /// Bij een gelijke stand tussen "3 dezelfde" en Kans wint "3 dezelfde":
    /// Kans scoort altijd en bewaar je dus liever voor een slechte worp.
    func testThreeOfAKindWinsTieOverChance() {
        var scorecard = Scorecard()
        scorecard.place(category: .sixes, score: 30, dobbelBonus: 0)
        scorecard.place(category: .fours, score: 20, dobbelBonus: 0)
        scorecard.place(category: .threes, score: 15, dobbelBonus: 0)
        scorecard.place(category: .twos, score: 0, dobbelBonus: 0)

        let advice = DobbelScorer.adviceCategory(dice: [2, 2, 2, 6, 5], scorecard: scorecard)
        XCTAssertEqual(advice, .threeOfAKind)
    }

    /// Levert elk open vakje nul op, dan is er geen tip.
    func testNoAdviceWhenEverythingScoresZero() {
        var scorecard = Scorecard()
        for category in ScoreCategory.allCases where category != .largeStraight {
            scorecard.place(category: category, score: 0, dobbelBonus: 0)
        }
        let advice = DobbelScorer.adviceCategory(dice: [1, 1, 2, 2, 3], scorecard: scorecard)
        XCTAssertNil(advice)
    }
}
