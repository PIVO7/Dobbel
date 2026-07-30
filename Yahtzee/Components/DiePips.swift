import SwiftUI

struct DiePips: View {
    let value: Int
    var inset: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let pad = s * 0.22
            let positions = DiePips.positions(for: value)

            ZStack {
                ForEach(Array(positions.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .frame(width: s * 0.16, height: s * 0.16)
                        .position(
                            x: pad + point.x * (s - pad * 2),
                            y: pad + point.y * (s - pad * 2)
                        )
                }
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
