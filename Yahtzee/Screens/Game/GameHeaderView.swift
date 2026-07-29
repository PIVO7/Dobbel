import SwiftUI

/// De stand van alle spelers op één regel, met de sluitknop ernaast.
struct GameHeaderView: View {
    let players: [GamePlayer]
    let currentPlayerID: UUID
    let onClose: () -> Void

    @Environment(\.metrics) private var m

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    if index > 0 {
                        Text("·")
                            .font(AppTheme.rounded(m.captionSize, .bold))
                            .foregroundStyle(AppTheme.dim)
                    }
                    Text("\(player.name) \(player.scorecard.total)")
                        .font(AppTheme.rounded(m.captionSize, .bold))
                        .foregroundStyle(player.id == currentPlayerID ? AppTheme.coral : AppTheme.ink)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, m.gutter * 0.5)
            .frame(maxWidth: .infinity)
            .toyBlock(fill: .white, radius: m.cellCorner + 3, depth: 3, border: m.thinBorder + 0.5)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: m.captionSize + 2, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: m.tapTarget, height: m.tapTarget)
            }
            .buttonStyle(ToyButtonStyle(fill: .white, radius: m.cellCorner, depth: 3, border: m.thinBorder))
            .accessibilityLabel("Spel verlaten")
        }
    }
}

#Preview {
    let lene = GamePlayer(profile: PlayerProfile(name: "Lene", avatarColorIndex: 0))
    let ellis = GamePlayer(profile: PlayerProfile(name: "Ellis", avatarColorIndex: 1))

    GameHeaderView(players: [lene, ellis], currentPlayerID: lene.id, onClose: {})
        .padding()
        .background(AppTheme.cream)
}
