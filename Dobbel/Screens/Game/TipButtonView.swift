import SwiftUI

/// Het "waarom?"-knopje onder de worp: zichtbaar zodra de tip een vakje
/// aanraadt, en een tik legt de keuze in kindertaal uit. De tip zelf komt van
/// de engine, zodat hij maar één keer per hertekening wordt uitgerekend.
struct TipButtonView: View {
    let advice: ScoreCategory?
    let onExplain: (ScoreCategory) -> Void

    @Environment(\.metrics) private var m

    var body: some View {
        if let advice {
            Button {
                onExplain(advice)
            } label: {
                Label("Waarom \(advice.title.lowercased())?", systemImage: "lightbulb.fill")
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
            }
            .buttonStyle(ToyButtonStyle(
                fill: AppTheme.tintAmber,
                radius: m.cellCorner + 2,
                depth: 3,
                border: m.thinBorder
            ))
            // Het gele blok blijft compact; het tikvlak eromheen haalt de
            // 44-puntsgrens.
            .frame(minHeight: m.tapTarget)
            .contentShape(.rect)
        }
    }
}

#Preview {
    TipButtonView(advice: .fives, onExplain: { _ in })
        .padding()
        .background(AppTheme.cream)
        .appMetrics()
}
