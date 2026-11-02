# Saisie guidée d'une solution, éléments liés

A solution's admin form offers its `Type de solution` as checkboxes on the fixed list `Solution::TYPES_SOLUTION` (9 values, a value outside it is refused), the `Légende de l’image` as a one-line text field, and the hint `L’image sera retirée à l’enregistrement.` under `Retirer l’image`. Its `Intégrations` tab lists `Ce qu’elle intègre` and `Solutions qui l’intègrent` as editable rows (see [admin-integrations-en-ligne.md](admin-integrations-en-ligne.md)); its `Recommandée dans` tab lists the démarches that recommend it.

## Sub-features

- `saisie-solution-types` `Type de solution` as checkboxes on the 9 fixed values, saved as ticked.
- `saisie-solution-type-refuse` a type outside the list is refused (spec only).
- `saisie-solution-image` `Légende de l’image` on one line, hint `L’image sera retirée à l’enregistrement.` under `Retirer l’image`.
- `saisie-solution-liens` tabs `Intégrations` and `Recommandée dans` list the linked rows, and the API lists the solution back.

## How to get to it (user POV)

- `/admin/solutions/<id>/edit`. Admin only.

## Driving it with Capybara

Drive: `features/admin-saisie-solution.rb` (SKILL.md § Drive).

Preconditions: logged in; the drive works on a solution it creates (`Vérif verify-map <browser>`, Brique technique, image + légende, first public organisation so it can be recommended) linked to the first visible API that has integratrices (consomme) and recommended by the first visible démarche; deleted in `ensure` with its links.

- **Fiche.** Légende is `input[type=text]`; the retirer hint is shown; the `Intégrations` and `Recommandée dans` tabs list the API and the démarche.
- **Other side.** The API's edit page: its `Solutions qui l’intègrent` rows equal its integrations by intégratrice name and include the drive's solution.
- **Types.** The 9 labels in order; tick `Portail agent` and `Hub d'échange`, Tab from `Portail agent` lands on the next box, `Enregistrer` → database has both; untick one, save → database has the other only.
- **Proof.** `tmp/verify/admin-saisie-solution/`, including `etroit-320`.

## Gotchas

- Read-backs after a mutation go through `ActiveRecord::Base.uncached`.
