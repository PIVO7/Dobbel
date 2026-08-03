import Foundation

/// Eén trofee in de kast. Elk doel is positief geformuleerd: er valt altijd
/// iets te verzamelen en nooit iets te verliezen — belangrijk in een
/// kinderapp.
struct ProfileBadge: Identifiable, Equatable {
    let id: String
    let title: String
    let goal: String
    let icon: String
    let isEarned: Bool

    /// De hele kast voor één profiel, in vaste volgorde: van makkelijk naar
    /// moeilijk, zodat er snel iets glimt.
    static func collection(for profile: PlayerProfile) -> [ProfileBadge] {
        [
            ProfileBadge(
                id: "eerste-potje",
                title: String(localized: "Eerste potje"),
                goal: String(localized: "Speel je eerste potje"),
                icon: "die.face.5.fill",
                isEarned: profile.gamesPlayed >= 1
            ),
            ProfileBadge(
                id: "winnaar",
                title: String(localized: "Winnaar"),
                goal: String(localized: "Win een potje"),
                icon: "crown.fill",
                isEarned: profile.wins >= 1
            ),
            ProfileBadge(
                id: "eerste-dobbel",
                title: String(localized: "Dobbel!"),
                goal: String(localized: "Gooi vijf dezelfde"),
                icon: "star.fill",
                isEarned: profile.dobbelCount >= 1
            ),
            ProfileBadge(
                id: "bonusjager",
                title: String(localized: "Bonusjager"),
                goal: String(localized: "Haal de bonus van 35"),
                icon: "plus.circle.fill",
                isEarned: profile.bonusCount >= 1
            ),
            ProfileBadge(
                id: "honderdklapper",
                title: String(localized: "Honderdklapper"),
                goal: String(localized: "Scoor 100 punten"),
                icon: "bolt.fill",
                isEarned: profile.bestScore >= 100
            ),
            ProfileBadge(
                id: "dobbelfan",
                title: String(localized: "Dobbelfan"),
                goal: String(localized: "Speel 10 potjes"),
                icon: "dice.fill",
                isEarned: profile.gamesPlayed >= 10
            ),
            ProfileBadge(
                id: "topvorm",
                title: String(localized: "Topvorm"),
                goal: String(localized: "Scoor 150 punten"),
                icon: "flame.fill",
                isEarned: profile.bestScore >= 150
            ),
            ProfileBadge(
                id: "hattrick",
                title: String(localized: "Hattrick"),
                goal: String(localized: "Win 3 potjes op rij"),
                icon: "sparkles",
                isEarned: profile.bestStreak >= 3
            ),
            ProfileBadge(
                id: "sterrenregen",
                title: String(localized: "Sterrenregen"),
                goal: String(localized: "Gooi 5 Dobbels"),
                icon: "star.circle.fill",
                isEarned: profile.dobbelCount >= 5
            ),
            ProfileBadge(
                id: "bonusbaas",
                title: String(localized: "Bonusbaas"),
                goal: String(localized: "Haal 5 keer de bonus"),
                icon: "checkmark.seal.fill",
                isEarned: profile.bonusCount >= 5
            ),
            ProfileBadge(
                id: "recordbreker",
                title: String(localized: "Recordbreker"),
                goal: String(localized: "Scoor 200 punten"),
                icon: "trophy.fill",
                isEarned: profile.bestScore >= 200
            ),
            ProfileBadge(
                id: "dobbelkampioen",
                title: String(localized: "Dobbelkampioen"),
                goal: String(localized: "Speel 25 potjes"),
                icon: "medal.fill",
                isEarned: profile.gamesPlayed >= 25
            )
        ]
    }
}
