# Reviewer-notities — Dobbel!

Voor het veld **App Review Information → Notes** in App Store Connect
(1.0 Prepare for Submission, onderaan). In het Engels, want de reviewer
leest geen Nederlands. Kopieer het blok hieronder integraal; het past ruim
binnen de limiet van 4000 tekens.

Sign-in-velden: vink **"Sign-in required" uit** — de app heeft geen
accounts, dus er is geen demo-account nodig.

---

## Notes (kopieer dit blok)

> Dobbel! is a dice game (Yahtzee-style rules) for children and families.
> No account, no sign-in, no internet connection required — the app is fully
> playable offline from first launch. No data is collected, there are no
> ads, no third-party SDKs, and no external links inside the app.
>
> LANGUAGES
> The primary language is Dutch, with full English and French
> localizations. The app follows the device language.
>
> FREE VS. PAID
> The free tier includes: 2-player games on one device, one computer
> opponent (Robbie), the Classic theme, and basic statistics. A single
> non-consumable in-app purchase "Family version" (com.pivo7.dobbel.gezin,
> Family Sharing enabled) unlocks 3-4 players, two extra computer
> opponents, three extra color themes, and the full statistics pages.
>
> HOW TO REACH THE PURCHASE SCREEN
> Tap the gear icon (top right on the home screen) → "Family version",
> or tap any locked item (a third player slot in game setup, a locked
> theme, or the locked statistics teaser).
>
> PARENTAL GATE (Kids Category, guideline 1.3)
> Every route to the purchase screen — including Restore Purchases — is
> protected by a parental gate: a multiplication question such as
> "How much is 7 × 8?" with three answer buttons. The question is
> randomized on every attempt (both factors are between 4 and 9). Simply
> multiply the two numbers shown and tap the matching answer; a wrong
> answer dismisses the gate.
>
> TESTING THE PURCHASE
> After passing the parental gate, the paywall shows the "Family version"
> product via StoreKit. In the sandbox you can complete the purchase with
> any sandbox Apple account; "Restore purchases" is available on the same
> screen. After purchase, 3-4 player setup, all opponents, all themes and
> the full statistics pages unlock immediately.
>
> OTHER NOTES
> - Dice can be rolled by tapping the roll button or by shaking the
>   device; shaking is optional and the button always works.
> - When several players share one device, a pass-the-device screen
>   appears between turns; tap it to continue.
> - Player "profiles" are just a name with an avatar color, stored only
>   on the device. They are not user accounts.

---

## Contactgegevens (aparte velden bij App Review Information)

| Veld | Waarde |
|---|---|
| First name / Last name | Jelle Wauters |
| Phone | jouw telefoonnummer (verplicht veld) |
| Email | jelle@pivo7.be |

## Waarom deze punten erin staan

- **Ouder-poort uitgelegd mét oplossing**: reviewers keuren kinder-apps af
  als ze de poort niet door raken; de uitleg "vermenigvuldig de twee
  getallen" voorkomt dat.
- **Kids Category / richtlijn 1.3**: expliciet benoemen dat élke route
  (ook herstellen) achter de poort zit, scheelt een vraag heen en weer.
- **Geen accounts/data/reclame**: dekt de privacyvragen af en verklaart
  waarom er geen demo-account is.
- **Sandbox-test beschreven**: de reviewer moet de aankoop kunnen
  voltooien om de IAP goed te keuren — de IAP moet dan wel bij de
  versie ingediend worden (sectie In-App Purchases op de versiepagina).
