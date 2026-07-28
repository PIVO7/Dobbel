import SwiftUI

/// Speelgoed-stijl: dikke inktranden, harde slagschaduwen zonder vervaging,
/// verzadigde kleuren. Alles moet eruitzien alsof je het kan indrukken.
enum AppTheme {
    // Grond en inkt
    static let cream = Color(red: 1.00, green: 0.98, blue: 0.95)   // #FFFBF2
    static let ink = Color(red: 0.13, green: 0.13, blue: 0.11)     // #22201C
    static let sunk = Color(red: 0.97, green: 0.95, blue: 0.89)    // #F7F1E4

    // Accenten
    static let amber = Color(red: 1.00, green: 0.79, blue: 0.24)   // #FFC93D
    static let coral = Color(red: 1.00, green: 0.42, blue: 0.29)   // #FF6B4A
    static let mint = Color(red: 0.24, green: 0.84, blue: 0.55)    // #3DD68C
    static let sky = Color(red: 0.29, green: 0.62, blue: 1.00)     // #4A9EFF

    // Zachte vlakken achter iconen
    static let tintAmber = Color(red: 1.00, green: 0.95, blue: 0.81) // #FFF1CE
    static let tintSky = Color(red: 0.89, green: 0.96, blue: 1.00)   // #E4F4FF
    static let tintCoral = Color(red: 1.00, green: 0.87, blue: 0.83) // #FFDDD4
    static let tintStone = Color(red: 0.93, green: 0.89, blue: 0.82) // #EDE4D2

    // Tekst
    static let faint = Color(red: 0.71, green: 0.64, blue: 0.55)   // #B5A48C
    static let soft = Color(red: 0.65, green: 0.58, blue: 0.49)    // #A6957D
    static let dim = Color(red: 0.78, green: 0.73, blue: 0.64)     // #C7BAA3

    // Uitgeschakeld
    static let offFill = Color(red: 0.86, green: 0.83, blue: 0.76) // #DCD3C2
    static let offInk = Color(red: 0.70, green: 0.66, blue: 0.59)  // #B3A896

    /// Alle tekst in de app komt hier langs; de maat komt uit `AppMetrics`,
    /// zodat een iPad grotere letters krijgt zonder aparte fontconstanten.
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Alle maten op één plek, zodat een iPad niet dezelfde punten krijgt als een
/// iPhone. Wordt uit de horizontale grootteklasse afgeleid: `.regular` is een
/// iPad op vol scherm, `.compact` een iPhone of een smal deelvenster.
struct AppMetrics {
    var dieSize: CGFloat
    var dieCorner: CGFloat
    var dieGap: CGFloat

    var rowHeight: CGFloat
    var iconWidth: CGFloat
    var cellCorner: CGFloat

    var cardCorner: CGFloat
    var depth: CGFloat
    var border: CGFloat
    var thinBorder: CGFloat

    var gutter: CGFloat
    var contentMaxWidth: CGFloat
    var avatarSize: CGFloat

    var brandSize: CGFloat
    var titleSize: CGFloat
    var displaySize: CGFloat
    var bodySize: CGFloat
    var captionSize: CGFloat
    var cellTextSize: CGFloat
    var buttonTextSize: CGFloat
    var buttonHeight: CGFloat

    static let phone = AppMetrics(
        dieSize: 60, dieCorner: 16, dieGap: 9,
        rowHeight: 38, iconWidth: 38, cellCorner: 11,
        cardCorner: 20, depth: 5, border: 3, thinBorder: 2,
        gutter: 14, contentMaxWidth: .infinity, avatarSize: 44,
        brandSize: 52, titleSize: 40, displaySize: 30,
        bodySize: 17, captionSize: 12, cellTextSize: 17,
        buttonTextSize: 21, buttonHeight: 60
    )

    static let pad = AppMetrics(
        dieSize: 88, dieCorner: 23, dieGap: 15,
        rowHeight: 54, iconWidth: 54, cellCorner: 15,
        cardCorner: 26, depth: 7, border: 4, thinBorder: 2.5,
        gutter: 24, contentMaxWidth: 760, avatarSize: 58,
        brandSize: 78, titleSize: 56, displaySize: 44,
        bodySize: 21, captionSize: 15, cellTextSize: 24,
        buttonTextSize: 28, buttonHeight: 78
    )

    static func resolve(_ sizeClass: UserInterfaceSizeClass?) -> AppMetrics {
        sizeClass == .regular ? .pad : .phone
    }
}

/// Het kenmerk van deze stijl: een gevuld blok met een inktrand, en daarachter
/// hetzelfde blok een paar punten lager. Geen vervaging — dat leest als dikte
/// in plaats van als schaduw.
struct ToyBlock: ViewModifier {
    var fill: Color
    var radius: CGFloat = 16
    var depth: CGFloat = 5
    var border: CGFloat = 3
    var borderColor: Color = AppTheme.ink
    var shadowColor: Color = AppTheme.ink

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: border)
            )
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(shadowColor)
                    .offset(y: depth)
            )
    }
}

extension View {
    func toyBlock(
        fill: Color,
        radius: CGFloat = 16,
        depth: CGFloat = 5,
        border: CGFloat = 3,
        borderColor: Color = AppTheme.ink,
        shadowColor: Color = AppTheme.ink
    ) -> some View {
        modifier(ToyBlock(
            fill: fill,
            radius: radius,
            depth: depth,
            border: border,
            borderColor: borderColor,
            shadowColor: shadowColor
        ))
    }
}

/// Knop die bij het indrukken echt inzakt: de schaduw krimpt terwijl de knop
/// evenveel naar beneden schuift, zodat de totale hoogte gelijk blijft.
struct ToyButtonStyle: ButtonStyle {
    var fill: Color
    var radius: CGFloat = 18
    var depth: CGFloat = 6
    var border: CGFloat = 3

    func makeBody(configuration: Configuration) -> some View {
        // Bij depth 0 valt er niets in te zakken; dan blijft de knop stilstaan.
        let sunk = configuration.isPressed && depth > 0
        let drop = max(depth - 2, 0)
        return configuration.label
            .toyBlock(fill: fill, radius: radius, depth: sunk ? 2 : depth, border: border)
            .offset(y: sunk ? drop : 0)
            .animation(.easeOut(duration: 0.08), value: sunk)
    }
}
