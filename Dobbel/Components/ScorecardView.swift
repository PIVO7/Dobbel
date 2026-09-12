import SwiftUI

/// Het hele scoreblad in twee kolommen, zodat alle dertien vakjes tegelijk in
/// beeld staan. Links sluiten Totaal- en Bonusrij het bovenblad af; rechts
/// staat de Dobbel-bonus (+100) onder het Dobbel-vakje, waardoor beide
/// kolommen even hoog blijven.
struct ScorecardView: View {
    let players: [GamePlayer]
    let currentPlayerID: UUID
    let diceValues: [Int]
    let canScore: Bool
    var variant: GameVariant = .classic
    /// De zojuist vastgelegde zet; die cel licht even op.
    var lastPlaced: PlacedMark?
    let onSelect: (ScoreCategory) -> Void

    @Environment(\.metrics) private var m
    @Environment(\.horizontalSizeClass) private var sizeClass
    /// Het categorie-icoon waar net op getikt is; het bordje met uitleg
    /// verdwijnt vanzelf weer.
    @State private var explained: ScoreCategory?
    @State private var explainDismissal: Task<Void, Never>?

    /// Bij drie of vier spelers op een smal scherm worden de vakjes te smal
    /// om te raken (ver onder de 44 punten). Dan toont het blad alleen de
    /// kolom van wie aan de beurt is; de scores van de anderen staan al
    /// bovenin het spelscherm.
    private var visiblePlayers: [GamePlayer] {
        guard sizeClass == .compact, players.count > 2 else { return players }
        return players.filter { $0.id == currentPlayerID }
    }

    /// Op een smal scherm krijgt wie aan de beurt is de brede kolom en
    /// versmalt de rest tot een spiekstrook: de keuzevakjes zijn dan groot,
    /// terwijl de stand van de ander zichtbaar blijft.
    private var passiveWidth: CGFloat? {
        guard sizeClass == .compact, visiblePlayers.count > 1 else { return nil }
        return max(m.iconWidth, 46)
    }

    /// De brede actieve kolom of de smalle spiekstrook.
    @ViewBuilder
    private func columnFrame(_ content: some View, isMine: Bool) -> some View {
        if let passiveWidth, !isMine {
            content.frame(width: passiveWidth)
        } else {
            content.frame(maxWidth: .infinity)
        }
    }

    var body: some View {
        // Eén keer per hertekening rekenen, zodat de scorer niet per vakje
        // draait.
        let open = Set(openCategories)

        return HStack(alignment: .top, spacing: m.gutter * 0.6) {
            column(categories: ScoreCategory.upper, showsBonus: true, open: open)
            column(categories: ScoreCategory.lower, showsBonus: false, open: open)
        }
        .padding(.horizontal, m.gutter * 0.8)
        .padding(.vertical, m.gutter * 0.55)
        .toyBlock(fill: AppTheme.card, radius: m.cardCorner, depth: m.depth, border: m.border)
        // Het uitlegbordje ligt midden op het blad, met een gedimde laag
        // eronder: bovenaan viel het wit-op-wit nauwelijks op. Een tik
        // waar dan ook stuurt het weg, en na een paar tellen gaat het
        // vanzelf.
        .overlay {
            if let explained {
                ZStack {
                    RoundedRectangle(cornerRadius: m.cardCorner, style: .continuous)
                        .fill(AppTheme.ink.opacity(0.35))
                        .onTapGesture { dismissExplainer() }
                        .accessibilityHidden(true)

                    CategoryExplainerChip(category: explained)
                        .padding(.horizontal, m.gutter * 1.5)
                        .onTapGesture { dismissExplainer() }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(1)
            }
        }
    }

    private func explain(_ category: ScoreCategory) {
        explainDismissal?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            explained = category
        }
        // Zes tellen: genoeg om rustig te lezen, kort genoeg om niet in de
        // weg te zitten — en een tik stuurt het altijd meteen weg.
        explainDismissal = Task {
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            dismissExplainer()
        }
    }

