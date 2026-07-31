import SwiftUI

struct DiePips: View {
    let value: Int
    var inset: CGFloat = 6

    var body: some View {
        // Een Canvas en geen GeometryReader met Circles: dit staat elf keer
        // per scherm en hoeft niet aan layout deel te nemen, alleen te tekenen.
        Canvas { context, size in
            let s = min(size.width, size.height)
            // Gecentreerd, ook in een tegel die hoger is dan breed; anders
            // hangen de ogen tegen de bovenrand.
            let dx = (size.width - s) / 2
            let dy = (size.height - s) / 2
            let pad = s * 0.22
            let pip = s * 0.16

            for point in Self.positions(for: value) {
                let rect = CGRect(
                    x: dx + pad + point.x * (s - pad * 2) - pip / 2,
                    y: dy + pad + point.y * (s - pad * 2) - pip / 2,
                    width: pip,
                    height: pip
                )
                context.fill(Circle().path(in: rect), with: .foreground)
            }
        }
        .padding(inset)
    }

    static func positions(for value: Int) -> [CGPoint] {
        switch value {
        case 1: return [.init(x: 0.5, y: 0.5)]
        case 2: return [.init(x: 0.18, y: 0.18), .init(x: 0.82, y: 0.82)]
        case 3: return [.init(x: 0.18, y: 0.18), .init(x: 0.5, y: 0.5), .init(x: 0.82, y: 0.82)]
        case 4: return [
            .init(x: 0.18, y: 0.18), .init(x: 0.82, y: 0.18),
            .init(x: 0.18, y: 0.82), .init(x: 0.82, y: 0.82)
        ]
        case 5: return [
            .init(x: 0.18, y: 0.18), .init(x: 0.82, y: 0.18),
            .init(x: 0.5, y: 0.5),
            .init(x: 0.18, y: 0.82), .init(x: 0.82, y: 0.82)
        ]
        default: return [
            .init(x: 0.18, y: 0.18), .init(x: 0.82, y: 0.18),
            .init(x: 0.18, y: 0.5), .init(x: 0.82, y: 0.5),
            .init(x: 0.18, y: 0.82), .init(x: 0.82, y: 0.82)
        ]
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        ForEach(1...6, id: \.self) { value in
            DiePips(value: value)
                .foregroundStyle(AppTheme.ink)
                .frame(width: 44, height: 44)
                .background(.white)
        }
    }
    .padding()
    .background(AppTheme.cream)
}
