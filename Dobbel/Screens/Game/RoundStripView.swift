import SwiftUI

/// Hoeveelste ronde we zijn, met een bolletje per ronde eronder.
struct RoundStripView: View {
    let roundNumber: Int
    let totalRounds: Int

    @Environment(\.metrics) private var m

    var body: some View {
        VStack(spacing: 7) {
            Text("RONDE \(roundNumber) / \(totalRounds)")
                .font(AppTheme.rounded(m.captionSize * 0.92))
                .kerning(1.6)
                .foregroundStyle(AppTheme.faint)

            HStack(spacing: 4) {
                ForEach(0..<totalRounds, id: \.self) { index in
                    Circle()
                        .fill(index < roundNumber ? AppTheme.amber : AppTheme.tintStone)
                        .frame(width: m.captionSize * 0.6, height: m.captionSize * 0.6)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ronde \(roundNumber) van \(totalRounds)")
    }
}

#Preview {
    RoundStripView(roundNumber: 4, totalRounds: ScoreCategory.allCases.count)
        .padding()
        .background(AppTheme.cream)
}
