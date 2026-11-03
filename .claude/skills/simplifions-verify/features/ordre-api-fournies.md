# Ranger les données et API fournies d'une solution

On a solution page, « Données et API fournies » lists the APIs and jeux de données it provides in the order the team set, unranked ones last by the title shown on the card (the data.gouv title, else the name). In the admin, the `API fournies (<n>)` tab of the solution lists the same rows in that order; the team moves a row with its drag handle or with the `Monter` / `Descendre` icon buttons, and each move saves at once. The first move renumbers every provided API 1..n. The integration's own page shows `Ordre : N` read-only. The Grist refresh keeps the order.

## Sub-features

- `tableau` the tab lists the provided APIs in the public order, one drag handle per row.
- `clavier` `Monter` / `Descendre` on a row: message `« <libellé> » déplacée en position N.`, focus stays on a button of that row (the other one when the row reaches an end).
- `glisser` dragging a row's handle to another place saves its new position.
- `lecture-seule` the integration page shows `Ordre : N` (or `aucun`) and `Ranger les API fournies de <solution>` opens the tab.

## How to get to it (user POV)

- Admin: `Solutions` → a solution → tab `API fournies (<n>)` (`?onglet=api-fournies`); or an API's integration page → `Ranger les API fournies de <solution>`. Admin only.
- Visitor: `/solutions/<slug>`, section `Données et API fournies`.

## Driving it with Capybara

Drive: `features/ordre-api-fournies.rb` (SKILL.md § Drive).

Preconditions: a visible solution providing at least five visible APIs on data.gouv (`bouquet-api-entreprise` in the Grist import), none ranked. Mutating then undone.

- **Avant.** Visit the solution with the most such APIs; read the card titles under `Données et API fournies`, one per visible provided API.
- **Tab.** Admin, tab `API fournies (<n>)`: h2 `API fournies`, rows in the same order as the database public order, a `[data-poignee]` on each row.
- **Keyboard.** `Monter l’intégration <libellé>` on the 5th row, Enter: `« <libellé> » déplacée en position 4.` in `#message-integrations`, database order swapped, ranks 1..n, focus on a `Monter` / `Descendre` button of that row.
- **Drag.** Drag the handle of the 4th row onto the handle of the 2nd (Capybara `drag_to`, else Selenium press/move/release): a message `déplacée en position N.` with N below 4, the table and the database show the row moved and the others unchanged.
- **Reload.** After a reload the tab lists the database order; the public page lists the cards in that order, different from **Avant**.
- **Read-only.** The moved integration's page: `Ordre : 2`, no `Ordre` field; `Ranger les API fournies de <solution>` opens the solution on the `API fournies` tab.
- **Undo.** Every integration's original `ordre` put back with `update_columns`; the public order equals **Avant**.
- **Proof.** `tmp/verify/ordre-api-fournies/` (`avant`, `onglet`, `clavier`, `glisser`, `rechargement`, `lecture-seule`, `defait`).

## Gotchas

- The first move rewrites `ordre` on every provided API of the solution: the drive restores the original values in `Undo` and again in its `ensure`.
- `drag_to` drops the row at the target's place as Sortable decides (it landed at position 1 over the 2nd row in Chrome), so the drive reads the resulting position from the database instead of assuming it.
- Each move leaves paper_trail versions on the integrations.
