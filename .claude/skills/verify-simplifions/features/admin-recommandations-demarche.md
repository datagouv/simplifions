# Gérer les recommandations depuis la démarche

A démarche's admin form lists its recommandations (Solution, Type de recommandation, Ordre, Visible, Modifié le), sorted by type then ordre, each solution linking to the recommandation, and offers `Ajouter une recommandation` with the démarche pre-selected. A recommandation's form opens on an encart: `Démarche : <nom>`, its description courte, `Voir la fiche <nom>`, and an accordion `Autres recommandations de la démarche (<n>)` holding the same table.

## How to get to it (user POV)

- `/admin/demarches/<id>/edit`, below the form: heading `Recommandations`.
- `/admin/recommandations/new?demarche_id=<id>` and `/admin/recommandations/<id>/edit`: the encart above the form. Admin only.

## Driving it with Capybara

`drive.rb recommandations-demarche`, mutating then undone. Démarche: the visible one with the most recommandations (41 on 2026-10-05); solution: the first public API it does not recommend yet.

- **Table.** Rows on the démarche page = `demarche.recommandations.count`.
- **Add.** `Ajouter une recommandation` → démarche selected, encart lists all its recommandations; save with `Ordre` 99 → stays on `/admin/recommandations/<id>/edit`, database count +1.
- **Context.** Open the accordion: table visible; `Voir la fiche <démarche>` opens the démarche, whose table shows the new row.
- **Undo.** Open the row, `Supprimer` → count back to its start.
- **Proof.** `tmp/verify/admin-recommandations-demarche/`, including `etroit-320` (no horizontal scroll).

## Gotchas

- Read-backs after a mutation go through `ActiveRecord::Base.uncached` (runner query cache).
- A run that fails midway leaves a recommandation with `ordre` 99 on that démarche: remove it before re-running, or the next run picks another solution.
