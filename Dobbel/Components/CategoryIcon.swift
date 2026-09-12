import SwiftUI

/// De icoontegel links van elke rij: ogen voor de bovenkant, een symbool voor
/// de onderkant.
struct CategoryIcon: View {
    let category: ScoreCategory

    @Environment(\.metrics) private var m

    var body: some View {
        content
            .foregroundStyle(inkColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toyBlock(fill: tint, radius: m.cellCorner, depth: 0, border: m.thinBorder)
            .accessibilityLabel(category.title)
    }

    private var glyphSize: CGFloat { m.iconWidth * 0.36 }

    @ViewBuilder
    private var content: some View {
        switch category {
        case .ones, .twos, .threes, .fours, .fives, .sixes:
            DiePips(value: face, inset: m.iconWidth * 0.11)
        case .threeOfAKind:
            Text("3×").font(AppTheme.rounded(glyphSize))
        case .fourOfAKind:
            Text("4×").font(AppTheme.rounded(glyphSize))
        case .fullHouse:
            Image(systemName: "house.fill").font(.system(size: glyphSize, weight: .black))
        case .smallStraight:
            StraightGlyph(bars: 4).padding(m.iconWidth * 0.2)
        case .largeStraight:
            StraightGlyph(bars: 5).padding(m.iconWidth * 0.18)
        case .dobbel:
            Image(systemName: "star.fill").font(.system(size: glyphSize * 1.1, weight: .black))
        case .chance:
            Text("?").font(AppTheme.rounded(glyphSize * 1.1))
        }
    }

    private var face: Int {
        category.faceValue ?? 6
    }

    // Eén kleur voor álle categorievakjes: de gele ogen-kolom en de blauwe
    // combikolom lazen als twee soorten vakjes, terwijl ze hetzelfde zeggen —
    // hier staat wát je scoort. Alleen de Dobbel-ster houdt haar feestkleur.
    private var tint: Color {
        AppTheme.tintAmber
    }

    private var inkColor: Color {
        category == .dobbel ? AppTheme.coral : AppTheme.ink
    }
}
