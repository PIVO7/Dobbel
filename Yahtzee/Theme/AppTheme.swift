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
