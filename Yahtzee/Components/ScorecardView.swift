import SwiftUI

/// Het hele scoreblad in twee kolommen, zodat alle dertien vakjes tegelijk in
/// beeld staan. De zevende rij links draagt de bonus; rechts loopt Chance daar
/// gewoon door, waardoor het raster sluit.
struct ScorecardView: View {
    let players: [GamePlayer]
    let currentPlayerID: UUID
    let diceValues: [Int]
    let canScore: Bool
    let onSelect: (ScoreCategory) -> Void

    private let rowHeight: CGFloat = 38
    private let iconWidth: CGFloat = 38

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            column(title: "BOVEN", categories: ScoreCategory.upper, showsBonus: true)
            column(title: "ONDER", categories: ScoreCategory.lower, showsBonus: false)
        }
        .padding(11)
        .toyBlock(fill: .white, radius: 20, depth: 5)
    }

    private var current: GamePlayer? {
        players.first { $0.id == currentPlayerID }
    }

    /// Advies van de scorer: alleen tonen als er echt gegooid is.
    private var bestCategory: ScoreCategory? {
        guard canScore, let current else { return nil }
        return YahtzeeScorer.bestCategory(dice: diceValues, scorecard: current.scorecard)
    }

    @ViewBuilder
    private func column(title: String, categories: [ScoreCategory], showsBonus: Bool) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppTheme.labelFont)
                .kerning(1.4)
                .foregroundStyle(AppTheme.faint)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 3)
                .padding(.bottom, 2)

            ForEach(categories) { category in
                row(for: category)
            }

            if showsBonus {
                bonusRow
            }
        }
    }

    private func row(for category: ScoreCategory) -> some View {
        HStack(spacing: 3) {
            CategoryIcon(category: category)
                .frame(width: iconWidth, height: rowHeight)

            ForEach(players) { player in
                cell(for: category, player: player)
            }
        }
    }

    @ViewBuilder
    private func cell(for category: ScoreCategory, player: GamePlayer) -> some View {
        let scored = player.scorecard.scores[category]
        let isMine = player.id == currentPlayerID
        let open = openCategories.contains(category)
        let selectable = isMine && canScore && open

        if selectable {
            let points = YahtzeeScorer.pointsForPlacing(
                category: category,
                dice: diceValues,
                scorecard: player.scorecard
            ).score
            let isBest = category == bestCategory

            Button {
                onSelect(category)
            } label: {
                Text("\(points)")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(isBest ? .white : AppTheme.coral)
                    .frame(maxWidth: .infinity)
                    .frame(height: rowHeight)
            }
            .buttonStyle(ToyButtonStyle(
                fill: isBest ? AppTheme.mint : .white,
                radius: 11,
                depth: isBest ? 3 : 0,
                border: 2
            ))
            .accessibilityLabel("\(category.title), \(points) punten\(isBest ? ", beste zet" : "")")
        } else {
            Text(scored.map { "\($0)" } ?? "–")
                .font(AppTheme.bodyFont)
                .foregroundStyle(scored == nil ? AppTheme.dim : AppTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: rowHeight)
                .toyBlock(fill: AppTheme.sunk, radius: 11, depth: 0, border: 2)
                .accessibilityLabel("\(category.title), \(scored.map { "\($0) punten" } ?? "leeg")")
        }
    }

    private var bonusRow: some View {
        HStack(spacing: 3) {
            VStack(spacing: 0) {
                Text("BONUS")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .kerning(0.6)
                    .foregroundStyle(AppTheme.soft)
                Text("+35")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
            }
            .frame(width: iconWidth, height: rowHeight)
            .toyBlock(fill: AppTheme.tintStone, radius: 11, depth: 0, border: 2)

            ForEach(players) { player in
                let subtotal = player.scorecard.upperSubtotal
                let reached = player.scorecard.upperBonus > 0
                Text(reached ? "+35" : "\(subtotal)/63")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(reached ? AppTheme.mint : AppTheme.soft)
                    .frame(maxWidth: .infinity)
                    .frame(height: rowHeight)
                    .toyBlock(fill: AppTheme.sunk, radius: 11, depth: 0, border: 2)
                    .accessibilityLabel(
                        reached
                            ? "Bonus behaald, 35 punten"
                            : "Bonus bij 63, nu \(subtotal)"
                    )
            }
        }
    }

    private var openCategories: [ScoreCategory] {
        guard let current else { return [] }
        return YahtzeeScorer.availableCategories(dice: diceValues, scorecard: current.scorecard)
    }
}

/// De icoontegel links van elke rij: ogen voor de bovenkant, een symbool voor
/// de onderkant.
struct CategoryIcon: View {
    let category: ScoreCategory

    var body: some View {
        content
            .foregroundStyle(inkColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toyBlock(fill: tint, radius: 11, depth: 0, border: 2)
            .accessibilityLabel(category.title)
    }

    @ViewBuilder
    private var content: some View {
        switch category {
        case .ones, .twos, .threes, .fours, .fives, .sixes:
            DiePips(value: face, inset: 4)
        case .threeOfAKind:
            Text("3×").font(.system(size: 13, weight: .black, design: .rounded))
        case .fourOfAKind:
            Text("4×").font(.system(size: 13, weight: .black, design: .rounded))
        case .fullHouse:
            Image(systemName: "house.fill").font(.system(size: 14, weight: .black))
        case .smallStraight:
            StraightGlyph(bars: 4).padding(9)
        case .largeStraight:
            StraightGlyph(bars: 5).padding(9)
        case .yahtzee:
            Image(systemName: "star.fill").font(.system(size: 15, weight: .black))
        case .chance:
            Text("?").font(.system(size: 15, weight: .black, design: .rounded))
        }
    }

    private var face: Int {
        switch category {
        case .ones: return 1
        case .twos: return 2
        case .threes: return 3
        case .fours: return 4
        case .fives: return 5
        default: return 6
        }
    }

    private var tint: Color {
        if category == .yahtzee { return AppTheme.tintCoral }
        return category.isUpper ? AppTheme.tintAmber : AppTheme.tintSky
    }

    private var inkColor: Color {
        if category == .yahtzee { return AppTheme.coral }
        return category.isUpper ? AppTheme.ink : AppTheme.sky
    }
}
