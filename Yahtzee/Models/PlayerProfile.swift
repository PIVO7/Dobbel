import Foundation

struct PlayerProfile: Identifiable, Equatable, Codable, Hashable {
    let id: UUID
    var name: String
    var wins: Int
    var gamesPlayed: Int
    var avatarColorIndex: Int
    var createdAt: Date
    /// Alleen gezet voor computertegenstanders; `nil` betekent een mens.
    var computerLevel: ComputerLevel?

    init(
        id: UUID = UUID(),
        name: String,
        wins: Int = 0,
        gamesPlayed: Int = 0,
        avatarColorIndex: Int = 0,
        createdAt: Date = .now,
        computerLevel: ComputerLevel? = nil
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.wins = wins
        self.gamesPlayed = gamesPlayed
        self.avatarColorIndex = avatarColorIndex
        self.createdAt = createdAt
        self.computerLevel = computerLevel
    }

    /// Vaste id's, zodat een bewaard spel na een herstart dezelfde
    /// tegenstander terugvindt.
    static let computerIDs: [ComputerLevel: UUID] = [
        .easy: UUID(uuidString: "00000000-0000-0000-0000-0000000000C1")!,
        .medium: UUID(uuidString: "00000000-0000-0000-0000-0000000000C0")!,
        .hard: UUID(uuidString: "00000000-0000-0000-0000-0000000000C2")!
    ]

    static func computer(level: ComputerLevel) -> PlayerProfile {
        PlayerProfile(
            id: computerIDs[level]!,
            name: level.personaName,
            avatarColorIndex: level.avatarColorIndex,
            computerLevel: level
        )
    }

    var isComputer: Bool {
        // Op id én op niveau: oude bewaarde spellen kennen alleen het id.
        computerLevel != nil || Self.computerIDs.values.contains(id)
    }
}
