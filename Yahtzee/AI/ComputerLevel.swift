import Foundation

/// De drie computertegenstanders. Geen kale moeilijkheidsgraden maar
/// persona's met een naam en een gezicht: een tegenstander kiezen voelt
/// anders dan een instelling omzetten.
enum ComputerLevel: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var personaName: String {
        switch self {
        case .easy: return "Dommel"
        case .medium: return "Robbie"
        case .hard: return "Professor Punt"
        }
    }

    var subtitle: String {
        switch self {
        case .easy: return "gooit maar wat"
        case .medium: return "speelt lekker mee"
        case .hard: return "rekent alles uit"
        }
    }

    var avatarColorIndex: Int {
        switch self {
        case .easy: return 2
        case .medium: return 5
        case .hard: return 4
        }
    }

    /// Elk persona een eigen gezichtje op het bolletje.
    var avatarSymbol: String {
        switch self {
        case .easy: return "tortoise.fill"
        case .medium: return "gamecontroller.fill"
        case .hard: return "graduationcap.fill"
        }
    }
}
