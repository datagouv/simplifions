# Distinguer les homonymes dans les sélecteurs

Wherever the admin offers or lists a solution (checkbox lists, select menus, intégration and recommandation names, the solutions list `Nom` and `Intégrée par` columns), the solution shows as `<nom> (<catégorie>)`, e.g. `API Impôt particulier (API)` and `API Impôt particulier (Brique technique)`. A solution without catégorie shows its name alone.

## How to get to it (user POV)

- `/admin/recommandations/new` (Solution), `/admin/integrations/new` (both selects), fournisseurs de services, organisations and vocabulaires forms (`Solutions` list), `/admin/integrations` and `/admin/recommandations` (row names), `/admin/solutions` (`Nom`, `Intégrée par`; `drive.rb listes` reads them). Admin only.

## Driving it with Capybara

`drive.rb homonymes`, read-only. Precondition: catalogue imported, two `API Impôt particulier` rows (ids 92 brique_logicielle, 187 api on 2026-10-05).

- **Selects.** Recommandation `Solution` and intégration `API ou jeu de données`: two distinct options for the name.
- **Checkbox list.** New type d'acteur, `Filtrer les solutions` with `impot particulier`: the same two labels.
- **Intégrée par.** Solutions list searched `impot particulier`: a cell names `API Impôt particulier (…)`.
- **Proof.** `tmp/verify/admin-homonymes/`.

## Gotchas

- Grist true duplicates (Logiciel Enfance, Malice) share name and catégorie: they stay identical, out of scope.
