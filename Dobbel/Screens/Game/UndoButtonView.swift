import SwiftUI

/// Het terugzet-knopje: zichtbaar zolang de vorige zet nog terug mag —
/// kinderen tikken vaak per ongeluk het verkeerde vakje aan. Staat op de
/// plek van het tipknopje; die twee sluiten elkaar vanzelf uit (de tip
/// bestaat pas ná een worp, de terugzet alleen ervóór).
struct UndoButtonView: View {
    let onUndo: () -> Void

    @Environment(\.metrics) private var m

    var body: some View {
        Button(action: onUndo) {
            Label("Zet de vorige zet terug", systemImage: "arrow.uturn.backward")
                .font(AppTheme.rounded(m.captionSize, .bold))
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
        }
        .buttonStyle(ToyButtonStyle(
            fill: AppTheme.card,
            radius: m.cellCorner + 2,
            depth: 3,
            border: m.thinBorder
        ))
        .frame(minHeight: m.tapTarget)
        .contentShape(.rect)
    }
}

#Preview {
    UndoButtonView(onUndo: {})
        .padding()
        .background(AppTheme.cream)
        .appMetrics()
}
