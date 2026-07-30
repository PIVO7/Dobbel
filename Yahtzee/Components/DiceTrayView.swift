import SwiftUI

struct DiceTrayView: View {
    let dice: [Die]
    let isRolling: Bool
    let canInteract: Bool
    let onToggle: (UUID) -> Void

    @Environment(\.metrics) private var m

    var body: some View {
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
                .accessibilityHint(die.isHeld ? "Vastgehouden, tik om los te laten" : "Tik om vast te houden")
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
