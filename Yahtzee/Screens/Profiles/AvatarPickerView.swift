import SwiftUI

/// De avatarkiezer: een kleur en een symbooltje voor op je bolletje — half
/// de fun van een eigen profiel.
struct AvatarPickerView: View {
    let profile: PlayerProfile
    let onSave: (Int, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.metrics) private var m

    @State private var colorIndex: Int
    @State private var symbol: String?

    /// Kindvriendelijke symbolen; de eerste keuze is "gewoon je letters".
    static let symbols: [String] = [
        "cat.fill", "dog.fill", "hare.fill", "tortoise.fill",
        "bird.fill", "fish.fill", "ladybug.fill", "pawprint.fill",
        "star.fill", "heart.fill", "bolt.fill", "crown.fill",
        "sun.max.fill", "moon.stars.fill", "flame.fill", "leaf.fill"
    ]

    init(profile: PlayerProfile, onSave: @escaping (Int, String?) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _colorIndex = State(initialValue: profile.avatarColorIndex)
        _symbol = State(initialValue: profile.avatarSymbol)
    }

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            VStack(spacing: m.gutter) {
                AvatarBadge(name: profile.name, colorIndex: colorIndex, symbol: symbol, size: m.avatarSize * 1.6)
                    .padding(.top, m.gutter * 1.4)

                Text(profile.name)
                    .font(AppTheme.rounded(m.titleSize * 0.55))
                    .foregroundStyle(AppTheme.headline)

                sectionTitle("KLEUR")
                HStack(spacing: m.gutter * 0.7) {
                    ForEach(Array(AvatarBadge.palette.enumerated()), id: \.offset) { index, color in
                        Button {
                            colorIndex = index
                        } label: {
                            Circle()
                                .fill(color)
                                .overlay(
                                    Circle().strokeBorder(
                                        AppTheme.ink,
                                        lineWidth: colorIndex == index ? 3.5 : 1.5
                                    )
                                )
                                .frame(width: m.tapTarget * 0.8, height: m.tapTarget * 0.8)
                                .scaleEffect(colorIndex == index ? 1.12 : 1)
                        }
                        .buttonStyle(.plain)
                        .animation(.easeOut(duration: 0.12), value: colorIndex)
                        .accessibilityLabel("Kleur \(index + 1)")
                        .accessibilityAddTraits(colorIndex == index ? .isSelected : [])
                    }
                }

                sectionTitle("SYMBOOL")
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: m.cellGap * 2), count: 6),
                    spacing: m.cellGap * 2
                ) {
                    symbolCell(nil)
                    ForEach(Self.symbols, id: \.self) { name in
                        symbolCell(name)
                    }
                }

                Spacer(minLength: 0)

                Button {
                    onSave(colorIndex, symbol)
                    dismiss()
                } label: {
                    Text("Klaar!")
                        .font(AppTheme.rounded(m.buttonTextSize * 0.8))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: m.buttonHeight * 0.85)
                }
                .buttonStyle(ToyButtonStyle(
                    fill: AppTheme.mint,
                    radius: m.cardCorner * 0.9,
                    depth: m.depth,
                    border: m.border
                ))
                .padding(.bottom, m.gutter)
            }
            .padding(.horizontal, m.gutter * 1.4)
            .frame(maxWidth: m.overlayMaxWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private func symbolCell(_ name: String?) -> some View {
        let picked = symbol == name
        return Button {
            symbol = name
        } label: {
            Group {
                if let name {
                    Image(systemName: name)
                        .font(.system(size: m.bodySize + 2, weight: .black))
                } else {
                    Text("ABC")
                        .font(AppTheme.rounded(m.captionSize * 0.9))
                }
            }
            .foregroundStyle(picked ? .white : AppTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: m.tapTarget * 0.95)
        }
        .buttonStyle(ToyButtonStyle(
            fill: picked ? AppTheme.coral : .white,
            radius: m.cellCorner,
            depth: picked ? 3 : 2,
            border: m.thinBorder
        ))
        .accessibilityLabel(name.map { "Symbool \($0)" } ?? "Initialen")
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.rounded(m.captionSize * 0.9))
            .kerning(1.4)
            .foregroundStyle(AppTheme.faint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, m.gutter * 0.4)
    }
}

#Preview {
    AvatarPickerView(
        profile: PlayerProfile(name: "Lene", avatarColorIndex: 0, avatarSymbol: "cat.fill"),
        onSave: { _, _ in }
    )
    .appMetrics()
}
