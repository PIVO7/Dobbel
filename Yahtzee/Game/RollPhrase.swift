import Foundation

/// Zet een worp om in één zin die een kind meteen begrijpt: "Drie vijven!".
/// Puur presentatie — hier zitten geen spelregels in.
enum RollPhrase {
    /// De enige zin die het spelscherm apart behandelt — hij kleurt mee en
    /// zet een viering in gang, dus staat hij hier in plaats van los in de UI.
    /// "DOBBEL!" is de merknaam en blijft in elke taal hetzelfde.
    static let yahtzee = "DOBBEL!"

    /// Wat er boven het scoreblad staat. Aan het begin van een beurt liggen de
    /// stenen op 1-1-1-1-1; dat is geen worp en mag dus niet als "DOBBEL!"
    /// worden voorgelezen.
    static func callout(dice: [Int], isRolling: Bool, hasRolled: Bool, isComputer: Bool) -> String {
        if isRolling { return "…" }
        guard hasRolled else {
            return isComputer
                ? String(localized: "Even wachten…")
                : String(localized: "Gooi maar!")
        }
        return describe(dice)
    }

    static func describe(_ dice: [Int]) -> String {
        guard dice.count == 5 else { return "" }

        if YahtzeeScorer.isYahtzee(dice) { return yahtzee }
        if YahtzeeScorer.score(category: .largeStraight, dice: dice) > 0 { return String(localized: "Grote straat!") }
        if YahtzeeScorer.score(category: .smallStraight, dice: dice) > 0 { return String(localized: "Kleine straat!") }
        if YahtzeeScorer.score(category: .fullHouse, dice: dice) > 0 { return String(localized: "Vol huis!") }

        let tally = YahtzeeScorer.counts(for: dice)
        // Bij gelijk aantal wint het hoogste oog: "Twee zessen" boven "Twee enen".
        let top = tally.max { lhs, rhs in
            lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value < rhs.value
        }

        guard let top, top.value > 1, let count = countWord(top.value),
              let face = faceWord(top.key) else {
            return String(localized: "Niets gelijk")
        }
        return String(localized: "\(count) \(face)!")
    }

    private static func countWord(_ count: Int) -> String? {
        switch count {
        case 2: return String(localized: "Twee")
        case 3: return String(localized: "Drie")
        case 4: return String(localized: "Vier")
        case 5: return String(localized: "Vijf")
        default: return nil
        }
    }

    private static func faceWord(_ face: Int) -> String? {
        switch face {
        case 1: return String(localized: "enen")
        case 2: return String(localized: "tweeën")
        case 3: return String(localized: "drieën")
        case 4: return String(localized: "vieren")
        case 5: return String(localized: "vijven")
        case 6: return String(localized: "zessen")
        default: return nil
        }
    }
}
