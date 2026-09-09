import SwiftUI

/// Een oplopend trapje van stippen, als ogen die netjes op een rij klimmen:
/// vier voor de kleine straat, vijf voor de grote. Dezelfde beeldtaal als de
/// stenen zelf, en met dichte stippen blijft het ook op de getinte tegels en
/// op kleine maten haarscherp — de vorige kaartjeswaaier versmolt daar tot
/// één vlek.
struct StraightGlyph: View {
    let bars: Int

    var body: some View {
        Canvas { context, size in
            let count = CGFloat(bars)
            // De stippen overlappen elkaar nét niet: groot genoeg om te
            // tellen, klein genoeg om het trapje te laten klimmen.
            let dot = min(size.width / count * 1.05, size.height * 0.44)
            for index in 0..<bars {
                let step = CGFloat(index) / (count - 1)
                let rect = CGRect(
                    x: step * (size.width - dot),
                    y: (1 - step) * (size.height - dot),
                    width: dot,
                    height: dot
                )
                context.fill(Path(ellipseIn: rect), with: .foreground)
            }
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        StraightGlyph(bars: 4)
        StraightGlyph(bars: 5)
    }
    .foregroundStyle(AppTheme.sky)
    .frame(height: 32)
    .padding()
    .background(AppTheme.cream)
}
