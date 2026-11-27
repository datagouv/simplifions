# Voir les données intégrées par une solution

On a cas d'usage page, each integrating solution card in « Données disponibles » shows the count of its recommendation (or a green check for a single datum) and the cas d'usage total, and has an eye button that opens that card's window: the same two counts, then the useful published data of the cas d'usage grouped by recommended data, each checked or crossed, and a click on a row shows or hides its detail. The « Solutions ayant intégré ces données » tab reuses the card and window with the total only ([onglet-solutions-integratrices.md](onglet-solutions-integratrices.md)).

## Sub-features

- `donnees-integrees-compteurs` each card shows its recommendation's count (or a check) and the cas d'usage total.
- `donnees-integrees-fenetre` the eye opens the card's window: the same counts and the useful data, each checked or crossed.
- `donnees-integrees-detail` a click on a row shows its detail (access, producer, data.gouv link), a second click hides it.
- `donnees-integrees-fermer` Escape closes the window and gives the focus back to the eye.
- `donnees-integrees-comparer` when the comparison table is useful, the window offers « Comparer avec les autres solutions »: the window closes and the « Solutions ayant intégré ces données » tab shows « Tableau comparatif », on any screen, without leaving the page.
- `donnees-integrees-ordre` cards come by their recommendation's count, highest first, then by name.

## How to get to it (user POV)

- `/demarches/<slug>`, unfold a « Via … » accordion, click the eye on a card.
- Anyone, no login.

## Driving it with Capybara

Drive: `features/fiche-donnees-integrees.rb` (SKILL.md § Drive).

Preconditions: a visible démarche with useful data (`Demarche#donnees_utiles` not empty) and an integrating solution under one of its recommendations.

- **Open.** In `#donnees-disponibles`, unfold the accordion holding the first eye button (`aria-controls` of the `.fr-collapse` around it), click the eye. `dialog#<aria-controls>[open]` appears.
- **Proof.** Read-back of the card's total and the window's « Sur l'ensemble du cas d'usage » against `Demarche#couverture(solution)`, and of the checked rows over all rows against the same total; one window per card (dialog count equals eye count).
- **Detail.** Click the first row that has a detail (a `summary` inside the row): its detail (access badge, producer, data.gouv link) shows; a second click hides it.
- **Close.** Escape: the dialog loses `open`, focus is back on the eye (`document.activeElement` has the same `aria-controls`).
- **Compare from the data.** Window 500 wide (under 48em, where the tab would open on cards), on a démarche where `Demarche#tableau_comparatif_utile?`: open a window from `#donnees-disponibles` as in Open, click `Comparer avec les autres solutions`: no `dialog[open]`, the selected tab is `Solutions ayant intégré ces données`, `Tableau comparatif` is checked and tables show; a mark set on `document.body` before the click is still there (no Turbo visit, no reload).
- **Compare from the cards.** Window 1280 wide: open the Solutions tab, choose `Cartes`, click the first card's eye, then `Comparer avec les autres solutions`: same result.
- **No compare without a useful table.** On a démarche with solutions where the table is not useful, the window of a card in the Solutions tab has no `Comparer avec les autres solutions`.
- **Order.** On every visible démarche, the cards of each « Via … » grid come by the count of their recommendation, highest first, then in the database's name order; the evidence names a grid where the cas d'usage totals would have given another order.

## Gotchas

- A plain `#solutions-integratrices` link inside the window would make Turbo fetch and render the page again: the window closes and the tab opens, but the view is the arrival one (cards on a phone). The body mark catches it; a `window` flag survives a Turbo render and does not.

- Windows sit after the tabs, outside both panels: find them with `visible: :all` until opened.
- Headless Firefox does not go below 500 px wide; check 375 px in Chrome.
