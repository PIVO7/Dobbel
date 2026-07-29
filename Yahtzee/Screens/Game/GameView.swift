import SwiftUI

struct GameView: View {
    @Bindable var engine: GameEngine
    @Environment(ProfileStore.self) private var profileStore
    @Environment(GameStore.self) private var gameStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.metrics) private var m
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onClose: () -> Void

    @State private var didRecordResult = false
    @State private var showExitConfirm = false
    @State private var showTurnBanner = false
    @State private var celebrateYahtzee = false
    @State private var celebrateBonus = false
    @State private var rollPulse = 0
    @State private var holdPulse = 0
    @State private var scorePulse = 0
    @State private var yahtzeePulse = 0

    private var isWide: Bool { sizeClass == .regular }

    var body: some View {
        GeometryReader { proxy in
            // Naast elkaar zodra er meer breedte dan hoogte is en we op een
            // iPad zitten. Een iPhone staat altijd rechtop, dus die valt
            // vanzelf in de kolomvorm.
            let sideBySide = sizeClass == .regular && proxy.size.width > proxy.size.height

            ZStack {
                AppTheme.cream.ignoresSafeArea()

                if sideBySide {
                    wideLayout(width: proxy.size.width)
                } else {
                    tallLayout
                }

                if showTurnBanner {
                    turnBanner
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        .zIndex(2)
                }

                if celebrateYahtzee {
                    celebrationBurst(title: "YAHTZEE!", tint: AppTheme.coral)
                        .zIndex(3)
                }

                if celebrateBonus {
                    celebrationBurst(title: "+\(engine.lastYahtzeeBonus)!", tint: AppTheme.amber)
                        .zIndex(3)
                }

                if engine.isFinished {
                    resultOverlay
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
            guard finished, !didRecordResult else { return }
            didRecordResult = true
            gameStore.clear()
            profileStore.recordGameResult(
                winnerProfileIDs: engine.winnerProfileIDs,
                participantProfileIDs: engine.players.map(\.profileID)
            )
        }
        .onChange(of: engine.isRolling) { wasRolling, isRolling in
            if wasRolling && !isRolling {
                rollPulse += 1
                if RollPhrase.describe(engine.diceValues) == "YAHTZEE!" {
                    celebrateYahtzee = true
                    yahtzeePulse += 1
                    dismissCelebration { celebrateYahtzee = false }
                }
            }
        }
        .onChange(of: engine.turnJustChanged) { _, changed in
            guard changed else { return }
            presentTurnBanner()
            engine.acknowledgeTurnChange()
        }
        .onChange(of: celebrateBonus) { _, show in
            if show { dismissCelebration { celebrateBonus = false } }
        }
        .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.85), trigger: rollPulse)
        .sensoryFeedback(.selection, trigger: holdPulse)
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.6), trigger: scorePulse)
        .sensoryFeedback(.success, trigger: yahtzeePulse)
        .confirmationDialog("Spel verlaten?", isPresented: $showExitConfirm, titleVisibility: .visible) {
            Button("Verlaten", role: .destructive) {
                persistProgress()
                onClose()
            }
            Button("Doorspelen", role: .cancel) {}
        } message: {
            Text("Je voortgang wordt bewaard.")
        }
    }

    // MARK: - Indelingen

    private var tallLayout: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, 6)

                roundStrip
                    .padding(.top, m.gutter)

                DiceTrayView(
                    dice: engine.dice,
                    isRolling: engine.isRolling,
                    canInteract: engine.canScore && engine.rollsRemaining > 0
                ) { id in
                    engine.toggleHold(dieID: id)
                    holdPulse += 1
                }
                .padding(.top, m.gutter * 0.8)

                callout
                    .padding(.top, 4)
                    .padding(.bottom, m.gutter)

                ScorecardView(
                    players: engine.players,
                    currentPlayerID: engine.currentPlayer.id,
                    diceValues: engine.diceValues,
                    canScore: engine.canScore,
                    onSelect: { category in
                        engine.score(in: category)
                        scorePulse += 1
                        if engine.lastYahtzeeBonus > 0 {
                            celebrateBonus = true
                            yahtzeePulse += 1
                        }
                    }
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
            rollButton
                .padding(.horizontal, m.gutter)
                .padding(.top, m.gutter * 0.4)
                .padding(.bottom, m.gutter * 0.6)
                .frame(maxWidth: m.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .background(AppTheme.cream)
        }
    }

    private func wideLayout(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 6)

            HStack(alignment: .top, spacing: m.gutter * 1.5) {
                VStack(spacing: 0) {
                    roundStrip
                        .padding(.top, m.gutter)

                    Spacer(minLength: 8)

                    DiceTrayView(
                        dice: engine.dice,
                        isRolling: engine.isRolling,
                        canInteract: engine.canScore && engine.rollsRemaining > 0
                    ) { id in
                        engine.toggleHold(dieID: id)
                        holdPulse += 1
                    }

                    callout
                        .padding(.top, 4)

                    Spacer(minLength: 8)

                    rollButton
                }
                .frame(width: max(width * 0.42 - m.gutter, 320))

                ScrollView {
                    ScorecardView(
                        players: engine.players,
                        currentPlayerID: engine.currentPlayer.id,
                        diceValues: engine.diceValues,
                        canScore: engine.canScore,
                        onSelect: { category in
                            engine.score(in: category)
                            scorePulse += 1
                            if engine.lastYahtzeeBonus > 0 {
                                celebrateBonus = true
                                yahtzeePulse += 1
                            }
                        }
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

    // MARK: - Kop

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(Array(engine.players.enumerated()), id: \.element.id) { index, player in
                    if index > 0 {
                        Text("·")
                            .font(AppTheme.rounded(m.captionSize, .bold))
                            .foregroundStyle(AppTheme.dim)
                    }
                    Text("\(player.name) \(player.scorecard.total)")
                        .font(AppTheme.rounded(m.captionSize, .bold))
                        .foregroundStyle(player.id == engine.currentPlayer.id ? AppTheme.coral : AppTheme.ink)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, m.gutter * 0.5)
            .frame(maxWidth: .infinity)
            .toyBlock(fill: .white, radius: m.cellCorner + 3, depth: 3, border: m.thinBorder + 0.5)

            Button {
                if engine.isFinished {
                    onClose()
                } else {
                    showExitConfirm = true
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: m.captionSize + 2, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: m.tapTarget, height: m.tapTarget)
            }
            .buttonStyle(ToyButtonStyle(fill: .white, radius: m.cellCorner, depth: 3, border: m.thinBorder))
            .accessibilityLabel("Spel verlaten")
        }
    }

    private var roundStrip: some View {
        VStack(spacing: 7) {
            Text("RONDE \(engine.roundNumber) / \(ScoreCategory.allCases.count)")
                .font(AppTheme.rounded(m.captionSize * 0.92))
                .kerning(1.6)
                .foregroundStyle(AppTheme.faint)

            HStack(spacing: 4) {
                ForEach(0..<ScoreCategory.allCases.count, id: \.self) { index in
                    Circle()
                        .fill(index < engine.roundNumber ? AppTheme.amber : AppTheme.tintStone)
                        .frame(width: m.captionSize * 0.6, height: m.captionSize * 0.6)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ronde \(engine.roundNumber) van \(ScoreCategory.allCases.count)")
    }

    // MARK: - Uitslag in woorden

    private var callout: some View {
        VStack(spacing: 4) {
            Text(calloutTitle)
                .font(AppTheme.rounded(m.displaySize))
                .foregroundStyle(calloutTitle == "YAHTZEE!" ? AppTheme.coral : AppTheme.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .contentTransition(.opacity)
                .scaleEffect(celebrateYahtzee && !reduceMotion ? 1.08 : 1)

            Text(engine.turnMessage)
                .font(AppTheme.rounded(m.captionSize, .bold))
                .foregroundStyle(AppTheme.soft)
                .multilineTextAlignment(.center)
        }
        .frame(minHeight: m.displaySize * 2.1)
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.6), value: celebrateYahtzee)
    }

    /// Aan het begin van een beurt liggen de stenen op 1-1-1-1-1. Dat is geen
    /// worp, dus die mag niet als "YAHTZEE!" worden voorgelezen.
    private var calloutTitle: String {
        if engine.isRolling { return "…" }
        guard engine.hasRolledThisTurn else {
            return engine.currentPlayer.isComputer ? "Even wachten…" : "Gooi maar!"
        }
        return RollPhrase.describe(engine.diceValues)
    }

    // MARK: - Gooien

    private var rollButton: some View {
        Button {
            Task { await engine.rollDice() }
        } label: {
            HStack(spacing: 10) {
                Text(rollTitle)
                    .font(AppTheme.rounded(m.buttonTextSize))
                if engine.rollsRemaining > 0 {
                    Text("\(engine.rollsRemaining)")
                        .font(AppTheme.rounded(m.buttonTextSize * 0.7))
                        .frame(minWidth: m.buttonTextSize * 1.35, minHeight: m.buttonTextSize * 1.35)
                        .background(
                            Color.black.opacity(0.18),
                            in: RoundedRectangle(cornerRadius: m.buttonTextSize * 0.42, style: .continuous)
                        )
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: m.buttonHeight)
        }
        .buttonStyle(ToyButtonStyle(
            fill: engine.canRoll ? AppTheme.mint : AppTheme.offFill,
            radius: m.cardCorner * 0.9,
            depth: m.depth + 1,
            border: m.border
        ))
        .disabled(!engine.canRoll)
    }

    private var rollTitle: String {
        if engine.isRolling { return "Bezig…" }
        if engine.rollsRemaining == 0 { return "Kies een vakje" }
        return "Gooien"
    }

    // MARK: - Beurt & viering

    private var turnBanner: some View {
        VStack {
            Spacer()
            Text("Beurt van \(engine.currentPlayer.name)")
                .font(AppTheme.rounded(m.bodySize + 2))
                .foregroundStyle(.white)
                .padding(.horizontal, m.gutter * 1.5)
                .padding(.vertical, m.gutter)
                .toyBlock(fill: AppTheme.coral, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)
                .padding(.bottom, isWide ? 40 : 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.ink.opacity(0.25).ignoresSafeArea())
        .allowsHitTesting(false)
    }

    private func celebrationBurst(title: String, tint: Color) -> some View {
        Text(title)
            .font(AppTheme.rounded(m.displaySize * 1.4))
            .foregroundStyle(.white)
            .padding(.horizontal, m.gutter * 2)
            .padding(.vertical, m.gutter * 1.3)
            .toyBlock(fill: tint, radius: m.cardCorner, depth: m.depth + 1, border: m.border)
            .scaleEffect(reduceMotion ? 1 : 1.05)
            .transition(.opacity.combined(with: .scale(scale: 0.8)))
            .allowsHitTesting(false)
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
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 700 : 1100))
            withAnimation(.easeOut(duration: 0.2)) {
                showTurnBanner = false
            }
        }
    }

    private func dismissCelebration(_ update: @escaping () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 600 : 1100))
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

    // MARK: - Einde

    private var resultOverlay: some View {
        ZStack {
            AppTheme.ink.opacity(0.5).ignoresSafeArea()

            VStack(spacing: m.gutter) {
                Text(engine.winnerProfileIDs.count == 1 ? "Gewonnen!" : "Klaar!")
                    .font(AppTheme.rounded(m.titleSize))
                    .foregroundStyle(AppTheme.ink)

                Text(engine.turnMessage)
                    .font(AppTheme.rounded(m.bodySize, .bold))
                    .foregroundStyle(AppTheme.soft)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    ForEach(engine.players) { player in
                        let isWinner = engine.winnerProfileIDs.contains(player.profileID)
                        HStack {
                            AvatarBadge(player: player, size: m.avatarSize * 0.72)
                            Text(player.name)
                                .font(AppTheme.rounded(m.bodySize, .bold))
                            Spacer()
                            Text("\(player.scorecard.total)")
                                .font(AppTheme.rounded(m.bodySize + 4))
                            if isWinner && engine.winnerProfileIDs.count == 1 {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(AppTheme.amber)
                            }
                        }
                        .foregroundStyle(AppTheme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .toyBlock(
                            fill: isWinner ? AppTheme.tintAmber : AppTheme.sunk,
                            radius: m.cellCorner + 1,
                            depth: 0,
                            border: m.thinBorder
                        )
                    }
                }

                Button(action: onClose) {
                    Text("Terug naar menu")
                        .font(AppTheme.rounded(m.buttonTextSize * 0.85))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: m.buttonHeight * 0.9)
                }
                .buttonStyle(ToyButtonStyle(
                    fill: AppTheme.coral,
                    radius: m.cardCorner * 0.8,
                    depth: m.depth,
                    border: m.border
                ))
                .padding(.top, 4)
            }
            .padding(m.gutter * 1.5)
            .toyBlock(fill: .white, radius: m.cardCorner + 4, depth: m.depth + 1, border: m.border)
            .frame(maxWidth: 460)
            .padding(m.gutter * 2)
        }
        .transition(.opacity.combined(with: .scale))
    }
}
