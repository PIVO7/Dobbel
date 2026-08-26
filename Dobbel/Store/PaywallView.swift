import SwiftUI

/// Het aankoopscherm van de Gezinsversie: wat je krijgt, één prijs — en de
/// ouder-poort vóór het hele scherm, niet alleen vóór de kassa.
struct PaywallView: View {
    let entitlements: EntitlementStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.metrics) private var m

    @State private var gateQuestion: ParentalGateQuestion?
    /// De poort staat vóór het hele scherm: ook de prijzen en de koopknoppen
    /// zijn oudergebied (kindercategorie).
    @State private var gatePassed = false
    @State private var isBusy = false
    /// StoreKit-fouten mogen niet stil verdwijnen: de ouder staat bij de
    /// kassa en moet weten waaróm er niets gebeurt.
    @State private var errorText: String?

    private var priceText: String {
        entitlements.familyProduct?.displayPrice ?? "…"
    }

    var body: some View {
        ZStack {
            ThemedBackground()

            if gatePassed || entitlements.isFamilyUnlocked {
                paywallContent
            }

            // De sluitknop hoort in de hoek van het vénster, niet in de hoek
            // van de smallere tekstkolom — en blijft ook mét dichte poort
            // bereikbaar, zodat een kind gewoon weg kan.
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Label("Sluiten", systemImage: "xmark")
                            .labelStyle(.iconOnly)
                            .font(.system(size: m.captionSize + 2, weight: .black))
                            .foregroundStyle(AppTheme.ink)
                            .frame(width: m.tapTarget, height: m.tapTarget)
                    }
                    .buttonStyle(ToyButtonStyle(fill: AppTheme.card, radius: m.cellCorner, depth: 3, border: m.thinBorder))
                }
                Spacer()
            }
            // Ruimer dan de standaardmarge: de ronde hoek van het sheet
            // liep anders dwars achter de knop door en knipte zijn schaduw.
            .padding(m.gutter * 1.4)

            // De ouder-poort: verplicht voor de kindercategorie, en eerlijk
            // gezegd gewoon verstandig.
            if let question = gateQuestion {
                gateOverlay(question)
            }
        }
        .interactiveDismissDisabled(isBusy)
        .onAppear {
            // De vraag komt meteen bij het openen; wie de winkel al heeft,
            // hoeft niets meer te rekenen.
            if !entitlements.isFamilyUnlocked && !gatePassed {
                gateQuestion = .make()
            }
        }
        // De prijs kan bij het openen nog ontbreken (geen netwerk bij de
        // start); hier krijgt hij een tweede kans.
        .task {
            if entitlements.familyProduct == nil {
                await entitlements.load()
            }
        }
    }

    private var paywallContent: some View {
        ScrollView {
            VStack(spacing: m.gutter) {
                Image(systemName: "figure.2.and.child.holdinghands")
                    .padding(.top, m.gutter)
                    .font(.system(size: m.titleSize, weight: .black))
                    .foregroundStyle(AppTheme.coral)

                Text("Gezinsversie")
                    .font(AppTheme.rounded(m.titleSize * 0.7))
                    .foregroundStyle(AppTheme.headline)

                Text("Eén keer kopen, voor het hele gezin — ook via Delen met gezin.")
                    .font(AppTheme.rounded(m.captionSize + 2, .bold))
                    .foregroundStyle(AppTheme.soft)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: m.gutter * 0.7) {
                    feature("person.3.fill", "Speel met 3 of 4 spelers aan één toestel")
                    feature("graduationcap.fill", "Alle drie de tegenstanders: Dommel, Robbie en Professor Punt")
                    feature("paintpalette.fill", "Alle kleurenthema's: Snoep, Oceaan en Nacht")
                    feature("chart.bar.fill", "Statistieken met trofeeën, een grafiekje en gezinsrecords")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(m.gutter)
                .toyBlock(fill: AppTheme.card, radius: m.cardCorner * 0.9, depth: m.depth, border: m.border)

                if entitlements.isFamilyUnlocked {
                    Label("Ontgrendeld — veel plezier!", systemImage: "checkmark.seal.fill")
                        .font(AppTheme.rounded(m.bodySize))
                        .foregroundStyle(AppTheme.mint)
                        .padding(.top, m.gutter)
                } else {
                    Button(action: startPurchase) {
                        Text("Ontgrendel voor \(priceText)")
                            .font(AppTheme.rounded(m.buttonTextSize * 0.8))
                            .foregroundStyle(AppTheme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: m.buttonHeight * 0.85)
                    }
                    .buttonStyle(ToyButtonStyle(
                        fill: AppTheme.mint,
                        radius: m.cardCorner * 0.9,
                        depth: m.depth,
                        border: m.border
                    ))
                    .disabled(isBusy)

                    Button(action: startRestore) {
                        Text("Eerder gekocht? Zet terug")
                            .font(AppTheme.rounded(m.captionSize, .bold))
                            .foregroundStyle(AppTheme.soft)
                            .frame(minHeight: m.tapTarget)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(isBusy)

                    if let errorText {
                        Label(errorText, systemImage: "exclamationmark.triangle.fill")
                            .font(AppTheme.rounded(m.captionSize, .bold))
                            .foregroundStyle(AppTheme.coral)
                            .multilineTextAlignment(.leading)
                            .padding(m.gutter * 0.8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .toyBlock(fill: AppTheme.card, radius: m.cardCorner * 0.8, depth: 3, border: m.thinBorder)
                    }
                }
            }
            .padding(.horizontal, m.gutter * 1.4)
            .padding(.bottom, m.gutter * 2)
            .frame(maxWidth: m.overlayMaxWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private func feature(_ icon: String, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: m.gutter * 0.6) {
            Image(systemName: icon)
                .font(.system(size: m.bodySize, weight: .black))
                .foregroundStyle(AppTheme.coral)
                .frame(width: m.bodySize * 1.6)
            Text(text)
                .font(AppTheme.rounded(m.captionSize + 2, .bold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func gateOverlay(_ question: ParentalGateQuestion) -> some View {
        ZStack {
            // Tikken naast de kaart sluit het hele scherm; VoiceOver krijgt
            // de opties op de kaart, niet dit vlak.
            AppTheme.ink.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
                .accessibilityHidden(true)

            VStack(spacing: m.gutter * 0.8) {
                Text("Vraag even aan papa of mama")
                    .font(AppTheme.rounded(m.bodySize + 2))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)

                Text(question.text)
                    .font(AppTheme.rounded(m.titleSize * 0.6))
                    .foregroundStyle(AppTheme.coral)

                HStack(spacing: m.gutter * 0.7) {
                    ForEach(question.options, id: \.self) { option in
                        Button {
                            answerGate(with: option, question: question)
                        } label: {
                            Text("\(option)")
                                .font(AppTheme.rounded(m.bodySize + 2))
                                .foregroundStyle(AppTheme.ink)
                                .frame(maxWidth: .infinity)
                                .frame(height: m.tapTarget)
                        }
                        .buttonStyle(ToyButtonStyle(fill: AppTheme.card, radius: m.cellCorner, depth: 3, border: m.thinBorder))
                    }
                }
            }
            .padding(m.gutter * 1.4)
            // Kaartwit en niet cream: in het nachtthema is cream donker en
            // zou de donkere inkt onleesbaar worden.
            .toyBlock(fill: AppTheme.card, radius: m.cardCorner + 4, depth: m.depth + 1, border: m.border)
            .frame(maxWidth: m.overlayMaxWidth * 0.82)
            .padding(m.gutter * 2)
            .accessibilityAddTraits(.isModal)
        }
        .transition(.opacity)
    }

    private func answerGate(with option: Int, question: ParentalGateQuestion) {
        guard option == question.answer else {
            // Fout: nieuwe vraag, zodat gokken niet loont.
            gateQuestion = .make()
            return
        }
        withAnimation(.easeOut(duration: 0.15)) {
            gateQuestion = nil
            gatePassed = true
        }
    }

    // MARK: - Kassa

    private func startPurchase() {
        errorText = nil
        isBusy = true
        Task {
            await purchase()
            isBusy = false
        }
    }

    private func startRestore() {
        errorText = nil
        isBusy = true
        Task {
            await restore()
            isBusy = false
        }
    }

    private func purchase() async {
        switch await entitlements.purchaseFamily() {
        case .success, .cancelled:
            break
        case .failed:
            errorText = String(localized: "De aankoop is niet gelukt. Controleer de internetverbinding en probeer het opnieuw.")
        }
    }

    private func restore() async {
        let synced = await entitlements.restorePurchases()
        if !synced {
            errorText = String(localized: "Terugzetten is niet gelukt. Controleer de internetverbinding en probeer het opnieuw.")
        } else if !entitlements.isFamilyUnlocked {
            errorText = String(localized: "Er is geen eerdere aankoop gevonden voor dit Apple-account.")
        }
    }
}

#Preview {
    PaywallView(entitlements: EntitlementStore(previewUnlocked: false))
        .appMetrics()
}
