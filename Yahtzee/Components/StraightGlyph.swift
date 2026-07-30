import SwiftUI

/// Oplopende staafjes voor de straten: vier voor de kleine, vijf voor de grote.
struct StraightGlyph: View {
    let bars: Int

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let gap = w * 0.09
            let barWidth = (w - gap * CGFloat(bars - 1)) / CGFloat(bars)

            ZStack(alignment: .bottomLeading) {
                ForEach(0..<bars, id: \.self) { index in
                    let fraction = 0.42 + 0.58 * (CGFloat(index) / CGFloat(bars - 1))
                    RoundedRectangle(cornerRadius: barWidth * 0.35, style: .continuous)
                        .frame(width: barWidth, height: h * fraction)
                        .offset(x: (barWidth + gap) * CGFloat(index))
                }
            }
            .frame(width: w, height: h, alignment: .bottomLeading)
        }
    }
}
