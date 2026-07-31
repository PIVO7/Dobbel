import Foundation

enum YahtzeeScorer {
    static let upperBonusThreshold = 63
    static let upperBonusPoints = 35
    static let yahtzeePoints = 50
    static let yahtzeeBonusPoints = 100
    static let fullHousePoints = 25
    static let smallStraightPoints = 30
    static let largeStraightPoints = 40

    static func counts(for dice: [Int]) -> [Int: Int] {
        Dictionary(grouping: dice, by: { $0 }).mapValues(\.count)
    }

    static func isYahtzee(_ dice: [Int]) -> Bool {
        guard dice.count == 5 else { return false }
        return Set(dice).count == 1
    }

    static func score(category: ScoreCategory, dice: [Int], asJoker: Bool = false) -> Int {
        precondition(dice.count == 5)
        let values = dice.sorted()
        let tally = counts(for: values)

        if asJoker {
            switch category {
            case .ones: return values.filter { $0 == 1 }.reduce(0, +)
            case .twos: return values.filter { $0 == 2 }.reduce(0, +)
            case .threes: return values.filter { $0 == 3 }.reduce(0, +)
            case .fours: return values.filter { $0 == 4 }.reduce(0, +)
            case .fives: return values.filter { $0 == 5 }.reduce(0, +)
            case .sixes: return values.filter { $0 == 6 }.reduce(0, +)
            case .threeOfAKind, .fourOfAKind, .chance:
                return values.reduce(0, +)
            case .fullHouse:
                return fullHousePoints
            case .smallStraight:
                return smallStraightPoints
            case .largeStraight:
                return largeStraightPoints
            case .yahtzee:
                return yahtzeePoints
            }
        }

        switch category {
        case .ones: return values.filter { $0 == 1 }.reduce(0, +)
        case .twos: return values.filter { $0 == 2 }.reduce(0, +)
        case .threes: return values.filter { $0 == 3 }.reduce(0, +)
        case .fours: return values.filter { $0 == 4 }.reduce(0, +)
        case .fives: return values.filter { $0 == 5 }.reduce(0, +)
        case .sixes: return values.filter { $0 == 6 }.reduce(0, +)
        case .threeOfAKind:
            return tally.values.contains(where: { $0 >= 3 }) ? values.reduce(0, +) : 0
        case .fourOfAKind:
            return tally.values.contains(where: { $0 >= 4 }) ? values.reduce(0, +) : 0
        case .fullHouse:
            let counts = Set(tally.values)
            return counts == [2, 3] ? fullHousePoints : 0
        case .smallStraight:
            return hasStraight(values, length: 4) ? smallStraightPoints : 0
        case .largeStraight:
            return hasStraight(values, length: 5) ? largeStraightPoints : 0
        case .yahtzee:
            return isYahtzee(values) ? yahtzeePoints : 0
        case .chance:
            return values.reduce(0, +)
        }
    }

    /// De jokerregel: is het Dobbel-vakje al gevuld — ook met een nul — dan
    /// moet een nieuwe Dobbel eerst naar het bijpassende vakje bovenin, en
    /// mag hij anders als joker in een vast vakje onderin. De 100-punten-
    /// bonus blijft apart voorbehouden aan een échte 50 (zie
    /// `pointsForPlacing`).
    static func canUseJoker(dice: [Int], scorecard: Scorecard) -> Bool {
        guard isYahtzee(dice) else { return false }
        guard scorecard.scores[.yahtzee] != nil else { return false }
        return true
    }

    static func availableCategories(dice: [Int], scorecard: Scorecard) -> [ScoreCategory] {
        let open = ScoreCategory.allCases.filter { scorecard.scores[$0] == nil }
        guard canUseJoker(dice: dice, scorecard: scorecard), let face = dice.first,
              let upperForFace = ScoreCategory.upper.first(where: { $0.faceValue == face }) else {
            return open
        }

        if open.contains(upperForFace) {
            return [upperForFace]
        }
        return open
    }

    static func pointsForPlacing(
        category: ScoreCategory,
        dice: [Int],
        scorecard: Scorecard
    ) -> (score: Int, yahtzeeBonus: Int) {
        let joker = canUseJoker(dice: dice, scorecard: scorecard) && category != .yahtzee
        let score = score(category: category, dice: dice, asJoker: joker)
        let bonus: Int
        if isYahtzee(dice), scorecard.scores[.yahtzee] == yahtzeePoints {
            bonus = yahtzeeBonusPoints
        } else {
            bonus = 0
        }
        return (score, bonus)
    }

    /// Nog waar om voor te spelen: de bonus is niet binnen, maar met de open
    /// vakjes bovenin valt de drempel nog te halen.
    static func upperBonusStillPossible(scorecard: Scorecard) -> Bool {
        guard scorecard.upperBonus == 0 else { return false }
        let openMaximum = ScoreCategory.upper
            .filter { scorecard.scores[$0] == nil }
            .compactMap(\.faceValue)
            .reduce(0) { $0 + 5 * $1 }
        return scorecard.upperSubtotal + openMaximum >= upperBonusThreshold
    }

    /// De tip voor de speler, of `nil` als elke open categorie nul oplevert.
    ///
    /// Niet simpelweg de hoogste opbrengst: zolang de bonus haalbaar is telt
    /// elk punt bovenin ongeveer 35/63e extra mee, want het brengt de +35
    /// dichterbij. Drie vijven wijzen dan naar de vijven, ook al levert
    /// "3 dezelfde" nu een paar punten meer op. Het blijft een vuistregel —
    /// de speler mag altijd iets anders kiezen.
    static func adviceCategory(dice: [Int], scorecard: Scorecard) -> ScoreCategory? {
        adviceCategory(
            dice: dice,
            scorecard: scorecard,
            open: availableCategories(dice: dice, scorecard: scorecard)
        )
    }

    /// Dezelfde tip, voor een aanroeper die de open vakjes al berekend heeft
    /// en de scorer niet nogmaals wil laten draaien.
    static func adviceCategory(
        dice: [Int],
        scorecard: Scorecard,
        open: [ScoreCategory]
    ) -> ScoreCategory? {
        let bonusWeight = upperBonusStillPossible(scorecard: scorecard)
            ? Double(upperBonusPoints) / Double(upperBonusThreshold)
            : 0

        var best: (category: ScoreCategory, value: Double)?
        for category in open {
            let score = pointsForPlacing(category: category, dice: dice, scorecard: scorecard).score
            guard score > 0 else { continue }
            var value = Double(score)
            if category.isUpper {
                value += Double(score) * bonusWeight
            }
            if value > (best?.value ?? 0) {
                best = (category, value)
            }
        }
        return best?.category
    }

    private static func hasStraight(_ values: [Int], length: Int) -> Bool {
        let unique = Array(Set(values)).sorted()
        guard unique.count >= length else { return false }
        for start in 0...(unique.count - length) {
            let slice = unique[start..<(start + length)]
            let first = slice.first!
            if zip(slice, first...).allSatisfy({ $0.0 == $0.1 }) {
                return true
            }
        }
        return false
    }
}
