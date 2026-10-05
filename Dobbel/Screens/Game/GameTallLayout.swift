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

    /// Op een iPad krimpt de verruiming mee met de schermhoogte, zodat ook
    /// een 11-inch of mini alles op één scherm houdt. De iPhone blijft op de
    /// basismaat: sinds de Dobbel-bonusrij is het overgebleven wit dat de
    /// rijen vroeger opvulden, al door het blad zelf ingenomen.
    private func boosted(for height: CGFloat) -> AppMetrics {
        guard sizeClass != .regular else { return base.roomier(fitting: height) }
        return base
    }

    /// Hoeveel het scoreblad meegroeit om de schermhoogte te vullen. Zonder
    /// dit bleef er op een iPad in portret een gat boven het scorebord en
    /// een gat onder het blad, waardoor alles leek te zweven.
    @State private var boardScale: CGFloat = 1

    /// Tot hier groeit het blad; wat daarna nog over is, komt tussen het blad
    /// en de stenen.
    private static let boardScaleRange: ClosedRange<CGFloat> = 1...1.35

    var body: some View {
        GeometryReader { geo in
            let metrics = boosted(for: geo.size.height)
            // Vastgelegd bij deze tekenbeurt, zodat de meting hieronder weet
            // bij welke schaal de vrije ruimte hoorde.
            let scale = boardScale

            ScrollView {
                VStack(spacing: 0) {
                    GameTopBar(engine: engine, actions: actions)
                        .padding(.top, 6)

                    Self.contentStack(
                        engine: engine,
                        actions: actions,
                        isCelebrating: isCelebrating,
                        metrics: metrics,
                        boardScale: scale,
                        onSlack: { slack in
                            let next = metrics.boardScale(from: scale, slack: slack, in: Self.boardScaleRange)
                            if abs(next - boardScale) > 0.002 {
                                boardScale = next
                            }
                        }
                    )
                }
                .padding(.horizontal, m.gutter)
                .frame(maxWidth: m.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geo.size.height)
                .environment(\.metrics, metrics)
            }
            .scrollBounceBehavior(.basedOnSize)
            // Een andere hoogte (Split View, Stage Manager) begint opnieuw
            // vanaf de gewone maat en meet dan opnieuw.
            .onChange(of: geo.size.height) { _, _ in
                boardScale = 1
            }
        }
        // De gooiknop blijft onderaan staan, ook als het scoreblad bij een
        // grote tekstinstelling langer wordt dan het scherm.
        .safeAreaInset(edge: .bottom) {
            RollButtonView(
                isRolling: engine.isRolling,
                rollsRemaining: engine.rollsRemaining,
                canRoll: engine.canRoll,
                mustChoose: engine.canScore && engine.rollsRemaining == 0,
                onRoll: actions.roll
            )
            .padding(.horizontal, m.gutter)
            .padding(.top, m.gutter * 0.3)
            .padding(.bottom, m.gutter * 0.45)
            .frame(maxWidth: m.contentMaxWidth)
            .frame(maxWidth: .infinity)
            .background(AppTheme.cream)
        }
        .environment(\.metrics, m)
    }

    /// De middenmoot tussen rondestrook en gooiknop. Eén plek voor de
    /// volgorde van worp, melding en scoreblad; de render-rooktest stapelt
    /// precies dit, zodat een render altijd de echte indeling toont.
    ///
    /// `onSlack` krijgt de ruimte die tussen blad en stenen over is boven de
    /// vaste marge; daarmee laat de indeling het blad meegroeien.
    @ViewBuilder
    static func contentStack(
        engine: GameEngine,
        actions: GameActions,
        isCelebrating: Bool,
        metrics m: AppMetrics,
        boardScale: CGFloat = 1,
        onSlack: ((CGFloat) -> Void)? = nil
    ) -> some View {
        let gap = m.gutter * 0.75

        // De tussenstand vlak onder de rondestrook en boven het blad dat hij
        // samenvat: een vaste afstand, zodat het scorebord niet meer los in
        // de ruimte hangt.
        ScoreChipsView(
            players: engine.players,
            currentPlayerID: engine.currentPlayer.id
        )
        .padding(.top, gap)
        .padding(.bottom, m.gutter * 0.3)

        // Wat er nú moet gebeuren, vlak boven het blad waar getikt wordt.
        GameStatusChipView(
            message: engine.turnMessage,
            mustChoose: engine.canScore && engine.rollsRemaining == 0
        )
        .padding(.bottom, m.gutter * 0.45)

        // Het scoreblad bovenaan, de worp onderaan bij de gooiknop: zo
        // blijft de hele gooien-vasthouden-lus in de duimzone en pendelt
        // het oog niet meer het scherm over.
        ScorecardView(
            players: engine.players,
            currentPlayerID: engine.currentPlayer.id,
            diceValues: engine.diceValues,
            canScore: engine.canScore,
            variant: engine.variant,
            lastPlaced: engine.lastPlaced,
            onSelect: actions.score
        )
        .environment(\.metrics, m.boardScaled(by: boardScale))

        // De enige rekbare ruimte: de indeling meet hem en laat het blad
        // groeien tot hij op zijn minimum staat. Op een klein scherm of bij
        // grote tekst blijft het minimum en schuift de rest.
        Spacer(minLength: gap)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                onSlack?(height - gap)
            }

        RollCalloutView(
            title: engine.calloutTitle,
            isCelebrating: isCelebrating
        )
        .padding(.bottom, m.gutter * 0.35)

        DiceTrayView(
            dice: engine.dice,
            isRolling: engine.isRolling,
            hasRolled: engine.hasRolledThisTurn,
            canInteract: engine.canHold,
            onToggle: actions.toggleHold
        )
        .padding(.bottom, m.gutter * 0.3)
    }
}

/// De dunne bovenrand van de staande indeling: de rondeteller (passieve
/// meta-info) met de terugzet- en sluitknop ernaast. De tussenstand staat
/// niet meer hier maar vlak boven het scoreblad.
struct GameTopBar: View {
    let engine: GameEngine
    let actions: GameActions

    @Environment(\.metrics) private var m

    var body: some View {
        // De teller staat in het échte midden van het scherm, niet in het
        // midden van de restruimte naast de knoppen: zo valt hij in de as
        // van het bord en het blad eronder, en staat hij stil wanneer het
        // terugzet-knopje verschijnt of verdwijnt.
        ZStack {
            RoundStripView(
                roundNumber: engine.roundNumber,
                totalRounds: ScoreCategory.allCases.count
            )

            HStack(spacing: 0) {
                Spacer()
                GameCornerButtons(
                    canUndo: engine.canUndoScore,
                    onUndo: actions.undo,
                    onLeave: actions.leave
                )
            }
        }
    }
}
