import SwiftUI

/// De staande vorm: alles onder elkaar, met de gooiknop onderaan vastgezet.
/// Dit is wat een iPhone altijd krijgt, en een iPad in portret.
struct GameTallLayout: View {
    let engine: GameEngine
    let actions: GameActions
    let isCelebrating: Bool

    @Environment(\.metrics) private var m

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                GameHeaderView(
                    players: engine.players,
                    currentPlayerID: engine.currentPlayer.id,
                    isFinished: engine.isFinished,
                    onLeave: actions.leave
                )
                .padding(.top, 6)

                RoundStripView(
                    roundNumber: engine.roundNumber,
                    totalRounds: ScoreCategory.allCases.count
                )
                .padding(.top, m.gutter)

                DiceTrayView(
                    dice: engine.dice,
                    isRolling: engine.isRolling,
                    canInteract: engine.canScore && engine.rollsRemaining > 0,
                    onToggle: actions.toggleHold
                )
                .padding(.top, m.gutter * 0.8)

                RollCalloutView(
                    title: engine.calloutTitle,
                    message: engine.turnMessage,
                    isCelebrating: isCelebrating
                )
                .padding(.top, 4)
                .padding(.bottom, m.gutter)

                ScorecardView(
                    players: engine.players,
                    currentPlayerID: engine.currentPlayer.id,
                    diceValues: engine.diceValues,
                    canScore: engine.canScore,
                    onSelect: actions.score
                )
                .padding(.bottom, m.gutter)
            }
            .padding(.horizontal, m.gutter)
            .frame(maxWidth: m.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        // De gooiknop blijft onderaan staan, ook als het scoreblad bij een
        // grote tekstinstelling langer wordt dan het scherm.
        .safeAreaInset(edge: .bottom) {
            RollButtonView(
                isRolling: engine.isRolling,
                rollsRemaining: engine.rollsRemaining,
                canRoll: engine.canRoll,
                onRoll: actions.roll
            )
            .padding(.horizontal, m.gutter)
            .padding(.top, m.gutter * 0.4)
            .padding(.bottom, m.gutter * 0.6)
            .frame(maxWidth: m.contentMaxWidth)
            .frame(maxWidth: .infinity)
            .background(AppTheme.cream)
        }
    }
}
