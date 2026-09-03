import SwiftUI

/// De gooiknop, met het aantal resterende worpen in een blokje ernaast.
/// Zijn de worpen op en moet er gekozen worden, dan maakt de knop plaats
/// voor een wenk naar het scoreblad: een grijze, uitgeschakelde knop leest
/// als "je kunt niets doen", terwijl de beurt juist op een tik wacht.
struct RollButtonView: View {
    let isRolling: Bool
    let rollsRemaining: Int
    let canRoll: Bool
    /// Alle worpen zijn op en de speler is aan zet op het scoreblad.
    let mustChoose: Bool
    let onRoll: () -> Void

    @Environment(\.metrics) private var m

    var body: some View {
        if mustChoose {
            ChooseHintView()
                .frame(height: m.heroButton.height)
        } else {
            Button(action: onRoll) {
                HStack(spacing: 10) {
                    Text(title)
                        .font(AppTheme.rounded(m.heroButton.textSize))
                    if rollsRemaining > 0 {
                        Text("\(rollsRemaining)")
                            .font(AppTheme.rounded(m.heroButton.textSize * 0.7))
                            .frame(minWidth: m.heroButton.textSize * 1.35, minHeight: m.heroButton.textSize * 1.35)
                            .background(
                                Color.black.opacity(0.18),
                                in: RoundedRectangle(cornerRadius: m.heroButton.textSize * 0.42)
                            )
                    }
                }
                .foregroundStyle(canRoll ? AppTheme.ink : AppTheme.offInk)
                .frame(maxWidth: .infinity)
                .frame(height: m.heroButton.height)
            }
            .buttonStyle(ToyButtonStyle(
                fill: canRoll ? AppTheme.mint : AppTheme.offFill,
                radius: m.buttonCorner,
                depth: m.heroDepth,
                border: m.border
            ))
            .disabled(!canRoll)
            .accessibilityLabel(
                rollsRemaining > 0
                    ? String(localized: "\(title), nog \(rollsRemaining) worpen")
                    : title
            )
        }
    }

    private var title: String {
        // Zonder worpen over is hier altijd een computer aan het kiezen; de
        // wenk voor de speler zelf staat in `ChooseHintView`.
        if isRolling || rollsRemaining == 0 { return String(localized: "Bezig…") }
        return String(localized: "Gooien")
    }
}

/// De wenk op de plek van de gooiknop: een zacht deinend pijltje omhoog met
/// de uitnodiging om een vakje te tikken. Eigen view, zodat de deining vers
/// begint telkens als de wenk verschijnt.
private struct ChooseHintView: View {
    @Environment(\.metrics) private var m
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bobbing = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "chevron.up")
                .font(.system(size: m.heroButton.textSize * 0.85, weight: .black))
                .foregroundStyle(AppTheme.coral)
                .offset(y: bobbing ? -4 : 2)
            Text("Tik een vakje om te scoren")
                .font(AppTheme.rounded(m.heroButton.textSize * 0.9))
                .foregroundStyle(AppTheme.headline)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                bobbing = true
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        RollButtonView(isRolling: false, rollsRemaining: 3, canRoll: true, mustChoose: false, onRoll: {})
        RollButtonView(isRolling: false, rollsRemaining: 0, canRoll: false, mustChoose: true, onRoll: {})
    }
    .padding()
    .background(AppTheme.cream)
}
