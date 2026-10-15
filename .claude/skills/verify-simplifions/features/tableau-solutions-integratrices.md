# Tableau des solutions ayant intégré les données

In the cas d'usage tab « Solutions ayant intégré ces données », a « Cartes / Tableau » choice shows, per category, one table: a row per solution, a column per useful datum, a check or a cross per cell. The table sorts by solution name and by count of integrated data.

## How to get to it (user POV)

- `/demarches/<slug>#solutions-integratrices`, then « Tableau » under « Affichage des solutions ».
- Anyone, no login.

## Driving it with Capybara

Preconditions: a visible démarche with `Demarche#integratrices_par_categorie` not empty; the first one in id order has 27 useful data and 12 solutions in its first category.

- **Choice.** `Cartes` checked on arrival, no `.vue-tableau` visible. `choose('Tableau', allow_label_click: true)`: cards hide, one table per category.
- **Proof.** First table rows `[data-nom, data-integrees]` equal `integratrices_par_categorie.values.first` with `donnees_integrees_par(solution).size`; column count minus two equals `donnees_utiles.size`.
- **Sort.** `Trier par solution` twice (ascending, descending, French collation), `Trier par données intégrées` twice (descending = served order, then ascending); `th[aria-sort]` follows.
- **Headers.** `aria_role` of a `thead th` is `columnheader`, of a `tbody th` `rowheader`.
- **Mobile.** Window 375 wide: `document.documentElement.scrollWidth <= clientWidth`, the `.fr-table__container` scrolls horizontally.
- **No JS.** `Verify.session(javascript: false)`: cards and tables both shown, no choice, no sort button.

## Gotchas

- The segmented radios are visually hidden by the DSFR: `choose` needs `allow_label_click: true`.
- Headless Firefox will not go under about 480 px wide; the mobile read-back gives the real width.
