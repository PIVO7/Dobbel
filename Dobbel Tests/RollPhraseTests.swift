import XCTest
@testable import Dobbel

final class RollPhraseTests: XCTestCase {
    /// Aan het begin van een beurt liggen de stenen op 1-1-1-1-1. Zonder deze
    /// controle begon elke beurt met "YAHTZEE!" in beeld.
    func testDoesNotCallDobbelBeforeFirstRoll() {
        let phrase = RollPhrase.callout(
            dice: [1, 1, 1, 1, 1],
            isRolling: false,
            hasRolled: false,
            isComputer: false
        )
        XCTAssertEqual(phrase, "Gooi maar!")
    }

    func testWaitsWhileComputerHasNotRolled() {
        let phrase = RollPhrase.callout(
            dice: [1, 1, 1, 1, 1],
            isRolling: false,
            hasRolled: false,
            isComputer: true
        )
        XCTAssertEqual(phrase, "Even wachten…")
    }

    func testCallsDobbelAfterRolling() {
        let phrase = RollPhrase.callout(
            dice: [1, 1, 1, 1, 1],
            isRolling: false,
            hasRolled: true,
            isComputer: false
        )
        XCTAssertEqual(phrase, RollPhrase.dobbel)
    }

    func testStaysQuietWhileRolling() {
        let phrase = RollPhrase.callout(
            dice: [6, 6, 6, 6, 6],
            isRolling: true,
            hasRolled: true,
            isComputer: false
        )
        XCTAssertEqual(phrase, "…")
    }

    func testNamesTheHighestPairOnATie() {
        // Twee enen en twee zessen: het hoogste oog wint.
        XCTAssertEqual(RollPhrase.describe([1, 1, 6, 6, 3]), "Twee zessen!")
    }
}
