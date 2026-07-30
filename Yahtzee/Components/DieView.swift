import SwiftUI

struct DieView: View {
    let die: Die
    let isRolling: Bool
    /// Elke steen landt een tikje later dan zijn buurman. Stoppen ze allemaal
    /// op hetzelfde moment, dan oogt het als één blok in plaats van vijf losse
    /// stenen.
    var settleDelay: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.metrics) private var m

    @State private var spin = 0.0

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
            .offset(y: isRolling && !reduceMotion ? -10 : 0)
            .animation(rollAnimation, value: isRolling)
            .animation(.easeOut(duration: 0.12), value: die.isHeld)
            .onChange(of: isRolling) { _, rolling in
                if rolling {
                    spin = Double.random(in: 9...17) * (Bool.random() ? 1 : -1)
                }
            }
    }

    /// Begrensd herhalen, geen `repeatForever`: een oneindige animatie die je
    /// later met vertraging probeert te vervangen kan blijven draaien, en dan
    /// wiebelt er een steen eeuwig door. Een even aantal herhalingen eindigt
    /// bovendien op de rustpositie, mocht de landing ooit uitblijven.
    private var rollAnimation: Animation? {
        guard !reduceMotion else { return nil }
        if isRolling {
            return .easeInOut(duration: 0.09).repeatCount(12, autoreverses: true)
        }
        return .spring(response: 0.3, dampingFraction: 0.6).delay(settleDelay)
    }
}

#Preview {
    HStack(spacing: 9) {
        DieView(die: Die(value: 5), isRolling: false)
        DieView(die: Die(value: 3, isHeld: true), isRolling: false)
    }
    .padding()
    .background(AppTheme.cream)
}
