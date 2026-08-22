import SwiftUI

/// De worp in woorden, groot en gecentreerd boven de stenen. Wie aan de
/// beurt is staat al in de scorechips boven het blad; een extra naamkaartje
/// hier was dubbelop. Hints voor het kiezen leven op het scoreblad zelf
/// (de tip-markering) en in de VoiceOver-aankondiging.
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