    private func dismissExplainer() {
        explainDismissal?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            explained = nil
        }
    }

    private var current: GamePlayer? {
        players.first { $0.id == currentPlayerID }
    }

    private var openCategories: [ScoreCategory] {
        guard let current else { return [] }
        return DobbelScorer.availableCategories(dice: diceValues, scorecard: current.scorecard, variant: variant)
    }

    // Zonder BOVEN/ONDER-kopjes: die zeiden een kind niets en de bonusrij
    // markeert het verschil al. De gewonnen ruimte gaat naar het raster.
    private func column(
        categories: [ScoreCategory],
        showsBonus: Bool,
        open: Set<ScoreCategory>
    ) -> some View {
        VStack(spacing: m.cellGap) {
            PlayerHeaderView(
                players: visiblePlayers,
                currentPlayerID: currentPlayerID,
                showsName: showsBonus,
                passiveWidth: passiveWidth
            )

            ForEach(categories) { category in
                row(for: category, open: open)
            }

            // Beide kolommen sluiten onderaan af met hun bonus: links het
            // totaal op weg naar +35, rechts de Dobbel-bonus van +100.
            if showsBonus {
                totalRow
                bonusRow
            } else {
                dobbelBonusRow
            }
        }
    }

    private func row(
        for category: ScoreCategory,
        open: Set<ScoreCategory>
    ) -> some View {
        HStack(spacing: m.cellGap) {
            // Tikbaar: de naam en één regel uitleg verschijnen op verzoek.
            Button {
                explain(category)
            } label: {
                CategoryIcon(category: category)
                    .frame(width: m.iconWidth, height: m.rowHeight)
            }
            .buttonStyle(.plain)
            .accessibilityHint(String(localized: "Toont de uitleg"))

            ForEach(visiblePlayers) { player in
                let isMine = player.id == currentPlayerID
                columnFrame(
                    ScoreCellView(
                        category: category,
                        player: player,
                        diceValues: diceValues,
                        isMine: isMine,
                        selectable: isMine && canScore && open.contains(category),
                        freshVersion: lastPlaced.flatMap {
                            $0.playerID == player.id && $0.category == category ? $0.version : nil
                        },
                        onSelect: onSelect
                    ),
                    isMine: isMine
                )
            }
        }
    }

    /// De rij met het bovenbladtotaal op weg naar 63: stand plus een klein
    /// voortgangsbalkje, zodat de bonus iets is om naartoe te spelen.
    private var totalRow: some View {
        HStack(spacing: m.cellGap) {
            labelCell(title: "TOTAAL", subtitle: nil)

            ForEach(visiblePlayers) { player in
                let subtotal = player.scorecard.upperSubtotal
                let isMine = player.id == currentPlayerID
                columnFrame(
                    VStack(spacing: m.rowHeight * 0.1) {
                        Text("\(subtotal)/63")
                            .font(AppTheme.rounded(m.captionSize))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        bonusBar(subtotal: subtotal)
                    }
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.rowHeight)
                    // Geen beurtkleur hier: de roze cel was de enige
                    // afwijkende in de kolom en brak het rustige raster.
                    // Wie aan de beurt is, zie je al aan de ring bovenaan.
                    .toyBlock(
                        fill: AppTheme.sunk,
                        radius: m.cellCorner,
                        depth: 0,
                        border: m.thinBorder
                    )
                    .accessibilityLabel(String(localized: "Bonus bij 63, nu \(subtotal)")),
                    isMine: isMine
                )
            }
        }
    }

    /// De bonusrij spreekt in stempels: een mintgroene cirkel met vinkje
    /// zodra de 63 binnen is, een rood kruis als de bonus zelfs met
    /// maximale worpen niet meer kan.
    private var bonusRow: some View {
        HStack(spacing: m.cellGap) {
            labelCell(title: "BONUS", subtitle: "+35")

            ForEach(visiblePlayers) { player in
                let reached = player.scorecard.upperBonus > 0
                let stillPossible = DobbelScorer.upperBonusStillPossible(scorecard: player.scorecard)
                columnFrame(
                    bonusCircle(earned: reached, missed: !reached && !stillPossible)
                        .accessibilityLabel(
                            reached
                                ? String(localized: "Bonus van 35 behaald")
                                : stillPossible
                                    ? String(localized: "Bonus nog te verdienen")
                                    : String(localized: "Bonus niet meer haalbaar")
                        ),
                    isMine: player.id == currentPlayerID
                )
            }
        }
    }

    /// De rij voor de 100-puntenbonus van een tweede Dobbel, in dezelfde
    /// stempeltaal. Het kruis komt pas als het Dobbel-vakje met een nul is
    /// doorgestreept — dan kan de bonus voorgoed niet meer.
    private var dobbelBonusRow: some View {
        HStack(spacing: m.cellGap) {
            labelCell(title: "BONUS", subtitle: "+100")

            ForEach(visiblePlayers) { player in
                let count = player.scorecard.dobbelBonusTotal / DobbelScorer.dobbelBonusPoints
                let missed = player.scorecard.scores[.dobbel] == 0
                columnFrame(
                    bonusCircle(earned: count > 0, missed: missed, count: count)
                        .accessibilityLabel(
                            count > 0
                                ? String(localized: "Dobbel-bonus: \(player.scorecard.dobbelBonusTotal) punten")
                                : missed
                                    ? String(localized: "Bonus niet meer haalbaar")
                                    : String(localized: "Nog geen Dobbel-bonus")
                        ),
                    isMine: player.id == currentPlayerID
                )
            }
        }
    }

    /// Het bonusoordeel als cirkel — bewust een andere vorm dan de
    /// speelvakjes: dit is geen vakje om te kiezen maar een stempel. Twee of
    /// meer Dobbel-bonussen tonen hun aantal in plaats van het vinkje.
    private func bonusCircle(earned: Bool, missed: Bool, count: Int = 1) -> some View {
        ZStack {
            Circle()
                .fill(earned ? AppTheme.mint : (missed ? AppTheme.tintCoral : AppTheme.sunk))
            Circle()
                .strokeBorder(AppTheme.ink, lineWidth: m.thinBorder)

            if earned {
                if count > 1 {
                    Text(verbatim: "\(count)×")
                        .font(AppTheme.rounded(m.captionSize))
                        .foregroundStyle(AppTheme.ink)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: m.captionSize * 1.15, weight: .black))
                        .foregroundStyle(AppTheme.ink)
                }
            } else if missed {
                Image(systemName: "xmark")
                    .font(.system(size: m.captionSize * 1.15, weight: .black))
                    .foregroundStyle(AppTheme.coral)
            } else {
                Text(verbatim: "–")
                    .font(AppTheme.rounded(m.captionSize, .bold))
                    .foregroundStyle(AppTheme.cardDim)
            }
        }
        .frame(width: m.rowHeight * 0.8, height: m.rowHeight * 0.8)
        .frame(maxWidth: .infinity)
        .frame(height: m.rowHeight)
    }

    /// Het naamvakje links van een bonusrij, in de stijl van de
    /// categorie-iconen.
    private func labelCell(title: LocalizedStringKey, subtitle: LocalizedStringKey?) -> some View {
        // Zonder kerning en met wat binnenmarge: "TOTAAL" en "BONUS" raakten
        // anders letterlijk de randen van het vakje.
        VStack(spacing: 0) {
            Text(title)
                .font(AppTheme.rounded(m.captionSize * 0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(AppTheme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(AppTheme.rounded(m.captionSize * 0.95))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(AppTheme.ink)
            }
        }
        .padding(.horizontal, 3)
        .frame(width: m.iconWidth, height: m.rowHeight)
        .toyBlock(fill: AppTheme.tintStone, radius: m.cellCorner, depth: 0, border: m.thinBorder)
    }

    /// Het voortgangsbalkje onder de bonusstand: hoe vol, hoe dichterbij.
    private func bonusBar(subtotal: Int) -> some View {
        Capsule()
            .fill(AppTheme.ink.opacity(0.12))
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    Capsule()
                        .fill(AppTheme.amber)
                        .frame(width: geo.size.width * min(CGFloat(subtotal) / 63, 1))
                }
            }
            .frame(maxWidth: m.iconWidth * 1.1)
            .frame(height: max(m.rowHeight * 0.09, 3))
    }

}

#Preview {
    let lene = GamePlayer(profile: PlayerProfile(name: "Lene", avatarColorIndex: 0))
    let ellis = GamePlayer(profile: PlayerProfile(name: "Ellis", avatarColorIndex: 1))

    ScorecardView(
        players: [lene, ellis],
        currentPlayerID: lene.id,
        diceValues: [3, 3, 3, 5, 2],
        canScore: true,
        onSelect: { _ in }
    )
    .padding()
    .background(AppTheme.cream)
    .appMetrics()
}
