import SwiftUI

/// De gooiknop, met het aantal resterende worpen in een blokje ernaast.
struct RollButtonView: View {
    let isRolling: Bool
    let rollsRemaining: Int
    let canRoll: Bool
    let onRoll: () -> Void

    @Environment(\.metrics) private var m

    var body: some View {
        Button(action: onRoll) {
            HStack(spacing: 10) {
                Text(title)
                    .font(AppTheme.rounded(m.buttonTextSize))
                if rollsRemaining > 0 {
                    Text("\(rollsRemaining)")
                        .font(AppTheme.rounded(m.buttonTextSize * 0.7))
                        .frame(minWidth: m.buttonTextSize * 1.35, minHeight: m.buttonTextSize * 1.35)
                        .background(
                            Color.black.opacity(0.18),
                            in: RoundedRectangle(cornerRadius: m.buttonTextSize * 0.42)
                        )
                }
            }
            .foregroundStyle(canRoll ? AppTheme.ink : AppTheme.offInk)
            .frame(maxWidth: .infinity)
            .frame(height: m.buttonHeight)
        }
        .buttonStyle(ToyButtonStyle(
            fill: canRoll ? AppTheme.mint : AppTheme.offFill,
            radius: m.cardCorner * 0.9,
            depth: m.depth + 1,
            border: m.border
        ))
        .disabled(!canRoll)
        .accessibilityLabel(
            rollsRemaining > 0
                ? String(localized: "\(title), nog \(rollsRemaining) worpen")
                : title
        )
    }

    private var title: String {
        if isRolling { return String(localized: "Bezig…") }
        if rollsRemaining == 0 { return String(localized: "Kies een vakje") }
        return String(localized: "Gooien")
    }
}

#Preview {
    VStack(spacing: 16) {
        RollButtonView(isRolling: false, rollsRemaining: 3, canRoll: true, onRoll: {})
        RollButtonView(isRolling: false, rollsRemaining: 0, canRoll: false, onRoll: {})
    }
    .padding()
    .background(AppTheme.cream)
}
