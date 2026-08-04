import SwiftUI

/// De worp in woorden, met daaronder wie er speelt: het avatar-bolletje met
/// de boodschap van dit moment op een eigen kaartje. Zo zie je onder de
/// stenen in één oogopslag wiens beurt het is.
struct RollCalloutView: View {
    let title: String
    let message: String
    let player: GamePlayer
    let isCelebrating: Bool

    @Environment(\.metrics) private var m
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: m.gutter * 0.5) {
            Text(title)
                .font(AppTheme.rounded(m.displaySize))
                .foregroundStyle(title == RollPhrase.dobbel ? AppTheme.coral : AppTheme.headline)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .contentTransition(.opacity)
                .scaleEffect(isCelebrating && !reduceMotion ? 1.08 : 1)

            HStack(spacing: 7) {
                AvatarBadge(player: player, size: m.captionSize * 1.9)
                Text(message.isEmpty ? player.name : message)
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .toyBlock(fill: AppTheme.card, radius: m.cellCorner + 3, depth: 3, border: m.thinBorder)
            .accessibilityElement(children: .combine)
        }
        .frame(minHeight: m.displaySize * 1.8)
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.6), value: isCelebrating)
    }
}

#Preview {
    VStack(spacing: 24) {
        RollCalloutView(
            title: "Gooi maar!",
            message: "Lene mag gooien",
            player: GamePlayer(profile: PlayerProfile(name: "Lene", avatarColorIndex: 0)),
            isCelebrating: false
        )
        RollCalloutView(
            title: RollPhrase.dobbel,
            message: "Kies een vakje",
            player: GamePlayer(profile: PlayerProfile(name: "Ellis", avatarColorIndex: 1, avatarSymbol: "star.fill")),
            isCelebrating: true
        )
    }
    .padding()
    .background(AppTheme.cream)
    .appMetrics()
}
