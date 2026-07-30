import SwiftUI

struct GameSetupView: View {
    let mode: GameMode
    @Environment(ProfileStore.self) private var profileStore
    @Environment(GameStore.self) private var gameStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.metrics) private var m
    /// Een lijst en geen verzameling: de volgorde van aantikken bepaalt de
    /// beurtvolgorde in het spel.
    @State private var selectedIDs: [UUID] = []
    @State private var opponentLevel: ComputerLevel = .medium
    @State private var activeGame: ActiveGame?
    @State private var showReplaceSavedConfirm = false


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
                        .foregroundStyle(AppTheme.headline)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    Text(mode.subtitle)
                        .font(AppTheme.rounded(m.bodySize, .bold))
                        .foregroundStyle(AppTheme.soft)
                }

                if profileStore.humanProfiles.isEmpty {
                    VStack(spacing: m.gutter) {
                        ContentUnavailableView(
                            "Geen profielen",
                            systemImage: "person.crop.circle.badge.plus",
                            description: Text("Maak eerst een profiel aan om te spelen.")
                        )
                        .foregroundStyle(AppTheme.soft)

                        NavigationLink(value: Destination.profiles) {
                            Text("Naar profielen")
                                .font(AppTheme.rounded(m.buttonTextSize * 0.85))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: m.buttonHeight * 0.9)
                        }
                        .buttonStyle(ToyButtonStyle(
                            fill: AppTheme.mint,
                            radius: m.cardCorner * 0.8,
                            depth: m.depth,
                            border: m.border
                        ))
                    }
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

                    if mode == .versusComputer {
                        Text("KIES JE TEGENSTANDER")
                            .font(AppTheme.rounded(m.captionSize * 0.9))
                            .kerning(1.4)
                            .foregroundStyle(AppTheme.faint)

                        HStack(spacing: m.gutter * 0.75) {
                            ForEach(ComputerLevel.allCases) { level in
                                opponentButton(level)
                            }
                        }
                    }

                    Button(action: requestStart) {
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

            // Eigen dialoog in de speelgoedstijl in plaats van het grijze
            // systeempaneel.
            if showReplaceSavedConfirm {
                ToyDialog(
                    title: "Lopend spel vervangen?",
                    message: "Er staat nog een spel klaar om verder te spelen.",
                    confirmTitle: "Nieuw spel starten",
                    cancelTitle: "Annuleer",
                    onConfirm: {
                        showReplaceSavedConfirm = false
                        beginNewGame()
                    },
                    onCancel: {
                        withAnimation(.easeOut(duration: 0.15)) {
                            showReplaceSavedConfirm = false
                        }
                    }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $activeGame) { game in
            GameView(engine: game.engine) {
                activeGame = nil
            }
            .environment(profileStore)
            .environment(gameStore)
            .appMetrics()
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

    /// De drie computertegenstanders naast elkaar; wie gekozen is, kleurt.
    private func opponentButton(_ level: ComputerLevel) -> some View {
        let picked = opponentLevel == level
        return Button {
            opponentLevel = level
        } label: {
            VStack(spacing: 6) {
                AvatarBadge(name: level.personaName, colorIndex: level.avatarColorIndex, size: m.avatarSize * 0.9)
                Text(level.personaName)
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(level.subtitle)
                    .font(AppTheme.rounded(m.captionSize * 0.82, .bold))
                    .foregroundStyle(AppTheme.soft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, m.gutter * 0.7)
            .padding(.horizontal, 4)
        }
        .buttonStyle(ToyButtonStyle(
            fill: picked ? AppTheme.tintCoral : .white,
            radius: m.cardCorner * 0.9,
            depth: picked ? m.depth : 3,
            border: m.border
        ))
        .accessibilityLabel("\(level.personaName), \(level.subtitle)")
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
        if let index = selectedIDs.firstIndex(of: id) {
            selectedIDs.remove(at: index)
        } else if selectedIDs.count < 4 {
            selectedIDs.append(id)
        }
    }

    /// Een nieuw spel gooit een bewaard spel weg, dus dat vragen we eerst.
    private func requestStart() {
        guard canStart else { return }
        if gameStore.hasSavedGame {
            withAnimation(.easeOut(duration: 0.15)) {
                showReplaceSavedConfirm = true
            }
        } else {
            beginNewGame()
        }
    }

    private func beginNewGame() {
        let humans = selectedIDs.compactMap { id in
            profileStore.humanProfiles.first { $0.id == id }
        }
        var profiles = humans
        if mode == .versusComputer {
            profiles.append(.computer(level: opponentLevel))
        }
        gameStore.clear()
        let engine = GameEngine(mode: mode, profiles: profiles)
        activeGame = ActiveGame(engine: engine)
    }
}

#Preview {
    // Tijdelijke bestanden, zodat de preview nooit aan echte spelersdata komt.
    let profiles = ProfileStore(fileURL: URL.temporaryDirectory.appending(path: "preview-\(UUID()).json"))
    let _ = profiles.addProfile(name: "Lene")
    let _ = profiles.addProfile(name: "Ellis")
    let _ = profiles.addProfile(name: "Noah")

    NavigationStack {
        GameSetupView(mode: .versusFriends)
    }
    .environment(profiles)
    .environment(GameStore(fileURL: URL.temporaryDirectory.appending(path: "preview-\(UUID()).json")))
    .appMetrics()
}
