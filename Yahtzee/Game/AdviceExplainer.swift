import Foundation

/// Vertaalt de tip van de scorer naar kindertaal: niet alleen wát het beste
/// vakje is, maar waaróm. Zo leert een kind spelenderwijs de strategie.
enum AdviceExplainer {
    static func explain(category: ScoreCategory, dice: [Int], scorecard: Scorecard) -> String {
        let score = YahtzeeScorer.pointsForPlacing(
            category: category,
            dice: dice,
            scorecard: scorecard
        ).score

        switch category {
        case .ones, .twos, .threes, .fours, .fives, .sixes:
            let face = category.faceValue ?? 1
            let count = dice.filter { $0 == face }.count
            var text = count == 1
                ? "Je hebt één \(faceName(face, count: 1)): \(score) punt\(score == 1 ? "" : "en")."
                : "Je hebt \(count) \(faceName(face, count: count)): samen \(score) punten."
            if YahtzeeScorer.upperBonusStillPossible(scorecard: scorecard) {
                text += " En alles bovenin helpt voor de +35-bonus bij 63!"
            }
            return text
        case .threeOfAKind:
            return "Drie dezelfde! Dan mag je álle ogen optellen: \(score) punten."
        case .fourOfAKind:
            return "Vier dezelfde! Dan mag je álle ogen optellen: \(score) punten."
        case .fullHouse:
            return "Twee én drie dezelfde — een vol huis! Dat is altijd 25 punten."
        case .smallStraight:
            return "Vier stenen op een rij — een kleine straat, goed voor 30 punten."
        case .largeStraight:
            return "Vijf stenen op een rij — een grote straat! De volle 40 punten."
        case .yahtzee:
            return "Vijf dezelfde — DOBBEL! Het duurste vakje van het blad: 50 punten."
        case .chance:
            return "Bij het vraagteken tellen alle ogen gewoon op: \(score) punten. Handig als er niets beters past."
        }
    }

    private static func faceName(_ face: Int, count: Int) -> String {
        let singular = ["een", "twee", "drie", "vier", "vijf", "zes"]
        let plural = ["enen", "tweeën", "drieën", "vieren", "vijven", "zessen"]
        guard (1...6).contains(face) else { return "" }
        return count == 1 ? singular[face - 1] : plural[face - 1]
    }
}
