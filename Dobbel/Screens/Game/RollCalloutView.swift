import SwiftUI

/// De regel boven de stenen: "Gooi maar!" vóór de worp, DOBBEL! bij vijf
/// dezelfde, en bij In volgorde wat de worp waard is voor het doelvakje.
/// Na een gewone worp staat hier niets — de ruimte blijft, zodat het scherm
/// niet verspringt.
struct RollCalloutView: View {
    let title: String
    let isCelebrating: Bool

    @Environment(\.metrics) private var m
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isDobbel: Bool { title == RollPhrase.dobbel }

    var body: some View {
        Text(title)
            .font(AppTheme.rounded(m.displaySize))
            .kerning(isDobbel ? 1.5 : 0)
            .foregroundStyle(isDobbel ? AppTheme.card : AppTheme.headline)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.7)
            .contentTransition(.opacity)
            // DOBBEL! krijgt hetzelfde koraalrode blok als de uitroepen in
            // Raak en Memo. Als achtergrond, zodat de regel even hoog blijft
            // en het scherm niet verspringt.
            .background {
                if isDobbel {
                    Color.clear
                        .toyBlock(fill: AppTheme.coral, radius: m.cellCorner, depth: m.heroDepth, border: m.border)
                        .padding(.horizontal, -m.gutter * 1.2)
                        .padding(.vertical, -m.gutter * 0.25)
                }
            }
            .scaleEffect(isCelebrating && !reduceMotion ? 1.08 : 1)
            .frame(maxWidth: .infinity)
            .frame(minHeight: m.displaySize * 1.3)
            .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.6), value: isCelebrating)
    }
}

#Preview {
    VStack(spacing: 24) {
        RollCalloutView(title: "Gooi maar!", isCelebrating: false)
        RollCalloutView(title: RollPhrase.dobbel, isCelebrating: true)
    }
    .padding()
    .background(AppTheme.cream)
    .appMetrics()
}
