import SwiftUI

/// Boven elke kolom van het scoreblad staat wie hem vult; zonder dat raak je
/// bij drie of vier spelers het spoor bijster welke kolom van jou is. Alleen
/// het bolletje — naam en kader erbij propten te veel in een celbreedte. Wie
/// niet aan de beurt is, dimt; de kleur blijft genoeg om je kolom terug te
/// vinden.
struct PlayerHeaderView: View {
    let players: [GamePlayer]
    let currentPlayerID: UUID
    /// Alleen de linkerkolom toont de naam; anders staat hij er twee keer.
    var showsName = true
    /// Breedte van de kolommen van wie níet aan de beurt is; nil betekent
    /// gelijke kolommen. Moet meelopen met `ScorecardView.passiveWidth`,
    /// anders staan de bolletjes naast hun kolom.
    var passiveWidth: CGFloat?

    @Environment(\.metrics) private var m

    private var avatarSize: CGFloat {
        min(m.iconWidth - 2, m.avatarSize * 0.72)
    }

    var body: some View {
        HStack(spacing: m.cellGap) {
            Color.clear
                .frame(width: m.iconWidth, height: avatarSize + 10)

            ForEach(players) { player in
                let isMine = player.id == currentPlayerID
                let bonus = player.scorecard.dobbelBonusTotal
                HStack(spacing: 6) {
                    avatar(for: player, isMine: isMine, bonus: bonus)
                    // Alleen bij één brede kolom (3-4 spelers op een smal
                    // scherm) is er plaats voor de naam; bij twee of meer
                    // kolommen zegt het bolletje genoeg.
                    if players.count == 1, showsName {
                        Text(player.name)
                            .font(AppTheme.rounded(m.captionSize + 1))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: passiveWidth != nil && !isMine ? nil : .infinity)
                .frame(width: passiveWidth != nil && !isMine ? passiveWidth : nil)
                .accessibilityElement()
                .accessibilityLabel(accessibilityText(for: player, isMine: isMine, bonus: bonus))
            }
        }
    }

    private func avatar(for player: GamePlayer, isMine: Bool, bonus: Int) -> some View {
        AvatarBadge(player: player, size: avatarSize)
                    .opacity(isMine ? 1 : 0.55)
                    // Een koraalring om wie aan de beurt is: dimmen alleen
                    // bleek te subtiel. De ring sluit strak aan op de rand
                    // van het bolletje — met een kier ertussen leek het een
                    // wit lijntje.
                    .overlay {
                        if isMine {
                            Circle()
                                .strokeBorder(AppTheme.coral, lineWidth: 3)
                                .frame(width: avatarSize + 6, height: avatarSize + 6)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if bonus > 0 {
                            Image(systemName: "star.fill")
                                .font(.system(size: avatarSize * 0.3, weight: .black))
                                .foregroundStyle(AppTheme.amber)
                                .offset(x: 3, y: -3)
                        }
                    }
    }

    private func accessibilityText(for player: GamePlayer, isMine: Bool, bonus: Int) -> String {
        var label = player.name
        if isMine {
            label += ", " + String(localized: "aan de beurt")
        }
        if bonus > 0 {
            label += ", " + String(localized: "Dobbel-bonus \(bonus)")
        }
        return label
    }
}

#Preview {
    let lene = GamePlayer(profile: PlayerProfile(name: "Lene", avatarColorIndex: 0))
    let ellis = GamePlayer(profile: PlayerProfile(name: "Ellis", avatarColorIndex: 1))

    PlayerHeaderView(players: [lene, ellis], currentPlayerID: lene.id)
        .padding()
        .background(AppTheme.cream)
        .appMetrics()
}
