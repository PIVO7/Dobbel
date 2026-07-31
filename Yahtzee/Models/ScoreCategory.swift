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
        case .ones: return String(localized: "Enen")
        case .twos: return String(localized: "Tweeën")
        case .threes: return String(localized: "Drieën")
        case .fours: return String(localized: "Vieren")
        case .fives: return String(localized: "Vijven")
        case .sixes: return String(localized: "Zessen")
        case .threeOfAKind: return String(localized: "3 dezelfde")
        case .fourOfAKind: return String(localized: "4 dezelfde")
        case .fullHouse: return String(localized: "Vol huis")
        case .smallStraight: return String(localized: "Kleine straat")
        case .largeStraight: return String(localized: "Grote straat")
        case .yahtzee: return String(localized: "Dobbel")
        case .chance: return String(localized: "Kans")
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
