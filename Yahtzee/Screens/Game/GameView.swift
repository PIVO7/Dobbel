import SwiftUI

/// Houdt het spel bij elkaar: kiest een indeling, bewaart de voortgang en
/// vertaalt zetten naar trillingen, banners en vieringen. Het tekenwerk zelf
/// zit in de losse views hiernaast.
struct GameView: View {
    let engine: GameEngine
    /// Vervangt het spel door een vers potje met dezelfde deelnemers; de
    /// eigenaar van de cover wisselt de engine.
    let onRematch: () -> Void
    let onClose: () -> Void

    @Environment(ProfileStore.self) private var profileStore
    @Environment(GameStore.self) private var gameStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.metrics) private var m

    /// De eerste-keer-uitleg: drie hints die elk op hun moment verschijnen.
    private enum CoachStep {
        case none, roll, hold, score
    }

    @State private var didRecordResult = false
    @State private var showTurnBanner = false
    @State private var showExitConfirm = false
    @State private var tipExplanation: String?
    @State private var coachStep: CoachStep = .none
    @State private var coachVisible = false
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
            leave: requestLeave,
            explainTip: explainTip
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

                if coachVisible {
                    coachOverlay
                        .zIndex(3)
                }

                if showTurnBanner {
                    TurnBannerView(player: engine.currentPlayer, title: bannerTitle)
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
                        onRematch: onRematch,
                        onClose: onClose
                    )
                    .zIndex(4)
                }

                if showExitConfirm {
                    ToyDialog(
                        title: "Spel verlaten?",
                        message: "Je voortgang wordt bewaard.",
                        confirmTitle: "Verlaten",
                        cancelTitle: "Doorspelen",
                        onConfirm: leave,
                        onCancel: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                showExitConfirm = false
                            }
                        }
                    )
                    .zIndex(5)
                }

                if let tipExplanation {
                    ToyDialog(
                        title: "Daarom!",
                        message: tipExplanation,
                        confirmTitle: "Snap ik!",
                        onConfirm: dismissTip,
                        onCancel: dismissTip
                    )
                    .zIndex(5)
                }
            }
        }
        .task(id: engine.currentPlayerIndex) {
            await engine.playComputerTurnIfNeeded()
        }
        .onAppear(perform: startCoachingIfNeeded)
        .onChange(of: engine.saveVersion) { _, _ in
            persistProgress()
        }
        .onChange(of: engine.isFinished) { _, finished in
            guard finished else { return }
            recordResult()
        }
        .onChange(of: engine.isRolling) { wasRolling, isRolling in
            // Hier en niet op de knop: zo ratelt het ook als de computer gooit.
            if !wasRolling, isRolling {
                SoundPlayer.shared.play(.roll)
            }
        }
        .onChange(of: engine.isSettling) { wasSettling, isSettling in
            // Pas als de stenen zijn uitgeveerd; anders barst de viering los
            // terwijl de laatste steen nog beweegt.
            guard wasSettling, !isSettling else { return }
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
        SoundPlayer.shared.play(.hold)
        if coachStep == .hold {
            advanceCoach(to: .score)
        }
    }

    private func place(_ category: ScoreCategory) {
        engine.score(in: category)
        scorePulse += 1
        if coachStep != .none {
            finishCoaching()
        }
        if engine.lastYahtzeeBonus > 0 {
            celebrateBonus = true
            yahtzeePulse += 1
            SoundPlayer.shared.play(.fanfare)
        } else {
            SoundPlayer.shared.play(.score)
        }
    }

    private func roll() {
        Task { await engine.rollDice() }
    }

    /// Een afgelopen spel valt niets meer te bewaren, dus dan slaan we de
    /// bevestiging over.
    private func requestLeave() {
        if engine.isFinished {
            leave()
        } else {
            withAnimation(.easeOut(duration: 0.15)) {
                showExitConfirm = true
            }
        }
    }

    private func leave() {
        persistProgress()
        onClose()
    }

    // MARK: - Eerste-keer-uitleg

    /// Alleen bij een allereerste, vers spel met een mens aan zet.
    private func startCoachingIfNeeded() {
        guard !CoachTour.seen,
              !engine.hasRolledThisTurn,
              !engine.isFinished,
              !engine.currentPlayer.isComputer else { return }
        advanceCoach(to: .roll)
    }

    private func advanceCoach(to step: CoachStep) {
        coachStep = step
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.35, dampingFraction: 0.8)) {
            coachVisible = true
        }
    }

    private func hideCoachBubble() {
        withAnimation(.easeOut(duration: 0.15)) {
            coachVisible = false
        }
    }

    private func finishCoaching() {
        CoachTour.seen = true
        coachStep = .none
        withAnimation(.easeOut(duration: 0.15)) {
            coachVisible = false
        }
    }

    @ViewBuilder
    private var coachOverlay: some View {
        VStack(spacing: 0) {
            switch coachStep {
            case .hold:
                CoachBubbleView(
                    text: "Tik op een steen om hem vast te houden. Met het handje gooit hij niet mee.",
                    icon: "hand.raised.fill",
                    onDismiss: hideCoachBubble
                )
                .padding(.top, m.tapTarget + m.gutter * 4)
                Spacer(minLength: 0)
            case .score:
                Spacer(minLength: 0)
                CoachBubbleView(
                    text: "Kies een vakje op het scoreblad voor je punten. Het groene vakje is de tip!",
                    icon: "checkmark.circle.fill",
                    onDismiss: hideCoachBubble
                )
                Spacer(minLength: 0)
            case .roll:
                Spacer(minLength: 0)
                CoachBubbleView(
                    text: "Tik op Gooien om te dobbelen!",
                    icon: "hand.tap.fill",
                    onDismiss: hideCoachBubble
                )
                .padding(.bottom, m.buttonHeight + m.gutter * 2)
            case .none:
                EmptyView()
            }
        }
        .padding(.horizontal, 24)
    }

    private func explainTip(_ category: ScoreCategory) {
        withAnimation(.easeOut(duration: 0.15)) {
            tipExplanation = AdviceExplainer.explain(
                category: category,
                dice: engine.diceValues,
                scorecard: engine.currentPlayer.scorecard
            )
        }
    }

    private func dismissTip() {
        withAnimation(.easeOut(duration: 0.15)) {
            tipExplanation = nil
        }
    }

    /// Solo spreekt de banner je aan; met z'n allen aan één toestel noemt hij
    /// de naam.
    private var bannerTitle: String? {
        if engine.mode == .versusComputer, !engine.currentPlayer.isComputer {
            return "Jij bent aan de beurt"
        }
        return nil
    }

    // MARK: - Reacties op het spel

    private func rollDidFinish() {
        rollPulse += 1
        // De worp in woorden ook uitspreken; visueel staat hij al in beeld.
        var announcement = engine.calloutTitle
        if !engine.turnMessage.isEmpty {
            announcement += ". \(engine.turnMessage)"
        }
        AccessibilityNotification.Announcement(announcement).post()
        switch coachStep {
        case .roll:
            advanceCoach(to: .hold)
        case .hold where !coachVisible:
            // De hint was al weggetikt en er is opnieuw gegooid: door naar
            // de laatste stap.
            advanceCoach(to: .score)
        default:
            break
        }
        guard YahtzeeScorer.isYahtzee(engine.diceValues) else { return }
        celebrateYahtzee = true
        yahtzeePulse += 1
        SoundPlayer.shared.play(.fanfare)
        yahtzeeDismissal?.cancel()
        yahtzeeDismissal = dismissCelebration { celebrateYahtzee = false }
    }

    private func recordResult() {
        guard !didRecordResult else { return }
        didRecordResult = true
        gameStore.clear()
        profileStore.recordGameResult(
            players: engine.players,
            winnerProfileIDs: engine.winnerProfileIDs
        )
    }

    private func presentTurnBanner() {
        guard !engine.isFinished else { return }
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.35, dampingFraction: 0.8)) {
            showTurnBanner = true
        }
        scorePulse += 1
        SoundPlayer.shared.play(.turn)
        AccessibilityNotification.Announcement(
            bannerTitle ?? "\(engine.currentPlayer.name) is aan de beurt"
        ).post()
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
