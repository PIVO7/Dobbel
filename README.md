# Dobbel (SwiftUI)

iOS-app voor kinderen: klassiek Dobbel met profielen, lokale multiplayer en solo tegen de computer.

## Features

- **Profielen** — naam + aantal overwinningen en gespeelde spellen (lokaal opgeslagen)
- **Tegen elkaar** — 2–4 spelers, beurten op één apparaat
- **Tegen de computer** — 1 kind + eenvoudige AI
- **Klassiek scoreblad** — bovenkant (1–6 + bonus 35 bij ≥63), onderkant, Chance
- **Dobbel-bonus** — 100 punten voor elke extra Dobbel nadat de Dobbel-rij op 50 staat (met joker-regel)
- **Dobbelanimatie** — korte roll-animatie bij gooien; tik om dobbelstenen vast te houden

## Openen in Xcode

`Dobbel.xcodeproj` staat in de repo, dus op een Mac volstaat:

```bash
open Dobbel.xcodeproj
```

Kies een simulator of iPhone, druk op Run. Vereisten: Xcode 15+, iOS 17+.

Vanaf de terminal bouwen of testen:

```bash
xcodebuild build -project Dobbel.xcodeproj -scheme Dobbel \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Het project opnieuw genereren

`project.yml` blijft de bron van waarheid voor de projectinstellingen. Voeg je bestanden toe of
hernoem je ze, dan kan je het project verversen met [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen   # eenmalig
xcodegen generate       # overschrijft Dobbel.xcodeproj
```

Dat is niet verplicht — nieuwe bestanden gewoon in Xcode toevoegen werkt ook. Houd `project.yml`
dan wel gelijk met wat er in het project staat.

## App-structuur

```
project.yml                 # XcodeGen-definitie (repo-root)
Dobbel/
  DobbelApp.swift
  Models/                   # Dobbelsteen, scorecategorieën, profiel, scoreblad
  Game/                     # GameEngine + DobbelScorer
  AI/                       # ComputerAI
  Persistence/              # ProfileStore (JSON in Documents)
  Components/               # Dice, scoreblad, avatar
  Screens/                  # Home, Profiles, Setup, Game
  Theme/
Dobbel Tests/              # Scoring, AI, profielen, engine
```

## Spelregels (kort)

1. Maximaal **3 worpen** per beurt; dobbelstenen mogen vastgehouden worden.
2. Na de beurt moet één **leeg** vakje gekozen worden (ook met 0 punten).
3. **Bovenbonus**: 35 punten als enen…zessen samen ≥ 63.
4. **Dobbel**: 50 punten. Elke volgende Dobbel (terwijl Dobbel=50) geeft **+100 Dobbel-bonus** en mag als joker in een ander vak.

## Ontwerpkeuzes

| Onderdeel | Keuze |
|-----------|--------|
| UI-taal | Nederlands (voor de kids) |
| Data | Lokaal JSON, geen account/cloud |
| AI | Heuristiek: houdt veelvoorkomende ogen / straten vast, scoort sterke hands vroeg |
| Architectuur | `@Observable` game engine + SwiftUI views |

## Tests

In Xcode: `⌘U`, of:

```bash
xcodebuild test -project Dobbel.xcodeproj -scheme Dobbel -destination 'platform=iOS Simulator,name=iPhone 16'
```
