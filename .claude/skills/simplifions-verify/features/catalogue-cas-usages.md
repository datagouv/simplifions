# Explorer le catalogue des cas d'usages

Visitors browse the list of cas d'usages (démarches), narrow it by full-text search and by four facets, and see how many match.

## Sub-features

- `catalogue-liste` shows the visible démarches, 20 per page, with a result count.
- `catalogue-recherche` filters by the `Rechercher` text field.
- `catalogue-facettes` filters by acteur, usager, catégorie de solution, type de simplification: each value is a DSFR selectable tag (a submit button, `aria-pressed`) showing its count, applied on click; several values of one facet add up (« ou »), facets combine (« et »). The focus then lands on the result count « N résultats sur M ». Acteurs show Communes et groupements, Départements, Régions, État, the 5 others in a native `details` « Afficher les 5 autres » (open when one of them is chosen, works without JavaScript; so does « Plus de filtres »). The tri keeps its select, applied by `Trier`, a button shown only while the chosen tri differs from the applied one.
- `catalogue-type` switches between `Cas d'usages` and `Solutions` keeping the filters.
- `catalogue-titre-filtres` the H2 « Filtrer les cas d'usages » / « Filtrer les solutions » is read by screen readers only (`fr-sr-only`): the search bar follows the H1 on screen.

## How to get to it (user POV)

- Header menu `Cas d'usages`, or the home page form `Explorer les démarches référencées`.
- URL `/demarches` (`/solutions` for the other type); `/cas-d-usages` redirects there.
- Filters live in the URL (`?q=…&target-users=entreprises`), so a filtered list is shareable.
- Anyone, no login.

## Driving it with Capybara

Drive: `features/catalogue-cas-usages.rb` (SKILL.md § Drive).

Preconditions:

- Launch done and doctor green (SKILL.md § Launch, § Doctor).
- At least one visible démarche whose title contains « marchés publics » and targets entreprises.

- **Open the list.** `page.visit("/demarches")`. H1 `Cas d'usages`, a `[role=status]` paragraph `N résultats`.
- **Filter heading.** On `/demarches` then `/solutions`: an H2 `Filtrer les cas d'usages` / `Filtrer les solutions` exists with `visible: :all` and is drawn 1 px wide at most; nothing visible sits between the H1 and the `Rechercher` field (vertical gap under 60 px). Screenshot each.
- **Search.** `fill_in "Rechercher", with: "marchés publics"` then `click_button "Rechercher"`. URL gains `q=`, the count drops.
- **Facet.** Under the heading `Démarches à destination des`, click the tag `Entreprises (N)`. URL gains `target-users=entreprises`; the focus is on the count (`resultats`); the count equals the N the tag showed.
- **Proof.** Screenshot, and the page count equals `Demarche.catalogue({ "q" => "marchés publics", "target-users" => "entreprises" }).count`.
- **Several.** Click the tag `Associations (N)`: URL has `target-users=entreprises%2Cassociations`, the count equals `Demarche.catalogue` for both, and is not below the Entreprises count. Screenshot `cumul`.
- **Actor.** Click the tag `Communes et groupements (N)`: URL gains `fournisseurs-de-service=communes`, the count equals the base. Screenshot `acteur`.
- **Show more.** the `details` of `Afficher les 5 autres` is closed; click its `summary`, then the tag `Tous les acteurs publics (N)`: the URL has `communes%2Ctout-acteurs-publics`, the block is still open, the count equals the base. Screenshot `afficher-plus`.
- **Remove.** Click each pressed tag (`aria-pressed=true`) in turn: none left, the count is back to the search count. Screenshot `retrait`.
- **Sort.** No `Trier` button at first. Choose `Date de création` in `Trier par :`: `Trier` shows; back to `Pertinence`: it hides; `Date de création` then `Trier`: URL has `sort=-created`, `Trier` hidden again. Screenshot `tri`.
- **Type height.** Window 390 px wide, `/demarches`: each « Type » link (`Cas d'usages`, `Solutions`) is as tall as the `Trier par :` select. Screenshot `type-390`, read-back `trier_par=<px> types=[<px>, <px>]`.
- **Without JavaScript.** JavaScript off, `/demarches?types-de-simplification=dlnuf`: « Plus de filtres » is open and its chosen tag shows; clicking the `summary` `Afficher les 5 autres` shows `Tous les acteurs publics (N)`. Screenshot `sans-js`.

## Gotchas

- Capybara counts an `fr-sr-only` element as visible (1 px, clipped): measure its width instead of `assert_no_selector`.
- Read the count only after `assert_current_path(/q=march/, url: false)`: Chrome returns the old page otherwise.
- Facet values are slugs (`entreprises`), labels are capitalised (`Entreprises`).
- The footer repeats some facet labels as links (`Départements`): click the tag button (its text ends with its count).
- A tag sends the current values of its facet (hidden field) then its own: the URL can hold the facet twice, the last one counts.
