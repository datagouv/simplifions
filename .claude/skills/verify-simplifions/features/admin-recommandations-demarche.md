# Gérer les recommandations depuis la démarche

A démarche's admin form lists, in its `Recommandations (<n>)` tab, its recommandations as editable rows (see [admin-recommandations-en-ligne.md](admin-recommandations-en-ligne.md)), sorted by type then ordre, each with `Modifier la recommandation <solution>` linking to the recommandation, then a blank row, and offers `Ajouter une recommandation` with the démarche pre-selected. A recommandation's form opens on an encart: `Démarche : <nom>`, its description courte, `Voir la fiche <nom>`, and an accordion `Autres recommandations de la démarche (<n>)` holding a read-only table (Solution, Type de recommandation, Ordre, Visible, Modifié le).

## How to get to it (user POV)

- `/admin/demarches/<id>/edit`, tab `Recommandations (<n>)`.
- `/admin/recommandations/new?demarche_id=<id>` and `/admin/recommandations/<id>/edit`: the encart above the form. Admin only.

## Driving it with Capybara

`drive.rb recommandations-demarche`, mutating then undone. Démarche: the visible one with the most recommandations (41 on 2026-10-05); solution: the first public API it does not recommend yet.

- **Table.** Rows on the démarche page = `demarche.recommandations.count` + the blank row.
- **Add.** `Ajouter une recommandation` → démarche selected, encart lists all its recommandations; save with `Ordre` 99 → stays on `/admin/recommandations/<id>/edit`, database count +1.
- **Context.** Open the accordion: table visible; `Voir la fiche <démarche>` opens the démarche, whose table shows the new row (`tr#recommandation_<id>`, solution selected).
- **Undo.** `Modifier la recommandation <solution>`, `Supprimer` → count back to its start.
- **Proof.** `tmp/verify/admin-recommandations-demarche/`, including `etroit-320` (no horizontal scroll).

## Gotchas

- Read-backs after a mutation go through `ActiveRecord::Base.uncached` (runner query cache).
- A run that fails midway leaves a recommandation with `ordre` 99 on that démarche: remove it before re-running, or the next run picks another solution.
