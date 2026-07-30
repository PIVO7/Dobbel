import SwiftUI

/// Het "waarom?"-knopje onder de worp: zichtbaar zodra de tip een vakje
/// aanraadt, en een tik legt de keuze in kindertaal uit.
struct TipButtonView: View {
    let engine: GameEngine
    let onExplain: (ScoreCategory) -> Void

    @Environment(\.metrics) private var m

    private var advice: ScoreCategory? {
        guard engine.canScore else { return nil }
        return YahtzeeScorer.adviceCategory(
            dice: engine.diceValues,
            scorecard: engine.currentPlayer.scorecard
        )
    }

    var body: some View {
        if let advice {
            Button {
                onExplain(advice)
            } label: {
                Label("Waarom \(advice.title.lowercased())?", systemImage: "lightbulb.fill")
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
            }
            .buttonStyle(ToyButtonStyle(
                fill: AppTheme.tintAmber,
                radius: m.cellCorner + 2,
                depth: 3,
                border: m.thinBorder
            ))
        }
    }
}

#Preview {
    let engine: GameEngine = {
        let engine = GameEngine(
            mode: .versusFriends,
            profiles: [PlayerProfile(name: "Lene"), PlayerProfile(name: "Ellis")],
            seed: 5
        )
        Task { await engine.rollDice() }
        return engine
    }()

    TipButtonView(engine: engine, onExplain: { _ in })
        .padding()
        .background(AppTheme.cream)
        .appMetrics()
}
