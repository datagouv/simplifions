# Ordonner les données et API fournies d'une solution

On a solution page, « Données et API fournies » lists first the APIs and jeux de données whose integration has an `Ordre`, smallest first, then those without one; ties and the unranked ones by the title shown on the card (the data.gouv title, else the name). The admin sets `Ordre` on the integration's own page; an empty field removes the rank. The Grist refresh keeps it.

## Sub-features

- `rang` — an API with `Ordre` 1 moves to the top, the others keep their order.
- `vide` — emptying `Ordre` puts the list back as it was.

## How to get to it (user POV)

- Admin: `Solutions` → a solution → tab `Intégrations (<n>)` → `Modifier l’intégration <libellé>` in `Ce qu’elle intègre`, or `Intégrations` → the row; field `Ordre`, button `Enregistrer`. Admin only.
- Visitor: `/solutions/<slug>`, section `Données et API fournies`.

## Driving it with Capybara

Drive: `features/ordre-api-fournies.rb` (SKILL.md § Drive).

Preconditions: a visible solution providing at least two visible APIs on data.gouv (`bouquet-api-entreprise` in the Grist import), none ranked. Mutating then undone.

- **Avant.** Visit the solution with the most such APIs; read the card titles under `Données et API fournies`.
- **Rang.** Admin, its `Intégrations` tab, `Modifier l’intégration` of the last API shown; `Ordre` = 1, `Enregistrer` → `enregistré`, `ordre` 1 in base. The public page shows that API first, then the others in their previous order.
- **Vide.** Back on the integration, `Ordre` emptied, `Enregistrer`; the public list equals the first read, `ordre` nil in base.
- **Proof.** `tmp/verify/ordre-api-fournies/` (`avant`, `ordre-saisi`, `en-tete`, `defait`).

## Gotchas

- Needs the `ordre` column: on a branch not yet merged, run the drive on a copy of the dev database (`createdb -T simplifions_development …`, `DATABASE_NAME_DEVELOPMENT=…`), never migrate the shared one.
- The drive's `ensure` puts the rank back if a step failed midway; each save leaves a paper_trail version on the integration.
