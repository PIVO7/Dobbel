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
    private(set) var isFinished: Bool = false
    private(set) var winnerProfileIDs: [UUID] = []
    private(set) var turnMessage: String = ""
    /// Bumps after meaningful state changes so de UI kan autosaven.
    private(set) var saveVersion: Int = 0
    /// Laatste Yahtzee-bonus die zojuist geplaatst werd (voor viering).
    private(set) var lastYahtzeeBonus: Int = 0
    /// True kort nadat een speler scoorde — UI toont beurt-wissel.
    private(set) var turnJustChanged: Bool = false

    private var rng: SplitMix64
    private let computerAI: ComputerAI

    var currentPlayer: GamePlayer { players[currentPlayerIndex] }

    var diceValues: [Int] { dice.map(\.value) }

    var canRoll: Bool {
        !isFinished && !isRolling && rollsRemaining > 0 && !currentPlayer.isComputer
    }

    var canScore: Bool {
        !isFinished && !isRolling && hasRolledThisTurn && !currentPlayer.isComputer
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
        !isFinished && !isRolling
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
        self.turnMessage = "\(currentPlayer.name) mag gooien"
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
        guard canScore, rollsRemaining > 0 else { return }
        guard let index = dice.firstIndex(where: { $0.id == dieID }) else { return }
        dice[index].isHeld.toggle()
        markDirty()
    }

    func rollDice() async {
        guard canRoll else { return }
        await performRoll()
    }

    func score(in category: ScoreCategory) {
        guard canScore else { return }
        placeScore(category)
    }

    func acknowledgeTurnChange() {
        turnJustChanged = false
    }

    func playComputerTurnIfNeeded() async {
        while !isFinished, currentPlayer.isComputer {
            await takeComputerTurn()
            try? await Task.sleep(for: .milliseconds(400))
        }
    }

    private func takeComputerTurn() async {
        // First roll of the turn.
        await performRoll()

        while !isFinished, currentPlayer.isComputer {
            let decision = computerAI.decide(
                dice: dice,
                rollsRemaining: rollsRemaining,
                scorecard: currentPlayer.scorecard
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
        turnMessage = "\(currentPlayer.name) gooit…"

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
        if currentPlayer.isComputer {
            turnMessage = "\(currentPlayer.name) denkt na…"
        } else {
            turnMessage = rollsRemaining == 0
                ? "Kies een vakje op het scoreblad"
                : "Houd dobbelstenen vast of gooi opnieuw"
        }
        markDirty()
    }

    private func placeScore(_ category: ScoreCategory) {
        let open = YahtzeeScorer.availableCategories(dice: diceValues, scorecard: currentPlayer.scorecard)
        guard open.contains(category) else { return }

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

        turnMessage = "\(currentPlayer.name) is aan de beurt"
        turnJustChanged = true
        markDirty()
    }

    private func finishGame() {
        isFinished = true
        let best = players.map(\.scorecard.total).max() ?? 0
        winnerProfileIDs = players.filter { $0.scorecard.total == best }.map(\.profileID)
        if winnerProfileIDs.count == 1,
           let winner = players.first(where: { $0.profileID == winnerProfileIDs[0] }) {
            turnMessage = "\(winner.name) wint met \(best) punten!"
        } else {
            turnMessage = "Gelijkspel met \(best) punten!"
        }
    }

    private func markDirty() {
        saveVersion += 1
    }
}
