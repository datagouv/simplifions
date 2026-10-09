# Modifier les intégrations ligne à ligne dans la solution

A solution's `Intégrations (<n>)` tab holds two editable tables, `Ce qu’elle intègre` (the row edits the `API ou jeu de données`) and `Solutions qui l’intègrent` (the row edits the `Solution`); the solution itself is the fixed other side. Each row has three selects: the other solution, then `Type d’intégration` above `Statut` in one column (at least 12rem, so the statut stays readable), a button `Enregistrer l’intégration <libellé>`, a link `Modifier l’intégration <libellé>` to the integration's own page (its démarches are ticked there) and a trash button `Supprimer l’intégration <libellé>` (confirmation `… ?`, then `destroy!`, the row and its two hidden forms removed by turbo-stream, focus on the message). A last blank row per table adds one (`Ajouter la nouvelle ligne de « Ce qu’elle intègre »` / `… « Solutions qui l’intègrent »`). A row saves alone, in place: message in `#message-integrations` (role=status), errors on the row (`fr-error-text`, `aria-describedby`), e.g. `Une solution ne peut pas s’intégrer elle-même`, or a démarche that leaves the rule when the other solution changes. No draft: integrations have none. The tables fit the page width from 1024 px up. `<n>` counts integrations (two types between the same pair are two rows).

## How to get to it (user POV)

`/admin/solutions/<id>/edit`, tab `Intégrations (<n>)`. Admin only.

## Driving it with Capybara

`drive.rb integrations-en-ligne`, mutating then undone. Solution: the visible non-API one with the most integrations it makes; row: its first one in `Ce qu’elle intègre`; added: the first API it does not integrate yet, and the first non-API solution that does not integrate it yet.

- **Row.** Change `Statut de l’intégration <libellé>`, fiche `Enregistrer` stays greyed; `Enregistrer l’intégration <libellé>` → `enregistré`, statut in base, still on the solution.
- **Error.** Blank `Ce qu’elle intègre` row with the solution itself → `elle-même` on the row, button described by it, nothing created.
- **Add.** The API in `Ce qu’elle intègre` (Intégrée), the other solution in `Solutions qui l’intègrent` (Fournie) → a row each, blank rows again, counts +1 / +1.
- **Width.** At 1280 and 1024 px, each `.fr-table__content` of the tab has `scrollWidth <= clientWidth`, the row's solution select is at least 150 px and its statut select at least 180 px.
- **Undo.** Each added row's trash: dismiss (row and base kept), accept (row gone, `supprimé`, focus on `#message-integrations`); statut put back through the row.
- **Proof.** `tmp/verify/admin-integrations-en-ligne/`, including `etroit-375`.

## Gotchas

- Saves leave paper_trail versions on the row's integration (statut changed then restored).
- The drive's `ensure` deletes the added integrations and restores the statut if a step failed midway.
