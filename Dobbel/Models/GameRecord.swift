import Foundation

/// Eén afgerond potje in de geschiedenis van een profiel: genoeg voor het
/// grafiekje en de trofeeën, niet meer dan dat.
struct GameRecord: Codable, Equatable, Hashable {
    var score: Int
    var won: Bool
    var date: Date
}
