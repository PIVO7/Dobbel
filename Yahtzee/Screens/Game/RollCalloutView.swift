import SwiftUI

/// De worp in woorden, met daaronder wat er nu van de speler verwacht wordt.
struct RollCalloutView: View {
    let title: String
    let message: String
    let isCelebrating: Bool

    @Environment(\.metrics) private var m
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppTheme.rounded(m.displaySize))
                .foregroundStyle(title == RollPhrase.yahtzee ? AppTheme.coral : AppTheme.headline)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .contentTransition(.opacity)
                .scaleEffect(isCelebrating && !reduceMotion ? 1.08 : 1)

            if !message.isEmpty {
                Text(message)
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.soft)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(minHeight: m.displaySize * 1.8)
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.6), value: isCelebrating)
    }
}

#Preview {
    VStack(spacing: 24) {
        RollCalloutView(title: "Gooi maar!", message: "Lene mag gooien", isCelebrating: false)
        RollCalloutView(title: RollPhrase.yahtzee, message: "Kies een vakje", isCelebrating: true)
    }
    .padding()
    .background(AppTheme.cream)
}
