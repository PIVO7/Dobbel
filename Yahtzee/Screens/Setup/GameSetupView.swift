import SwiftUI

struct GameSetupView: View {
    let mode: GameMode
    @Environment(ProfileStore.self) private var profileStore
    @State private var selectedIDs: Set<UUID> = []
    @State private var activeGame: ActiveGame?

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(AppTheme.titleFont)
                        .foregroundStyle(AppTheme.ink)

                    Text(mode.subtitle)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.soft)
                }

                if profileStore.humanProfiles.isEmpty {
                    ContentUnavailableView(
                        "Geen profielen",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Maak eerst een profiel aan onder Profielen.")
                    )
                    .foregroundStyle(AppTheme.soft)
                } else {
                    Text(mode == .versusComputer ? "KIES JOUW PROFIEL" : "KIES 2 TOT 4 SPELERS")
                        .font(AppTheme.labelFont)
                        .kerning(1.4)
                        .foregroundStyle(AppTheme.faint)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(profileStore.humanProfiles) { profile in
                                profileButton(profile)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    Button(action: startGame) {
                        Text("Start spel")
                            .font(.system(size: 21, weight: .black, design: .rounded))
                            .foregroundStyle(canStart ? .white : AppTheme.offInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                    }
                    .buttonStyle(ToyButtonStyle(fill: canStart ? AppTheme.mint : AppTheme.offFill, radius: 18, depth: 6))
                    .disabled(!canStart)
                    .padding(.bottom, 6)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 6)
            .padding(.bottom, 18)
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $activeGame) { game in
            GameView(engine: game.engine) {
                activeGame = nil
            }
            .environment(profileStore)
        }
    }

    private func profileButton(_ profile: PlayerProfile) -> some View {
        let picked = selectedIDs.contains(profile.id)
        return Button {
            toggle(profile.id)
        } label: {
            HStack(spacing: 13) {
                AvatarBadge(profile: profile)

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.ink)
                    Text("\(profile.wins) overwinningen")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.soft)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: picked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(picked ? AppTheme.coral : AppTheme.dim)
            }
            .padding(13)
        }
        .buttonStyle(ToyButtonStyle(fill: picked ? AppTheme.tintCoral : .white, radius: 18, depth: 5))
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    private var canStart: Bool {
        switch mode {
        case .versusComputer:
            return selectedIDs.count == 1
        case .versusFriends:
            return (2...4).contains(selectedIDs.count)
        }
    }

    private func toggle(_ id: UUID) {
        if mode == .versusComputer {
            selectedIDs = [id]
            return
        }
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else if selectedIDs.count < 4 {
            selectedIDs.insert(id)
        }
    }

    private func startGame() {
        let humans = profileStore.humanProfiles.filter { selectedIDs.contains($0.id) }
        var profiles = humans
        if mode == .versusComputer {
            profiles.append(.computer)
        }
        let engine = GameEngine(mode: mode, profiles: profiles)
        activeGame = ActiveGame(engine: engine)
    }
}

private struct ActiveGame: Identifiable {
    let id = UUID()
    let engine: GameEngine
}
