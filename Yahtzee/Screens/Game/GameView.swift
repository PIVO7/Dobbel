import SwiftUI

struct GameView: View {
    @Bindable var engine: GameEngine
    @Environment(ProfileStore.self) private var profileStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    let onClose: () -> Void

    @State private var didRecordResult = false
    @State private var showExitConfirm = false

    private var m: AppMetrics { .resolve(sizeClass) }

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

                if engine.isFinished {
                    resultOverlay
                }
            }
        }
        .task(id: engine.currentPlayerIndex) {
            await engine.playComputerTurnIfNeeded()
        }
        .onChange(of: engine.isFinished) { _, finished in
            guard finished, !didRecordResult else { return }
            didRecordResult = true
            profileStore.recordGameResult(
                winnerProfileIDs: engine.winnerProfileIDs,
                participantProfileIDs: engine.players.map(\.profileID)
            )
        }
        .confirmationDialog("Spel verlaten?", isPresented: $showExitConfirm, titleVisibility: .visible) {
            Button("Verlaten", role: .destructive, action: onClose)
            Button("Doorspelen", role: .cancel) {}
        }
    }

    // MARK: - Indelingen

    private var tallLayout: some View {
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
                onSelect: { engine.score(in: $0) }
            )

            Spacer(minLength: 12)

            rollButton
                .padding(.bottom, m.gutter * 1.5)
        }
        .padding(.horizontal, m.gutter)
        .frame(maxWidth: m.contentMaxWidth)
        .frame(maxWidth: .infinity)
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
                    }

                    callout
                        .padding(.top, 4)

                    Spacer(minLength: 8)

                    rollButton
                }
                .frame(width: max(width * 0.42 - m.gutter, 320))

                ScorecardView(
                    players: engine.players,
                    currentPlayerID: engine.currentPlayer.id,
                    diceValues: engine.diceValues,
                    canScore: engine.canScore,
                    onSelect: { engine.score(in: $0) }
                )
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
                    .frame(width: m.avatarSize * 0.78, height: m.avatarSize * 0.78)
            }
            .buttonStyle(ToyButtonStyle(fill: .white, radius: m.cellCorner, depth: 3, border: m.thinBorder))
            .accessibilityLabel("Spel verlaten")
        }
    }

    private var roundStrip: some View {
        VStack(spacing: 7) {
            Text("RONDE \(roundNumber) / \(ScoreCategory.allCases.count)")
                .font(AppTheme.rounded(m.captionSize * 0.92))
                .kerning(1.6)
                .foregroundStyle(AppTheme.faint)

            HStack(spacing: 4) {
                ForEach(0..<ScoreCategory.allCases.count, id: \.self) { index in
                    Circle()
                        .fill(index < roundNumber ? AppTheme.amber : AppTheme.tintStone)
                        .frame(width: m.captionSize * 0.6, height: m.captionSize * 0.6)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ronde \(roundNumber) van \(ScoreCategory.allCases.count)")
    }

    private var roundNumber: Int {
        min(engine.currentPlayer.scorecard.filledCount + 1, ScoreCategory.allCases.count)
    }

    // MARK: - Uitslag in woorden

    private var callout: some View {
        VStack(spacing: 4) {
            Text(engine.isRolling ? "…" : RollPhrase.describe(engine.diceValues))
                .font(AppTheme.rounded(m.displaySize))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .contentTransition(.opacity)

            Text(engine.turnMessage)
                .font(AppTheme.rounded(m.captionSize, .bold))
                .foregroundStyle(AppTheme.soft)
                .multilineTextAlignment(.center)
        }
        .frame(minHeight: m.displaySize * 2.1)
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

    // MARK: - Einde

    private var resultOverlay: some View {
        ZStack {
            AppTheme.ink.opacity(0.5).ignoresSafeArea()

            VStack(spacing: m.gutter) {
                Text("Klaar!")
                    .font(AppTheme.rounded(m.titleSize))
                    .foregroundStyle(AppTheme.ink)

                Text(engine.turnMessage)
                    .font(AppTheme.rounded(m.bodySize, .bold))
                    .foregroundStyle(AppTheme.soft)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    ForEach(engine.players) { player in
                        HStack {
                            Text(player.name)
                                .font(AppTheme.rounded(m.bodySize, .bold))
                            Spacer()
                            Text("\(player.scorecard.total)")
                                .font(AppTheme.rounded(m.bodySize + 4))
                        }
                        .foregroundStyle(AppTheme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .toyBlock(fill: AppTheme.sunk, radius: m.cellCorner + 1, depth: 0, border: m.thinBorder)
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
