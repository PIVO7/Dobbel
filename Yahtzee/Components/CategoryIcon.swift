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
            StraightGlyph(bars: 4).padding(m.iconWidth * 0.24)
        case .largeStraight:
            StraightGlyph(bars: 5).padding(m.iconWidth * 0.24)
        case .yahtzee:
            Image(systemName: "star.fill").font(.system(size: glyphSize * 1.1, weight: .black))
        case .chance:
            Text("?").font(AppTheme.rounded(glyphSize * 1.1))
        }
    }

    private var face: Int {
        category.faceValue ?? 6
    }

    private var tint: Color {
        if category == .yahtzee { return AppTheme.tintCoral }
        return category.isUpper ? AppTheme.tintAmber : AppTheme.tintSky
    }

    private var inkColor: Color {
        if category == .yahtzee { return AppTheme.coral }
        return category.isUpper ? AppTheme.ink : AppTheme.sky
    }
}
