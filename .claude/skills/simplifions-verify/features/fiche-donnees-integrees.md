# Voir les données intégrées par une solution

On a cas d'usage page, each integrating solution card in « Données disponibles » shows the count of its recommendation (or a green check for a single datum) and the cas d'usage total, and has an eye button that opens that card's window: the same two counts, then the useful published data of the cas d'usage grouped by recommended data, each checked or crossed, and a click on a row shows or hides its detail.

## How to get to it (user POV)

- `/demarches/<slug>`, unfold a « Via … » accordion, click the eye on a card.
- Anyone, no login.

## Driving it with Capybara

Preconditions: a visible démarche with useful data (`Demarche#donnees_utiles` not empty) and an integrating solution under one of its recommendations.

- **Open.** Unfold the accordion holding the first eye button (`aria-controls` of the `.fr-collapse` around it), click the eye. `dialog#<aria-controls>[open]` appears.
- **Proof.** Read-back of the card's total and the window's « Sur l'ensemble du cas d'usage » against `Demarche#couverture(solution)`, and of the checked rows over all rows against the same total; one window per card (dialog count equals eye count).
- **Detail.** Click the first row that has a detail (a `summary` inside the row): its detail (access badge, producer, data.gouv link) shows; a second click hides it.
- **Close.** Escape: the dialog loses `open`, focus is back on the eye (`document.activeElement` has the same `aria-controls`).
- **Order.** On every visible démarche, the cards of each « Via … » grid come by the count of their recommendation, highest first, then in the database's name order; the evidence names a grid where the cas d'usage totals would have given another order.

## Gotchas

- Windows sit at the end of the section, outside the accordions: find them with `visible: :all` until opened.
- Headless Firefox does not go below 500 px wide; check 375 px in Chrome.
