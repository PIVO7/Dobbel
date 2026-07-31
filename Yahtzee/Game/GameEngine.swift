import Foundation
import Observation

@MainActor
@Observable
final class GameEngine {
    let mode: GameMode
    private(set) var players: [GamePlayer]
    private(set) var currentPlayerIndex: Int = 0
    private(set) var dice: [Die]
    private(set) var rollsRemaining: Int = 3
    private(set) var hasRolledThisTurn: Bool = false
    private(set) var isRolling: Bool = false
    /// De stenen hebben hun waarde al, maar veren nog na. Zolang dit waar is
    /// blijft het scoreblad dicht — anders staan de punten er al terwijl de
    /// stenen nog rollen.
    private(set) var isSettling: Bool = false
    private(set) var isFinished: Bool = false
    private(set) var winnerProfileIDs: [UUID] = []
    private(set) var turnMessage: String = ""
    /// Bumps after meaningful state changes so de UI kan autosaven.
    private(set) var saveVersion: Int = 0
    /// Laatste Yahtzee-bonus die zojuist geplaatst werd (voor viering).
    private(set) var lastYahtzeeBonus: Int = 0
    /// True kort nadat een speler scoorde — UI toont beurt-wissel.
    private(set) var turnJustChanged: Bool = false

    /// De stand van vlak vóór de laatste menselijke zet. Kinderen tikken
    /// vaak per ongeluk; tot de volgende speler gooit mag de zet terug.
    private var undoSnapshot: GameSnapshot?

    private var rng: SplitMix64
    private let computerAI: ComputerAI

    var currentPlayer: GamePlayer { players[currentPlayerIndex] }

    var diceValues: [Int] { dice.map(\.value) }

    var canRoll: Bool {
        !isFinished && !isRolling && !isSettling && rollsRemaining > 0 && !currentPlayer.isComputer
    }

    var canScore: Bool {
        !isFinished && !isRolling && !isSettling && hasRolledThisTurn && !currentPlayer.isComputer
    }

    /// Stenen vastzetten mag zolang er nog een worp over is.
    var canHold: Bool {
        canScore && rollsRemaining > 0
    }

    /// De vorige zet mag terug zolang het spel niet uit is en de volgende
    /// (menselijke) speler nog niets heeft gedaan. Solo betekent dit: ook de
    /// tegenzet van de computer wordt teruggedraaid en hij speelt opnieuw.
    var canUndoScore: Bool {
        undoSnapshot != nil && !isFinished && !isRolling && !isSettling
            && !hasRolledThisTurn && !currentPlayer.isComputer
    }

    func undoLastScore() {
        guard canUndoScore, let undoSnapshot else { return }
        players = undoSnapshot.players
        currentPlayerIndex = undoSnapshot.currentPlayerIndex
        dice = undoSnapshot.dice
        rollsRemaining = undoSnapshot.rollsRemaining
        hasRolledThisTurn = undoSnapshot.hasRolledThisTurn
        turnMessage = undoSnapshot.turnMessage
        lastYahtzeeBonus = 0
        self.undoSnapshot = nil
        markDirty()
    }

    /// De tip voor de speler, of `nil` zolang er niets te kiezen valt.
    var adviceCategory: ScoreCategory? {
        guard canScore else { return nil }
        return YahtzeeScorer.adviceCategory(dice: diceValues, scorecard: currentPlayer.scorecard)
    }

    /// De worp in woorden. Staat naast `turnMessage`, zodat het spelscherm
    /// geen beurtstand hoeft na te rekenen om te weten wat er mag staan.
    var calloutTitle: String {
        RollPhrase.callout(
            dice: diceValues,
            isRolling: isRolling,
            hasRolled: hasRolledThisTurn,
            isComputer: currentPlayer.isComputer
        )
    }

    /// Globale ronde (1…13), stabiel over beurtwissels heen.
    var roundNumber: Int {
        let filled = players.reduce(0) { $0 + $1.scorecard.filledCount }
        let round = filled / max(players.count, 1) + 1
        return min(max(round, 1), ScoreCategory.allCases.count)
    }

    private var canPerformTurnAction: Bool {
        !isFinished && !isRolling && !isSettling
    }

