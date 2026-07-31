import SwiftUI

/// De statistieken van één profiel, als blad over het profielenscherm heen.
struct ProfileStatsView: View {
    let profile: PlayerProfile

    @Environment(\.dismiss) private var dismiss
    @Environment(\.metrics) private var m

    private var average: Int? {
        guard profile.gamesPlayed > 0 else { return nil }
        return Int((Double(profile.totalPoints) / Double(profile.gamesPlayed)).rounded())
    }

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: m.gutter) {
                    AvatarBadge(profile: profile, size: m.avatarSize * 1.4)
                        .padding(.top, m.gutter)

                    Text(profile.name)
                        .font(AppTheme.rounded(m.titleSize * 0.6))
                        .foregroundStyle(AppTheme.headline)

                    if profile.gamesPlayed == 0 {
                        Text("Nog geen potjes gespeeld. Gooi maar!")
                            .font(AppTheme.rounded(m.bodySize, .bold))
                            .foregroundStyle(AppTheme.soft)
                            .padding(.top, m.gutter)
                    } else {
                        VStack(spacing: m.cellGap * 2) {
                            statRow(String(localized: "Gespeeld"), "\(profile.gamesPlayed)", icon: "die.face.5.fill")
                            statRow(String(localized: "Gewonnen"), "\(profile.wins)", icon: "crown.fill")
                            statRow(String(localized: "Hoogste score"), "\(profile.bestScore)", icon: "arrow.up.circle.fill")
                            statRow(String(localized: "Gemiddeld"), average.map { "\($0)" } ?? "–", icon: "equal.circle.fill")
                            statRow(String(localized: "Dobbels"), "\(profile.dobbelCount)", icon: "star.fill")
                            statRow(
                                String(localized: "Winreeks"),
                                profile.currentStreak > 0
                                    ? String(localized: "\(profile.currentStreak) op rij · beste \(profile.bestStreak)")
                                    : String(localized: "beste \(profile.bestStreak)"),
                                icon: "flame.fill"
                            )
                            statRow(String(localized: "Bonus gehaald"), String(localized: "\(profile.bonusCount) van \(profile.gamesPlayed)"), icon: "plus.circle.fill")
                        }
                        .padding(.top, m.gutter * 0.5)
                    }
                }
                .padding(.horizontal, m.gutter * 1.5)
                .padding(.bottom, m.gutter * 2)
                .frame(maxWidth: m.overlayMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Label("Sluit", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.system(size: m.captionSize + 2, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: m.tapTarget, height: m.tapTarget)
            }
            .buttonStyle(ToyButtonStyle(fill: .white, radius: m.cellCorner, depth: 3, border: m.thinBorder))
            .padding(m.gutter)
        }
    }

    private func statRow(_ title: String, _ value: String, icon: String) -> some View {
        HStack(spacing: m.gutter * 0.8) {
            Image(systemName: icon)
                .font(.system(size: m.bodySize, weight: .black))
                .foregroundStyle(AppTheme.coral)
                .frame(width: m.bodySize * 1.6)

            Text(title)
                .font(AppTheme.rounded(m.bodySize, .bold))
                .foregroundStyle(AppTheme.soft)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(AppTheme.rounded(m.bodySize + 3))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(.horizontal, m.gutter)
        .padding(.vertical, m.gutter * 0.7)
        .toyBlock(fill: .white, radius: m.cardCorner * 0.8, depth: 3, border: m.thinBorder + 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview {
    ProfileStatsView(profile: PlayerProfile(
        name: "Lene", wins: 3, gamesPlayed: 7,
        bestScore: 289, totalPoints: 1512, dobbelCount: 4, bonusCount: 2
    ))
    .appMetrics()
}
