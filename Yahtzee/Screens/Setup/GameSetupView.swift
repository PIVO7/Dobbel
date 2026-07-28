import SwiftUI

struct GameSetupView: View {
    let mode: GameMode
    @Environment(ProfileStore.self) private var profileStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedIDs: Set<UUID> = []
    @State private var activeGame: ActiveGame?

    private var m: AppMetrics { .resolve(sizeClass) }

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: m.gutter), count: count)
    }

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            VStack(alignment: .leading, spacing: m.gutter) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(AppTheme.rounded(m.titleSize))
                        .foregroundStyle(AppTheme.ink)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    Text(mode.subtitle)
                        .font(AppTheme.rounded(m.bodySize, .bold))
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
                        .font(AppTheme.rounded(m.captionSize * 0.9))
                        .kerning(1.4)
                        .foregroundStyle(AppTheme.faint)

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: m.gutter) {
                            ForEach(profileStore.humanProfiles) { profile in
                                profileButton(profile)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    Button(action: startGame) {
                        Text("Start spel")
                            .font(AppTheme.rounded(m.buttonTextSize))
                            .foregroundStyle(canStart ? .white : AppTheme.offInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: m.buttonHeight * 0.96)
                    }
                    .buttonStyle(ToyButtonStyle(
                        fill: canStart ? AppTheme.mint : AppTheme.offFill,
                        radius: m.cardCorner * 0.9,
                        depth: m.depth + 1,
                        border: m.border
                    ))
                    .disabled(!canStart)
                    .padding(.bottom, 6)
                }
            }
            .padding(.horizontal, m.gutter * 1.5)
            .padding(.top, 6)
            .padding(.bottom, m.gutter)
            .frame(maxWidth: m.contentMaxWidth)
            .frame(maxWidth: .infinity)
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
            HStack(spacing: m.gutter * 0.9) {
                AvatarBadge(profile: profile, size: m.avatarSize)

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(AppTheme.rounded(m.bodySize + 2))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                    Text("\(profile.wins) overwinningen")
                        .font(AppTheme.rounded(m.captionSize, .bold))
                        .foregroundStyle(AppTheme.soft)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: picked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: m.bodySize * 1.4, weight: .black))
                    .foregroundStyle(picked ? AppTheme.coral : AppTheme.dim)
            }
            .padding(m.gutter * 0.9)
        }
        .buttonStyle(ToyButtonStyle(
            fill: picked ? AppTheme.tintCoral : .white,
            radius: m.cardCorner * 0.9,
            depth: m.depth,
            border: m.border
        ))
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
