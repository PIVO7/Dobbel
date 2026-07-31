import Foundation

/// Zet een worp om in één zin die een kind meteen begrijpt: "Drie vijven!".
/// Puur presentatie — hier zitten geen spelregels in.
enum RollPhrase {
    /// De enige zin die het spelscherm apart behandelt — hij kleurt mee en
    /// zet een viering in gang, dus staat hij hier in plaats van los in de UI.
    static let yahtzee = "DOBBEL!"

    private static let faceNames = [
        1: "enen", 2: "tweeën", 3: "drieën", 4: "vieren", 5: "vijven", 6: "zessen"
    ]
    private static let countNames = [
        2: "Twee", 3: "Drie", 4: "Vier", 5: "Vijf"
    ]

    /// Wat er boven het scoreblad staat. Aan het begin van een beurt liggen de
    /// stenen op 1-1-1-1-1; dat is geen worp en mag dus niet als "DOBBEL!"
    /// worden voorgelezen.
    static func callout(dice: [Int], isRolling: Bool, hasRolled: Bool, isComputer: Bool) -> String {
        if isRolling { return "…" }
        guard hasRolled else { return isComputer ? "Even wachten…" : "Gooi maar!" }
        return describe(dice)
    }

    static func describe(_ dice: [Int]) -> String {
        guard dice.count == 5 else { return "" }

        if YahtzeeScorer.isYahtzee(dice) { return yahtzee }
        if YahtzeeScorer.score(category: .largeStraight, dice: dice) > 0 { return "Grote straat!" }
        if YahtzeeScorer.score(category: .smallStraight, dice: dice) > 0 { return "Kleine straat!" }
        if YahtzeeScorer.score(category: .fullHouse, dice: dice) > 0 { return "Vol huis!" }

        let tally = YahtzeeScorer.counts(for: dice)
        // Bij gelijk aantal wint het hoogste oog: "Twee zessen" boven "Twee enen".
        let top = tally.max { lhs, rhs in
            lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value < rhs.value
        }

        guard let top, top.value > 1, let count = countNames[top.value],
              let face = faceNames[top.key] else {
            return "Niets gelijk"
        }
        return "\(count) \(face)!"
    }
}
