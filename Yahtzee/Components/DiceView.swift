import SwiftUI

struct DiceTrayView: View {
    let dice: [Die]
    let isRolling: Bool
    let canInteract: Bool
    let onToggle: (UUID) -> Void

    @Environment(\.metrics) private var m

    var body: some View {
        HStack(spacing: m.dieGap) {
            ForEach(dice) { die in
                // Een echte knop en geen tikgebaar: anders kan VoiceOver de
                // steen wel voorlezen maar niet vasthouden.
                Button {
                    onToggle(die.id)
                } label: {
                    DieView(die: die, isRolling: isRolling && !die.isHeld)
                }
                .buttonStyle(DieButtonStyle())
                .disabled(!canInteract)
                .accessibilityLabel("Dobbelsteen \(die.value)")
                .accessibilityHint(die.isHeld ? "Vastgehouden, tik om los te laten" : "Tik om vast te houden")
                .accessibilityAddTraits(die.isHeld ? .isSelected : [])
            }
        }
        .padding(.vertical, 8)
    }
}

/// Een steen ziet er hetzelfde uit of hij nu tikbaar is of niet: het grijs dat
/// `.plain` op uitgeschakelde knoppen legt, hoort niet bij deze stijl. Of je
/// mag vasthouden blijkt al uit de beurt zelf.
private struct DieButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

struct DieView: View {
    let die: Die
    let isRolling: Bool

    @State private var spin = 0.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.metrics) private var m

    var body: some View {
        DiePips(value: die.value)
            .foregroundStyle(AppTheme.ink)
            .frame(width: m.dieSize, height: m.dieSize)
            // Vastgehouden stenen zakken in: schaduw krimpt, steen schuift mee omlaag.
            .toyBlock(
                fill: die.isHeld ? AppTheme.amber : .white,
                radius: m.dieCorner,
                depth: die.isHeld ? 2 : m.depth,
                border: m.border
            )
            .offset(y: die.isHeld ? m.depth - 2 : 0)
            .rotationEffect(.degrees(isRolling && !reduceMotion ? spin : 0))
            .offset(y: isRolling && !reduceMotion ? -8 : 0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.08).repeatCount(6, autoreverses: true),
                value: isRolling
            )
            .animation(.easeOut(duration: 0.12), value: die.isHeld)
            .onChange(of: isRolling) { _, rolling in
                guard !reduceMotion else { return }
                if rolling {
                    spin = Double.random(in: -18...18)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        spin = 0
                    }
                }
            }
    }
}

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
