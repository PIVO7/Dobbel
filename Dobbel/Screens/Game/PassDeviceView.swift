import SwiftUI

/// Aan of uit voor het doorgeefscherm tussen beurten; instelbaar in het
/// instellingenscherm.
enum PassAndPlay {
    private static let key = "doorgeefscherm-aan"

    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: key) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

/// De pauze tussen twee beurten aan één toestel: het spel wacht tot de
/// volgende speler het toestel heeft en er klaar voor is, in plaats van
/// meteen het blad te tonen.
struct PassDeviceView: View {
    let player: GamePlayer
    let onReady: () -> Void
    /// Alleen gezet als de vorige zet nog terug mag.
    let onUndo: (() -> Void)?

    @Environment(\.metrics) private var m

    var body: some View {
        ZStack {
            AppTheme.ink.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(perform: onReady)

            VStack(spacing: m.gutter) {
                AvatarBadge(player: player, size: m.avatarSize * 1.5)
                    .padding(.top, m.gutter * 0.4)

                Text("Geef door aan \(player.name)")
                    .font(AppTheme.rounded(m.titleSize * 0.6))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)

                Button(action: onReady) {
                    Text("We spelen door!")
                        .font(AppTheme.rounded(m.buttonTextSize * 0.8))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: m.buttonHeight * 0.85)
                }
                .buttonStyle(ToyButtonStyle(
                    fill: AppTheme.mint,
                    radius: m.cardCorner * 0.8,
                    depth: m.depth,
                    border: m.border
                ))
                .padding(.top, 4)

                if let onUndo {
                    Button(action: onUndo) {
                        Label("Oeps — zet de vorige zet terug", systemImage: "arrow.uturn.backward")
                            .font(AppTheme.rounded(m.captionSize, .bold))
                            .foregroundStyle(AppTheme.soft)
                            .frame(minHeight: m.tapTarget)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(m.gutter * 1.4)
            .toyBlock(fill: AppTheme.cream, radius: m.cardCorner + 4, depth: m.depth + 1, border: m.border)
            .frame(maxWidth: m.overlayMaxWidth * 0.82)
            .padding(m.gutter * 2)
            .accessibilityAddTraits(.isModal)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.94)))
    }
}

#Preview {
    PassDeviceView(
        player: GamePlayer(profile: PlayerProfile(name: "Ellis", avatarColorIndex: 1, avatarSymbol: "star.fill")),
        onReady: {},
        onUndo: {}
    )
    .background(AppTheme.cream)
    .appMetrics()
}
