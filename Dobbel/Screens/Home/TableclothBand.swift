import SwiftUI

/// De schulprand van het startscherm: een rij halve bogen, zoals de zoom van
/// een feestelijk tafelkleed. Elke schulp is een kubische benadering van een
/// halve cirkel (controlepunten op 4/3 van de hoogte boven de eindpunten),
/// zodat heen- en terugweg exact dezelfde toppen delen en de inktlijn-overlay
/// er precies op valt.
struct ScallopLine: Shape {
    /// Met `hanging` bollen de schulpen omlaag vanaf de bovenrand van het
    /// frame in plaats van omhoog vanaf de onderrand.
    var hanging = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseY = hanging ? rect.minY : rect.maxY
        path.move(to: CGPoint(x: rect.minX, y: baseY))
        Self.addScallops(to: &path, across: rect, baseY: baseY, height: rect.height, hanging: hanging)
        return path
    }

    /// Tekent de schulpen verder vanaf het huidige punt; met `reversed` van
    /// rechts naar links, voor de onderrand van een gesloten vlak. De
    /// schulpbreedte volgt uit de beschikbare ruimte, zodat er altijd hele
    /// schulpen staan — een halve schulp aan de rand oogt als een fout.
    static func addScallops(to path: inout Path, across rect: CGRect, baseY: CGFloat, height: CGFloat, hanging: Bool = false, reversed: Bool = false) {
        let count = max(Int((rect.width / 30).rounded()), 6)
        let step = rect.width / CGFloat(count) * (reversed ? -1 : 1)
        let startX = reversed ? rect.maxX : rect.minX
        let crest = baseY + (hanging ? height : -height) * 4 / 3
        for scallop in 0..<count {
            let from = startX + CGFloat(scallop) * step
            path.addCurve(
                to: CGPoint(x: from + step, y: baseY),
                control1: CGPoint(x: from, y: crest),
                control2: CGPoint(x: from + step, y: crest)
            )
        }
    }
}

/// Een gevuld vlak met een schulprand boven en (optioneel) onder. De inktlijn
/// komt er als overlay bovenop, want een vlak en zijn rand vullen anders
/// elkaars halve lijndikte weg.
struct ScallopBandShape: Shape {
    var height: CGFloat
    var scallopedBottom = true

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + height))
        ScallopLine.addScallops(to: &path, across: rect, baseY: rect.minY + height, height: height)
        if scallopedBottom {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - height))
            ScallopLine.addScallops(to: &path, across: rect, baseY: rect.maxY - height, height: height, hanging: true, reversed: true)
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

/// De amberkleurige tafelkleedband waarin de titel ligt: schulpen boven en
/// onder, met een inktlijn op beide randen.
struct ClothBandView<Content: View>: View {
    var height: CGFloat = 11
    var lineWidth: CGFloat = 3
    @ViewBuilder var content: () -> Content

    var body: some View {
        // Vulling en inktlijn komen uit exact dezelfde shape in dezelfde
        // rect: zo kunnen schulptelling en fase nooit uit elkaar lopen. De
        // negatieve horizontale marge duwt de zijranden van de omtreklijn
        // net buiten beeld.
        let shape = ScallopBandShape(height: height)
        content()
            .frame(maxWidth: .infinity)
            .padding(.vertical, height * 2 + 12)
            .background {
                ZStack {
                    shape.fill(AppTheme.tintAmber)
                    shape.stroke(AppTheme.ink, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
                }
                .padding(.horizontal, -lineWidth)
            }
    }
}

/// Het tafelkleed onder aan het scherm: schulprand bovenaan, gevuld tot de
/// schermrand, met vage ogen-stippen en twee rustende dobbelstenen. Puur
/// decor — ligt achter de inhoud en vangt geen aanrakingen.
struct TableclothView: View {
    var scallopHeight: CGFloat = 9
    var lineWidth: CGFloat = 3
    var height: CGFloat = 84

    var body: some View {
        // Zelfde één-shape-opbouw als de titelband; onder- en zijranden van
        // de omtreklijn worden net buiten beeld geduwd.
        let shape = ScallopBandShape(height: scallopHeight, scallopedBottom: false)
        ZStack {
            shape.fill(AppTheme.tintAmber)
            shape.stroke(AppTheme.ink, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
        }
        .padding(.horizontal, -lineWidth)
        .padding(.bottom, -lineWidth)
            .overlay {
                // Zonder de pips lezen schulpjes als wolkjes: de vage ogen
                // maken er onmiskenbaar een dobbeltafel van.
                HStack(spacing: height * 0.7) {
                    DiePips(value: 3, inset: 4)
                    DiePips(value: 5, inset: 4)
                    DiePips(value: 2, inset: 4)
                }
                .foregroundStyle(AppTheme.ink.opacity(0.3))
                .frame(height: height * 0.3)
                .padding(.top, scallopHeight)
            }
            .overlay(alignment: .topLeading) {
                restingDie(face: 4, fill: AppTheme.card, size: height * 0.42, tilt: -7)
                    .padding(.leading, height * 0.6)
                    .offset(y: -height * 0.16)
            }
            .overlay(alignment: .topTrailing) {
                restingDie(face: 1, fill: AppTheme.amber, size: height * 0.36, tilt: 9)
                    .padding(.trailing, height * 0.75)
                    .offset(y: -height * 0.1)
            }
            .frame(height: height)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }

    private func restingDie(face: Int, fill: Color, size: CGFloat, tilt: Double) -> some View {
        DiePips(value: face, inset: size * 0.18)
            .foregroundStyle(AppTheme.ink)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                    .fill(fill)
            )
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                    .strokeBorder(AppTheme.ink, lineWidth: lineWidth * 0.8)
            }
            .background(
                RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                    .fill(AppTheme.ink)
                    .offset(y: 2.5)
            )
            .rotationEffect(.degrees(tilt))
    }
}

#Preview {
    VStack(spacing: 40) {
        ClothBandView {
            Text(verbatim: "Dobbel!")
                .font(AppTheme.rounded(42))
                .foregroundStyle(AppTheme.ink)
        }
        Spacer()
        TableclothView()
    }
    .background(AppTheme.cream)
    .ignoresSafeArea(edges: .bottom)
    .appMetrics()
}
