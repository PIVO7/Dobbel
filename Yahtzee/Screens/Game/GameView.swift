import SwiftUI

struct GameView: View {
    @Bindable var engine: GameEngine
    @Environment(ProfileStore.self) private var profileStore
    let onClose: () -> Void

    @State private var didRecordResult = false
    @State private var showExitConfirm = false
    @State private var messageBounce = false
    @State private var resultAppeared = false

    var body: some View {
        ZStack {
            FeltBackground()

            VStack(spacing: 0) {
                header
                playerStrip
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                DiceTrayView(
                    dice: engine.dice,
                    isRolling: engine.isRolling,
                    canInteract: engine.canScore && engine.rollsRemaining > 0
                ) { id in
                    engine.toggleHold(dieID: id)
                }
                .padding(.horizontal, 12)

                Text(engine.turnMessage)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.cream)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .scaleEffect(messageBounce ? 1.05 : 1)
                    .animation(AppTheme.springBouncy, value: messageBounce)

                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(index < engine.rollsRemaining ? AppTheme.gold : AppTheme.cream.opacity(0.25))
                                .frame(width: 12, height: 12)
                                .scaleEffect(index < engine.rollsRemaining ? 1 : 0.85)
                        }
                        Text("worpen")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.gold)
                    }

                    Spacer()

                    Button {
                        Task { await engine.rollDice() }
                    } label: {
                        Text(engine.isRolling ? "Bezig…" : "Gooien!")
                            .font(AppTheme.headlineFont)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(engine.canRoll ? AppTheme.coral : AppTheme.coral.opacity(0.35))
                                    .shadow(
                                        color: engine.canRoll ? AppTheme.coral.opacity(0.35) : .clear,
                                        radius: 8,
                                        y: 4
                                    )
                            )
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(PopButtonStyle())
                    .disabled(!engine.canRoll)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                ScorecardView(
                    players: engine.players,
                    currentPlayerID: engine.currentPlayer.id,
                    diceValues: engine.diceValues,
                    canScore: engine.canScore,
                    onSelect: { engine.score(in: $0) }
                )
            }

            if engine.isFinished {
                resultOverlay
            }
        }
        .task(id: engine.currentPlayerIndex) {
            await engine.playComputerTurnIfNeeded()
        }
        .onChange(of: engine.turnMessage) { _, _ in
            messageBounce = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                messageBounce = false
            }
        }
        .onChange(of: engine.isFinished) { _, finished in
            guard finished, !didRecordResult else { return }
            didRecordResult = true
            withAnimation(AppTheme.springBouncy) {
                resultAppeared = true
            }
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

    private var header: some View {
        HStack {
            Button {
                if engine.isFinished {
                    onClose()
                } else {
                    showExitConfirm = true
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.cream.opacity(0.9))
            }
            Spacer()
            Text("Yahtzee")
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.cream)
            Spacer()
            Color.clear.frame(width: 28, height: 28)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var playerStrip: some View {
        HStack(spacing: 8) {
            ForEach(engine.players) { player in
                let isCurrent = player.id == engine.currentPlayer.id
                VStack(spacing: 4) {
                    Text(player.name)
                        .font(AppTheme.captionFont)
                        .lineLimit(1)
                    Text("\(player.scorecard.total)")
                        .font(AppTheme.headlineFont)
                        .contentTransition(.numericText())
                }
                .foregroundStyle(isCurrent ? AppTheme.ink : AppTheme.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isCurrent ? AppTheme.gold : AppTheme.feltDeep.opacity(0.55))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(isCurrent ? AppTheme.cream.opacity(0.55) : .clear, lineWidth: 2)
                }
                .scaleEffect(isCurrent ? 1.03 : 1)
                .animation(AppTheme.springSnappy, value: engine.currentPlayerIndex)
            }
        }
    }

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.48).ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppTheme.menuAccents[index % AppTheme.menuAccents.count])
                            .frame(width: 18, height: 18)
                            .rotationEffect(.degrees(Double(index) * 28 - 40))
                            .offset(
                                x: CGFloat([-48, -24, 0, 28, 52][index]),
                                y: resultAppeared ? CGFloat([-18, -34, -42, -30, -14][index]) : 0
                            )
                            .opacity(resultAppeared ? 1 : 0)
                    }

                    Text("Klaar!")
                        .font(AppTheme.titleFont)
                }
                .frame(height: 70)

                Text(engine.turnMessage)
                    .font(AppTheme.bodyFont)
                    .multilineTextAlignment(.center)

                ForEach(engine.players) { player in
                    HStack {
                        Text(player.name)
                        Spacer()
                        Text("\(player.scorecard.total)")
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(
                                engine.winnerProfileIDs.contains(player.profileID)
                                    ? AppTheme.coral
                                    : AppTheme.ink
                            )
                    }
                }

                Button("Terug naar menu", action: onClose)
                    .font(AppTheme.headlineFont)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 14)
                    .background(AppTheme.coral, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .foregroundStyle(.white)
                    .buttonStyle(PopButtonStyle())
                    .padding(.top, 6)
            }
            .foregroundStyle(AppTheme.ink)
            .padding(26)
            .background(AppTheme.cream, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
            .padding(28)
            .scaleEffect(resultAppeared ? 1 : 0.86)
            .opacity(resultAppeared ? 1 : 0)
        }
        .transition(.opacity)
    }
}
