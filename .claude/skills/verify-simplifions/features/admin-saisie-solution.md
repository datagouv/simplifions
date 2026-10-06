# Saisie guidée d'une solution, éléments liés

A solution's admin form offers its `Type de solution` as checkboxes on the fixed list `Solution::TYPES_SOLUTION` (9 values, a value outside it is refused), the `Légende de l’image` as a one-line text field, and the hint `L’image sera retirée à l’enregistrement.` under `Retirer l’image`. Above the form, an `Éléments liés` section lists, read-only and each with a link to its admin page: `Démarches qui la recommandent`, `Solutions qui l’intègrent`, `Ce qu’elle intègre`; absent when the solution is linked to nothing.

## How to get to it (user POV)

- `/admin/solutions/<id>/edit`. Admin only.

## Driving it with Capybara

`drive.rb saisie-solution`, on a solution it creates (`Vérif verify-map <browser>`, Brique technique, image + légende, first public organisation so it can be recommended) linked to the first visible API that has integratrices (consomme) and recommended by the first visible démarche; deleted in `ensure` with its links.

- **Fiche.** Légende is `input[type=text]`; the retirer hint is shown; `Éléments liés` equals the démarche and the API.
- **Link.** Click the API in `Éléments liés` → its edit page; `Solutions qui l’intègrent` equals `api.integratrices` and includes the drive's solution.
- **Types.** The 9 labels in order; tick `Portail agent` and `Hub d'échange`, Tab from `Portail agent` lands on the next box, `Enregistrer` → database has both; untick one, save → database has the other only.
- **Proof.** `tmp/verify/admin-saisie-solution/`, including `etroit-320`.

## Gotchas

- Read-backs after a mutation go through `ActiveRecord::Base.uncached`.
