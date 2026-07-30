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
        // Eén keer per hertekening rekenen: de lijst voedt zowel de open-check
        // als de tip, zodat de scorer niet per vakje — of dubbel — draait.
        let openList = openCategories
        let open = Set(openList)
        let advice = adviceCategory(open: openList)

        return HStack(alignment: .top, spacing: m.gutter * 0.6) {
            column(categories: ScoreCategory.upper, showsBonus: true, open: open, advice: advice)
            column(categories: ScoreCategory.lower, showsBonus: false, open: open, advice: advice)
        }
        .padding(m.gutter * 0.8)
        .toyBlock(fill: .white, radius: m.cardCorner, depth: m.depth, border: m.border)
    }

    private var current: GamePlayer? {
        players.first { $0.id == currentPlayerID }
    }

    private var openCategories: [ScoreCategory] {
        guard let current else { return [] }
        return YahtzeeScorer.availableCategories(dice: diceValues, scorecard: current.scorecard)
    }

    /// De tip van de scorer; alleen tonen als er echt gegooid is. Weegt de
    /// bonus bovenin mee, maar blijft een vuistregel — kiezen doet de speler.
    private func adviceCategory(open: [ScoreCategory]) -> ScoreCategory? {
        guard canScore, !open.isEmpty, let current else { return nil }
        return YahtzeeScorer.adviceCategory(dice: diceValues, scorecard: current.scorecard, open: open)
    }

    // Zonder BOVEN/ONDER-kopjes: die zeiden een kind niets en de bonusrij
    // markeert het verschil al. De gewonnen ruimte gaat naar het raster.
    private func column(
        categories: [ScoreCategory],
        showsBonus: Bool,
        open: Set<ScoreCategory>,
        advice: ScoreCategory?
    ) -> some View {
        VStack(spacing: m.cellGap) {
            PlayerHeaderView(players: players, currentPlayerID: currentPlayerID)

            ForEach(categories) { category in
                row(for: category, open: open, advice: advice)
            }

            if showsBonus {
                bonusRow
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
                let selectable = player.id == currentPlayerID && canScore && open.contains(category)
                ScoreCellView(
                    category: category,
                    player: player,
                    diceValues: diceValues,
                    selectable: selectable,
                    isAdvised: selectable && category == advice,
                    onSelect: onSelect
                )
            }
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

#Preview {
    let lene = GamePlayer(profile: PlayerProfile(name: "Lene", avatarColorIndex: 0))
    let ellis = GamePlayer(profile: PlayerProfile(name: "Ellis", avatarColorIndex: 1))

    ScorecardView(
        players: [lene, ellis],
        currentPlayerID: lene.id,
        diceValues: [3, 3, 3, 5, 2],
        canScore: true,
        onSelect: { _ in }
    )
    .padding()
    .background(AppTheme.cream)
    .appMetrics()
}
