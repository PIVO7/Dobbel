import Foundation
import Observation

@MainActor
@Observable
final class GameStore {
    private(set) var savedGame: GameSnapshot?

    private let fileURL: URL
    private let decoder = JSONDecoder()
    /// De laatste schrijfactie; elke volgende wacht hierop, zodat een oudere
    /// worp nooit ná een nieuwere op schijf kan landen.
    private var pendingWrite: Task<Void, Never>?

    init(filename: String = "yahtzee-saved-game.json") {
        self.fileURL = URL.documentsDirectory.appending(path: filename)
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
        // Elke zet komt hierlangs, tot het vasthouden van één steen aan toe.
        // Schrijven gebeurt daarom naast de main actor, in volgorde.
        let url = fileURL
        let previous = pendingWrite
        pendingWrite = Task.detached(priority: .utility) {
            await previous?.value
            // Lokale kids-app; stil falen zoals ProfileStore.
            try? JSONEncoder().encode(snapshot).write(to: url, options: [.atomic])
        }
    }

    func clear() {
        savedGame = nil
        let url = fileURL
        let previous = pendingWrite
        pendingWrite = Task.detached(priority: .utility) {
            await previous?.value
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Wacht tot alle schrijfacties op schijf staan. Voor tests, die meteen
    /// na een `save` of `clear` het bestand willen inspecteren.
    func flush() async {
        await pendingWrite?.value
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
}
