import SwiftUI

/// Het bordje dat verschijnt als je op een categorie-icoon tikt: de naam en
/// één regel uitleg. Zo leert het spel zichzelf uit, precies op het moment
/// dat de vraag opkomt — zonder het blad vol tekst te zetten.
struct CategoryExplainerChip: View {
    let category: ScoreCategory

    @Environment(\.metrics) private var m

    var body: some View {
        HStack(spacing: m.gutter * 0.7) {
            CategoryIcon(category: category)
                .frame(width: m.iconWidth * 1.25, height: m.rowHeight * 1.25)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                    .font(AppTheme.rounded(m.captionSize + 4))
                    .foregroundStyle(AppTheme.ink)
                Text(category.explanation)
                    .font(AppTheme.rounded(m.captionSize + 1, .bold))
                    .foregroundStyle(AppTheme.cardSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(m.gutter * 0.9)
        .toyBlock(fill: AppTheme.card, radius: m.cardCorner * 0.8, depth: m.depth, border: m.border)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 16) {
        CategoryExplainerChip(category: .fullHouse)
        CategoryExplainerChip(category: .dobbel)
        CategoryExplainerChip(category: .smallStraight)
    }
    .padding()
    .background(AppTheme.cream)
    .appMetrics()
}
