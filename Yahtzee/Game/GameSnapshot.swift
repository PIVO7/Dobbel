import Foundation

/// Serialiseerbare snapshot van een lopend spel, zodat kids kunnen hervatten.
struct GameSnapshot: Codable, Equatable {
    var mode: GameMode
    var players: [GamePlayer]
    var currentPlayerIndex: Int
    var dice: [Die]
    var rollsRemaining: Int
    var hasRolledThisTurn: Bool
    var turnMessage: String
    var savedAt: Date

    var summaryTitle: String {
        let names = players.filter { !$0.isComputer }.map(\.name)
        switch mode {
        case .versusComputer:
            return names.first.map { String(localized: "\($0) vs Computer") } ?? mode.title
        case .versusFriends:
            return names.joined(separator: " · ")
        }
    }
}
