import SwiftUI

/// De spelregels op kindhoogte: hoe een beurt werkt, wat de vakjes betekenen,
/// de twee lastige regels — de bonus bovenin en de extra Dobbel — en de
/// spelvorm "In volgorde" uit de Gezinsversie.
struct RulesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.metrics) private var m

    var body: some View {
        ZStack {
            ThemedBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: m.gutter * 1.4) {
                    HStack {
                        Text("Hoe werkt Dobbel?")
                            .font(AppTheme.rounded(m.titleSize * 0.62))
                            .foregroundStyle(AppTheme.headline)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)

                        Spacer()

                        Button(action: { dismiss() }) {
                            Label("Sluiten", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                                .font(.system(size: m.captionSize + 2, weight: .black))
                                .foregroundStyle(AppTheme.ink)
                                .frame(width: m.tapTarget, height: m.tapTarget)
                        }
                        .buttonStyle(ToyButtonStyle(fill: AppTheme.card, radius: m.cellCorner, depth: m.shallowDepth, border: m.thinBorder))
                    }

                    section("ZO SPEEL JE") {
                        card {
                            bullet("die.face.5.fill", String(localized: "Gooi de vijf stenen. Je mag tot drie keer gooien per beurt."))
                            bullet("hand.raised.fill", String(localized: "Tik op stenen om ze vast te houden; die gooien niet mee."))
                            bullet("checkmark.circle.fill", String(localized: "Kies daarna een vakje voor je punten. Elk vakje kan maar één keer."))
                            bullet("flag.checkered", String(localized: "Na dertien beurten is het blad vol. De meeste punten wint!"))
                        }
                    }

                    section("BOVENIN") {
                        card {
                            Text("Bij de enen tot en met de zessen tellen alleen díé ogen. Drie vijven bij de vijven? Dat is 15 punten.")
                                .font(AppTheme.rounded(m.captionSize + 2, .bold))
                                .foregroundStyle(AppTheme.cardSoft)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: m.gutter * 0.6) {
                                Text("BONUS\n+35")
                                    .font(AppTheme.rounded(m.captionSize * 0.9))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(AppTheme.ink)
                                    .padding(8)
                                    .toyBlock(fill: AppTheme.tintAmber, radius: m.cellCorner, depth: 0, border: m.thinBorder)

                                Text("Gooi je bovenin samen 63 of meer bij elkaar? Dan krijg je er 35 punten bij!")
                                    .font(AppTheme.rounded(m.captionSize + 2, .bold))
                                    .foregroundStyle(AppTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    section("ONDERIN") {
                        card {
                            categoryRow(.threeOfAKind, String(localized: "Drie dezelfde ogen."), points: String(localized: "alle ogen"))
                            categoryRow(.fourOfAKind, String(localized: "Vier dezelfde ogen."), points: String(localized: "alle ogen"))
                            categoryRow(.fullHouse, String(localized: "Twee én drie dezelfde samen."), points: "25")
                            categoryRow(.smallStraight, String(localized: "Vier stenen op een rij."), points: "30")
                            categoryRow(.largeStraight, String(localized: "Vijf stenen op een rij."), points: "40")
                            categoryRow(.dobbel, String(localized: "Vijf dezelfde: DOBBEL!"), points: "50")
                            categoryRow(.chance, String(localized: "Alles mag; tel alle ogen op."), points: String(localized: "alle ogen"))
                        }
                    }

                    section("NOG EEN DOBBEL?") {
                        card {
                            bullet("star.fill", String(localized: "Gooi je nóg eens vijf dezelfde terwijl je Dobbel-vakje al vol is? Dan krijg je er 100 punten bij!"))
                            bullet("arrow.uturn.up", String(localized: "De worp zelf zet je bovenin bij dat getal. Is dat vakje al vol, dan mag hij als joker in een vakje onderin."))
                        }
                    }

                    section("IN VOLGORDE") {
                        card {
                            bullet("list.number", String(localized: "In deze spelvorm vul je het blad van boven naar onder: eerst de enen, dan de tweeën… tot en met kans."))
                            bullet("die.face.5.fill", String(localized: "Kiezen hoeft niet — het volgende vakje staat al klaar. Gooi zo goed mogelijk voor precies dát vakje!"))
                            bullet("figure.2.and.child.holdinghands", String(localized: "Hoort bij de Gezinsversie."))
                        }
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

    private func categoryRow(_ category: ScoreCategory, _ text: String, points: String) -> some View {
        HStack(spacing: m.gutter * 0.7) {
            CategoryIcon(category: category)
                .frame(width: m.iconWidth, height: m.rowHeight)

            VStack(alignment: .leading, spacing: 1) {
                Text(category.title)
                    .font(AppTheme.rounded(m.captionSize + 2))
                    .foregroundStyle(AppTheme.ink)
                Text(text)
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.cardSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(points)
                .font(AppTheme.rounded(m.captionSize + 1))
                .foregroundStyle(AppTheme.coral)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.title): \(text) Punten: \(points).")
    }

    private func bullet(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: m.gutter * 0.6) {
            Image(systemName: icon)
                .font(.system(size: m.bodySize, weight: .black))
                .foregroundStyle(AppTheme.coral)
                .frame(width: m.bodySize * 1.5)

            Text(text)
                .font(AppTheme.rounded(m.captionSize + 2, .bold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: m.gutter * 0.8) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(m.gutter)
        .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)
    }

    @ViewBuilder
    private func section<Content: View>(
        _ title: LocalizedStringKey,
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
    RulesView()
        .appMetrics()
}
