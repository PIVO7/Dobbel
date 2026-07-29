import SwiftUI

struct ProfilesView: View {
    @Environment(ProfileStore.self) private var profileStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.metrics) private var m
    @State private var newName = ""
    @State private var renameTarget: PlayerProfile?
    @State private var renameText = ""
    @State private var deleteTarget: PlayerProfile?


    /// Op een iPad past er een tweede kolom naast; op een iPhone niet.
    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: m.gutter), count: count)
    }

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: m.gutter * 1.5) {
                    section("NIEUW PROFIEL") {
                        HStack(spacing: 10) {
                            TextField("Naam van je kind", text: $newName)
                                .font(AppTheme.rounded(m.bodySize, .bold))
                                .foregroundStyle(AppTheme.ink)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.done)
                                .onSubmit(addProfile)

                            Button("Voeg toe", action: addProfile)
                                .font(AppTheme.rounded(m.captionSize, .bold))
                                .foregroundStyle(canAdd ? .white : AppTheme.offInk)
                                .padding(.horizontal, 14)
                                .frame(minHeight: m.tapTarget)
                                .toyBlock(
                                    fill: canAdd ? AppTheme.mint : AppTheme.offFill,
                                    radius: m.cellCorner + 1,
                                    depth: 3,
                                    border: m.thinBorder + 0.5,
                                    borderColor: canAdd ? AppTheme.ink : AppTheme.offInk,
                                    shadowColor: canAdd ? AppTheme.ink : AppTheme.offInk
                                )
                                .disabled(!canAdd)
                        }
                        .padding(m.gutter)
                        .toyBlock(fill: .white, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)
                    }

                    section("SPELERS") {
                        if profileStore.humanProfiles.isEmpty {
                            Text("Nog geen profielen. Maak er een aan om te spelen.")
                                .font(AppTheme.rounded(m.bodySize, .bold))
                                .foregroundStyle(AppTheme.soft)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(m.gutter)
                                .toyBlock(fill: .white, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)
                        } else {
                            LazyVGrid(columns: columns, spacing: m.gutter) {
                                ForEach(profileStore.humanProfiles) { profile in
                                    profileRow(profile)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, m.gutter * 1.3)
                .padding(.top, 8)
                .padding(.bottom, m.gutter * 2)
                .frame(maxWidth: m.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Profielen")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Naam wijzigen", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )) {
            TextField("Naam", text: $renameText)
            Button("Bewaar") {
                if let id = renameTarget?.id {
                    profileStore.renameProfile(id: id, to: renameText)
                }
                renameTarget = nil
            }
            Button("Annuleer", role: .cancel) {
                renameTarget = nil
            }
        }
        .confirmationDialog(
            deleteTarget.map { "\($0.name) verwijderen?" } ?? "Verwijderen?",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Verwijderen", role: .destructive) {
                if let id = deleteTarget?.id {
                    profileStore.deleteProfile(id: id)
                }
                deleteTarget = nil
            }
            Button("Annuleer", role: .cancel) { deleteTarget = nil }
        } message: {
            Text("De overwinningen van dit profiel gaan verloren.")
        }
    }

    private var canAdd: Bool {
        !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addProfile() {
        guard canAdd else { return }
        profileStore.addProfile(name: newName)
        newName = ""
    }

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppTheme.rounded(m.captionSize * 0.9))
                .kerning(1.4)
                .foregroundStyle(AppTheme.faint)
                .padding(.leading, 4)
            content()
        }
    }

    private func profileRow(_ profile: PlayerProfile) -> some View {
        HStack(spacing: m.gutter * 0.9) {
            AvatarBadge(profile: profile, size: m.avatarSize)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(AppTheme.rounded(m.bodySize + 2))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                Text("\(profile.wins)× gewonnen · \(profile.gamesPlayed) gespeeld")
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.soft)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                renameTarget = profile
                renameText = profile.name
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: m.captionSize + 2, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: m.tapTarget, height: m.tapTarget)
            }
            .buttonStyle(ToyButtonStyle(fill: AppTheme.tintAmber, radius: m.cellCorner, depth: 3, border: m.thinBorder))
            .accessibilityLabel("\(profile.name) hernoemen")

            Button {
                deleteTarget = profile
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: m.captionSize + 2, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: m.tapTarget, height: m.tapTarget)
            }
            .buttonStyle(ToyButtonStyle(fill: AppTheme.tintCoral, radius: m.cellCorner, depth: 3, border: m.thinBorder))
            .accessibilityLabel("\(profile.name) verwijderen")
        }
        .padding(m.gutter * 0.9)
        .toyBlock(fill: .white, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)
    }
}
