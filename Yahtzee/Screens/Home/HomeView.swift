import SwiftUI

struct HomeView: View {
    @Environment(ProfileStore.self) private var profileStore
    @Environment(GameStore.self) private var gameStore
    @Environment(\.metrics) private var m
    @State private var activeGame: ActiveGame?
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 8) {
                            Text("Dobbel!")
                                .font(AppTheme.rounded(m.brandSize))
                                .foregroundStyle(AppTheme.headline)

                            Text("Gooi, reken en win samen")
                                .font(AppTheme.rounded(m.bodySize, .bold))
                                .foregroundStyle(AppTheme.soft)
                        }
                        .padding(.top, m.gutter * 2)
                        .padding(.bottom, m.gutter * 2.4)

                        VStack(spacing: m.gutter) {
                            if let saved = gameStore.savedGame {
                                Button {
                                    activeGame = ActiveGame(engine: GameEngine(snapshot: saved))
                                } label: {
                                    menuLabel(
                                        "Verder spelen",
                                        subtitle: saved.summaryTitle,
                                        tint: AppTheme.coral,
                                        face: 5
                                    )
                                }
                            }

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
                        .padding(.bottom, m.gutter * 2)
                    }
                    .padding(.horizontal, m.gutter * 1.5)
                    .frame(maxWidth: m.contentMaxWidth)
                    .frame(maxWidth: .infinity)
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
            // Rechtsboven, buiten de meeloop van de menutegels: instellingen
            // zijn voor de ouders, niet voor het spel.
            .overlay(alignment: .topTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Label("Instellingen", systemImage: "gearshape.fill")
                        .labelStyle(.iconOnly)
                        .font(.system(size: m.captionSize + 3, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: m.tapTarget, height: m.tapTarget)
                }
                .buttonStyle(ToyButtonStyle(fill: .white, radius: m.cellCorner, depth: 3, border: m.thinBorder))
                .padding(.trailing, m.gutter * 1.5)
                .padding(.top, m.gutter * 0.5)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .appMetrics()
            }
            .fullScreenCover(item: $activeGame) { game in
                GameView(
                    engine: game.engine,
                    onRematch: {
                        let engine = GameEngine(
                            mode: game.engine.mode,
                            profiles: game.engine.rematchProfiles()
                        )
                        gameStore.save(engine.snapshot)
                        activeGame = ActiveGame(engine: engine)
                    },
                    onClose: { activeGame = nil }
                )
                .environment(profileStore)
                .environment(gameStore)
                .appMetrics()
            }
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
        HStack(spacing: m.gutter) {
            DiePips(value: face, inset: m.avatarSize * 0.2)
                .foregroundStyle(AppTheme.ink)
                .frame(width: m.avatarSize + 2, height: m.avatarSize + 2)
                .toyBlock(fill: tint, radius: m.cellCorner + 2, depth: 0, border: m.thinBorder + 0.5)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTheme.rounded(m.bodySize + 3))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.soft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: m.bodySize * 0.9, weight: .black))
                .foregroundStyle(AppTheme.dim)
        }
        .padding(m.gutter * 1.15)
        .toyBlock(fill: .white, radius: m.cardCorner, depth: m.depth, border: m.border)
    }
}

#Preview {
    // Tijdelijke bestanden, zodat de preview nooit aan echte spelersdata komt.
    let profiles = ProfileStore(fileURL: URL.temporaryDirectory.appending(path: "preview-\(UUID()).json"))
    let _ = profiles.addProfile(name: "Lene")
    let _ = profiles.addProfile(name: "Ellis")

    HomeView()
        .environment(profiles)
        .environment(GameStore(fileURL: URL.temporaryDirectory.appending(path: "preview-\(UUID()).json")))
        .appMetrics()
}
