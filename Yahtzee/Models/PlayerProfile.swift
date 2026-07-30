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

    // Statistieken, bijgehouden per afgerond spel.
    var bestScore: Int
    var totalPoints: Int
    var dobbelCount: Int
    var bonusCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        wins: Int = 0,
        gamesPlayed: Int = 0,
        avatarColorIndex: Int = 0,
        createdAt: Date = .now,
        computerLevel: ComputerLevel? = nil,
        bestScore: Int = 0,
        totalPoints: Int = 0,
        dobbelCount: Int = 0,
        bonusCount: Int = 0
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.wins = wins
        self.gamesPlayed = gamesPlayed
        self.avatarColorIndex = avatarColorIndex
        self.createdAt = createdAt
        self.computerLevel = computerLevel
        self.bestScore = bestScore
        self.totalPoints = totalPoints
        self.dobbelCount = dobbelCount
        self.bonusCount = bonusCount
    }

    /// Met de hand, zodat oudere profielbestanden zonder de statistiekvelden
    /// gewoon blijven laden.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        wins = try container.decode(Int.self, forKey: .wins)
        gamesPlayed = try container.decode(Int.self, forKey: .gamesPlayed)
        avatarColorIndex = try container.decode(Int.self, forKey: .avatarColorIndex)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        computerLevel = try container.decodeIfPresent(ComputerLevel.self, forKey: .computerLevel)
        bestScore = try container.decodeIfPresent(Int.self, forKey: .bestScore) ?? 0
        totalPoints = try container.decodeIfPresent(Int.self, forKey: .totalPoints) ?? 0
        dobbelCount = try container.decodeIfPresent(Int.self, forKey: .dobbelCount) ?? 0
        bonusCount = try container.decodeIfPresent(Int.self, forKey: .bonusCount) ?? 0
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
