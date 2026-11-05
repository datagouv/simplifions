# Distinguer les homonymes dans les sélecteurs

Wherever the admin offers or lists a solution (checkbox lists, select menus, intégration and recommandation names, the rows of the solutions list), the solution shows as `<nom> (<catégorie>)`, e.g. `API Impôt particulier (API)` and `API Impôt particulier (Brique technique)`. A solution without catégorie shows its name alone.

## Sub-features

- `homonymes-selects` recommandation and intégration selects show `<nom> (<catégorie>)`.
- `homonymes-cases` the `Solutions` checkbox lists of the forms show the same labels.
- `homonymes-liste` the solutions list rows tell the homonyms apart by their catégorie label under the name.
- `homonymes-lignes` recommandation row names, solution H1 and breadcrumb (spec only).
- `homonymes-sans-categorie` a solution without catégorie shows its name alone (not driven).

## How to get to it (user POV)

- `/admin/recommandations/new` (Solution), `/admin/integrations/new` (both selects), fournisseurs de services, organisations and vocabulaires forms (`Solutions` list), `/admin/integrations` and `/admin/recommandations` (row names), `/admin/solutions` (list rows). Admin only.

## Driving it with Capybara

Drive: `features/admin-homonymes.rb` (SKILL.md § Drive).

Read-only. Precondition: catalogue imported, two `API Impôt particulier` rows (ids 92 brique_logicielle, 187 api on 2026-10-05).

- **Selects.** Recommandation `Solution` and intégration `API ou jeu de données`: two distinct options for the name.
- **Checkbox list.** New type d'acteur, `Filtrer les solutions` with `impot particulier`: the same two labels.
- **Categories in the list.** Solutions list searched `impot particulier`: two rows named `API Impôt particulier`, each followed by a different catégorie label (`API`, `Brique technique`).
- **Proof.** `tmp/verify/admin-homonymes/`.

## Gotchas

- Grist true duplicates (Logiciel Enfance, Malice) share name and catégorie: they stay identical, out of scope.
