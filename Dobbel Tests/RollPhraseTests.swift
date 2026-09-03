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

    /// Geen "Grote straat!" meer boven de stenen: dat las als advies terwijl
    /// je soms beter iets anders kiest. Het blad laat zelf zien wat elk vakje
    /// oplevert.
    func testSaysNothingAfterAnOrdinaryRoll() {
        let phrase = RollPhrase.callout(
            dice: [1, 2, 3, 4, 5],
            isRolling: false,
            hasRolled: true,
            isComputer: false
        )
        XCTAssertEqual(phrase, "")
    }

    /// In volgorde valt er niets te kiezen; dan mag er wél staan wat de worp
    /// waard is voor het vakje dat aan de beurt is.
    func testNamesTheTargetBoxInOrder() {
        let phrase = RollPhrase.callout(
            dice: [3, 3, 1, 2, 6],
            isRolling: false,
            hasRolled: true,
            isComputer: false,
            target: RollPhrase.Target(category: .threes, points: 6)
        )
        XCTAssertEqual(phrase, "\(ScoreCategory.threes.title): 6 punten")
    }

    /// Ook in volgorde blijft DOBBEL! het feest, boven de doelvakje-regel.
    func testDobbelBeatsTheTargetLine() {
        let phrase = RollPhrase.callout(
            dice: [4, 4, 4, 4, 4],
            isRolling: false,
            hasRolled: true,
            isComputer: false,
            target: RollPhrase.Target(category: .fours, points: 20)
        )
        XCTAssertEqual(phrase, RollPhrase.dobbel)
    }
}
