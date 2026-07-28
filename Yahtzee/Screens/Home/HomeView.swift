import SwiftUI

struct HomeView: View {
    @Environment(ProfileStore.self) private var profileStore

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 30)

                    VStack(spacing: 8) {
                        Text("Yahtzee")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.ink)

                        Text("Gooi, reken en win samen")
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.soft)
                    }
                    .padding(.bottom, 34)

                    VStack(spacing: 16) {
                        NavigationLink(value: Destination.setup(.versusFriends)) {
                            menuLabel("Tegen elkaar", subtitle: "2 tot 4 spelers, één toestel",
                                      tint: AppTheme.amber, face: 4)
                        }
                        NavigationLink(value: Destination.setup(.versusComputer)) {
                            menuLabel("Tegen de computer", subtitle: "Solo uitdaging",
                                      tint: AppTheme.sky, face: 1)
                        }
                        NavigationLink(value: Destination.profiles) {
                            menuLabel("Profielen", subtitle: winsSubtitle,
                                      tint: AppTheme.mint, face: 6)
                        }
                    }
                    .padding(.horizontal, 22)

                    Spacer()
                }
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .profiles:
                    ProfilesView()
                case .setup(let mode):
                    GameSetupView(mode: mode)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .tint(AppTheme.coral)
    }

    private var winsSubtitle: String {
        let total = profileStore.humanProfiles.reduce(0) { $0 + $1.wins }
        if profileStore.humanProfiles.isEmpty {
            return "Maak eerst een speler aan"
        }
        return "\(profileStore.humanProfiles.count) spelers · \(total) overwinningen"
    }

    private func menuLabel(_ title: String, subtitle: String, tint: Color, face: Int) -> some View {
        HStack(spacing: 14) {
            DiePips(value: face, inset: 9)
                .foregroundStyle(AppTheme.ink)
                .frame(width: 46, height: 46)
                .toyBlock(fill: tint, radius: 13, depth: 0, border: 2.5)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.soft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(AppTheme.dim)
        }
        .padding(16)
        .toyBlock(fill: .white, radius: 20, depth: 5)
    }
}

enum Destination: Hashable {
    case profiles
    case setup(GameMode)
}
