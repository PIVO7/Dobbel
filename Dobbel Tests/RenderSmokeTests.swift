import XCTest
import SwiftUI
@testable import Dobbel

/// Geen assert-tests maar een rooktest die het spelscherm naar PNG rendert,
/// zodat een indeling zonder simulator-interactie visueel te beoordelen
/// valt. De echte componenten, gestapeld in de volgorde van
/// `GameTallLayout` (ImageRenderer kan diens ScrollView niet aan). De
/// bestanden landen in de map uit RENDER_OUTPUT_DIR; zonder die variabele
/// slaat de test over.
@MainActor
final class RenderSmokeTests: XCTestCase {
    private var outputDirectory: URL? {
        ProcessInfo.processInfo.environment["RENDER_OUTPUT_DIR"].map {
            URL(fileURLWithPath: $0, isDirectory: true)
        }
    }

    func testRenderThemeBackgrounds() throws {
        guard let outputDirectory else {
            throw XCTSkip("RENDER_OUTPUT_DIR niet gezet; rooktest alleen op verzoek.")
        }
        let previous = ThemeStore.shared.themeID
        defer { ThemeStore.shared.select(previous) }

        for theme in [ThemeID.snoep, .oceaan, .nacht] {
            ThemeStore.shared.select(theme)
            let renderer = ImageRenderer(
                content: ThemedBackground().frame(width: 393, height: 852)
            )
            renderer.scale = 2
            let image = try XCTUnwrap(renderer.uiImage)
            try XCTUnwrap(image.pngData())
                .write(to: outputDirectory.appending(path: "thema-\(theme.rawValue).png"))
        }
    }

    func testRenderTallLayout() async throws {
        guard let outputDirectory else {
            throw XCTSkip("RENDER_OUTPUT_DIR niet gezet; rooktest alleen op verzoek.")
        }

        let engine = GameEngine(
            mode: .versusFriends,
            profiles: [
                PlayerProfile(name: "Lene", avatarColorIndex: 4, avatarSymbol: "heart.fill"),
                PlayerProfile(name: "Papa", avatarColorIndex: 1, avatarSymbol: "star.fill")
            ],
            seed: 7
        )
        // Een paar beurten spelen zodat het blad scores draagt en de worp
        // een tip oplevert — een leeg blad zegt niets over de indeling.
        for _ in 0..<4 {
            await engine.rollDice()
            guard let eerste = DobbelScorer.availableCategories(
                dice: engine.diceValues,
                scorecard: engine.currentPlayer.scorecard
            ).first else { break }
            _ = engine.score(in: eerste)
        }
        await engine.rollDice()

        // Twee maten: iPhone en iPad portret (de staande indeling geldt op
        // beide; de sizeclass-hint stuurt het scoreblad, want de render
        // draait buiten een echt venster).
        let variants: [(suffix: String, width: CGFloat, height: CGFloat, metrics: AppMetrics, sizeClass: UserInterfaceSizeClass)] = [
            ("", 393, 852, .phone, .compact),
            ("-ipad", 834, 1194, AppMetrics.pad.roomier(), .regular)
        ]
        for variant in variants {
            let view = GameScreenRenderStack(engine: engine)
                .environment(\.metrics, variant.metrics)
                .environment(\.horizontalSizeClass, variant.sizeClass)
                .frame(width: variant.width, height: variant.height)

            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            let image = try XCTUnwrap(renderer.uiImage)
            try XCTUnwrap(image.pngData())
                .write(to: outputDirectory.appending(path: "spelscherm\(variant.suffix).png"))
        }
    }
}

/// De onderdelen van het spelscherm in dezelfde volgorde als
/// `GameTallLayout`, maar zonder ScrollView/GeometryReader.
private struct GameScreenRenderStack: View {
    let engine: GameEngine

    @Environment(\.metrics) private var m

    var body: some View {
        let actions = GameActions(
            toggleHold: { _ in }, score: { _ in }, roll: {}, leave: {}, undo: {}
        )
        VStack(spacing: 0) {
            GameTopBar(engine: engine, actions: actions)
                .padding(.top, 6)

            GameTallLayout.contentStack(
                engine: engine,
                actions: actions,
                isCelebrating: false,
                metrics: m
            )

            Spacer(minLength: m.gutter)

            RollButtonView(
                isRolling: engine.isRolling,
                rollsRemaining: engine.rollsRemaining,
                canRoll: engine.canRoll,
                onRoll: actions.roll
            )
            .padding(.top, m.gutter * 0.4)
        }
        .padding(.horizontal, m.gutter)
        .background(AppTheme.cream)
    }
}
