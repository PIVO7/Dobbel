import SwiftUI

/// De spelstand als toy-chip vlak boven het scoreblad: wie er mag gooien,
/// hoeveel worpen er nog zijn, en zodra de worpen op zijn de uitnodiging om
/// een vakje te tikken. Bewust hier en niet onderaan: het vakje dat getikt
/// moet worden staat er direct onder.
///
/// De verdeling met `RollCalloutView` is: die zegt wát je gooide en hoort
/// daarom bij de stenen; deze chip zegt wat er nú moet gebeuren.
struct GameStatusChipView: View {
    let message: String
    /// Alle worpen zijn op en de speler is aan zet op het scoreblad.
    let mustChoose: Bool

    @Environment(\.metrics) private var m

    var body: some View {
        Text(title)
            .font(AppTheme.rounded(m.bodySize, .bold))
            .foregroundStyle(AppTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, m.gutter)
            .padding(.vertical, m.gutter * 0.45)
            .frame(maxWidth: .infinity)
            // Amber zodra er gekozen moet worden: dan is de chip geen
            // mededeling meer maar een opdracht.
            .toyBlock(
                fill: mustChoose ? AppTheme.tintAmber : AppTheme.card,
                radius: m.cellCorner,
                depth: m.shallowDepth,
                border: m.thinBorder + 0.5
            )
            .animation(.easeOut(duration: 0.15), value: title)
    }

    private var title: String {
        mustChoose ? String(localized: "Tik een vakje om te scoren") : message
    }
}

#Preview {
    VStack(spacing: 16) {
        GameStatusChipView(message: "Lene mag gooien", mustChoose: false)
        GameStatusChipView(message: "Lene mag gooien", mustChoose: true)
    }
    .padding()
    .background(AppTheme.cream)
    .appMetrics()
}
