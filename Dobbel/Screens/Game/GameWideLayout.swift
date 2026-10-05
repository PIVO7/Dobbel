import SwiftUI

/// De liggende vorm voor een iPad: gooien links, scoreblad rechts, zodat je
/// niet hoeft te scrollen tussen je worp en je keuze.
///
/// Twee kolommen met dezelfde randen: het scorebord staat boven de
/// gooikolom en de beurtmelding boven het blad, de rondeteller begint op de
/// bovenrand van het blad en de gooiknop eindigt op de onderrand ervan.
struct GameWideLayout: View {
    let engine: GameEngine
    let actions: GameActions
    let isCelebrating: Bool
    let availableWidth: CGFloat
    let availableHeight: CGFloat

    @Environment(\.metrics) private var m

    /// Hoe groot het blad getekend wordt; `nil` zolang er nog niet gemeten
    /// is, dan geldt de schatting.
    @State private var measuredScale: CGFloat?
    @State private var viewportHeight: CGFloat?
    /// De gemeten hoogte van het blad, met de schaal waarbij die hoorde.
    @State private var board: (height: CGFloat, scale: CGFloat)?

    /// Op een krappe iPad mini mag het blad een fractie krimpen, op een grote
    /// iPad groeit het mee tot de onderrand. Een liggende 13-inch heeft
    /// zo'n 1,7 nodig; met 1,5 als plafond bleef er onderaan een strook leeg.
    private static let boardScaleRange: ClosedRange<CGFloat> = 0.85...1.8

    private var columnWidth: CGFloat {
        max(availableWidth * 0.42 - m.gutter, 320)
    }

    private var columnSpacing: CGFloat {
        m.gutter * 1.5
    }

    /// Een eerste schatting voor de allereerste tekenbeurt; daarna meet de
    /// indeling het blad en vult het precies de vrije hoogte.
    private var estimatedScale: CGFloat {
        let naturalHeight = m.boardRowsHeight + 100
        let room = availableHeight - 170
        return min(max(room / naturalHeight, Self.boardScaleRange.lowerBound), Self.boardScaleRange.upperBound)
    }

    var body: some View {
        let scale = measuredScale ?? estimatedScale

        VStack(spacing: m.gutter * 0.5) {
            topRow

            ScrollView {
                HStack(alignment: .top, spacing: columnSpacing) {
                    rollColumn
                        .frame(width: columnWidth)
                        .frame(maxHeight: .infinity)

                    ScorecardView(
                        players: engine.players,
                        currentPlayerID: engine.currentPlayer.id,
                        diceValues: engine.diceValues,
                        canScore: engine.canScore,
                        variant: engine.variant,
                        lastPlaced: engine.lastPlaced,
                        onSelect: actions.score
                    )
                    .environment(\.metrics, m.boardScaled(by: scale))
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        board = (height, scale)
                        refit()
                    }
                    .frame(maxWidth: .infinity)
                }
                // Beide kolommen even hoog als het blad: zo eindigt de
                // gooiknop precies op de onderrand van het blad.
                .fixedSize(horizontal: false, vertical: true)
                // Ruimte voor de dikte onder blad en knop, anders knipt de
                // ScrollView die onderrand weg.
                .padding(.bottom, m.heroDepth)
            }
            .scrollBounceBehavior(.basedOnSize)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                viewportHeight = height
                refit()
            }
        }
        .padding(.top, 6)
        .padding(.bottom, m.gutter * 1.2 - m.heroDepth)
        .padding(.horizontal, m.gutter)
    }

    /// Het blad zo schalen dat het de ruimte onder de bovenrij precies vult.
    private func refit() {
        guard let viewportHeight, let board else { return }
        let next = m.boardScale(
            from: board.scale,
            slack: viewportHeight - m.heroDepth - board.height,
            in: Self.boardScaleRange
        )
        if abs(next - (measuredScale ?? estimatedScale)) > 0.002 {
            measuredScale = next
        }
    }

    /// Bovenaan dezelfde twee kolommen: het scorebord zo breed als de
    /// gooikolom, de beurtmelding en de knopjes zo breed als het blad.
    private var topRow: some View {
        HStack(spacing: columnSpacing) {
            ScoreChipsView(
                players: engine.players,
                currentPlayerID: engine.currentPlayer.id
            )
            .frame(width: columnWidth)

            HStack(spacing: 8) {
                GameStatusChipView(
                    message: engine.turnMessage,
                    mustChoose: engine.canScore && engine.rollsRemaining == 0
                )

                GameCornerButtons(
                    canUndo: engine.canUndoScore,
                    onUndo: actions.undo,
                    onLeave: actions.leave
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var rollColumn: some View {
        VStack(spacing: 0) {
            RoundStripView(
                roundNumber: engine.roundNumber,
                totalRounds: ScoreCategory.allCases.count
            )

            Spacer(minLength: 8)

            DiceTrayView(
                dice: engine.dice,
                isRolling: engine.isRolling,
                hasRolled: engine.hasRolledThisTurn,
                canInteract: engine.canHold,
                onToggle: actions.toggleHold
            )

            RollCalloutView(
                title: engine.calloutTitle,
                isCelebrating: isCelebrating
            )
            .padding(.top, 4)

            Spacer(minLength: 8)

            RollButtonView(
                isRolling: engine.isRolling,
                rollsRemaining: engine.rollsRemaining,
                canRoll: engine.canRoll,
                mustChoose: engine.canScore && engine.rollsRemaining == 0,
                onRoll: actions.roll
            )
        }
    }
}
