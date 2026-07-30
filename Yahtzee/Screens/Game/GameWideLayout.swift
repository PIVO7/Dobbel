import SwiftUI

/// De liggende vorm voor een iPad: gooien links, scoreblad rechts, zodat je
/// niet hoeft te scrollen tussen je worp en je keuze.
struct GameWideLayout: View {
    let engine: GameEngine
    let actions: GameActions
    let isCelebrating: Bool
    let availableWidth: CGFloat

    @Environment(\.metrics) private var m

    var body: some View {
        VStack(spacing: 0) {
            GameHeaderView(
                players: engine.players,
                currentPlayerID: engine.currentPlayer.id,
                onLeave: actions.leave
            )
            .padding(.top, 6)

            HStack(alignment: .top, spacing: m.gutter * 1.5) {
                rollColumn
                    .frame(width: max(availableWidth * 0.42 - m.gutter, 320))

                ScrollView {
                    ScorecardView(
                        players: engine.players,
                        currentPlayerID: engine.currentPlayer.id,
                        diceValues: engine.diceValues,
                        canScore: engine.canScore,
                        onSelect: actions.score
                    )
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxWidth: .infinity)
            }
            .padding(.top, m.gutter * 0.5)
            .padding(.bottom, m.gutter * 1.2)
        }
        .padding(.horizontal, m.gutter)
    }

    private var rollColumn: some View {
        VStack(spacing: 0) {
            RoundStripView(
                roundNumber: engine.roundNumber,
                totalRounds: ScoreCategory.allCases.count
            )
            .padding(.top, m.gutter)

            Spacer(minLength: 8)

            DiceTrayView(
                dice: engine.dice,
                isRolling: engine.isRolling,
                canInteract: engine.canScore && engine.rollsRemaining > 0,
                onToggle: actions.toggleHold
            )

            RollCalloutView(
                title: engine.calloutTitle,
                message: engine.turnMessage,
                isCelebrating: isCelebrating
            )
            .padding(.top, 4)

            TipButtonView(engine: engine, onExplain: actions.explainTip)

            Spacer(minLength: 8)

            RollButtonView(
                isRolling: engine.isRolling,
                rollsRemaining: engine.rollsRemaining,
                canRoll: engine.canRoll,
                onRoll: actions.roll
            )
        }
    }
}
