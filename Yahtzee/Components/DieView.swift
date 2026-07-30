import SwiftUI

struct DieView: View {
    let die: Die
    let isRolling: Bool
    /// Elke steen tuimelt een tikje langer dan zijn buurman, zodat ze van
    /// links naar rechts tot stilstand komen in plaats van als één blok.
    var settleDelay: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.metrics) private var m

    /// Wanneer de huidige worp begon; `nil` betekent stilliggen.
    @State private var tumbleStart: Date?
    /// De ogen op de drie zijden die tijdens het rollen langskomen.
    @State private var hiddenFaces: [Int] = [2, 4, 5]
    /// Zijwaarts wentelen of naar voren kantelen, met richting.
    @State private var sideways = false
    @State private var direction: Double = 1

    var body: some View {
        // Een kubus is geen animeerbaar kenmerk: welke zijden je ziet moet
        // per beeldje opnieuw bepaald worden. De tijdlijn staat stil zodra
        // de steen ligt, dus in rust kost dit niets.
        TimelineView(.animation(minimumInterval: nil, paused: tumbleStart == nil)) { context in
            cube(angle: angle(at: context.date))
        }
        .background(
            // De slagschaduw is de grond en rolt dus niet mee.
            RoundedRectangle(cornerRadius: m.dieCorner, style: .continuous)
                .fill(AppTheme.ink)
                .offset(y: die.isHeld ? 2 : m.depth)
        )
        .offset(y: die.isHeld ? m.depth - 2 : 0)
        .animation(.easeOut(duration: 0.12), value: die.isHeld)
        .onChange(of: isRolling) { _, rolling in
            if rolling { startTumble() }
        }
    }

    // MARK: - Wenteling

    private var duration: Double { 0.6 + settleDelay }

    /// Twee volledige omwentelingen die uitlopen met een klein stuitje aan
    /// het einde. Een veelvoud van 360 toont de echte worp weer recht van
    /// voren, dus na afloop ligt de steen vanzelf goed.
    private func angle(at date: Date) -> Double {
        guard let start = tumbleStart else { return 0 }
        let progress = date.timeIntervalSince(start) / duration
        guard progress < 1 else { return 0 }

        // Uitlopende curve met een lichte overshoot: het stuitje van de
        // landing. De 0.8 houdt dat stuitje op zo'n vijftien graden.
        let p = progress - 1
        let bounce = 1 + p * p * ((0.8 + 1) * p + 0.8)
        return direction * 720 * bounce
    }

    private func startTumble() {
        guard !reduceMotion else { return }
        hiddenFaces = (0..<3).map { _ in Int.random(in: 1...6) }
        sideways = Bool.random()
        direction = Bool.random() ? 1 : -1

        let started = Date.now
        tumbleStart = started
        Task {
            try? await Task.sleep(for: .seconds(duration))
            // Alleen onze eigen worp stilleggen, niet die van een nieuwe.
            if tumbleStart == started {
                tumbleStart = nil
            }
        }
    }

    // MARK: - De kubus

    /// Vier zijden als een band om de draaias, elk een kwartslag verder en
    /// een halve steen naar achteren verankerd. Alleen de zijden die naar de
    /// kijker wijzen worden getekend, de dichtstbijzijnde bovenop.
    private func cube(angle: Double) -> some View {
        let faces: [(offset: Double, value: Int)] = [
            (0, die.value),
            (90, hiddenFaces[0]),
            (180, hiddenFaces[1]),
            (270, hiddenFaces[2])
        ]

        return ZStack {
            ForEach(faces, id: \.offset) { face in
                let facing = cos(Angle.degrees(angle + face.offset).radians)
                if facing > 0.001 {
                    facePlate(value: face.value)
                        .rotation3DEffect(
                            .degrees(angle + face.offset),
                            axis: sideways ? (x: 0, y: 1, z: 0) : (x: 1, y: 0, z: 0),
                            anchor: .center,
                            anchorZ: -m.dieSize / 2,
                            perspective: 0.25
                        )
                        .zIndex(facing)
                }
            }
        }
    }

    private func facePlate(value: Int) -> some View {
        DiePips(value: value)
            .foregroundStyle(AppTheme.ink)
            .frame(width: m.dieSize, height: m.dieSize)
            .background(
                RoundedRectangle(cornerRadius: m.dieCorner, style: .continuous)
                    .fill(die.isHeld ? AppTheme.amber : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: m.dieCorner, style: .continuous)
                    .strokeBorder(AppTheme.ink, lineWidth: m.border)
            )
    }
}

#Preview {
    HStack(spacing: 9) {
        DieView(die: Die(value: 5), isRolling: false)
        DieView(die: Die(value: 3, isHeld: true), isRolling: false)
    }
    .padding()
    .background(AppTheme.cream)
}
