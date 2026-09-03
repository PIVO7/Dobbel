import SwiftUI

/// Het hele scoreblad in twee kolommen, zodat alle dertien vakjes tegelijk in
/// beeld staan. De zevende rij links draagt de bonus; rechts loopt Chance daar
/// gewoon door, waardoor het raster sluit.
struct ScorecardView: View {
    let players: [GamePlayer]
    let currentPlayerID: UUID
    let diceValues: [Int]
    let canScore: Bool
    var variant: GameVariant = .classic
    let onSelect: (ScoreCategory) -> Void

    @Environment(\.metrics) private var m
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Bij drie of vier spelers op een smal scherm worden de vakjes te smal
    /// om te raken (ver onder de 44 punten). Dan toont het blad alleen de
    /// kolom van wie aan de beurt is; de scores van de anderen staan al
    /// bovenin het spelscherm.
    private var visiblePlayers: [GamePlayer] {
        guard sizeClass == .compact, players.count > 2 else { return players }
        return players.filter { $0.id == currentPlayerID }
    }

    /// Op een smal scherm krijgt wie aan de beurt is de brede kolom en
    /// versmalt de rest tot een spiekstrook: de keuzevakjes zijn dan groot,
    /// terwijl de stand van de ander zichtbaar blijft.
    private var passiveWidth: CGFloat? {
        guard sizeClass == .compact, visiblePlayers.count > 1 else { return nil }
        return max(m.iconWidth, 46)
    }

    /// De brede actieve kolom of de smalle spiekstrook.
    @ViewBuilder
    private func columnFrame(_ content: some View, isMine: Bool) -> some View {
        if let passiveWidth, !isMine {
            content.frame(width: passiveWidth)
        } else {
            content.frame(maxWidth: .infinity)
        }
    }

    var body: some View {
        // Eén keer per hertekening rekenen, zodat de scorer niet per vakje
        // draait.
        let open = Set(openCategories)

        return HStack(alignment: .top, spacing: m.gutter * 0.6) {
            column(categories: ScoreCategory.upper, showsBonus: true, open: open)
            column(categories: ScoreCategory.lower, showsBonus: false, open: open)
        }
        .padding(m.gutter * 0.8)
        .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)
    }

    private var current: GamePlayer? {
        players.first { $0.id == currentPlayerID }
    }

    private var openCategories: [ScoreCategory] {
        guard let current else { return [] }
        return DobbelScorer.availableCategories(dice: diceValues, scorecard: current.scorecard, variant: variant)
    }

    // Zonder BOVEN/ONDER-kopjes: die zeiden een kind niets en de bonusrij
    // markeert het verschil al. De gewonnen ruimte gaat naar het raster.
    private func column(
        categories: [ScoreCategory],
        showsBonus: Bool,
        open: Set<ScoreCategory>
    ) -> some View {
        VStack(spacing: m.cellGap) {
            PlayerHeaderView(
                players: visiblePlayers,
                currentPlayerID: currentPlayerID,
                showsName: showsBonus,
                passiveWidth: passiveWidth
            )

            ForEach(categories) { category in
                row(for: category, open: open)
            }

            if showsBonus {
                bonusRow
            }
        }
    }

    private func row(
        for category: ScoreCategory,
        open: Set<ScoreCategory>
    ) -> some View {
        HStack(spacing: m.cellGap) {
            CategoryIcon(category: category)
                .frame(width: m.iconWidth, height: m.rowHeight)

            ForEach(visiblePlayers) { player in
                let isMine = player.id == currentPlayerID
                columnFrame(
                    ScoreCellView(
                        category: category,
                        player: player,
                        diceValues: diceValues,
                        isMine: isMine,
                        selectable: isMine && canScore && open.contains(category),
                        onSelect: onSelect
                    ),
                    isMine: isMine
                )
            }
        }
    }

    private var bonusRow: some View {
        HStack(spacing: m.cellGap) {
            VStack(spacing: 0) {
                Text("BONUS")
                    .font(AppTheme.rounded(m.captionSize * 0.82))
                    .kerning(0.6)
                    .foregroundStyle(AppTheme.ink)
                Text("+35")
                    .font(AppTheme.rounded(m.captionSize))
                    .foregroundStyle(AppTheme.ink)
            }
            .frame(width: m.iconWidth, height: m.rowHeight)
            .toyBlock(fill: AppTheme.tintStone, radius: m.cellCorner, depth: 0, border: m.thinBorder)

            ForEach(visiblePlayers) { player in
                let subtotal = player.scorecard.upperSubtotal
                let reached = player.scorecard.upperBonus > 0
                let isMine = player.id == currentPlayerID
                columnFrame(
                    Group {
                        if reached {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: m.captionSize * 1.35, weight: .black))
                        } else {
                            // Stand plus een klein balkje: zo leeft de rij mee
                            // met de kolom in plaats van dood grijs te ogen, en
                            // wordt de bonus iets om naartoe te spelen.
                            VStack(spacing: m.rowHeight * 0.1) {
                                Text("\(subtotal)/63")
                                    .font(AppTheme.rounded(m.captionSize))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                bonusBar(subtotal: subtotal)
                            }
                        }
                    }
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.rowHeight)
                    .toyBlock(
                        fill: reached ? AppTheme.mint : (isMine ? AppTheme.tintCoral : AppTheme.sunk),
                        radius: m.cellCorner,
                        depth: 0,
                        border: m.thinBorder
                    )
                    .accessibilityLabel(
                        reached
                            ? String(localized: "\(subtotal) punten bovenin, bonus van 35 behaald")
                            : String(localized: "Bonus bij 63, nu \(subtotal)")
                    ),
                    isMine: isMine
                )
            }
        }
    }

    /// Het voortgangsbalkje onder de bonusstand: hoe vol, hoe dichterbij.
    private func bonusBar(subtotal: Int) -> some View {
        Capsule()
            .fill(AppTheme.ink.opacity(0.12))
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    Capsule()
                        .fill(AppTheme.amber)
                        .frame(width: geo.size.width * min(CGFloat(subtotal) / 63, 1))
                }
            }
            .frame(maxWidth: m.iconWidth * 1.1)
            .frame(height: max(m.rowHeight * 0.09, 3))
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
