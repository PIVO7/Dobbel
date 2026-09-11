import SwiftUI

struct DiceTrayView: View {
    let dice: [Die]
    let isRolling: Bool
    /// Vóór de eerste worp van de beurt liggen hier verzonken lege vakjes:
    /// vijf witte stenen met één oog lazen als een echte worp van enen,
    /// terwijl er nog helemaal niet gegooid is.
    var hasRolled: Bool = true
    let canInteract: Bool
    let onToggle: (UUID) -> Void

    @Environment(\.metrics) private var m

    var body: some View {
        if !hasRolled && !isRolling {
            HStack(spacing: m.dieGap) {
                ForEach(dice) { _ in
                    Color.clear
                        .frame(width: m.dieSize, height: m.dieSize)
                        .toyBlock(fill: AppTheme.sunk, radius: m.dieCorner, depth: 0, border: m.thinBorder)
                }
            }
            .padding(.vertical, 8)
            .accessibilityElement()
            .accessibilityLabel(String(localized: "Nog geen worp"))
        } else {
            rolledTray
        }
    }

    private var rolledTray: some View {
        HStack(spacing: m.dieGap) {
            // De Array-omweg blijft nodig zolang het doel iOS 17 is: ForEach
            // over enumerated() zelf vraagt de collection-conformance van
            // iOS 26.
            ForEach(Array(dice.enumerated()), id: \.element.id) { index, die in
                // Een echte knop en geen tikgebaar: anders kan VoiceOver de
                // steen wel voorlezen maar niet vasthouden.
                Button {
                    onToggle(die.id)
                } label: {
                    DieView(
                        die: die,
                        isRolling: isRolling && !die.isHeld,
                        settleDelay: Double(index) * 0.04
                    )
                }
                .buttonStyle(DieButtonStyle())
                .disabled(!canInteract)
                .accessibilityLabel("Dobbelsteen \(die.value)")
                .accessibilityHint(die.isHeld
                    ? LocalizedStringKey("Vastgehouden, tik om los te laten")
                    : LocalizedStringKey("Tik om vast te houden"))
                .accessibilityAddTraits(die.isHeld ? .isSelected : [])
            }
        }
        .padding(.vertical, 8)
    }
}


/// Een steen ziet er hetzelfde uit of hij nu tikbaar is of niet: het grijs dat
/// `.plain` op uitgeschakelde knoppen legt, hoort niet bij deze stijl. Of je
/// mag vasthouden blijkt al uit de beurt zelf.
private struct DieButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

#Preview {
    DiceTrayView(
        dice: [Die(value: 5), Die(value: 3, isHeld: true), Die(value: 1), Die(value: 6), Die(value: 2)],
        isRolling: false,
        canInteract: true,
        onToggle: { _ in }
    )
    .padding()
    .background(AppTheme.cream)
    .appMetrics()
}
