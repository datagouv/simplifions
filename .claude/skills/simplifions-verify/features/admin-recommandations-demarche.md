# Gérer les recommandations depuis la démarche

A démarche's fiche shows its recommandations in two blocks, `Solutions recommandées (<n>)` as cards and `Données disponibles (<n>)` as a list, each edited in a window on the page (see [admin-recommandations-en-ligne.md](admin-recommandations-en-ligne.md)). A recommandation's own page stays at its address, `/admin/recommandations/<id>/edit`, with no link from the démarche. `/admin/recommandations/new?demarche_id=<id>` pre-selects the démarche. A recommandation's form opens on an encart: `Démarche : <nom>`, its description courte, `Voir la fiche <nom>`, and an accordion `Autres recommandations de la démarche (<n>)` holding a read-only table (Solution, Type de recommandation, Position, Visible, Modifié le).

## Sub-features

- `recos-demarche-blocs` the fiche shows every recommandation: a card under `Solutions recommandées`, or a line under `Données disponibles`.
- `recos-demarche-nouvelle` `/admin/recommandations/new?demarche_id=<id>` pre-selects the démarche.
- `recos-demarche-encart` a recommandation's form opens on `Démarche : <nom>`, `Voir la fiche <nom>`, accordion `Autres recommandations de la démarche (<n>)`.
- `recos-demarche-modifier` `/admin/recommandations/<id>/edit` still opens the recommandation, whose `Supprimer` removes it.

## How to get to it (user POV)

- `/admin/demarches/<id>/edit`, blocks `Solutions recommandées (<n>)` and `Données disponibles (<n>)`.
- `/admin/recommandations/new?demarche_id=<id>` and `/admin/recommandations/<id>/edit`: the encart above the form. Admin only.

## Driving it with Capybara

Drive: `features/admin-recommandations-demarche.rb` (SKILL.md § Drive).

Preconditions: logged in; mutating then undone. Démarche: the visible one with the most recommandations (41 on 2026-10-05); solution: the first public API it does not recommend yet.

- **Blocks.** Cards plus lines of `Données disponibles` on the démarche page = `demarche.recommandations.count`.
- **Add.** `/admin/recommandations/new?demarche_id=<id>` → démarche selected, encart lists all its recommandations; save as `Donnée utile` with `Position` 99 → stays on `/admin/recommandations/<id>/edit`, database count +1.
- **Context.** Open the accordion: table visible; `Voir la fiche <démarche>` opens the démarche, whose `Données disponibles` list the new one with position 99, and whose `Modifier les données utiles` window has its line.
- **Undo.** `/admin/recommandations/<id>/edit`, `Supprimer` → count back to its start.
- **Proof.** `tmp/verify/admin-recommandations-demarche/`, including `etroit-320` (no horizontal scroll).

## Gotchas

- Read-backs after a mutation go through `ActiveRecord::Base.uncached` (runner query cache).
- A run that fails midway leaves a recommandation with `ordre` 99 on that démarche: remove it before re-running, or the next run picks another solution.
