import SwiftUI

/// De stand van alle spelers op één regel, met de sluitknop ernaast. Wie aan
/// de beurt is krijgt een gekleurde chip met zijn bolletje — een kleurtje in
/// de naam alleen bleek te subtiel.
struct GameHeaderView: View {
    let players: [GamePlayer]
    let currentPlayerID: UUID
    /// Alleen waar zolang de vorige zet nog terug mag; dan verschijnt het
    /// terugzet-knopje naast de sluitknop, weg uit het speelveld.
    let canUndo: Bool
    let onUndo: () -> Void
    let onLeave: () -> Void

    @Environment(\.metrics) private var m

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(players) { player in
                    chip(for: player)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, m.gutter * 0.45)
            .frame(maxWidth: .infinity)
            .toyBlock(fill: AppTheme.card, radius: m.cellCorner + 3, depth: 3, border: m.thinBorder + 0.5)

            if canUndo {
                Button(action: onUndo) {
                    Label("Zet de vorige zet terug", systemImage: "arrow.uturn.backward")
                        .labelStyle(.iconOnly)
                        .font(.system(size: m.captionSize + 2, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: m.tapTarget, height: m.tapTarget)
                }
                .buttonStyle(ToyButtonStyle(fill: AppTheme.tintAmber, radius: m.cellCorner, depth: 3, border: m.thinBorder))
            }

            Button(action: onLeave) {
                Label("Spel verlaten", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.system(size: m.captionSize + 2, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: m.tapTarget, height: m.tapTarget)
            }
            .buttonStyle(ToyButtonStyle(fill: AppTheme.card, radius: m.cellCorner, depth: 3, border: m.thinBorder))
        }
    }

    private func chip(for player: GamePlayer) -> some View {
        let isMine = player.id == currentPlayerID
        return HStack(spacing: 5) {
            AvatarBadge(player: player, size: m.captionSize * 1.8)
            Text("\(player.name) \(player.scorecard.total)")
                // Wie aan de beurt is, springt er ook in de letters uit.
                .font(AppTheme.rounded(m.captionSize, isMine ? .black : .bold))
                .foregroundStyle(isMine ? AppTheme.ink : AppTheme.cardSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: m.cellCorner, style: .continuous)
                .fill(isMine ? AppTheme.tintCoral : .clear)
        )
        .overlay {
            RoundedRectangle(cornerRadius: m.cellCorner, style: .continuous)
                .strokeBorder(isMine ? AppTheme.coral : .clear, lineWidth: m.thinBorder)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(player.name), \(player.scorecard.total) punten" + (isMine ? ", aan de beurt" : "")
        )
    }
}

#Preview {
    let lene = GamePlayer(profile: PlayerProfile(name: "Lene", avatarColorIndex: 0))
    let ellis = GamePlayer(profile: PlayerProfile(name: "Ellis", avatarColorIndex: 1))

    GameHeaderView(players: [lene, ellis], currentPlayerID: lene.id, canUndo: true, onUndo: {}, onLeave: {})
        .padding()
        .background(AppTheme.cream)
        .appMetrics()
}
