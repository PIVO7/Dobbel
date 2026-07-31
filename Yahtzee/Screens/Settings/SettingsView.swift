import SwiftUI

/// Instellingen: het thema en het geluid. Bewust klein gehouden — een
/// kinderapp hoort weinig knoppen te hebben.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.metrics) private var m

    @State private var soundOn = SoundPlayer.shared.isEnabled
    @State private var shakeOn = ShakeToRoll.isEnabled
    @State private var passOn = PassAndPlay.isEnabled
    @State private var coachReset = false
    @State private var showRules = false

    private var themeStore: ThemeStore { .shared }

    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: m.gutter * 1.4) {
                    HStack {
                        Text("Instellingen")
                            .font(AppTheme.rounded(m.titleSize * 0.7))
                            .foregroundStyle(AppTheme.headline)

                        Spacer()

                        Button(action: { dismiss() }) {
                            Label("Sluiten", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                                .font(.system(size: m.captionSize + 2, weight: .black))
                                .foregroundStyle(AppTheme.ink)
                                .frame(width: m.tapTarget, height: m.tapTarget)
                        }
                        .buttonStyle(ToyButtonStyle(fill: .white, radius: m.cellCorner, depth: 3, border: m.thinBorder))
                    }

                    section("THEMA") {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: m.gutter), GridItem(.flexible(), spacing: m.gutter)],
                            spacing: m.gutter
                        ) {
                            ForEach(ThemeID.allCases) { theme in
                                themeCard(theme)
                            }
                        }
                    }

                    section("GELUID") {
                        Toggle(isOn: $soundOn) {
                            Text("Geluidseffecten")
                                .font(AppTheme.rounded(m.bodySize, .bold))
                                .foregroundStyle(AppTheme.ink)
                        }
                        .tint(AppTheme.mint)
                        .padding(m.gutter)
                        .toyBlock(fill: .white, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)
                        .onChange(of: soundOn) { _, isOn in
                            SoundPlayer.shared.isEnabled = isOn
                            if isOn {
                                SoundPlayer.shared.play(.hold)
                            }
                        }
                    }

                    section("BESTUREN") {
                        Toggle(isOn: $shakeOn) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Schudden om te gooien")
                                    .font(AppTheme.rounded(m.bodySize, .bold))
                                    .foregroundStyle(AppTheme.ink)
                                Text("Schud het toestel en de stenen rollen")
                                    .font(AppTheme.rounded(m.captionSize, .bold))
                                    .foregroundStyle(AppTheme.soft)
                            }
                        }
                        .tint(AppTheme.mint)
                        .padding(m.gutter)
                        .toyBlock(fill: .white, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)
                        .onChange(of: shakeOn) { _, isOn in
                            ShakeToRoll.isEnabled = isOn
                        }

                        Toggle(isOn: $passOn) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Doorgeefscherm")
                                    .font(AppTheme.rounded(m.bodySize, .bold))
                                    .foregroundStyle(AppTheme.ink)
                                Text("Even pauze tot de volgende speler klaar zit")
                                    .font(AppTheme.rounded(m.captionSize, .bold))
                                    .foregroundStyle(AppTheme.soft)
                            }
                        }
                        .tint(AppTheme.mint)
                        .padding(m.gutter)
                        .toyBlock(fill: .white, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)
                        .onChange(of: passOn) { _, isOn in
                            PassAndPlay.isEnabled = isOn
                        }
                    }

                    section("UITLEG") {
                        Button {
                            showRules = true
                        } label: {
                            HStack {
                                Text("Hoe werkt Dobbel?")
                                    .font(AppTheme.rounded(m.bodySize, .bold))
                                    .foregroundStyle(AppTheme.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "book.fill")
                                    .font(.system(size: m.bodySize, weight: .black))
                                    .foregroundStyle(AppTheme.sky)
                            }
                            .padding(m.gutter)
                        }
                        .buttonStyle(ToyButtonStyle(fill: .white, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border))
                        .sheet(isPresented: $showRules) {
                            RulesView()
                                .appMetrics()
                        }

                        Button {
                            CoachTour.seen = false
                            coachReset = true
                        } label: {
                            HStack {
                                Text(coachReset ? "De uitleg verschijnt weer bij het volgende potje" : "Uitleg opnieuw tonen")
                                    .font(AppTheme.rounded(m.bodySize, .bold))
                                    .foregroundStyle(coachReset ? AppTheme.soft : AppTheme.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: coachReset ? "checkmark.circle.fill" : "questionmark.bubble.fill")
                                    .font(.system(size: m.bodySize, weight: .black))
                                    .foregroundStyle(coachReset ? AppTheme.mint : AppTheme.coral)
                            }
                            .padding(m.gutter)
                        }
                        .buttonStyle(ToyButtonStyle(fill: .white, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border))
                        .disabled(coachReset)
                    }
                }
                .padding(.horizontal, m.gutter * 1.3)
                .padding(.top, m.gutter)
                .padding(.bottom, m.gutter * 2)
                .frame(maxWidth: m.overlayMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
    }

    /// Eén themakaart: de achtergrondkleur van het thema met zijn drie
    /// accenten als bolletjes, zodat je ziet wat je kiest voor je tikt.
    private func themeCard(_ theme: ThemeID) -> some View {
        let palette = theme.palette
        let picked = themeStore.themeID == theme

        return Button {
            themeStore.select(theme)
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(Array([palette.coral, palette.amber, palette.mint, palette.sky].enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .overlay(Circle().strokeBorder(palette.ink, lineWidth: 1.5))
                            .frame(width: m.captionSize + 4, height: m.captionSize + 4)
                    }
                }

                Text(theme.title)
                    .font(AppTheme.rounded(m.captionSize + 1, .bold))
                    .foregroundStyle(theme == .nacht ? palette.headline : palette.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, m.gutter * 0.9)
        }
        .buttonStyle(ToyButtonStyle(
            fill: palette.cream,
            radius: m.cardCorner * 0.9,
            depth: picked ? m.depth : 3,
            border: picked ? m.border + 1 : m.border,
            borderColor: picked ? AppTheme.coral : AppTheme.ink
        ))
        .accessibilityLabel("Thema \(theme.title)")
        .accessibilityAddTraits(picked ? .isSelected : [])
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
}

#Preview {
    SettingsView()
        .appMetrics()
}
