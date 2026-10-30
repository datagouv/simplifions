# Tableau comparatif des solutions ayant intégré les données

In the cas d'usage tab « Solutions ayant intégré ces données », a « Cartes / Tableau comparatif » choice and a « Trier par » menu sit above the categories. « Tableau comparatif » shows, per category, one table: a row per solution with its counter, columns grouped by bouquet (then « Autres API et jeux de données »), one column per useful datum, a check or a dash per cell. « Trier par » (« Le plus de données intégrées » on arrival, or « Titre ») orders cards and tables alike.

## How to get to it (user POV)

- `/demarches/<slug>#solutions-integratrices`, then « Tableau comparatif » and the « Trier par : » menu.
- Anyone, no login.

## Driving it with Capybara

Drive: `features/tableau-solutions-integratrices.rb` (SKILL.md § Drive).

Preconditions: a visible démarche with `Demarche#integratrices_par_categorie` not empty.

- **Arrival.** `Cartes` checked, `Trier par :` on `integrees`, no table visible, no « Les solutions sont classées » sentence.
- **Sort cards.** `select 'Titre', from: 'Trier par :'`: every visible list (`[data-tri-solutions-target=liste]`, children `data-nom`) is in French alphabetical order; `Le plus de données intégrées`: back to the served order (`integratrices_par_categorie`).
- **Table.** `choose('Tableau comparatif', allow_label_click: true)`: cards hide, one table per category, already in the order last chosen; sort back by data: served order.
- **Columns.** `th[scope=colgroup]` texts equal `groupes_donnees_utiles` titles; `th[scope=col]` count minus two equals `donnees_utiles.size`; no sort button in the headers.
- **Announcement.** A cell's `headers` resolve to solution, group, datum; its text is `Intégrée` or `Non intégrée`.
- **Mobile.** Window 375 wide: `document.documentElement.scrollWidth <= clientWidth`, the table container scrolls; after `scrollLeft = 400`, the first row's name cell is at the container's left edge and its counter has scrolled away under it (only the name is frozen).
- **No JS.** Quit the JS session, then `Verify.session(javascript: false)`: cards and tables both shown, no choice, no sort menu.

## Gotchas

- The segmented radios are visually hidden by the DSFR: `choose` needs `allow_label_click: true`.
- Headless Firefox will not go under about 480 px wide; the mobile read-back gives the real width.
