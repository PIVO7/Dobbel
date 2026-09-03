# TestFlight — Dobbel!

Dit document bevat de teksten die TestFlight vraagt en het stappenplan om
een build bij testers te krijgen.

## Wat al klaarstaat

- **Build 11** (2026-09-03) — het project staat op versie 1.0, build 11
  (`CURRENT_PROJECT_VERSION: 11` in project.yml, gecommit als "Build 11 voor
  versie 1.0"). Ten opzichte van build 10 bevat hij: geen worp-in-woorden
  meer boven de stenen en "In volgorde" toont het doelvakje. De archive
  **"Dobbel 1.0 (11)"** (gebouwd met Xcode 26.6, iOS 26.5 SDK) staat in de
  Organizer; uploaden moet nog gebeuren. Bevat Dobbel.app (nl/en/fr),
  dSYM-symbolen, minimum iOS 17.0.
- Let op: de archive "Dobbel 03-09-2026, 17.23" van dezelfde dag komt uit
  Xcode-beta en is door Apple afgekeurd — die mag weg.
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
3. **Archiveren, altijd met de definitieve Xcode** (nu Xcode 26.6 in
   /Applications/Developer/Xcode.app, níét Xcode-beta): bestemming "Any iOS
   Device (arm64)" → Product → **Archive**. De archive verschijnt in Window →
   Organizer als "Dobbel 1.0 (11)". Een archive uit een bèta-Xcode wordt bij
   het valideren afgekeurd met "Unsupported SDK or Xcode version".
   Weigert macOS (bèta) Xcode 26.6 te openen ("niet compatibel"), start hem
   dan rechtstreeks vanuit Terminal:
   `nohup /Applications/Developer/Xcode.app/Contents/MacOS/Xcode &`.
   Of upload de 26.6-archive gewoon via de Organizer van Xcode-beta; alleen
   de SDK waarmee de archive gebouwd is telt.
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

App Store Connect → TestFlight → de build kiezen → **Test Details** →
"What to Test". Het veld is per taal; plak de Nederlandse tekst bij
Dutch, de Engelse bij English en de Franse bij French. Platte tekst,
geen markdown; elk blok blijft ruim onder de limiet van 4000 tekens.

### Nederlands (build 11)

```text
Build 11 van Dobbel! Nieuw sinds de vorige build: boven de stenen staat de worp niet meer in woorden, en bij "In volgorde" zie je meteen welk vakje je vult.

Kijk vooral naar:

- Een heel potje tegen elkaar aan één toestel (2 tot 4 spelers) en solo tegen Robbie: kloppen de punten, de bonus en de tweede Dobbel?
- "In volgorde": is het duidelijk welk vakje aan de beurt is, ook nadat je een worp opnieuw gooit?
- De Gezinsversie kopen (gratis in TestFlight): lukt de ouder-poort, en ontgrendelen thema's, statistieken en de extra tegenstanders meteen?
- Taal: zet het toestel eens op Engels of Frans. Is alles vertaald?
- Onderbreken: sluit de app midden in een potje af en open opnieuw. Gaat het spel verder waar het was?
- Schudden om te gooien, de terugzet-knop en het doorgeefscherm.

Feedback graag via de TestFlight-app (schermafbeelding plus opmerking) of naar jelle@pivo7.be.
```

### English (build 11)

```text
Build 11 of Dobbel! New since the previous build: the roll is no longer spelled out in words above the dice, and "In order" now shows you which box you are filling.

Please look at:

- A full game against each other on one device (2 to 4 players) and solo against Robbie: are the points, the bonus and the second Dobbel correct?
- "In order": is it clear which box is up, also after you reroll?
- Buying the Family Version (free in TestFlight): does the parent gate work, and do themes, statistics and the extra opponents unlock right away?
- Language: switch the device to Dutch or French. Is everything translated?
- Interrupting: quit the app in the middle of a game and open it again. Does the game continue where it was?
- Shake to roll, the undo button and the pass-the-device screen.

Feedback via the TestFlight app (screenshot plus a note) or to jelle@pivo7.be.
```

### Français (build 11)

```text
Build 11 de Dobbel ! Nouveau depuis la version précédente : le lancer n'est plus écrit en mots au-dessus des dés, et « Dans l'ordre » montre directement la case que vous remplissez.

À tester en priorité :

- Une partie complète les uns contre les autres sur un seul appareil (2 à 4 joueurs) et en solo contre Robbie : les points, le bonus et le deuxième Dobbel sont-ils corrects ?
- « Dans l'ordre » : voit-on clairement quelle case est en jeu, aussi après avoir relancé ?
- Acheter la version Famille (gratuite dans TestFlight) : le contrôle parental fonctionne-t-il, et les thèmes, les statistiques et les adversaires supplémentaires se débloquent-ils tout de suite ?
- Langue : mettez l'appareil en néerlandais ou en anglais. Tout est-il traduit ?
- Interruption : quittez l'app au milieu d'une partie et rouvrez-la. La partie reprend-elle où elle en était ?
- Secouer pour lancer, le bouton d'annulation et l'écran de passage de l'appareil.

Vos retours via l'app TestFlight (capture d'écran plus remarque) ou à jelle@pivo7.be.
```

## Uitnodiging voor externe testers (versturen via bericht of mail)

Vervang `<LINK>` door de publieke link van de externe groep (App Store
Connect → TestFlight → de groep → Public Link → Enable). Het onderwerp voor
een mail: **Wil je Dobbel! mee testen?**

### Nederlands

```text
Hallo!

Ik heb een dobbelspel-app gemaakt voor kinderen en het gezin: Dobbel! Je speelt samen aan één toestel of solo tegen de computer, met tips die uitleggen wat slim is. Geen reclame, geen accounts, alles blijft op het toestel.

Voor de app in de App Store komt, zoek ik een paar gezinnen die hem willen uitproberen. Dat duurt een kwartiertje, en het is helemaal gratis.

Zo doe je mee:
1. Installeer de app TestFlight uit de App Store (dat is Apple's testapp).
2. Open deze link op je iPhone of iPad: <LINK>
3. Tik op "Accepteren" en daarna op "Installeren". Dobbel! staat dan gewoon tussen je apps.

Waar ik vooral benieuwd naar ben:
- Speel een heel potje met twee of meer, en eens solo tegen Robbie. Kloppen de punten?
- Probeer de Gezinsversie te kopen. In TestFlight is dat gratis en er wordt niets aangerekend. Werkt de rekensom voor ouders, en gaan de extra thema's en spelers meteen open?
- Laat de kinderen gewoon spelen en kijk waar ze vastlopen. Dat is voor mij het waardevolst.

Feedback geven kan rechtstreeks in TestFlight: open TestFlight, tik op Dobbel! en dan op "Feedback versturen". Een schermafbeelding nemen in de app werkt ook; TestFlight vraagt dan of je ze wilt delen. Of mail me gewoon op jelle@pivo7.be.

De testversie werkt 90 dagen. Als de app in de App Store staat, laat ik het weten.

Alvast bedankt!
Jelle
```

### English

```text
Hi!

I've made a dice game app for children and families: Dobbel! You play together on one device or solo against the computer, with hints that explain what a smart move is. No ads, no accounts, everything stays on the device.

Before it goes to the App Store, I'm looking for a few families to try it out. It takes about fifteen minutes and is completely free.

How to join:
1. Install the TestFlight app from the App Store (Apple's testing app).
2. Open this link on your iPhone or iPad: <LINK>
3. Tap "Accept", then "Install". Dobbel! will appear among your apps.

What I'm most curious about:
- Play a full game with two or more people, and one solo game against Robbie. Are the scores right?
- Try buying the Family Version. In TestFlight it's free and nothing is charged. Does the parent gate work, and do the extra themes and players unlock right away?
- Let the kids just play and watch where they get stuck. That's the most valuable feedback for me.

You can send feedback straight from TestFlight: open TestFlight, tap Dobbel!, then "Send Feedback". Taking a screenshot in the app also works; TestFlight will ask if you want to share it. Or just email me at jelle@pivo7.be.

The test version works for 90 days. I'll let you know when the app is in the App Store.

Thanks a lot!
Jelle
```

### Français

```text
Bonjour !

J'ai créé une app de jeu de dés pour les enfants et la famille : Dobbel ! On joue ensemble sur un seul appareil ou en solo contre l'ordinateur, avec des conseils qui expliquent ce qui est malin. Pas de publicité, pas de compte, tout reste sur l'appareil.

Avant sa sortie sur l'App Store, je cherche quelques familles pour l'essayer. Cela prend un quart d'heure et c'est entièrement gratuit.

Pour participer :
1. Installez l'app TestFlight depuis l'App Store (l'app de test d'Apple).
2. Ouvrez ce lien sur votre iPhone ou iPad : <LINK>
3. Touchez « Accepter », puis « Installer ». Dobbel ! apparaît alors parmi vos apps.

Ce qui m'intéresse surtout :
- Jouez une partie complète à deux ou plus, et une partie en solo contre Robbie. Les points sont-ils corrects ?
- Essayez d'acheter la Version Famille. Dans TestFlight c'est gratuit, rien n'est facturé. Le contrôle parental fonctionne-t-il, et les thèmes et joueurs supplémentaires se débloquent-ils tout de suite ?
- Laissez simplement les enfants jouer et regardez où ils bloquent. C'est le retour le plus précieux pour moi.

Vous pouvez envoyer vos remarques directement depuis TestFlight : ouvrez TestFlight, touchez Dobbel !, puis « Envoyer des commentaires ». Une capture d'écran dans l'app fonctionne aussi ; TestFlight vous propose alors de la partager. Ou écrivez-moi simplement à jelle@pivo7.be.

La version de test fonctionne pendant 90 jours. Je vous préviens dès que l'app est sur l'App Store.

Merci d'avance !
Jelle
```

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
