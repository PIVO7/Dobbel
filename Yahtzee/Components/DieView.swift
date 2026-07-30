import SwiftUI

struct DieView: View {
    let die: Die
    let isRolling: Bool

    @State private var spin = 0.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.metrics) private var m

    var body: some View {
        DiePips(value: die.value)
            .foregroundStyle(AppTheme.ink)
            .frame(width: m.dieSize, height: m.dieSize)
            // Vastgehouden stenen zakken in: schaduw krimpt, steen schuift mee omlaag.
            .toyBlock(
                fill: die.isHeld ? AppTheme.amber : .white,
                radius: m.dieCorner,
                depth: die.isHeld ? 2 : m.depth,
                border: m.border
            )
            .offset(y: die.isHeld ? m.depth - 2 : 0)
            .rotationEffect(.degrees(isRolling && !reduceMotion ? spin : 0))
            .offset(y: isRolling && !reduceMotion ? -8 : 0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.08).repeatCount(6, autoreverses: true),
                value: isRolling
            )
            .animation(.easeOut(duration: 0.12), value: die.isHeld)
            .onChange(of: isRolling) { _, rolling in
                guard !reduceMotion else { return }
                if rolling {
                    spin = Double.random(in: -18...18)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        spin = 0
                    }
                }
            }
    }
}
