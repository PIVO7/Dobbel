import SwiftUI

/// Korte melding bij een beurtwissel, zodat aan één toestel duidelijk is wie
/// er nu mag.
///
/// Hij komt bovenaan en dimt niets. Onderaan dekte hij precies de gooiknop af
/// — juist de knop die de nieuwe speler nodig heeft — en een grijs bord leest
/// als "de app doet even niets". De avatar staat erbij omdat een kind die
/// sneller herkent dan zijn naam.
struct TurnBannerView: View {
    let player: GamePlayer

    @Environment(\.metrics) private var m

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: m.gutter * 0.6) {
                AvatarBadge(player: player, size: m.avatarSize * 0.62)

                Text("\(player.name) is aan de beurt")
                    .font(AppTheme.rounded(m.bodySize))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.leading, m.gutter * 0.5)
            .padding(.trailing, m.gutter)
            .padding(.vertical, m.gutter * 0.4)
            .toyBlock(
                fill: AppTheme.coral,
                radius: m.cardCorner * 0.8,
                depth: m.depth,
                border: m.border
            )
            // Net onder de kop, waar alleen de rondestrip zit en geen knoppen.
            .padding(.top, m.tapTarget + m.gutter)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}

#Preview {
    TurnBannerView(player: GamePlayer(profile: PlayerProfile(name: "Ellis", avatarColorIndex: 1)))
        .background(AppTheme.cream)
}
