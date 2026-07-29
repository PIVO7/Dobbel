import SwiftUI

/// De eindstand over het spelbord heen, met de winnaar in de verf.
struct GameResultOverlay: View {
    let players: [GamePlayer]
    let winnerProfileIDs: [UUID]
    let message: String
    let onClose: () -> Void

    @Environment(\.metrics) private var m

    private var hasSingleWinner: Bool { winnerProfileIDs.count == 1 }

    var body: some View {
        ZStack {
            AppTheme.ink.opacity(0.5).ignoresSafeArea()

            VStack(spacing: m.gutter) {
                Text(hasSingleWinner ? "Gewonnen!" : "Klaar!")
                    .font(AppTheme.rounded(m.titleSize))
                    .foregroundStyle(AppTheme.ink)

                Text(message)
                    .font(AppTheme.rounded(m.bodySize, .bold))
                    .foregroundStyle(AppTheme.soft)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    ForEach(players) { player in
                        row(for: player)
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
            .frame(maxWidth: m.overlayMaxWidth)
            .padding(m.gutter * 2)
        }
        .transition(.opacity.combined(with: .scale))
    }

    private func row(for player: GamePlayer) -> some View {
        let isWinner = winnerProfileIDs.contains(player.profileID)
        return HStack {
            AvatarBadge(player: player, size: m.avatarSize * 0.72)
            Text(player.name)
                .font(AppTheme.rounded(m.bodySize, .bold))
            Spacer()
            Text("\(player.scorecard.total)")
                .font(AppTheme.rounded(m.bodySize + 4))
            if isWinner && hasSingleWinner {
                Image(systemName: "star.fill")
                    .foregroundStyle(AppTheme.amber)
                    .accessibilityHidden(true)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(player.name), \(player.scorecard.total) punten"
                + (isWinner && hasSingleWinner ? ", winnaar" : "")
        )
    }
}

#Preview {
    let lene = GamePlayer(profile: PlayerProfile(name: "Lene", avatarColorIndex: 0))
    let ellis = GamePlayer(profile: PlayerProfile(name: "Ellis", avatarColorIndex: 1))

    GameResultOverlay(
        players: [lene, ellis],
        winnerProfileIDs: [lene.profileID],
        message: "Lene wint met 212 punten!",
        onClose: {}
    )
    .background(AppTheme.cream)
}
