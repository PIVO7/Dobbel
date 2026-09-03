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

    var body: some View {
        Text(title)
            .font(AppTheme.rounded(m.displaySize))
            .foregroundStyle(title == RollPhrase.dobbel ? AppTheme.coral : AppTheme.headline)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.7)
            .contentTransition(.opacity)
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
