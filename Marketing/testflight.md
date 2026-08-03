# TestFlight — Dobbel!

De archive staat klaar; dit document bevat de teksten die TestFlight vraagt en
het stappenplan om de eerste build bij testers te krijgen.

## Wat al klaarstaat

- **Archive "Dobbel 1.0 (3)"** (2026-08-03) — ondertekend en zichtbaar in
  Xcode → Window → **Organizer**. Bevat Dobbel.app (nl/en/fr), dSYM-symbolen,
  versie 1.0 (3), minimum iOS 17.0, inclusief alle bugfixes, de nieuwe
  nachtmodus en de uitgebreide statistieken (trofeeën, grafiekje,
  gezinsrecords). De oudere archives (1) en (2) zijn achterhaald — niet
  uploaden.
- `ITSAppUsesNonExemptEncryption` staat op NO in het project, dus TestFlight
  slaat de export-compliance-vraag bij elke build over.
- Eén universeel 1024-appicoon (vereist voor de upload) zit in de asset catalog.

## Stappenplan (eenmalig, met jouw account)

1. **App Store Connect → Apps → ➕ Nieuwe app**
   - Platform iOS, naam **Dobbel!**, primaire taal **Nederlands**,
     bundle-id **com.pivo7.dobbel**, SKU bv. `dobbel-001`.
2. **In-app-aankoop aanmaken** (mag ook later, maar vóór het testen van de
   Gezinsversie): niet-verbruiksartikel `com.pivo7.dobbel.gezin`,
   gezinsdeling aan — alle waarden staan in [appstore-tekst.md](appstore-tekst.md).
3. **Uploaden**: Xcode → Window → Organizer → archive "Dobbel 1.0 (3)" →
   **Distribute App → TestFlight & App Store → Upload**. Automatische
   ondertekening regelt het distributiecertificaat.
4. Na 5–15 minuten verwerken verschijnt de build onder het tabblad
   **TestFlight**. Vul daar de testinformatie in (teksten hieronder).
5. **Interne testers** (meteen, geen review): voeg jezelf en gezinsleden toe
   onder Interne testen. Zij krijgen een uitnodiging in de TestFlight-app.
6. **Externe testers** (optioneel, na een korte beta-review van Apple): maak
   een externe groep of deel een publieke link.

## Testinformatie (tabblad TestFlight, eenmalig)

| Veld | Waarde |
|---|---|
| Beta-appbeschrijving | Dobbel! is een dobbelspel voor kinderen en het gezin: samen aan één toestel of solo tegen de computer, met tips die uitleggen wat slim is. Geen reclame, geen accounts, alles blijft op het toestel. |
| Feedback-e-mail | jelle@pivo7.be |
| Contactgegevens beta-review | Jelle Wauters · jelle@pivo7.be |
| Aanmelden vereist? | Nee |

## "Wat te testen" (per build in te vullen)

> Eerste build van Dobbel! Alles mag stuk, maar kijk vooral naar:
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
  project.yml (3 → 4), draai `xcodegen generate`, archiveer en upload opnieuw.
  Testers krijgen de update automatisch.
- De **privacyverklaring-URL** is voor TestFlight nog niet verplicht, wel voor
  de echte review — regel die dus ergens tijdens de testronde.
