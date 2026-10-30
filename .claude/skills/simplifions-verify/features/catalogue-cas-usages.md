# Explorer le catalogue des cas d'usages

Visitors browse the list of cas d'usages (démarches), narrow it by full-text search and by four facets, and see how many match.

## Sub-features

- `catalogue-liste` shows the visible démarches, 20 per page, with a result count.
- `catalogue-recherche` filters by the `Rechercher` text field.
- `catalogue-facettes` filters by acteur, usager, catégorie de solution, type de simplification, applied with the tri by `Appliquer les filtres`.
- `catalogue-type` switches between `Cas d'usages` and `Solutions` keeping the filters.

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
- **Search.** `fill_in "Rechercher", with: "marchés publics"` then `click_button "Rechercher"`. URL gains `q=`, the count drops.
- **Facet.** `select "Entreprises", from: "Démarches à destination des :"`, then `click_button "Appliquer les filtres"`. URL gains `target-users=entreprises`; the count updates.
- **Proof.** Screenshot, and the page count equals `Demarche.catalogue({ "q" => "marchés publics", "target-users" => "entreprises" }).count`.

## Gotchas

- Read the count only after `assert_current_path(/q=march/, url: false)`: Chrome returns the old page otherwise.
- Facet values are slugs (`entreprises`), labels are capitalised (`Entreprises`).
