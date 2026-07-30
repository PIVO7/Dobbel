import SwiftUI

/// De eindstand over het spelbord heen, met de winnaar in de verf.
struct GameResultOverlay: View {
    let players: [GamePlayer]
    let winnerProfileIDs: [UUID]
    let message: String
    let onRematch: () -> Void
    let onClose: () -> Void

    @Environment(\.metrics) private var m

    private var hasSingleWinner: Bool { winnerProfileIDs.count == 1 }

    var body: some View {
        ZStack {
            AppTheme.ink.opacity(0.5).ignoresSafeArea()

            VStack(spacing: m.gutter) {
                // De winnaar groot in beeld, met een kroontje: het sterretje
                // naast de score bleek te zoeken.
                if hasSingleWinner,
                   let winner = players.first(where: { winnerProfileIDs.contains($0.profileID) }) {
                    AvatarBadge(player: winner, size: m.avatarSize * 1.5)
                        .overlay(alignment: .top) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: m.avatarSize * 0.52, weight: .black))
                                .foregroundStyle(AppTheme.amber)
                                .rotationEffect(.degrees(14))
                                .offset(x: m.avatarSize * 0.52, y: -m.avatarSize * 0.4)
                        }
                        .padding(.top, m.gutter * 0.4)
                        .accessibilityHidden(true)
                }

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

                // De meest gemiste knop: meteen nog een potje met dezelfde
                // spelers en hetzelfde computerniveau.
                Button(action: onRematch) {
                    Text("Nog een keer!")
                        .font(AppTheme.rounded(m.buttonTextSize * 0.85))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: m.buttonHeight * 0.9)
                }
                .buttonStyle(ToyButtonStyle(
                    fill: AppTheme.mint,
                    radius: m.cardCorner * 0.8,
                    depth: m.depth,
                    border: m.border
                ))
                .padding(.top, 4)

                Button(action: onClose) {
                    Text("Terug naar menu")
                        .font(AppTheme.rounded(m.buttonTextSize * 0.85))
                        .foregroundStyle(AppTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: m.buttonHeight * 0.9)
                }
                .buttonStyle(ToyButtonStyle(
                    fill: .white,
                    radius: m.cardCorner * 0.8,
                    depth: m.depth,
                    border: m.border
                ))
            }
            .padding(m.gutter * 1.5)
            .toyBlock(fill: .white, radius: m.cardCorner + 4, depth: m.depth + 1, border: m.border)
            .frame(maxWidth: m.overlayMaxWidth)
            .padding(m.gutter * 2)
            // Modaal voor VoiceOver: het spelbord eronder is voorbij.
            .accessibilityAddTraits(.isModal)
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
            depth: isWinner ? 3 : 0,
            border: isWinner ? m.border : m.thinBorder
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
        onRematch: {},
        onClose: {}
    )
    .background(AppTheme.cream)
}
