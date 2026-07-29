import Foundation

struct GamePlayer: Identifiable, Equatable, Codable {
    let id: UUID
    let profileID: UUID
    let name: String
    let isComputer: Bool
    var avatarColorIndex: Int
    var scorecard: Scorecard

    init(profile: PlayerProfile) {
        self.id = UUID()
        self.profileID = profile.id
        self.name = profile.name
        self.isComputer = profile.isComputer
        self.avatarColorIndex = profile.avatarColorIndex
        self.scorecard = Scorecard()
    }
}
