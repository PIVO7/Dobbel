import XCTest
@testable import Yahtzee

@MainActor
final class SoundPlayerTests: XCTestCase {
    /// Elke geluidsnaam moet een echt bestand in de bundel zijn; een typefout
    /// in een bestandsnaam zou anders stilletjes niets afspelen.
    func testAllSoundsExistInBundle() {
        let bundle = Bundle(for: GameEngine.self)
        for sound in SoundPlayer.Sound.allCases {
            XCTAssertNotNil(
                bundle.url(forResource: sound.rawValue, withExtension: "wav"),
                "Geluidsbestand ontbreekt: \(sound.rawValue).wav"
            )
        }
    }
}
