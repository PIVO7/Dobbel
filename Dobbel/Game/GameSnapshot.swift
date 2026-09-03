import Foundation

/// Serialiseerbare snapshot van een lopend spel, zodat kids kunnen hervatten.
struct GameSnapshot: Codable, Equatable {
    var mode: GameMode
    /// Optioneel zodat bewaarde spellen van vóór de spelvormen blijven
    /// laden; die waren allemaal klassiek.
    var variant: GameVariant?
    var players: [GamePlayer]
    /// Wie dit potje begon; optioneel zodat oudere bewaarde spellen zonder
    /// dit veld gewoon blijven laden (dan geldt speler 0).
    var startingPlayerIndex: Int?
    var currentPlayerIndex: Int
    var dice: [Die]
    var rollsRemaining: Int
    var hasRolledThisTurn: Bool
    var turnMessage: String
    var savedAt: Date

    var summaryTitle: String {
        let names = players.filter { !$0.isComputer }.map(\.name)
        let base: String
        switch mode {
        case .versusComputer:
            base = names.first.map { String(localized: "\($0) vs Computer") } ?? mode.title
        case .versusFriends:
            base = names.joined(separator: " · ")
        }
        guard let variant, variant != .classic else { return base }
        return "\(base) · \(variant.title)"
    }
}
