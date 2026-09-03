import Foundation

/// Wat er groot boven de stenen staat. Puur presentatie — hier zitten geen
/// spelregels in. Bewust géén worp-in-woorden meer ("Grote straat!", "Drie
/// vijven!"): dat las als advies, terwijl je soms beter iets anders kiest.
/// Alleen DOBBEL! blijft — dat is het feest, geen tip.
enum RollPhrase {
    /// De enige zin die het spelscherm apart behandelt — hij kleurt mee en
    /// zet een viering in gang, dus staat hij hier in plaats van los in de UI.
    /// "DOBBEL!" is de merknaam en blijft in elke taal hetzelfde.
    static let dobbel = "DOBBEL!"

    /// Bij In volgorde valt er niets te kiezen; dan mag er wél staan wat de
    /// worp waard is voor het vakje dat aan de beurt is.
    struct Target {
        let category: ScoreCategory
        let points: Int
    }

    /// Wat er boven het scoreblad staat. Aan het begin van een beurt liggen de
    /// stenen op 1-1-1-1-1; dat is geen worp en mag dus niet als "DOBBEL!"
    /// worden voorgelezen. Na een gewone worp staat er niets: het blad zelf
    /// laat zien wat elk vakje oplevert.
    static func callout(
        dice: [Int],
        isRolling: Bool,
        hasRolled: Bool,
        isComputer: Bool,
        target: Target? = nil
    ) -> String {
        if isRolling { return "…" }
        guard hasRolled else {
            return isComputer
                ? String(localized: "Even wachten…")
                : String(localized: "Gooi maar!")
        }
        if DobbelScorer.isDobbel(dice) { return dobbel }
        if let target {
            return String(localized: "\(target.category.title): \(target.points) punten")
        }
        return ""
    }
}
