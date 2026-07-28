import SwiftUI

struct AvatarBadge: View {
    let profile: PlayerProfile
    var size: CGFloat = 44

    private var color: Color {
        let palette: [Color] = [
            AppTheme.coral,
            AppTheme.sky,
            AppTheme.amber,
            AppTheme.mint,
            Color(red: 0.78, green: 0.47, blue: 0.90),
            Color(red: 0.98, green: 0.60, blue: 0.35)
        ]
        return palette[profile.avatarColorIndex % palette.count]
    }

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.36, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .toyBlock(fill: color, radius: size / 2, depth: 3, border: 2.5)
            .accessibilityHidden(true)
    }

    private var initials: String {
        let parts = profile.name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(profile.name.prefix(2)).uppercased()
    }
}
