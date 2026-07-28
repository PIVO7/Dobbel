import SwiftUI

struct ProfilesView: View {
    @Environment(ProfileStore.self) private var profileStore
    @State private var newName = ""
    @State private var renameTarget: PlayerProfile?
    @State private var renameText = ""
    @State private var deleteTarget: PlayerProfile?

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    section("NIEUW PROFIEL") {
                        HStack(spacing: 10) {
                            TextField("Naam van je kind", text: $newName)
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.ink)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.done)
                                .onSubmit(addProfile)

                            Button("Voeg toe", action: addProfile)
                                .font(AppTheme.captionFont)
                                .foregroundStyle(canAdd ? .white : AppTheme.offInk)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .toyBlock(
                                    fill: canAdd ? AppTheme.mint : AppTheme.offFill,
                                    radius: 12,
                                    depth: 3,
                                    border: 2.5,
                                    borderColor: canAdd ? AppTheme.ink : AppTheme.offInk,
                                    shadowColor: canAdd ? AppTheme.ink : AppTheme.offInk
                                )
                                .disabled(!canAdd)
                        }
                        .padding(14)
                        .toyBlock(fill: .white, radius: 18, depth: 5)
                    }

                    section("SPELERS") {
                        if profileStore.humanProfiles.isEmpty {
                            Text("Nog geen profielen. Maak er een aan om te spelen.")
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.soft)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .toyBlock(fill: .white, radius: 18, depth: 5)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(profileStore.humanProfiles) { profile in
                                    profileRow(profile)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 32)
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
                .font(AppTheme.labelFont)
                .kerning(1.4)
                .foregroundStyle(AppTheme.faint)
                .padding(.leading, 4)
            content()
        }
    }

    private func profileRow(_ profile: PlayerProfile) -> some View {
        HStack(spacing: 13) {
            AvatarBadge(profile: profile)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.ink)
                Text("\(profile.wins)× gewonnen · \(profile.gamesPlayed) gespeeld")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.soft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                renameTarget = profile
                renameText = profile.name
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(ToyButtonStyle(fill: AppTheme.tintAmber, radius: 11, depth: 3))
            .accessibilityLabel("\(profile.name) hernoemen")

            Button {
                deleteTarget = profile
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(ToyButtonStyle(fill: AppTheme.tintCoral, radius: 11, depth: 3))
            .accessibilityLabel("\(profile.name) verwijderen")
        }
        .padding(13)
        .toyBlock(fill: .white, radius: 18, depth: 5)
    }
}
