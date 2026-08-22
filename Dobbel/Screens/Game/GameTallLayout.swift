import SwiftUI

/// De staande vorm: alles onder elkaar, met de gooiknop onderaan vastgezet.
/// Dit is wat een iPhone altijd krijgt, en een iPad in portret.
struct GameTallLayout: View {
    let engine: GameEngine
    let actions: GameActions
    let isCelebrating: Bool

    @Environment(\.metrics) private var base
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Op een iPad in portret is dit de enige kolom op een groot scherm, dus
    /// mag alles wat ruimer; op iPhone blijven de gewone maten staan.
    private var m: AppMetrics {
        sizeClass == .regular ? base.roomier() : base
    }

    /// Op hogere iPhones gaat het overgebleven wit naar het scoreblad: de
    /// rijen groeien tot twaalf procent mee met de schermhoogte. Kleine
    /// schermen blijven op de basismaat en scrollen zoals voorheen.
    private func boosted(for height: CGFloat) -> AppMetrics {
        guard sizeClass != .regular else { return m }
        let factor = min(max(1 + (height - 700) / 1500, 1), 1.12)
        guard factor > 1 else { return base }
        var copy = base
        copy.rowHeight *= factor
        copy.iconWidth *= factor
        copy.cellTextSize *= factor
        return copy
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    GameHeaderView(
                        players: engine.players,
                        currentPlayerID: engine.currentPlayer.id,
                        canUndo: engine.canUndoScore,
                        onUndo: actions.undo,
                        onLeave: actions.leave
                    )
                    .padding(.top, 6)

                    RoundStripView(
                        roundNumber: engine.roundNumber,
                        totalRounds: ScoreCategory.allCases.count
                    )
                    .padding(.top, m.gutter)

                    Self.contentStack(
                        engine: engine,
                        actions: actions,
                        isCelebrating: isCelebrating,
                        metrics: m
                    )
                }
                .padding(.horizontal, m.gutter)
                .frame(maxWidth: m.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geo.size.height)
                .environment(\.metrics, boosted(for: geo.size.height))
            }
            .scrollBounceBehavior(.basedOnSize)
        }
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
        .environment(\.metrics, m)
    }

    /// De middenmoot tussen rondestrook en gooiknop. Eén plek voor de
    /// volgorde van worp, melding en scoreblad; de render-rooktest stapelt
    /// precies dit, zodat een render altijd de echte indeling toont.
    @ViewBuilder
    static func contentStack(
        engine: GameEngine,
        actions: GameActions,
        isCelebrating: Bool,
        metrics m: AppMetrics
    ) -> some View {
        // Flexibel: op een hoog scherm spreidt de inhoud zich uit, op een
        // klein scherm of bij grote tekst krimpen deze tussenruimtes tot
        // hun minimum en schuift de rest.
        Spacer(minLength: m.gutter * 0.8)

        // Het scoreblad bovenaan, de worp onderaan bij de gooiknop: zo
        // blijft de hele gooien-vasthouden-lus in de duimzone en pendelt
        // het oog niet meer het scherm over.
        ScorecardView(
            players: engine.players,
            currentPlayerID: engine.currentPlayer.id,
            diceValues: engine.diceValues,
            canScore: engine.canScore,
            onSelect: actions.score
        )

        Spacer(minLength: m.gutter)

        RollCalloutView(
            title: engine.calloutTitle,
            message: engine.turnMessage,
            player: engine.currentPlayer,
            isCelebrating: isCelebrating
        )
        .padding(.bottom, m.gutter * 0.5)

        DiceTrayView(
            dice: engine.dice,
            isRolling: engine.isRolling,
            canInteract: engine.canHold,
            onToggle: actions.toggleHold
        )
        .padding(.bottom, m.gutter * 0.4)
    }
}
