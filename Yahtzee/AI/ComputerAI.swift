import Foundation

struct ComputerAI {
    func decide(
        dice: [Die],
        rollsRemaining: Int,
        scorecard: Scorecard,
        level: ComputerLevel = .medium
    ) -> ComputerDecision {
        let values = dice.map(\.value)
        let open = YahtzeeScorer.availableCategories(dice: values, scorecard: scorecard)

        if level == .easy {
            return decideEasy(values: values, open: open, rollsRemaining: rollsRemaining, scorecard: scorecard)
        }

        if rollsRemaining == 0 {
            return ComputerDecision(
                holdMask: dice.map(\.isHeld),
                shouldScore: true,
                category: bestCategory(values: values, open: open, scorecard: scorecard, level: level)
            )
        }

        // If we already have a strong scoreable Yahtzee / large straight, take it.
        if YahtzeeScorer.isYahtzee(values), open.contains(.yahtzee) || YahtzeeScorer.canUseJoker(dice: values, scorecard: scorecard) {
            return ComputerDecision(
                holdMask: Array(repeating: true, count: 5),
                shouldScore: true,
                category: bestCategory(values: values, open: open, scorecard: scorecard, level: level)
            )
        }

        let large = YahtzeeScorer.score(category: .largeStraight, dice: values)
        if large > 0, open.contains(.largeStraight) {
            return ComputerDecision(
                holdMask: Array(repeating: true, count: 5),
                shouldScore: true,
                category: .largeStraight
            )
        }

        if rollsRemaining == 1 {
            let best = bestCategory(values: values, open: open, scorecard: scorecard, level: level)
            let expected = best.map { YahtzeeScorer.pointsForPlacing(category: $0, dice: values, scorecard: scorecard).score } ?? 0
            // Keep rolling only if current best is weak and we still have a roll.
            // De professor legt de lat hoger en gokt vaker op de laatste worp.
            if expected >= (level == .hard ? 25 : 20) {
                return ComputerDecision(holdMask: holdMaskFor(values: values), shouldScore: true, category: best)
            }
        }

        return ComputerDecision(
            holdMask: holdMaskFor(values: values),
            shouldScore: false,
            category: nil
        )
    }

    /// Dommel: houdt alleen drie-of-meer dezelfde vast, ziet geen straten of
    /// paren, en kiest op het eind gewoon wat nu het meest oplevert — zonder
    /// dure vakjes te beschermen. Eén uitzondering: een Dobbel pakt hij wel,
    /// anders wordt het gênant.
    private func decideEasy(
        values: [Int],
        open: [ScoreCategory],
        rollsRemaining: Int,
        scorecard: Scorecard
    ) -> ComputerDecision {
        if YahtzeeScorer.isYahtzee(values), open.contains(.yahtzee) {
            return ComputerDecision(
                holdMask: Array(repeating: true, count: 5),
                shouldScore: true,
                category: .yahtzee
            )
        }

        if rollsRemaining == 0 {
            let category = open.max { lhs, rhs in
                let l = YahtzeeScorer.pointsForPlacing(category: lhs, dice: values, scorecard: scorecard).score
                let r = YahtzeeScorer.pointsForPlacing(category: rhs, dice: values, scorecard: scorecard).score
                if l == r { return categoryPriority(lhs) > categoryPriority(rhs) }
                return l < r
            }
            return ComputerDecision(holdMask: values.map { _ in false }, shouldScore: true, category: category)
        }

        let counts = YahtzeeScorer.counts(for: values)
        if let (face, count) = counts.max(by: { $0.value < $1.value }), count >= 3 {
            return ComputerDecision(holdMask: values.map { $0 == face }, shouldScore: false, category: nil)
        }
        return ComputerDecision(holdMask: values.map { _ in false }, shouldScore: false, category: nil)
    }

    private func holdMaskFor(values: [Int]) -> [Bool] {
        let counts = YahtzeeScorer.counts(for: values)
        let bestFace = counts.max { lhs, rhs in
            if lhs.value == rhs.value { return lhs.key < rhs.key }
            return lhs.value < rhs.value
        }?.key

        // Prefer holding the most frequent face; for near-straights hold sequential.
        if let straightHold = straightHoldMask(values: values) {
            return straightHold
        }

        guard let bestFace else {
            return Array(repeating: false, count: values.count)
        }
        return values.map { $0 == bestFace }
    }

    private func straightHoldMask(values: [Int]) -> [Bool]? {
        let unique = Set(values)
        let candidates: [Set<Int>] = [
            [1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6],
            [1, 2, 3, 4, 5], [2, 3, 4, 5, 6]
        ]
        guard let best = candidates.max(by: { $0.intersection(unique).count < $1.intersection(unique).count }),
              best.intersection(unique).count >= 3 else {
            return nil
        }

        var used: [Int: Int] = [:]
        return values.map { value in
            let keep = best.contains(value) && (used[value] ?? 0) == 0
            if keep { used[value, default: 0] += 1 }
            return keep
        }
    }

    private func bestCategory(
        values: [Int],
        open: [ScoreCategory],
        scorecard: Scorecard,
        level: ComputerLevel = .medium
    ) -> ScoreCategory? {
        guard !open.isEmpty else { return nil }

        return open.max { lhs, rhs in
            let l = utility(category: lhs, values: values, scorecard: scorecard, level: level)
            let r = utility(category: rhs, values: values, scorecard: scorecard, level: level)
            if l == r {
                // Prefer dumping zeros into chance last; prefer upper when equal.
                return categoryPriority(lhs) < categoryPriority(rhs)
            }
            return l < r
        }
    }

    private func utility(
        category: ScoreCategory,
        values: [Int],
        scorecard: Scorecard,
        level: ComputerLevel = .medium
    ) -> Double {
        let result = YahtzeeScorer.pointsForPlacing(category: category, dice: values, scorecard: scorecard)
        var score = Double(result.score + result.yahtzeeBonus)

        // Prefer scoring meaningful upper faces toward the bonus.
        if category.isUpper, result.score > 0 {
            score += 2
        }

        // De professor rekent de bonus bovenin mee, net als de tip voor de
        // speler: elk punt bovenin telt extra zolang de +35 haalbaar is.
        if level == .hard, category.isUpper, result.score > 0,
           YahtzeeScorer.upperBonusStillPossible(scorecard: scorecard) {
            score += Double(result.score) * Double(YahtzeeScorer.upperBonusPoints) / Double(YahtzeeScorer.upperBonusThreshold)
        }

        // Avoid wasting Yahtzee box on zero when alternatives exist.
        if category == .yahtzee, result.score == 0 {
            score -= 40
        }

        // Prefer not zeroing valuable fixed boxes early.
        if result.score == 0 {
            switch category {
            case .yahtzee, .largeStraight, .smallStraight, .fullHouse:
                score -= 15
            default:
                score -= 3
            }
        }

        return score
    }

    private func categoryPriority(_ category: ScoreCategory) -> Int {
        switch category {
        case .chance: return 0
        case .ones: return 1
        case .twos: return 2
        case .threes: return 3
        case .fours: return 4
        case .fives: return 5
        case .sixes: return 6
        case .threeOfAKind: return 7
        case .fourOfAKind: return 8
        case .fullHouse: return 9
        case .smallStraight: return 10
        case .largeStraight: return 11
        case .yahtzee: return 12
        }
    }
}
