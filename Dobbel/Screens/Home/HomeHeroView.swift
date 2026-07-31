import SwiftUI

/// Het anker van het startscherm: twee grote speelgoed-dobbelstenen boven de
/// titel. Tikken laat ze wiebelen en opnieuw vallen — puur voor de fun.
struct HomeHeroView: View {
    @Environment(\.metrics) private var m
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var faces: [Int] = [5, 3]
    @State private var wiggle = 0

    var body: some View {
        Button(action: tumble) {
            HStack(spacing: -m.dieSize * 0.18) {
                heroDie(face: faces[0], fill: .white, tilt: -9)
                    .zIndex(1)
                heroDie(face: faces[1], fill: AppTheme.amber, tilt: 8)
                    .offset(y: m.dieSize * 0.16)
            }
            .rotationEffect(.degrees(wiggle.isMultiple(of: 2) ? 0 : 3))
            .animation(.spring(response: 0.3, dampingFraction: 0.35), value: wiggle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Twee dobbelstenen")
        .accessibilityHint("Tik om ze te laten rollen")
    }

    private func heroDie(face: Int, fill: Color, tilt: Double) -> some View {
        DiePips(value: face, inset: m.dieSize * 0.14)
            .foregroundStyle(AppTheme.ink)
            .frame(width: m.dieSize * 1.15, height: m.dieSize * 1.15)
            .background(
                RoundedRectangle(cornerRadius: m.dieCorner * 1.15, style: .continuous)
                    .fill(fill)
            )
            .overlay {
                RoundedRectangle(cornerRadius: m.dieCorner * 1.15, style: .continuous)
                    .strokeBorder(AppTheme.ink, lineWidth: m.border)
            }
            .background(
                RoundedRectangle(cornerRadius: m.dieCorner * 1.15, style: .continuous)
                    .fill(AppTheme.ink)
                    .offset(y: m.depth)
            )
            .rotationEffect(.degrees(tilt))
    }

    private func tumble() {
        faces = [Int.random(in: 1...6), Int.random(in: 1...6)]
        if !reduceMotion {
            wiggle += 1
        }
        SoundPlayer.shared.play(.roll)
    }
}

#Preview {
    HomeHeroView()
        .padding(40)
        .background(AppTheme.cream)
        .appMetrics()
}
