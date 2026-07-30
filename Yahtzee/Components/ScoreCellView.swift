import SwiftUI

/// Eén vakje op het scoreblad. Zolang het aan te tikken valt toont het wat de
/// worp daar zou opleveren; daarna alleen nog de vastgelegde score.
struct ScoreCellView: View {
    let category: ScoreCategory
    let player: GamePlayer
    let diceValues: [Int]
    let selectable: Bool
    let isAdvised: Bool
    let onSelect: (ScoreCategory) -> Void

    @Environment(\.metrics) private var m

    var body: some View {
        if selectable {
            let points = YahtzeeScorer.pointsForPlacing(
                category: category,
                dice: diceValues,
                scorecard: player.scorecard
            ).score

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
            let scored = player.scorecard.scores[category]
            Text(scored.map { "\($0)" } ?? "–")
                .font(AppTheme.rounded(m.cellTextSize, .bold))
                .foregroundStyle(scored == nil ? AppTheme.dim : AppTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: m.rowHeight)
                .toyBlock(fill: AppTheme.sunk, radius: m.cellCorner, depth: 0, border: m.thinBorder)
                .accessibilityLabel("\(category.title), \(scored.map { "\($0) punten" } ?? "leeg")")
        }
    }
}

#Preview {
    let lene = GamePlayer(profile: PlayerProfile(name: "Lene"))

    HStack(spacing: 8) {
        ScoreCellView(
            category: .threes, player: lene, diceValues: [3, 3, 3, 5, 2],
            selectable: true, isAdvised: true, onSelect: { _ in }
        )
        ScoreCellView(
            category: .chance, player: lene, diceValues: [3, 3, 3, 5, 2],
            selectable: true, isAdvised: false, onSelect: { _ in }
        )
        ScoreCellView(
            category: .yahtzee, player: lene, diceValues: [3, 3, 3, 5, 2],
            selectable: false, isAdvised: false, onSelect: { _ in }
        )
    }
    .padding()
    .background(AppTheme.cream)
    .appMetrics()
}
