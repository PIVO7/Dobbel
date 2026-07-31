import Foundation

/// Wat de computer met een worp wil: vasthouden en doorgooien, of scoren.
struct ComputerDecision: Equatable {
    var holdMask: [Bool]
    var shouldScore: Bool
    var category: ScoreCategory?
}
