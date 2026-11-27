# Lire une fiche solution

A solution page shows the operator badge (« Solution publique / privée | opérateur ») and, under « Solutions intégrant … », one tab per category of integrating solution with its count. Its example image, when it has one, sits in a black frame with a shadow, its corners square like the frame.

## Sub-features

- `fiche-solution-badge` the operator badge reads « Solution publique | … » or « Solution privée | … ».
- `fiche-solution-onglets` one tab per category of integrating solution with its count, in the model's order; a click switches tab.
- `fiche-solution-carte` integrating solution cards keep the cas d'usage card's blue arrow.
- `fiche-solution-cas-usages` « Cas d'usages simplifiables » shows démarche cards (blue header, public visé, no description) that are not clickable as a whole: « Consulter la démarche » leads to the démarche, and a second link to its Solutions tab: « Solutions intégrant "<solution>" pour cette démarche » when the solution is a data source the démarche recommends, « Comparer avec les autres solutions » when it integrates the démarche's data; no second link when the Solutions tab is greyed out (no integrating solution).
- `fiche-solution-image` the example image sits in a black shadowed frame, its corners square.

## How to get to it (user POV)

- From `/solutions`, click a card title; URL `/solutions/<slug>`, visible solutions only, anyone.

## Driving it with Capybara

Drive: `features/fiche-solution.rb` (SKILL.md § Drive).

Preconditions: a visible solution with integratrices in two categories or more (`bouquet-api-entreprise` in the Grist import), and a visible solution with an image.

- **Open.** Visit the solution with the most tabs (`Solution#integratrices_par_categorie`); the operator badge reads `Solution publique |` or `Solution privée |`.
- **Tabs.** `page.all('[role=tab]').map(&:text)` equals each category's label from `public.onglets_integratrices` with its count, in the model's order.
- **Switch.** Click the last tab; it becomes `aria-selected='true'`.
- **Card arrow.** In the open tab, a card's `.solution-integratrice-card__arrow` is `position: absolute` and its icon blue (`rgb(0, 0, 145)`): the stylesheet is shared with the cas d'usage cards.
- **Example image.** On the first visible solution with an image (by slug), the `.example-image` frame keeps its `4px` black border and its shadow, and its `img` has square corners (`border-radius: 0px`).
- **Cas d'usage cards.** Window 1280 wide, on the solution with the most démarches among those listing a démarche without integrating solution (`Demarche#integratrices_par_categorie` empty, e.g. `authentification-dun-particulier`): one card per `Solution#demarches_simplifiables`, in order, title not a link, each with `Consulter la démarche`, and, exactly when `integratrices_par_categorie` is not empty, `Solutions intégrant "<solution>" pour cette démarche` if the démarche recommends the solution (`Solution#demarche_ids_recommandantes`), `Comparer avec les autres solutions` otherwise; no `.fr-enlarge-link`; cards of a row have the same height, the same blue header height, and their links end at the same line, at the bottom; hovering a card keeps its background.
- **Compare from a card.** Click the first of these two links: the démarche opens on its Solutions tab, `Tableau comparatif` checked exactly when `Demarche#tableau_comparatif_utile?`.
- **Cas d'usage cards on a phone.** Window 375 wide: the page does not scroll sideways.
- **Proof.** Screenshots after the switch, of the card arrow, of the example image, of the cards (desktop, phone) and after Comparer; read-back of the slug, tab texts, model counts and the image's corner, frame and shadow.
