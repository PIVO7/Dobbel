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

    @Environment(\.metrics) private var m

    var body: some View {
        // Eén keer per hertekening rekenen. Als computed property werd de scorer
        // per vakje opnieuw aangeroepen — dertien keer per kolom, en tijdens de
        // gooianimatie acht keer per worp.
        let open = openCategories
        let best = bestCategory(open: open)

        return HStack(alignment: .top, spacing: m.gutter * 0.6) {
            column(title: "BOVEN", categories: ScoreCategory.upper, showsBonus: true, open: open, best: best)
            column(title: "ONDER", categories: ScoreCategory.lower, showsBonus: false, open: open, best: best)
        }
        .padding(m.gutter * 0.8)
        .toyBlock(fill: .white, radius: m.cardCorner, depth: m.depth, border: m.border)
    }

    private var current: GamePlayer? {
        players.first { $0.id == currentPlayerID }
    }

    private var openCategories: Set<ScoreCategory> {
        guard let current else { return [] }
        return Set(YahtzeeScorer.availableCategories(dice: diceValues, scorecard: current.scorecard))
    }

    /// Advies van de scorer: alleen tonen als er echt gegooid is.
    private func bestCategory(open: Set<ScoreCategory>) -> ScoreCategory? {
        guard canScore, !open.isEmpty, let current else { return nil }
        return YahtzeeScorer.bestCategory(dice: diceValues, scorecard: current.scorecard)
    }

    private func column(
        title: String,
        categories: [ScoreCategory],
        showsBonus: Bool,
        open: Set<ScoreCategory>,
        best: ScoreCategory?
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppTheme.rounded(m.captionSize * 0.9))
                .kerning(1.4)
                .foregroundStyle(AppTheme.faint)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 3)
                .padding(.bottom, 2)

            playerHeader

            ForEach(categories) { category in
                row(for: category, open: open, best: best)
            }

            if showsBonus {
                bonusRow
            }
        }
    }

    /// Boven elke kolom staat wie hem vult; zonder dat raak je bij drie of vier
    /// spelers het spoor bijster welke kolom van jou is.
    private var playerHeader: some View {
        HStack(spacing: 3) {
            Color.clear
                .frame(width: m.iconWidth, height: max(m.rowHeight - 4, 28))

            ForEach(players) { player in
                let isMine = player.id == currentPlayerID
                VStack(spacing: 2) {
                    AvatarBadge(player: player, size: min(m.iconWidth - 4, m.avatarSize * 0.6))
                    if players.count <= 2 {
                        Text(player.name)
                            .font(AppTheme.rounded(m.captionSize * 0.75))
                            .foregroundStyle(isMine ? AppTheme.coral : AppTheme.soft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    if player.scorecard.yahtzeeBonusTotal > 0 {
                        Text("★\(player.scorecard.yahtzeeBonusTotal)")
                            .font(AppTheme.rounded(m.captionSize * 0.68))
                            .foregroundStyle(AppTheme.coral)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
                .toyBlock(
                    fill: isMine ? AppTheme.tintCoral : AppTheme.sunk,
                    radius: m.cellCorner,
                    depth: 0,
                    border: m.thinBorder
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    player.name
                        + (isMine ? ", aan de beurt" : "")
                        + (player.scorecard.yahtzeeBonusTotal > 0
                           ? ", Yahtzee-bonus \(player.scorecard.yahtzeeBonusTotal)" : "")
                )
            }
        }
    }

    private func row(
        for category: ScoreCategory,
        open: Set<ScoreCategory>,
        best: ScoreCategory?
    ) -> some View {
        HStack(spacing: 3) {
            CategoryIcon(category: category)
                .frame(width: m.iconWidth, height: m.rowHeight)

            ForEach(players) { player in
                cell(for: category, player: player, open: open, best: best)
            }
        }
    }

    @ViewBuilder
    private func cell(
        for category: ScoreCategory,
        player: GamePlayer,
        open: Set<ScoreCategory>,
        best: ScoreCategory?
    ) -> some View {
        let scored = player.scorecard.scores[category]
        let isMine = player.id == currentPlayerID
        let selectable = isMine && canScore && open.contains(category)

        if selectable {
            let points = YahtzeeScorer.pointsForPlacing(
                category: category,
                dice: diceValues,
                scorecard: player.scorecard
            ).score
            let isBest = category == best

            Button {
                onSelect(category)
            } label: {
                Text("\(points)")
                    .font(AppTheme.rounded(m.cellTextSize, .bold))
                    .foregroundStyle(isBest ? .white : AppTheme.coral)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.rowHeight)
            }
            .buttonStyle(ToyButtonStyle(
                fill: isBest ? AppTheme.mint : .white,
                radius: m.cellCorner,
                depth: isBest ? 3 : 0,
                border: m.thinBorder
            ))
            .accessibilityLabel("\(category.title), \(points) punten\(isBest ? ", beste zet" : "")")
        } else {
            Text(scored.map { "\($0)" } ?? "–")
                .font(AppTheme.rounded(m.cellTextSize, .bold))
                .foregroundStyle(scored == nil ? AppTheme.dim : AppTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: m.rowHeight)
                .toyBlock(fill: AppTheme.sunk, radius: m.cellCorner, depth: 0, border: m.thinBorder)
                .accessibilityLabel("\(category.title), \(scored.map { "\($0) punten" } ?? "leeg")")
        }
    }

    private var bonusRow: some View {
        HStack(spacing: 3) {
            VStack(spacing: 0) {
                Text("BONUS")
                    .font(AppTheme.rounded(m.captionSize * 0.68))
                    .kerning(0.6)
                    .foregroundStyle(AppTheme.soft)
                Text("+35")
                    .font(AppTheme.rounded(m.captionSize))
                    .foregroundStyle(AppTheme.ink)
            }
            .frame(width: m.iconWidth, height: m.rowHeight)
            .toyBlock(fill: AppTheme.tintStone, radius: m.cellCorner, depth: 0, border: m.thinBorder)

            ForEach(players) { player in
                let subtotal = player.scorecard.upperSubtotal
                let reached = player.scorecard.upperBonus > 0
                Text(reached ? "+35" : "\(subtotal)/63")
                    .font(AppTheme.rounded(m.captionSize * 0.92))
                    .foregroundStyle(reached ? AppTheme.mint : AppTheme.soft)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.rowHeight)
                    .toyBlock(fill: AppTheme.sunk, radius: m.cellCorner, depth: 0, border: m.thinBorder)
                    .accessibilityLabel(
                        reached ? "Bonus behaald, 35 punten" : "Bonus bij 63, nu \(subtotal)"
                    )
            }
        }
    }

}
