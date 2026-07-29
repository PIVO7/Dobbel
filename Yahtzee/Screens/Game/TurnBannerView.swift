import SwiftUI

/// Korte melding bij een beurtwissel, zodat aan één toestel duidelijk is wie
/// er nu mag. Vangt geen tikken op — hij verdwijnt vanzelf.
struct TurnBannerView: View {
    let playerName: String
    let isWide: Bool

    @Environment(\.metrics) private var m

    var body: some View {
        VStack {
            Spacer()
            Text("Beurt van \(playerName)")
                .font(AppTheme.rounded(m.bodySize + 2))
                .foregroundStyle(.white)
                .padding(.horizontal, m.gutter * 1.5)
                .padding(.vertical, m.gutter)
                .toyBlock(fill: AppTheme.coral, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)
                .padding(.bottom, isWide ? 40 : 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.ink.opacity(0.25).ignoresSafeArea())
        .allowsHitTesting(false)
    }
}

#Preview {
    TurnBannerView(playerName: "Ellis", isWide: false)
        .background(AppTheme.cream)
}
