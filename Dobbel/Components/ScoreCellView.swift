import SwiftUI

/// Eén vakje op het scoreblad. Zolang het aan te tikken valt toont het met
/// een plusje wat de worp daar zou opleveren; daarna alleen nog de
/// vastgelegde score — die bij het vastleggen even oplicht.
struct ScoreCellView: View {
    let category: ScoreCategory
    let player: GamePlayer
    let diceValues: [Int]
    /// De kolom van wie aan de beurt is kleurt zacht mee, zodat je in het
    /// raster meteen ziet wiens beurt het is.
    let isMine: Bool
    let selectable: Bool
    /// Versienummer van de zet die dit vakje zojuist vulde, of `nil`. Elke
    /// nieuwe waarde zet de oplichtanimatie één keer in gang.
    var freshVersion: Int?
    let onSelect: (ScoreCategory) -> Void

    @Environment(\.metrics) private var m
    @State private var isFlashing = false
    /// Net als de gooiknop: het vakje wisselt na een tik meteen naar de
    /// vastgelegde staat, waardoor de klik van ToyButtonStyle wegvalt.
    /// Daarom zakt het eerst zichtbaar in en volgt de score een tel later.
    @State private var isPressBouncing = false

    var body: some View {
        if selectable {
            let points = DobbelScorer.pointsForPlacing(
                category: category,
                dice: diceValues,
                scorecard: player.scorecard
            ).score

            Button {
                pressAndScore()
            } label: {
                // Het plusje zegt wat het rode cijfer is: wat je erbíj zou
                // krijgen, niet wat je hebt. Een nul dempt: zo gaat het oog
                // vanzelf naar de vakjes die iets opleveren, zonder dat het
                // blad een keuze voorzegt.
                Text(verbatim: "+\(points)")
                    .font(AppTheme.rounded(m.cellTextSize, .bold))
                    .foregroundStyle(points == 0 ? AppTheme.cardDim : AppTheme.gain)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.rowHeight)
            }
            // Diepte op élk open vakje: zo zie je in één oogopslag wat nog te
            // kiezen valt, en zakt het vakje voelbaar in bij het tikken.
            .buttonStyle(ToyButtonStyle(
                fill: AppTheme.card,
                radius: m.cellCorner,
                depth: m.shallowDepth,
                border: m.thinBorder,
                forcePressed: isPressBouncing
            ))
            .accessibilityLabel(String(localized: "\(category.title), levert \(points) punten op"))
        } else {
            let scored = player.scorecard.scores[category]
            Text(scored.map { "\($0)" } ?? "–")
                .font(AppTheme.rounded(m.cellTextSize, .bold))
                .foregroundStyle(scored == nil ? AppTheme.cardDim : AppTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: m.rowHeight)
                .toyBlock(
                    fill: isFlashing ? AppTheme.mint : (isMine ? AppTheme.tintCoral : AppTheme.sunk),
                    radius: m.cellCorner,
                    depth: 0,
                    border: m.thinBorder
                )
                // Even mint oplichten op het moment van vastleggen: zo zie je
                // de omslag van voorspelling (+21) naar score (21) gebeuren.
                .task(id: freshVersion) {
                    guard freshVersion != nil else { return }
                    isFlashing = true
                    try? await Task.sleep(for: .milliseconds(650))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeOut(duration: 0.45)) {
                        isFlashing = false
                    }
                }
                .accessibilityLabel(
                    scored.map { String(localized: "\(category.title), \($0) punten") }
                        ?? String(localized: "\(category.title), leeg")
                )
        }
    }

    /// Eerst de klik laten zien, dan pas scoren: daarna wisselt de cel naar
    /// de vastgelegde staat en licht hij mint op.
    private func pressAndScore() {
        guard !isPressBouncing else { return }
        isPressBouncing = true
        Task {
            try? await Task.sleep(for: .milliseconds(120))
            isPressBouncing = false
            onSelect(category)
        }
    }
}

#Preview {
    let lene = GamePlayer(profile: PlayerProfile(name: "Lene"))

    HStack(spacing: 8) {
        ScoreCellView(
            category: .threes, player: lene, diceValues: [3, 3, 3, 5, 2],
            isMine: true, selectable: true, onSelect: { _ in }
        )
        ScoreCellView(
            category: .smallStraight, player: lene, diceValues: [3, 3, 3, 5, 2],
            isMine: true, selectable: true, onSelect: { _ in }
        )
        ScoreCellView(
            category: .dobbel, player: lene, diceValues: [3, 3, 3, 5, 2],
            isMine: false, selectable: false, onSelect: { _ in }
        )
    }
    .padding()
    .background(AppTheme.cream)
    .appMetrics()
}
