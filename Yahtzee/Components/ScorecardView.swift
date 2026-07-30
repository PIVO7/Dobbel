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
        let advice = adviceCategory(open: open)

        return HStack(alignment: .top, spacing: m.gutter * 0.6) {
            column(title: "BOVEN", categories: ScoreCategory.upper, showsBonus: true, open: open, advice: advice)
            column(title: "ONDER", categories: ScoreCategory.lower, showsBonus: false, open: open, advice: advice)
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

    /// De tip van de scorer; alleen tonen als er echt gegooid is. Weegt de
    /// bonus bovenin mee, maar blijft een vuistregel — kiezen doet de speler.
    private func adviceCategory(open: Set<ScoreCategory>) -> ScoreCategory? {
        guard canScore, !open.isEmpty, let current else { return nil }
        return YahtzeeScorer.adviceCategory(dice: diceValues, scorecard: current.scorecard)
    }

    private func column(
        title: String,
        categories: [ScoreCategory],
        showsBonus: Bool,
        open: Set<ScoreCategory>,
        advice: ScoreCategory?
    ) -> some View {
        VStack(spacing: m.cellGap) {
            Text(title)
                .font(AppTheme.rounded(m.captionSize * 0.9))
                .kerning(1.4)
                .foregroundStyle(AppTheme.faint)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 3)
                .padding(.bottom, 2)

            playerHeader

            ForEach(categories) { category in
                row(for: category, open: open, advice: advice)
            }

            if showsBonus {
                bonusRow
            }
        }
    }

    /// Boven elke kolom staat wie hem vult; zonder dat raak je bij drie of
    /// vier spelers het spoor bijster welke kolom van jou is. Alleen het
    /// bolletje — naam en kader erbij propten te veel in een celbreedte. Wie
    /// niet aan de beurt is, dimt; de kleur blijft genoeg om je kolom terug
    /// te vinden.
    private var headerAvatarSize: CGFloat {
        min(m.iconWidth - 2, m.avatarSize * 0.72)
    }

    private var playerHeader: some View {
        HStack(spacing: m.cellGap * 0.75) {
            Color.clear
                .frame(width: m.iconWidth, height: headerAvatarSize + 4)

            ForEach(players) { player in
                let isMine = player.id == currentPlayerID
                let bonus = player.scorecard.yahtzeeBonusTotal
                AvatarBadge(player: player, size: headerAvatarSize)
                    .overlay(alignment: .topTrailing) {
                        if bonus > 0 {
                            Image(systemName: "star.fill")
                                .font(.system(size: headerAvatarSize * 0.3, weight: .black))
                                .foregroundStyle(AppTheme.amber)
                                .offset(x: 3, y: -3)
                        }
                    }
                    .opacity(isMine ? 1 : 0.55)
                    .frame(maxWidth: .infinity)
                    .accessibilityElement()
                    .accessibilityLabel(
                        player.name
                            + (isMine ? ", aan de beurt" : "")
                            + (bonus > 0 ? ", Yahtzee-bonus \(bonus)" : "")
                    )
            }
        }
    }

    private func row(
        for category: ScoreCategory,
        open: Set<ScoreCategory>,
        advice: ScoreCategory?
    ) -> some View {
        HStack(spacing: m.cellGap * 0.75) {
            CategoryIcon(category: category)
                .frame(width: m.iconWidth, height: m.rowHeight)

            ForEach(players) { player in
                cell(for: category, player: player, open: open, advice: advice)
            }
        }
    }

    @ViewBuilder
    private func cell(
        for category: ScoreCategory,
        player: GamePlayer,
        open: Set<ScoreCategory>,
        advice: ScoreCategory?
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
            let isAdvised = category == advice

            Button {
                onSelect(category)
            } label: {
                Text("\(points)")
                    .font(AppTheme.rounded(m.cellTextSize, .bold))
                    .foregroundStyle(isAdvised ? .white : AppTheme.coral)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.rowHeight)
            }
            .buttonStyle(ToyButtonStyle(
                fill: isAdvised ? AppTheme.mint : .white,
                radius: m.cellCorner,
                depth: isAdvised ? 3 : 0,
                border: m.thinBorder
            ))
            .accessibilityLabel("\(category.title), \(points) punten\(isAdvised ? ", tip" : "")")
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
        HStack(spacing: m.cellGap * 0.75) {
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
