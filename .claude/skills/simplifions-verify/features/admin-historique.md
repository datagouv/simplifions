# Historique d'une fiche

Every create, update and delete on the seven admin tables is kept by paper_trail (`versions` table) with its author: the admin's id, `Import Grist` (import job and `grist:import`) or `data.gouv` (data.gouv refresh). The `État et actions` column of an edit page says `Créée par … le …` or `Modifiée par … le …` (admin e-mail or import label) and links `Historique`, only when a version exists (rows untouched since deploy have none). `/admin/historique/<table>/<id>` lists the versions, newest first: one `h2` per version (`Modification par … le 07/10/2026 à 11:40`) and a table `Champ / Avant / Après` under the French label of each changed field. On a published démarche, solution or recommandation, each `Enregistrer` kept as a draft gets its own line, `Modification en brouillon par …`, with the fields it changed (before: the previous draft, else the published value); `Publier` gives `Publication du brouillon par …`, `Abandonner le brouillon` gives `Abandon du brouillon par …` (before: the draft, after: the published value). Habtm links and the image are not versioned.

## How to get to it (user POV)

- Dashboard `/admin` → `Démarches` → a row name → column `Historique`.
- Admin only.

## Driving it with Capybara

`drive.rb historique`. The drive creates `Vérif verify-map <browser>` as `Import Grist`, renames it from the form, reads the column and the history page, publishes it to read the draft lines in the `Historique` tab, then deletes the démarche and its versions.

- **Created.** Column: `Créée par Import Grist le …`.
- **Updated.** Rename, `Enregistrer`: column `Modifiée par verif@simplifions.local le …`; base versions `['Import Grist', <admin id>]`.
- **History.** `Historique` → two `h2`, newest first; first row `Nom | <old> | <new>`.
- **Mobile.** 375 px: no horizontal scroll.
- **Back.** `Retour à la fiche` → the edit page.
- **Draft.** The drive publishes the démarche, renames it, `Enregistrer`: tab `Historique`, first `h2` `Modification en brouillon par verif@simplifions.local le …`, first row `Nom | <published> | <draft>`.
- **Publication.** `Publier`: first `h2` `Publication du brouillon par …`, same row.
- **Abandon.** Rename back, `Enregistrer`, `Abandonner le brouillon` (confirm): first `h2` `Abandon du brouillon par …`, row `Nom | <draft> | <published>`; base events end with `brouillon, publication, brouillon, abandon`.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-historique/`.

## Gotchas

- The dev database needs the `versions` migration (`bin/rails db:migrate`, new table only).
- Cleanup deletes the drive's versions by hand: a destroyed row keeps its versions.
