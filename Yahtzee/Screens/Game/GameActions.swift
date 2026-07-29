import Foundation

/// Wat een speler tijdens een beurt kan doen, gebundeld zodat de indelingen
/// het door kunnen geven zonder vier losse closures in hun signatuur.
struct GameActions {
    var toggleHold: (UUID) -> Void
    var score: (ScoreCategory) -> Void
    var roll: () -> Void
    var requestClose: () -> Void
}
