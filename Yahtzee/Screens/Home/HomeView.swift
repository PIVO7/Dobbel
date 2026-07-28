import SwiftUI

struct HomeView: View {
    @Environment(ProfileStore.self) private var profileStore
    @State private var appeared = false
    @State private var floatPhase = false

    var body: some View {
        NavigationStack {
            ZStack {
                FeltBackground()

                VStack(spacing: 0) {
                    Spacer(minLength: 20)

                    brandHero
                        .padding(.bottom, 28)
                        .scaleEffect(appeared ? 1 : 0.82)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 24)

                    VStack(spacing: 14) {
                        menuButton(
                            title: "Tegen elkaar",
                            subtitle: "Samen op één iPhone of iPad",
                            accent: AppTheme.menuAccents[0],
                            destination: .setup(.versusFriends),
                            delay: 0.08
                        )
                        menuButton(
                            title: "Tegen de computer",
                            subtitle: "Solo uitdaging",
                            accent: AppTheme.menuAccents[1],
                            destination: .setup(.versusComputer),
                            delay: 0.16
                        )
                        menuButton(
                            title: "Profielen",
                            subtitle: winsSubtitle,
                            accent: AppTheme.menuAccents[2],
                            destination: .profiles,
                            delay: 0.24
                        )
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 16)
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
            .onAppear {
                withAnimation(AppTheme.springBouncy) {
                    appeared = true
                }
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    floatPhase = true
                }
            }
        }
    }

    private var brandHero: some View {
        VStack(spacing: 14) {
            ZStack {
                ForEach(Array(heroDice.enumerated()), id: \.offset) { index, face in
                    MiniDieFace(value: face)
                        .rotationEffect(.degrees(heroAngles[index] + (floatPhase ? 4 : -4)))
                        .offset(
                            x: heroOffsets[index].width,
                            y: heroOffsets[index].height + (floatPhase ? -8 : 6)
                        )
                        .opacity(0.95)
                }

                Text("Yahtzee")
                    .font(AppTheme.brandFont)
                    .foregroundStyle(AppTheme.cream)
                    .shadow(color: .black.opacity(0.28), radius: 10, y: 5)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(height: 120)

            Text("Gooi, reken en win samen")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.cream.opacity(0.92))
        }
    }

    private var heroDice: [Int] { [5, 6, 1] }
    private var heroAngles: [Double] { [-18, 12, 22] }
    private var heroOffsets: [CGSize] {
        [
            CGSize(width: -92, height: -8),
            CGSize(width: 88, height: -18),
            CGSize(width: 18, height: 42)
        ]
    }

    private var winsSubtitle: String {
        let total = profileStore.humanProfiles.reduce(0) { $0 + $1.wins }
        if profileStore.humanProfiles.isEmpty {
            return "Maak eerst een speler aan"
        }
        return "\(profileStore.humanProfiles.count) spelers · \(total) overwinningen"
    }

    private func menuButton(
        title: String,
        subtitle: String,
        accent: Color,
        destination: Destination,
        delay: Double
    ) -> some View {
        NavigationLink(value: destination) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(accent)
                    .frame(width: 10, height: 46)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.ink.opacity(0.62))
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            }
            .padding(.leading, 10)
            .padding(.trailing, 16)
            .padding(.vertical, 14)
            .background(AppTheme.cream.opacity(0.96), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        }
        .buttonStyle(PopButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 28)
        .animation(AppTheme.springSoft.delay(delay), value: appeared)
    }
}

private struct MiniDieFace: View {
    let value: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.cream)
                .shadow(color: .black.opacity(0.22), radius: 6, y: 3)
            DiePips(value: value)
                .foregroundStyle(AppTheme.ink)
                .padding(4)
        }
        .frame(width: 48, height: 48)
        .accessibilityHidden(true)
    }
}

enum Destination: Hashable {
    case profiles
    case setup(GameMode)
}
