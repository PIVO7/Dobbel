import SwiftUI

/// Houdt het spel bij elkaar: kiest een indeling, bewaart de voortgang en
/// vertaalt zetten naar trillingen, banners en vieringen. Het tekenwerk zelf
/// zit in de losse views hiernaast.
struct GameView: View {
    let engine: GameEngine
    let onClose: () -> Void

    @Environment(ProfileStore.self) private var profileStore
    @Environment(GameStore.self) private var gameStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var didRecordResult = false
    @State private var showTurnBanner = false
    @State private var celebrateYahtzee = false
    @State private var celebrateBonus = false
    @State private var bannerDismissal: Task<Void, Never>?
    @State private var yahtzeeDismissal: Task<Void, Never>?
    @State private var bonusDismissal: Task<Void, Never>?
    @State private var rollPulse = 0
    @State private var holdPulse = 0
    @State private var scorePulse = 0
    @State private var yahtzeePulse = 0

    private var isWide: Bool { sizeClass == .regular }

    private var actions: GameActions {
        GameActions(
            toggleHold: holdDie,
            score: place,
            roll: roll,
            leave: leave
        )
    }

    var body: some View {
        GeometryReader { proxy in
            // Naast elkaar zodra er meer breedte dan hoogte is en we op een
            // iPad zitten. Een iPhone staat altijd rechtop, dus die valt
            // vanzelf in de kolomvorm.
            let sideBySide = isWide && proxy.size.width > proxy.size.height

            ZStack {
                AppTheme.cream.ignoresSafeArea()

                if sideBySide {
                    GameWideLayout(
                        engine: engine,
                        actions: actions,
                        isCelebrating: celebrateYahtzee,
                        availableWidth: proxy.size.width
                    )
                } else {
                    GameTallLayout(
                        engine: engine,
                        actions: actions,
                        isCelebrating: celebrateYahtzee
                    )
                }

                if showTurnBanner {
                    TurnBannerView(player: engine.currentPlayer)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .move(edge: .top).combined(with: .opacity)
                        )
                        .zIndex(2)
                }

                if celebrateYahtzee {
                    CelebrationBurstView(title: RollPhrase.yahtzee, tint: AppTheme.coral)
                        .zIndex(3)
                }

                if celebrateBonus {
                    CelebrationBurstView(title: "+\(engine.lastYahtzeeBonus)!", tint: AppTheme.amber)
                        .zIndex(3)
                }

                if engine.isFinished {
                    GameResultOverlay(
                        players: engine.players,
                        winnerProfileIDs: engine.winnerProfileIDs,
                        message: engine.turnMessage,
                        onClose: onClose
                    )
                    .zIndex(4)
                }
            }
        }
        .task(id: engine.currentPlayerIndex) {
            await engine.playComputerTurnIfNeeded()
        }
        .onChange(of: engine.saveVersion) { _, _ in
            persistProgress()
        }
        .onChange(of: engine.isFinished) { _, finished in
            guard finished else { return }
            recordResult()
        }
        .onChange(of: engine.isRolling) { wasRolling, isRolling in
            guard wasRolling, !isRolling else { return }
            rollDidFinish()
        }
        .onChange(of: engine.turnJustChanged) { _, changed in
            guard changed else { return }
            presentTurnBanner()
            engine.acknowledgeTurnChange()
        }
        .onChange(of: celebrateBonus) { _, show in
            guard show else { return }
            bonusDismissal?.cancel()
            bonusDismissal = dismissCelebration { celebrateBonus = false }
        }
        .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.85), trigger: rollPulse)
        .sensoryFeedback(.selection, trigger: holdPulse)
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.6), trigger: scorePulse)
        .sensoryFeedback(.success, trigger: yahtzeePulse)
    }

    // MARK: - Zetten

    private func holdDie(_ id: UUID) {
        engine.toggleHold(dieID: id)
        holdPulse += 1
    }

    private func place(_ category: ScoreCategory) {
        engine.score(in: category)
        scorePulse += 1
        if engine.lastYahtzeeBonus > 0 {
            celebrateBonus = true
            yahtzeePulse += 1
        }
    }

    private func roll() {
        Task { await engine.rollDice() }
    }

    private func leave() {
        persistProgress()
        onClose()
    }

    // MARK: - Reacties op het spel

    private func rollDidFinish() {
        rollPulse += 1
        guard YahtzeeScorer.isYahtzee(engine.diceValues) else { return }
        celebrateYahtzee = true
        yahtzeePulse += 1
        yahtzeeDismissal?.cancel()
        yahtzeeDismissal = dismissCelebration { celebrateYahtzee = false }
    }

    private func recordResult() {
        guard !didRecordResult else { return }
        didRecordResult = true
        gameStore.clear()
        profileStore.recordGameResult(
            winnerProfileIDs: engine.winnerProfileIDs,
            participantProfileIDs: engine.players.map(\.profileID)
        )
    }

    private func presentTurnBanner() {
        guard !engine.isFinished else { return }
        // Solo tegen de computer: geen banner voor je eigen beurt na de AI.
        if engine.mode == .versusComputer, !engine.currentPlayer.isComputer {
            scorePulse += 1
            return
        }
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.35, dampingFraction: 0.8)) {
            showTurnBanner = true
        }
        scorePulse += 1
        // Bij twee snelle beurtwissels zou de timer van de eerste de banner
        // van de tweede verbergen; annuleren voorkomt dat.
        bannerDismissal?.cancel()
        bannerDismissal = Task {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 700 : 1100))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                showTurnBanner = false
            }
        }
    }

    private func dismissCelebration(_ update: @escaping () -> Void) -> Task<Void, Never> {
        Task {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 600 : 1100))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                update()
            }
        }
    }

    private func persistProgress() {
        if engine.isFinished {
            gameStore.clear()
        } else {
            gameStore.save(engine.snapshot)
        }
    }
}
