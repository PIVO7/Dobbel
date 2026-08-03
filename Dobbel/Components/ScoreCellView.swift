import SwiftUI

/// Eén vakje op het scoreblad. Zolang het aan te tikken valt toont het wat de
/// worp daar zou opleveren; daarna alleen nog de vastgelegde score.
struct ScoreCellView: View {
    let category: ScoreCategory
    let player: GamePlayer
    let diceValues: [Int]
    /// De kolom van wie aan de beurt is kleurt zacht mee, zodat je in het
    /// raster meteen ziet wiens beurt het is.
    let isMine: Bool
    let selectable: Bool
    let isAdvised: Bool
    let onSelect: (ScoreCategory) -> Void

    @Environment(\.metrics) private var m

    var body: some View {
        if selectable {
            let points = DobbelScorer.pointsForPlacing(
                category: category,
                dice: diceValues,
                scorecard: player.scorecard
            ).score

            Button {
                onSelect(category)
            } label: {
                Text("\(points)")
                    .font(AppTheme.rounded(m.cellTextSize, .bold))
                    .foregroundStyle(isAdvised ? AppTheme.ink : AppTheme.coral)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.rowHeight)
            }
            // Diepte op élk open vakje: zo zie je in één oogopslag wat nog te
            // kiezen valt, en zakt het vakje voelbaar in bij het tikken.
            .buttonStyle(ToyButtonStyle(
                fill: isAdvised ? AppTheme.mint : AppTheme.card,
                radius: m.cellCorner,
                depth: 3,
                border: m.thinBorder
            ))
            .accessibilityLabel(
                isAdvised
                    ? String(localized: "\(category.title), \(points) punten, tip")
                    : String(localized: "\(category.title), \(points) punten")
            )
        } else {
            let scored = player.scorecard.scores[category]
            Text(scored.map { "\($0)" } ?? "–")
                .font(AppTheme.rounded(m.cellTextSize, .bold))
                .foregroundStyle(scored == nil ? AppTheme.cardDim : AppTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: m.rowHeight)
                .toyBlock(fill: isMine ? AppTheme.tintCoral : AppTheme.sunk, radius: m.cellCorner, depth: 0, border: m.thinBorder)
                .accessibilityLabel(
                    scored.map { String(localized: "\(category.title), \($0) punten") }
                        ?? String(localized: "\(category.title), leeg")
                )
        }
    }
}

#Preview {
    let lene = GamePlayer(profile: PlayerProfile(name: "Lene"))

    HStack(spacing: 8) {
        ScoreCellView(
            category: .threes, player: lene, diceValues: [3, 3, 3, 5, 2],
            isMine: true, selectable: true, isAdvised: true, onSelect: { _ in }
        )
        ScoreCellView(
            category: .chance, player: lene, diceValues: [3, 3, 3, 5, 2],
            isMine: true, selectable: true, isAdvised: false, onSelect: { _ in }
        )
        ScoreCellView(
            category: .dobbel, player: lene, diceValues: [3, 3, 3, 5, 2],
            isMine: false, selectable: false, isAdvised: false, onSelect: { _ in }
        )
    }
    .padding()
    .background(AppTheme.cream)
    .appMetrics()
}
