import Foundation
import Observation

@MainActor
@Observable
final class ProfileStore {
    private(set) var profiles: [PlayerProfile] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "yahtzee-profiles.json") {
        self.fileURL = URL.documentsDirectory.appending(path: filename)
        load()
    }

    /// Test seam.
    init(fileURL: URL) {
        self.fileURL = fileURL
        load()
    }

    var humanProfiles: [PlayerProfile] {
        profiles.filter { !$0.isComputer }.sorted { $0.createdAt < $1.createdAt }
    }

    func addProfile(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let color = profiles.count % 6
        let profile = PlayerProfile(name: trimmed, avatarColorIndex: color)
        profiles.append(profile)
        save()
    }

    func renameProfile(id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = profiles.firstIndex(where: { $0.id == id && !$0.isComputer }) else { return }
        profiles[index].name = trimmed
        save()
    }

    func deleteProfile(id: UUID) {
        profiles.removeAll { $0.id == id && !$0.isComputer }
        save()
    }

    /// Werkt na een afgerond spel de statistieken van alle menselijke
    /// deelnemers bij: potjes, winst, hoogste en totale score, Dobbels en de
    /// bonus bovenin.
    func recordGameResult(players: [GamePlayer], winnerProfileIDs: [UUID]) {
        for player in players where !player.isComputer {
            guard let index = profiles.firstIndex(where: { $0.id == player.profileID }) else { continue }
            let card = player.scorecard
            profiles[index].gamesPlayed += 1
            profiles[index].totalPoints += card.total
            profiles[index].bestScore = max(profiles[index].bestScore, card.total)
            profiles[index].dobbelCount +=
                (card.scores[.yahtzee] == YahtzeeScorer.yahtzeePoints ? 1 : 0)
                + card.yahtzeeBonusTotal / YahtzeeScorer.yahtzeeBonusPoints
            if card.upperBonus > 0 {
                profiles[index].bonusCount += 1
            }
            if winnerProfileIDs.contains(player.profileID), winnerProfileIDs.count == 1 {
                profiles[index].wins += 1
            }
        }
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            profiles = []
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            profiles = try decoder.decode([PlayerProfile].self, from: data)
                .filter { !$0.isComputer }
        } catch {
            profiles = []
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(profiles.filter { !$0.isComputer })
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Local-only kids app; ignore disk errors silently.
        }
    }
}
