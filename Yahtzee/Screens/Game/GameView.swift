import SwiftUI

struct GameView: View {
    @Bindable var engine: GameEngine
    @Environment(ProfileStore.self) private var profileStore
    let onClose: () -> Void

    @State private var didRecordResult = false
    @State private var showExitConfirm = false

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                roundStrip
                    .padding(.top, 16)

                DiceTrayView(
                    dice: engine.dice,
                    isRolling: engine.isRolling,
                    canInteract: engine.canScore && engine.rollsRemaining > 0
                ) { id in
                    engine.toggleHold(dieID: id)
                }
                .padding(.top, 12)

                callout
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    .padding(.bottom, 14)

                ScorecardView(
                    players: engine.players,
                    currentPlayerID: engine.currentPlayer.id,
                    diceValues: engine.diceValues,
                    canScore: engine.canScore,
                    onSelect: { engine.score(in: $0) }
                )
                .padding(.horizontal, 14)

                Spacer(minLength: 12)

                rollButton
                    .padding(.horizontal, 14)
                    .padding(.bottom, 22)
            }

            if engine.isFinished {
                resultOverlay
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

    // MARK: - Kop

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(Array(engine.players.enumerated()), id: \.element.id) { index, player in
                    if index > 0 {
                        Text("·")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.dim)
                    }
                    Text("\(player.name) \(player.scorecard.total)")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(player.id == engine.currentPlayer.id ? AppTheme.coral : AppTheme.ink)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .toyBlock(fill: .white, radius: 14, depth: 3, border: 2.5)

            Button {
                if engine.isFinished {
                    onClose()
                } else {
                    showExitConfirm = true
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(ToyButtonStyle(fill: .white, radius: 11, depth: 3))
            .accessibilityLabel("Spel verlaten")
        }
    }

    private var roundStrip: some View {
        VStack(spacing: 7) {
            Text("RONDE \(roundNumber) / \(ScoreCategory.allCases.count)")
                .font(AppTheme.labelFont)
                .kerning(1.6)
                .foregroundStyle(AppTheme.faint)

            HStack(spacing: 4) {
                ForEach(0..<ScoreCategory.allCases.count, id: \.self) { index in
                    Circle()
                        .fill(index < roundNumber ? AppTheme.amber : AppTheme.tintStone)
                        .frame(width: 7, height: 7)
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
                .font(AppTheme.displayFont)
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)

            Text(engine.turnMessage)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.soft)
                .multilineTextAlignment(.center)
        }
        .frame(minHeight: 62)
    }

    // MARK: - Gooien

    private var rollButton: some View {
        Button {
            Task { await engine.rollDice() }
        } label: {
            HStack(spacing: 10) {
                Text(rollTitle)
                    .font(.system(size: 21, weight: .black, design: .rounded))
                if engine.rollsRemaining > 0 {
                    Text("\(engine.rollsRemaining)")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .frame(minWidth: 28, minHeight: 28)
                        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
        .buttonStyle(ToyButtonStyle(fill: engine.canRoll ? AppTheme.mint : AppTheme.offFill, radius: 18, depth: 6))
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

            VStack(spacing: 16) {
                Text("Klaar!")
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.ink)

                Text(engine.turnMessage)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.soft)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    ForEach(engine.players) { player in
                        HStack {
                            Text(player.name)
                                .font(AppTheme.bodyFont)
                            Spacer()
                            Text("\(player.scorecard.total)")
                                .font(AppTheme.headlineFont)
                        }
                        .foregroundStyle(AppTheme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .toyBlock(fill: AppTheme.sunk, radius: 12, depth: 0, border: 2)
                    }
                }

                Button(action: onClose) {
                    Text("Terug naar menu")
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                }
                .buttonStyle(ToyButtonStyle(fill: AppTheme.coral, radius: 16, depth: 5))
                .padding(.top, 4)
            }
            .padding(22)
            .toyBlock(fill: .white, radius: 24, depth: 6)
            .padding(28)
        }
        .transition(.opacity.combined(with: .scale))
    }
}
