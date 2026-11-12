# Modifier les intégrations ligne à ligne dans la solution

A solution's integrations sit in three tabs, `API fournies (<n>)`, `API intégrées (<n>)` (the row edits the `API ou jeu de données`) and `Solutions qui l’intègrent (<n>)` (the row edits the `Solution`), each holding one table titled by an H2 of its name (panels `onglet-api-fournies-panneau`, `onglet-api-integrees-panneau`, `onglet-integratrices-panneau`); the solution itself is the fixed other side. `API fournies` is ordered by hand ([ordre-api-fournies.md](ordre-api-fournies.md)). Each row has the other solution's select, then a column `Statut` (at least 12rem, so the statut stays readable); in `Solutions qui l’intègrent` that column is `Type d’intégration (obligatoire) et statut`, `Type d’intégration` above `Statut`, since that tab lists both types. In `API fournies` and `API intégrées` the row has the tab's type (Fournie / Intégrée), set by the server whatever the request sends, with no type select. Each row has a button `Enregistrer l’intégration <libellé>`, a link `Modifier l’intégration <libellé>` to the integration's own page (its démarches are ticked there) and a trash button `Supprimer l’intégration <libellé>` (confirmation `… ?`, followed by `La suppression est immédiate, même pendant un brouillon : « Abandonner le brouillon » ne la remet pas.` when either solution of the integration is published; then `destroy!`, the row and its hidden forms (three on an `API fournies` row) removed by turbo-stream, focus on the message). A last blank row per table adds one (`Ajouter la nouvelle ligne de « API fournies »` / `… « API intégrées »` / `… « Solutions qui l’intègrent »`), with the tab's type in the first two, the type chosen in the third. A row saves alone, in place: message in `#message-integrations` (role=status, above the tab list), errors on the row (`fr-error-text`, `aria-describedby`), e.g. `Une solution ne peut pas s’intégrer elle-même`, or a démarche that leaves the rule when the other solution changes. No draft: integrations have none. The tables fit the page width from 1024 px up. `<n>` counts the tab's integrations (two types between the same pair are two rows), and follows a row added or deleted in place, in all three tabs, without a reload. A bouquet's `Solutions qui l’intègrent` tab also lists, read-only, each « Intégrée » intégration of one of its APIs as `<solution> — via <API>` with a `Voir la fiche` link to the API, where it is edited; `<n>` counts these lines too.

## Sub-features

- `integrations-ligne` a row saves alone with `Enregistrer l’intégration <libellé>`: `enregistré` in `#message-integrations`, fiche `Enregistrer` stays greyed.
- `integrations-erreur` a refused row keeps its error on the row (`… elle-même`), described by its button; nothing saved.
- `integrations-hors-regle` changing the other solution so that a démarche leaves the rule is refused on the row (spec only).
- `integrations-ajouter` the last blank row of `API intégrées` and of `Solutions qui l’intègrent` adds one, typed `Intégrée` by its tab in the first (no type select, message `… (intégrée) » enregistré`), then a blank row again; both tab counts +1 without a reload.
- `integrations-modifier` link `Modifier l’intégration <libellé>` to the integration's own page (spec only).
- `integrations-supprimer` trash `Supprimer l’intégration <libellé>`, confirmation, row gone, focus on `supprimé`, the tab counts back without a reload.
- `integrations-avertissement` the confirmation warns that deleting is immediate when either solution of the integration is published, from any tab (row trash; `Supprimer` of the intégration page, with the short `La suppression est immédiate.` since that page has no draft), not when both are masked.
- `integrations-largeur` the `API intégrées` and `Solutions qui l’intègrent` tables fit the page at 1280 and 1024 px, statut select readable.
- `integrations-bouquet` a bouquet lists read-only `<solution> — via <API>` lines with `Voir la fiche`, counted in `Solutions qui l’intègrent (<n>)`.

## How to get to it (user POV)

`/admin/solutions/<id>/edit`, tabs `API fournies`, `API intégrées`, `Solutions qui l’intègrent` (`?onglet=api-fournies|api-integrees|integratrices`). Admin only.

## Driving it with Capybara

Drive: `features/admin-integrations-en-ligne.rb` (SKILL.md § Drive).

Preconditions: logged in; the row part mutates then undoes, the bouquet part is read-only. The Warning step creates two masked solutions `Vérif verify-map <browser> A` and `… B` (API), the intégrations A → B and A → the first published API, deleted at the end.

Rows. Solution: the visible non-API one with the most integrations it makes; row: its first « Intégrée » one in `API intégrées`; added: the first API it does not integrate yet, and the first non-API solution that does not integrate it yet.

- **Row.** Change `Statut de l’intégration <libellé>`, fiche `Enregistrer` stays greyed; `Enregistrer l’intégration <libellé>` → `enregistré`, statut in base, still on the solution.
- **Error.** Blank `API intégrées` row (no `Type d’intégration` field) with the solution itself → `elle-même` on the row, button described by it, nothing created.
- **Add.** The API in `API intégrées` (no type to choose) → message `… (intégrée) » enregistré`, saved `consomme`; the other solution in `Solutions qui l’intègrent` (Fournie chosen) → a row each, blank rows again, counts in base +1 / +1, and without a reload the tabs read `API intégrées (<n>+1)` and `Solutions qui l’intègrent (<n>+1)`, `API fournies (<n>)` unchanged; type selects per tab `[0, 0, n]`.
- **Width.** At 1280 and 1024 px, each `.fr-table__content` of the `API intégrées` and `Solutions qui l’intègrent` tabs has `scrollWidth <= clientWidth`, the row's solution select is at least 150 px and its statut select at least 180 px.
- **Undo.** Each added row's trash: dismiss (confirmation with the warning, the solution being published; row and base kept), accept (row gone, `supprimé`, focus on `#message-integrations`); after both, without a reload, the three tabs read their first counts again; statut put back through the row.
- **Warning.** Published solution: its first row's trash in `API intégrées` and `Supprimer` of that integration's page (short form) end with the warning. Masked A → B: the row's trash in A's `API intégrées` and in B's `Solutions qui l’intègrent`, and `Supprimer` of its page, read `… ?` alone. Masked A → published API: the row's trash in A's `API intégrées` ends with the warning. Dismissed each time, all integrations still in base.
- **Proof.** `tmp/verify/admin-integrations-en-ligne/`, including `etroit-375`.

Bouquet, read-only: the solution with the most intégrations of its APIs (Bouquet API Entreprise, 202 on 2026-10-28).

- **Bouquet list.** `Solutions`, search its name, open its row: the fiche opens on the right, the open row of the left list is `aria-current`.
- **Bouquet tab.** Its fiche, `Solutions qui l’intègrent`: tab `Solutions qui l’intègrent (<own rows + lines via its APIs>)`, as many `— via` lines as `integrations_de_ses_api`.
- **Bouquet link.** The first line's `Voir la fiche`: opens the edit page of one of its APIs.
- **Bouquet proof.** `tmp/verify/admin-integrations-en-ligne/`, steps `bouquet-liste`, `bouquet-lignes-via` and `bouquet-fiche-via`.

## Gotchas

- Saves leave paper_trail versions on the row's integration (statut changed then restored).
- The drive's `ensure` deletes the added integrations and restores the statut if a step failed midway.