    /// Het vakje bovenin dat de jokerregel afdwingt bij een tweede Yahtzee,
    /// of `nil` als de speler vrij mag kiezen.
    private var jokerForcedCategory: ScoreCategory? {
        guard YahtzeeScorer.canUseJoker(dice: diceValues, scorecard: currentPlayer.scorecard),
              let upper = ScoreCategory.upper.first(where: { $0.faceValue == diceValues.first }),
              currentPlayer.scorecard.scores[upper] == nil else { return nil }
        return upper
    }

    var snapshot: GameSnapshot {
        GameSnapshot(
            mode: mode,
            players: players,
            currentPlayerIndex: currentPlayerIndex,
            dice: dice,
            rollsRemaining: rollsRemaining,
            hasRolledThisTurn: hasRolledThisTurn,
            turnMessage: turnMessage,
            savedAt: .now
        )
    }

    init(
        mode: GameMode,
        profiles: [PlayerProfile],
        seed: UInt64? = nil,
        computerAI: ComputerAI = ComputerAI()
    ) {
        self.mode = mode
        self.players = profiles.map(GamePlayer.init)
        self.dice = (0..<5).map { _ in Die(value: 1) }
        self.computerAI = computerAI
        self.rng = SplitMix64(seed: seed ?? UInt64.random(in: .min ... .max))
        self.turnMessage = String(localized: "\(currentPlayer.name) mag gooien")
    }

    init(snapshot: GameSnapshot, seed: UInt64? = nil, computerAI: ComputerAI = ComputerAI()) {
        self.mode = snapshot.mode
        self.players = snapshot.players
        self.currentPlayerIndex = min(max(snapshot.currentPlayerIndex, 0), max(snapshot.players.count - 1, 0))
        self.dice = snapshot.dice
        self.rollsRemaining = snapshot.rollsRemaining
        self.hasRolledThisTurn = snapshot.hasRolledThisTurn
        self.turnMessage = snapshot.turnMessage
        self.computerAI = computerAI
        self.rng = SplitMix64(seed: seed ?? UInt64.random(in: .min ... .max))
        self.isFinished = snapshot.players.allSatisfy(\.scorecard.isComplete)
        if isFinished {
            finishGame()
        }
    }

    func toggleHold(dieID: UUID) {
        guard canHold else { return }
        guard let index = dice.firstIndex(where: { $0.id == dieID }) else { return }
        // Wie de stenen aanraakt, is aan zijn eigen beurt begonnen.
        undoSnapshot = nil
        dice[index].isHeld.toggle()
        markDirty()
    }

    func rollDice() async {
        guard canRoll else { return }
        undoSnapshot = nil
        await performRoll()
    }

    /// Meldt of de zet echt geplaatst is, zodat de UI geen geluid of
    /// viering afvuurt bij een afgewezen tik.
    @discardableResult
    func score(in category: ScoreCategory) -> Bool {
        guard canScore else { return false }
        let beforeScore = snapshot
        guard placeScore(category) else { return false }
        // Pas na een geslaagde zet vastleggen, en niet voor de computer:
        // die vergist zich niet.
        undoSnapshot = isFinished ? nil : beforeScore
        return true
    }

    func acknowledgeTurnChange() {
        turnJustChanged = false
    }

    func playComputerTurnIfNeeded() async {
        // Expliciet annuleerbaar: als het spel dichtgaat stopt de lus, in
        // plaats van in de achtergrond razendsnel het potje uit te spelen.
        while !Task.isCancelled, !isFinished, currentPlayer.isComputer {
            await takeComputerTurn()
            try? await Task.sleep(for: .milliseconds(400))
        }
    }

    private func takeComputerTurn() async {
        // De eerste worp van de beurt — behalve als een hervat spel al
        // midden in de computerbeurt zat: dan eerst gewoon beslissen, anders
        // gooit hij een klaarliggende Dobbel zomaar opnieuw.
        if !hasRolledThisTurn {
            await performRoll()
        }

        while !Task.isCancelled, !isFinished, currentPlayer.isComputer {
            let decision = computerAI.decide(
                dice: dice,
                rollsRemaining: rollsRemaining,
                scorecard: currentPlayer.scorecard,
                level: currentPlayer.computerLevel ?? .medium
            )

            if decision.shouldScore || rollsRemaining == 0 {
                let category = decision.category
                    ?? YahtzeeScorer.availableCategories(
                        dice: diceValues,
                        scorecard: currentPlayer.scorecard
                    ).first
                if let category {
                    placeScore(category)
                }
                return
            }

            for index in dice.indices {
                dice[index].isHeld = decision.holdMask[index]
            }
            markDirty()
            await performRoll()
        }
    }

