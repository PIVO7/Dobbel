import SwiftUI

/// Een waaier van kaartjes, als een handje opeenvolgende stenen: vier voor de
/// kleine straat, vijf voor de grote. De grote waaiert breder uit, zodat het
/// verschil ook zonder tellen te zien is. Wit met een rand in de tintkleur,
/// zodat de kaartjes elkaar kunnen overlappen zonder tot één vlek te
/// versmelten.
struct StraightGlyph: View {
    let bars: Int

    var body: some View {
        Canvas { context, size in
            // Brede kaartjes en een stevige lijn: dunner werd het op de
            // getinte tegels een vage vlek.
            let plateWidth = size.width * (bars == 4 ? 0.46 : 0.40)
            let plateHeight = size.height * 0.92
            let spread: Double = bars == 4 ? 30 : 38
            let lineWidth = max(plateWidth * 0.19, 1.6)

            for index in 0..<bars {
                let angle = -spread + 2 * spread * Double(index) / Double(bars - 1)
                var ctx = context
                ctx.translateBy(x: size.width / 2, y: size.height * 1.05)
                ctx.rotate(by: .degrees(angle))
                let rect = CGRect(
                    x: -plateWidth / 2,
                    y: -size.height * 1.02,
                    width: plateWidth,
                    height: plateHeight
                )
                let path = Path(roundedRect: rect, cornerRadius: plateWidth * 0.3, style: .continuous)
                ctx.fill(path, with: .color(.white))
                ctx.stroke(path, with: .foreground, lineWidth: lineWidth)
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
