import SwiftUI

struct DiceTrayView: View {
    let dice: [Die]
    let isRolling: Bool
    let canInteract: Bool
    let onToggle: (UUID) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(dice.enumerated()), id: \.element.id) { index, die in
                DieView(die: die, isRolling: isRolling && !die.isHeld)
                    .onTapGesture {
                        guard canInteract else { return }
                        withAnimation(AppTheme.springSnappy) {
                            onToggle(die.id)
                        }
                    }
                    .accessibilityLabel("Dobbelsteen \(die.value)")
                    .accessibilityHint(die.isHeld ? "Vastgehouden, tik om los te laten" : "Tik om vast te houden")
                    .accessibilityAddTraits(die.isHeld ? .isSelected : [])
                    .transition(.scale.combined(with: .opacity))
                    .animation(AppTheme.springSoft.delay(Double(index) * 0.03), value: die.isHeld)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.feltDeep.opacity(0.45))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(AppTheme.cream.opacity(0.12), lineWidth: 1)
                }
        )
    }
}

struct DieView: View {
    let die: Die
    let isRolling: Bool

    @State private var spin = 0.0
    @State private var bounce = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(die.isHeld ? AppTheme.held : AppTheme.cream)
                .shadow(color: .black.opacity(0.28), radius: die.isHeld ? 2 : 7, y: die.isHeld ? 1 : 4)

            DiePips(value: die.value)
                .foregroundStyle(AppTheme.ink)
                .opacity(isRolling ? 0.35 : 1)
        }
        .frame(width: 60, height: 60)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    die.isHeld ? AppTheme.coral : AppTheme.cream.opacity(0.55),
                    lineWidth: die.isHeld ? 3.5 : 1.5
                )
        }
        .scaleEffect(die.isHeld ? 1.06 : (bounce ? 1.08 : 1))
        .rotationEffect(.degrees(isRolling ? spin : 0))
        .offset(y: isRolling ? -10 : (die.isHeld ? -2 : 0))
        .animation(AppTheme.springSnappy, value: die.isHeld)
        .onChange(of: isRolling) { _, rolling in
            if rolling {
                spin = Double.random(in: -28...28)
                bounce = true
            } else {
                withAnimation(AppTheme.springBouncy) {
                    spin = 0
                    bounce = false
                }
            }
        }
        .onChange(of: die.value) { _, _ in
            guard !isRolling else { return }
            withAnimation(AppTheme.springSnappy) {
                bounce = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(AppTheme.springSoft) {
                    bounce = false
                }
            }
        }
    }
}

struct DiePips: View {
    let value: Int

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let inset = s * 0.22
            let positions = pipPositions(for: value)

            ZStack {
                ForEach(Array(positions.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .frame(width: s * 0.16, height: s * 0.16)
                        .position(
                            x: inset + point.x * (s - inset * 2),
                            y: inset + point.y * (s - inset * 2)
                        )
                }
            }
        }
        .padding(6)
    }

    private func pipPositions(for value: Int) -> [CGPoint] {
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
