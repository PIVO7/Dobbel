import SwiftUI

/// De liggende vorm voor een iPad: gooien links, scoreblad rechts, zodat je
/// niet hoeft te scrollen tussen je worp en je keuze.
struct GameWideLayout: View {
    let engine: GameEngine
    let actions: GameActions
    let isCelebrating: Bool
    let availableWidth: CGFloat
    let availableHeight: CGFloat

    @Environment(\.metrics) private var m

    /// Het scoreblad groeit mee met de schermhoogte: op een liggende iPad
    /// bleef er anders een halve lege pagina onder over.
    private var boardMetrics: AppMetrics {
        let naturalHeight: CGFloat = 7 * (m.rowHeight + m.cellGap) + 100
        let room = availableHeight - 170
        let factor = min(max(room / naturalHeight, 1), 1.5)
        guard factor > 1 else { return m }
        var copy = m
        copy.rowHeight *= factor
        copy.iconWidth *= factor
        copy.cellTextSize *= factor
        copy.cellGap *= factor
        return copy
    }

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
                    .environment(\.metrics, boardMetrics)
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
                canInteract: engine.canHold,
                onToggle: actions.toggleHold
            )

            RollCalloutView(
                title: engine.calloutTitle,
                message: engine.turnMessage,
                player: engine.currentPlayer,
                isCelebrating: isCelebrating
            )
            .padding(.top, 4)


            if engine.canUndoScore {
                UndoButtonView(onUndo: actions.undo)
            }

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
