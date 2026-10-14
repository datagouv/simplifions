# Historique d'une fiche

Every create, update and delete on the seven admin tables is kept by paper_trail (`versions` table) with its author: the admin's id, `Import Grist` (import job and `grist:import`) or `data.gouv` (data.gouv refresh). The `État et actions` column of an edit page says `Créée par … le …` or `Modifiée par … le …` (admin e-mail or import label) and links `Historique`, only when a version exists (rows untouched since deploy have none). `/admin/historique/<table>/<id>` lists the versions, newest first: one `h2` per version (`Modification par … le 07/10/2026 à 11:40`) and a table `Champ / Avant / Après` under the French label of each changed field. Habtm links and the image are not versioned.

## How to get to it (user POV)

- Dashboard `/admin` → `Démarches` → a row name → column `Historique`.
- Admin only.

## Driving it with Capybara

`drive.rb historique`. The drive creates `Vérif verify-map <browser>` as `Import Grist`, renames it from the form, reads the column and the history page, then deletes the démarche and its versions.

- **Created.** Column: `Créée par Import Grist le …`.
- **Updated.** Rename, `Enregistrer`: column `Modifiée par verif@simplifions.local le …`; base versions `['Import Grist', <admin id>]`.
- **History.** `Historique` → two `h2`, newest first; first row `Nom | <old> | <new>`.
- **Mobile.** 375 px: no horizontal scroll.
- **Back.** `Retour à la fiche` → the edit page.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-historique/`.

## Gotchas

- The dev database needs the `versions` migration (`bin/rails db:migrate`, new table only).
- Cleanup deletes the drive's versions by hand: a destroyed row keeps its versions.
