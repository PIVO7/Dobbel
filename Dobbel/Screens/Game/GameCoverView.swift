import SwiftUI

/// De volledige-schermcover met een lopend spel. Eén plek voor het
/// rematch-ritueel (verse engine met dezelfde deelnemers, meteen bewaren),
/// zodat start- en beginscherm niet elk hun eigen kopie dragen.
struct GameCoverView: View {
    let game: ActiveGame
    let profileStore: ProfileStore
    let gameStore: GameStore
    @Binding var activeGame: ActiveGame?

    var body: some View {
        GameView(
            engine: game.engine,
            onRematch: {
                let engine = GameEngine(
                    mode: game.engine.mode,
                    profiles: game.engine.rematchProfiles()
                )
                gameStore.save(engine.snapshot)
                activeGame = ActiveGame(engine: engine)
            },
            onClose: { activeGame = nil }
        )
        .environment(profileStore)
        .environment(gameStore)
        .appMetrics()
    }
}
