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
            var text: String
            if count == 1 {
                // Alleen bij één "een" is de score precies 1 punt; dan hoort
                // er ook enkelvoud te staan.
                text = score == 1
                    ? String(localized: "Je hebt één \(faceName(face, count: 1)): 1 punt.")
                    : String(localized: "Je hebt één \(faceName(face, count: 1)): \(score) punten.")
            } else {
                text = String(localized: "Je hebt \(count) \(faceName(face, count: count)): samen \(score) punten.")
            }
            if YahtzeeScorer.upperBonusStillPossible(scorecard: scorecard) {
                text += " " + String(localized: "En alles bovenin helpt voor de +35-bonus bij 63!")
            }
            return text
        case .threeOfAKind:
            return String(localized: "Drie dezelfde! Dan mag je álle ogen optellen: \(score) punten.")
        case .fourOfAKind:
            return String(localized: "Vier dezelfde! Dan mag je álle ogen optellen: \(score) punten.")
        case .fullHouse:
            // Via de jokerregel kan een tweede Dobbel hier terecht; dan ligt
            // er natuurlijk geen echt vol huis.
            if YahtzeeScorer.canUseJoker(dice: dice, scorecard: scorecard) {
                return String(localized: "Nog eens vijf dezelfde! De jokerregel laat die als vol huis tellen: 25 punten.")
            }
            return String(localized: "Twee én drie dezelfde — een vol huis! Dat is altijd 25 punten.")
        case .smallStraight:
            if YahtzeeScorer.canUseJoker(dice: dice, scorecard: scorecard) {
                return String(localized: "Nog eens vijf dezelfde! De jokerregel laat die als kleine straat tellen: 30 punten.")
            }
            return String(localized: "Vier stenen op een rij — een kleine straat, goed voor 30 punten.")
        case .largeStraight:
            if YahtzeeScorer.canUseJoker(dice: dice, scorecard: scorecard) {
                return String(localized: "Nog eens vijf dezelfde! De jokerregel laat die als grote straat tellen: 40 punten.")
            }
            return String(localized: "Vijf stenen op een rij — een grote straat! De volle 40 punten.")
        case .yahtzee:
            return String(localized: "Vijf dezelfde — DOBBEL! Het duurste vakje van het blad: 50 punten.")
        case .chance:
            return String(localized: "Bij het vraagteken tellen alle ogen gewoon op: \(score) punten. Handig als er niets beters past.")
        }
    }

    private static func faceName(_ face: Int, count: Int) -> String {
        switch (face, count == 1) {
        case (1, true): return String(localized: "een")
        case (2, true): return String(localized: "twee")
        case (3, true): return String(localized: "drie")
        case (4, true): return String(localized: "vier")
        case (5, true): return String(localized: "vijf")
        case (6, true): return String(localized: "zes")
        case (1, false): return String(localized: "enen")
        case (2, false): return String(localized: "tweeën")
        case (3, false): return String(localized: "drieën")
        case (4, false): return String(localized: "vieren")
        case (5, false): return String(localized: "vijven")
        case (6, false): return String(localized: "zessen")
        default: return ""
        }
    }
}
