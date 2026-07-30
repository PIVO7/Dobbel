import SwiftUI

/// Oplopende staafjes voor de straten: vier voor de kleine, vijf voor de grote.
struct StraightGlyph: View {
    let bars: Int

    var body: some View {
        // Een Canvas en geen GeometryReader met rechthoeken: puur tekenwerk,
        // zonder deelname aan layout.
        Canvas { context, size in
            let gap = size.width * 0.09
            let barWidth = (size.width - gap * CGFloat(bars - 1)) / CGFloat(bars)

            for index in 0..<bars {
                let fraction = 0.42 + 0.58 * (CGFloat(index) / CGFloat(bars - 1))
                let height = size.height * fraction
                let rect = CGRect(
                    x: (barWidth + gap) * CGFloat(index),
                    y: size.height - height,
                    width: barWidth,
                    height: height
                )
                context.fill(
                    Path(roundedRect: rect, cornerRadius: barWidth * 0.35, style: .continuous),
                    with: .foreground
                )
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
