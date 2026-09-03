import Foundation

/// De spelvorm: klassiek kies je zelf je vakje, "in volgorde" vul je het blad
/// van boven naar onder — eerst de enen, dan de tweeën, tot en met kans. Dat
/// haalt de moeilijkste beslissing weg (jongere kinderen kunnen meedoen) en
/// maakt het voor de ouders juist een spannender gokspel.
enum GameVariant: String, CaseIterable, Identifiable, Codable {
    case classic
    case inOrder

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: String(localized: "Klassiek")
        case .inOrder: String(localized: "In volgorde")
        }
    }

    var subtitle: String {
        switch self {
        case .classic: String(localized: "Kies zelf je vakje")
        case .inOrder: String(localized: "Van de enen tot en met kans")
        }
    }

    var symbol: String {
        switch self {
        case .classic: "hand.tap.fill"
        case .inOrder: "list.number"
        }
    }

    /// Alleen de klassieke spelvorm is gratis; de rest hoort bij de
    /// Gezinsversie.
    var isPremium: Bool { self != .classic }
}
