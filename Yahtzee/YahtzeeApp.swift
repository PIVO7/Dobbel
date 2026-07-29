import SwiftUI

@main
struct YahtzeeApp: App {
    @State private var profileStore = ProfileStore()
    @State private var gameStore = GameStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(profileStore)
                .environment(gameStore)
                .appMetrics()
        }
    }
}
