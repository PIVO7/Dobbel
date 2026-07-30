import Foundation

enum ScoreCategory: String, CaseIterable, Codable, Identifiable, Hashable {
    case ones
    case twos
    case threes
    case fours
    case fives
    case sixes
    case threeOfAKind
    case fourOfAKind
    case fullHouse
    case smallStraight
    case largeStraight
    case yahtzee
    case chance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ones: return "Enen"
        case .twos: return "Tweeën"
        case .threes: return "Drieën"
        case .fours: return "Vieren"
        case .fives: return "Vijven"
        case .sixes: return "Zessen"
        case .threeOfAKind: return "3 dezelfde"
        case .fourOfAKind: return "4 dezelfde"
        case .fullHouse: return "Vol huis"
        case .smallStraight: return "Kleine straat"
        case .largeStraight: return "Grote straat"
        case .yahtzee: return "Dobbel"
        case .chance: return "Kans"
        }
    }

    var isUpper: Bool {
        switch self {
        case .ones, .twos, .threes, .fours, .fives, .sixes:
            return true
        default:
            return false
        }
    }

    /// Het oog dat bij een vakje bovenin hoort; `nil` voor de onderkant.
    var faceValue: Int? {
        switch self {
        case .ones: return 1
        case .twos: return 2
        case .threes: return 3
        case .fours: return 4
        case .fives: return 5
        case .sixes: return 6
        default: return nil
        }
    }

    static let upper: [ScoreCategory] = [.ones, .twos, .threes, .fours, .fives, .sixes]
    static let lower: [ScoreCategory] = [
        .threeOfAKind, .fourOfAKind, .fullHouse, .smallStraight, .largeStraight, .yahtzee, .chance
    ]
}
