import SwiftUI

/// Het feestje bij een Dobbel of een bonus. Bij Verminder beweging valt de
/// schaalsprong weg en blijft alleen het in- en uitvloeien over.
struct CelebrationBurstView: View {
    let title: String
    let tint: Color

    @Environment(\.metrics) private var m
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ConfettiView()
                .ignoresSafeArea()

            Text(title)
                .font(AppTheme.rounded(m.displaySize * 1.4))
                .foregroundStyle(.white)
                .padding(.horizontal, m.gutter * 2)
                .padding(.vertical, m.gutter * 1.3)
                .toyBlock(fill: tint, radius: m.cardCorner, depth: m.depth + 1, border: m.border)
                .scaleEffect(reduceMotion ? 1 : 1.05)
        }
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.9)))
        .allowsHitTesting(false)
    }
}

#Preview {
    CelebrationBurstView(title: RollPhrase.dobbel, tint: AppTheme.coral)
        .padding()
        .background(AppTheme.cream)
}