    private func performRoll() async {
        guard canPerformTurnAction, rollsRemaining > 0 else { return }
        isRolling = true
        turnMessage = String(localized: "\(currentPlayer.name) gooit…")

        for _ in 0..<8 {
            for index in dice.indices where !dice[index].isHeld {
                dice[index].value = Int.random(in: 1...6, using: &rng)
            }
            try? await Task.sleep(for: .milliseconds(55))
        }

        for index in dice.indices {
            dice[index].roll(using: &rng)
        }

        rollsRemaining -= 1
        hasRolledThisTurn = true
        isRolling = false

        // De stenen zijn uitgeteld maar veren nog na; pas daarna gaat het
        // scoreblad open.
        isSettling = true
        try? await Task.sleep(for: .milliseconds(Self.settleDuration))
        isSettling = false

        if currentPlayer.isComputer {
            turnMessage = String(localized: "\(currentPlayer.name) denkt na…")
        } else if let forced = jokerForcedCategory {
            // De jokerregel sluit alle andere vakjes; zonder uitleg ziet dat
            // eruit alsof het scoreblad kapot is.
            turnMessage = String(localized: "Tweede Dobbel! Die moet bovenin, bij \(forced.title.lowercased())")
        } else {
            // Midden in de beurt geen staande instructie: de worp in woorden
            // is genoeg, en het scherm blijft rustig.
            turnMessage = rollsRemaining == 0
                ? String(localized: "Kies een vakje op het scoreblad")
                : ""
        }
        markDirty()
    }

    @discardableResult
    private func placeScore(_ category: ScoreCategory) -> Bool {
        let open = YahtzeeScorer.availableCategories(dice: diceValues, scorecard: currentPlayer.scorecard)
        guard open.contains(category) else { return false }

        let result = YahtzeeScorer.pointsForPlacing(
            category: category,
            dice: diceValues,
            scorecard: currentPlayer.scorecard
        )
        lastYahtzeeBonus = result.yahtzeeBonus
        players[currentPlayerIndex].scorecard.place(
            category: category,
            score: result.score,
            yahtzeeBonus: result.yahtzeeBonus
        )
        advanceTurn()
        return true
    }

    private func advanceTurn() {
        dice = (0..<5).map { _ in Die(value: 1) }
        rollsRemaining = 3
        hasRolledThisTurn = false

        if players.allSatisfy(\.scorecard.isComplete) {
            finishGame()
            markDirty()
            return
        }

        repeat {
            currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        } while players[currentPlayerIndex].scorecard.isComplete

        turnMessage = String(localized: "\(currentPlayer.name) is aan de beurt")
        turnJustChanged = true
        markDirty()
    }

    private func finishGame() {
        isFinished = true
        let best = players.map(\.scorecard.total).max() ?? 0
        winnerProfileIDs = players.filter { $0.scorecard.total == best }.map(\.profileID)
        if winnerProfileIDs.count == 1,
           let winner = players.first(where: { $0.profileID == winnerProfileIDs[0] }) {
            turnMessage = String(localized: "\(winner.name) wint met \(best) punten!")
        } else {
            turnMessage = String(localized: "Gelijkspel met \(best) punten!")
        }
    }

    /// De deelnemers van dit spel als profielen, voor een rematch met
    /// dezelfde spelers en hetzelfde computerniveau.
    func rematchProfiles() -> [PlayerProfile] {
        players.map { player in
            PlayerProfile(
                id: player.profileID,
                name: player.name,
                avatarColorIndex: player.avatarColorIndex,
                computerLevel: player.computerLevel
            )
        }
    }

    /// Even lang als de landing van de laatste dobbelsteen in `DieView`.
    static let settleDuration = 360

    private func markDirty() {
        saveVersion += 1
    }
}
