import Foundation

struct Scorecard: Equatable, Codable {
    var scores: [ScoreCategory: Int] = [:]
    var dobbelBonusTotal: Int = 0

    // De JSON-sleutel blijft de oude naam, anders raakt een bestaand
    // bewaard spel zijn bonuspunten kwijt.
    private enum CodingKeys: String, CodingKey {
        case scores
        case dobbelBonusTotal = "yahtzeeBonusTotal"
    }

    var upperSubtotal: Int {
        ScoreCategory.upper.compactMap { scores[$0] }.reduce(0, +)
    }

    var upperBonus: Int {
        upperSubtotal >= DobbelScorer.upperBonusThreshold ? DobbelScorer.upperBonusPoints : 0
    }

    var lowerSubtotal: Int {
        ScoreCategory.lower.compactMap { scores[$0] }.reduce(0, +)
    }

    var total: Int {
        upperSubtotal + upperBonus + lowerSubtotal + dobbelBonusTotal
    }

    var isComplete: Bool {
        ScoreCategory.allCases.allSatisfy { scores[$0] != nil }
    }

    var filledCount: Int {
        scores.count
    }

    /// Het eerste lege vakje van boven naar onder — het enige dat bij
    /// "In volgorde" gevuld mag worden.
    var nextOpenCategory: ScoreCategory? {
        ScoreCategory.allCases.first { scores[$0] == nil }
    }

    mutating func place(category: ScoreCategory, score: Int, dobbelBonus: Int) {
        precondition(scores[category] == nil)
        scores[category] = score
        dobbelBonusTotal += dobbelBonus
    }
}
