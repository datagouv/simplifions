# Historique d'une fiche

Every create, update and delete on the seven admin tables is kept by paper_trail (`versions` table) with its author: the admin's id, `Import Grist` (import job and `grist:import`) or `data.gouv` (data.gouv refresh). The `État et actions` column of an edit page says `Créée par … le …` or `Modifiée par … le …` (admin e-mail or import label) and links `Historique`, only when a version exists (rows untouched since deploy have none). `/admin/historique/<table>/<id>` lists the versions, newest first: one `h2` per version (`Modification par … le 07/10/2026 à 11:40`) and a table `Champ / Avant / Après` under the French label of each changed field. On a published démarche, solution or recommandation, each `Enregistrer` kept as a draft gets its own line, `Modification en brouillon par …`, with the fields it changed (before: the previous draft, else the published value); `Publier` gives `Publication du brouillon par …`, `Abandonner le brouillon` gives `Abandon du brouillon par …` (before: the draft, after: the published value). Habtm links and the image are not versioned.

## Sub-features

- `historique-colonne` `Créée par …` / `Modifiée par … le …` and link `Historique` in the column; on a démarche, in its state bar, and the link `Historique de la démarche` at the bottom of the fiche.
- `historique-sans-version` nothing said on a row without version (spec only).
- `historique-page` versions newest first, `Champ / Avant / Après`, no horizontal scroll at 375 px, `Retour à la fiche`.
- `historique-brouillon` lines `Modification en brouillon`, `Publication du brouillon`, `Abandon du brouillon` on the history page.
- `historique-data-gouv` author `data.gouv` for the data.gouv refresh (spec only).

## How to get to it (user POV)

- Dashboard `/admin` → `Démarches` → a row name → `Historique de la démarche` at the bottom of the fiche (a solution: column link and tab `Historique`; other tables: column `Historique`).
- Admin only.

## Driving it with Capybara

Drive: `features/admin-historique.rb` (SKILL.md § Drive).

The drive creates `Vérif verify-map <browser>` as `Import Grist`, renames it from the en-tête modal, reads the state bar and the history page, publishes it to read the draft lines on the history page, then deletes the démarche and its versions. Preconditions: logged in.

- **Created.** State bar: `Créée par Import Grist le …`.
- **Updated.** `Modifier l’en-tête`, rename, `Enregistrer`: state bar `Modifiée par verif@simplifions.local le …`; base versions `['Import Grist', <admin id>]`.
- **History.** `Historique de la démarche` → two `h2`, newest first; first row `Nom | <old> | <new>`.
- **Mobile.** 375 px: no horizontal scroll.
- **Back.** `Retour à la fiche` → the edit page.
- **Draft.** The drive publishes the démarche, renames it in the en-tête modal, `Enregistrer`, `Historique de la démarche`: first `h2` `Modification en brouillon par verif@simplifions.local le …`, first row `Nom | <published> | <draft>`.
- **Publication.** `Publier`: first `h2` `Publication du brouillon par …`, same row.
- **Abandon.** Rename back in the en-tête modal, `Enregistrer`, `Abandonner le brouillon` (confirm): first `h2` `Abandon du brouillon par …`, same row, then `Retour à la fiche`; base events end with `brouillon, publication, brouillon, abandon`.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-historique/`.

## Gotchas

- The dev database needs the `versions` migration (`bin/rails db:migrate`, new table only).
- Cleanup deletes the drive's versions by hand: a destroyed row keeps its versions.
