import Foundation
import Observation

@Observable
final class GameStore {
    private(set) var savedGame: GameSnapshot?

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "yahtzee-saved-game.json") {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.fileURL = folder.appendingPathComponent(filename)
        load()
    }

    /// Test seam.
    init(fileURL: URL) {
        self.fileURL = fileURL
        load()
    }

    var hasSavedGame: Bool { savedGame != nil }

    func save(_ snapshot: GameSnapshot) {
        guard !snapshot.players.isEmpty else { return }
        savedGame = snapshot
        persist()
    }

    func clear() {
        savedGame = nil
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            savedGame = nil
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let snapshot = try decoder.decode(GameSnapshot.self, from: data)
            // Afgeronde of corrupte snapshots niet hervatten.
            guard snapshot.players.contains(where: { !$0.scorecard.isComplete }),
                  snapshot.currentPlayerIndex >= 0,
                  snapshot.currentPlayerIndex < snapshot.players.count else {
                clear()
                return
            }
            savedGame = snapshot
        } catch {
            savedGame = nil
        }
    }

    private func persist() {
        guard let savedGame else { return }
        do {
            let data = try encoder.encode(savedGame)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Lokale kids-app; stil falen zoals ProfileStore.
        }
    }
}
