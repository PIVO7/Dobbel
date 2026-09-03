# TestFlight — Dobbel!

Dit document bevat de teksten die TestFlight vraagt en het stappenplan om
een build bij testers te krijgen.

## Wat al klaarstaat

- **Build 11** (2026-09-03) — het project staat op versie 1.0, build 11
  (`CURRENT_PROJECT_VERSION: 11` in project.yml, gecommit als "Build 11 voor
  versie 1.0"). Ten opzichte van build 10 bevat hij: geen worp-in-woorden
  meer boven de stenen en "In volgorde" toont het doelvakje. Archiveren en
  uploaden moet nog gebeuren (zie het stappenplan). Bevat Dobbel.app
  (nl/en/fr), dSYM-symbolen, minimum iOS 17.0.
- De oudere archives 1.0 (1) t/m (10) in de Organizer zijn achterhaald —
  niet meer uploaden.
- `ITSAppUsesNonExemptEncryption` staat op NO in het project, dus TestFlight
  slaat de export-compliance-vraag bij elke build over.
- Eén universeel 1024-appicoon (vereist voor de upload) zit in de asset catalog.

## Stappenplan (met jouw account)

1. **App Store Connect → Apps → ➕ Nieuwe app** (eenmalig, al gedaan als de
   app er staat)
   - Platform iOS, naam **Dobbel!**, primaire taal **Nederlands**,
     bundle-id **com.pivo7.dobbel**, SKU bv. `dobbel-001`.
2. **In-app-aankoop aanmaken** (mag ook later, maar vóór het testen van de
   Gezinsversie): niet-verbruiksartikel `com.pivo7.dobbel.gezin`,
   gezinsdeling aan — alle waarden staan in [appstore-tekst.md](appstore-tekst.md).
3. **Archiveren**: Xcode → bestemming "Any iOS Device (arm64)" → Product →
   **Archive**. De archive verschijnt in Window → Organizer als
   "Dobbel 1.0 (11)".
4. **Uploaden**: in de Organizer die archive kiezen →
   **Distribute App → TestFlight & App Store → Upload**. Automatische
   ondertekening regelt het distributiecertificaat.
5. Na 5–15 minuten verwerken verschijnt de build onder het tabblad
   **TestFlight**. Vul daar de testinformatie in (teksten hieronder).
6. **Interne testers** (meteen, geen review): voeg jezelf en gezinsleden toe
   onder Interne testen. Zij krijgen een uitnodiging in de TestFlight-app.
7. **Externe testers** (optioneel, na een korte beta-review van Apple): maak
   een externe groep of deel een publieke link.

## Testinformatie (tabblad TestFlight, eenmalig)

| Veld | Waarde |
|---|---|
| Beta-appbeschrijving | Dobbel! is een dobbelspel voor kinderen en het gezin: samen aan één toestel of solo tegen de computer, met tips die uitleggen wat slim is. Geen reclame, geen accounts, alles blijft op het toestel. |
| Feedback-e-mail | jelle@pivo7.be |
| Contactgegevens beta-review | Jelle Wauters · jelle@pivo7.be |
| Aanmelden vereist? | Nee |

## "Wat te testen" (per build in te vullen)

> Build 11 van Dobbel! Nieuw sinds de vorige build: boven de stenen staat de
> worp niet meer in woorden, en bij "In volgorde" zie je welk vakje je
> vult. Kijk vooral naar:
>
> - **Een heel potje** tegen elkaar aan één toestel (2–4 spelers) en solo
>   tegen Robbie: kloppen de punten, de bonus en de tweede Dobbel?
> - **De Gezinsversie kopen** (gratis in TestFlight): lukt de ouder-poort, en
>   ontgrendelen thema's, statistieken en de extra tegenstanders meteen?
> - **Taal**: zet het toestel eens op Engels of Frans — is álles vertaald?
> - **Onderbreken**: sluit de app midden in een potje af en open opnieuw —
>   gaat het spel verder waar het was?
> - **Schudden om te gooien**, de terugzet-knop en het doorgeefscherm.
>
> Feedback graag via de TestFlight-app (schermafbeelding + opmerking) of
> naar jelle@pivo7.be.

## Goed om te weten tijdens het testen

- **Aankopen in TestFlight zijn gratis** en gebruiken de sandbox; "Eerder
  gekocht? Zet terug" werkt daar ook. Het product moet wél eerst in App Store
  Connect bestaan (stap 2), anders blijft de prijs op "…" staan.
- **Volgende build uploaden**: verhoog `CURRENT_PROJECT_VERSION` in
  project.yml (11 → 12), draai `xcodegen generate`, commit ("Build 12 voor
  versie 1.0"), archiveer en upload opnieuw. Testers krijgen de update
  automatisch. Voor een nieuwe versie (bv. 1.1) verhoog je ook
  `MARKETING_VERSION`; het buildnummer loopt gewoon door.
- De **privacyverklaring-URL** is voor TestFlight nog niet verplicht, wel voor
  de echte review — regel die dus ergens tijdens de testronde.
