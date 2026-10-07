# Éditer une table du catalogue (vocabulaires)

Admins add, edit and delete rows of every catalogue table from plain DSFR forms; vocabulaires is the smallest table and the drive for all seven.

## Sub-features

- `admin-liste` table `Id`, `Nom` (the name links to the read page `/admin/vocabulaires/<id>`, no `Supprimer`), an `Ajouter` button; search and pagination in `admin-listes.md`.
- `admin-lire` read page: H1 = the name, `dt`/`dd` Slug, Catégorie, Démarches, Solutions; button `Modifier`.
- `admin-creer` form `Nom`, `Slug`, `Catégorie`, `Grist`, checkboxes for linked démarches and solutions.
- `admin-modifier` same form on `/admin/vocabulaires/<id>/edit`, H1 = the row's name, breadcrumb `Administration › Vocabulaires › <nom>`, tab title `<nom> — Modifier — Vocabulaire | Simplifions.data.gouv.fr`, prefixed with the notice right after a save (`« <nom> » enregistré. — <nom> — …`) so a screen reader announces it.
- `admin-enregistrer` create and update stay on the row's edit page with `« <nom> » enregistré.` (every table, name or `libelle` for recommandations and intégrations); vocabulaires and fournisseurs de services land on their read page instead.
- `admin-supprimer` on the edit page, in the `État et actions` column: confirm dialog `Supprimer « <nom> » ?` followed by what goes or is detached with it (`2 démarches en seront détachées.`), then `« <nom> » supprimé.`

## How to get to it (user POV)

- Dashboard `/admin` → link `Vocabulaires` (also Démarches, Solutions, Recommandations, Intégrations, Organisations, Fournisseurs de services).
- URL `/admin/vocabulaires`, `/admin/vocabulaires/new`.
- Admin only.

## Driving it with Capybara

Preconditions:

- Logged in (`Verify.login`).
- No row named `Vérif verify-map <browser>` exists.

- **Reach the table.** `click_link "Vocabulaires"`. H1 `Vocabulaires`.
- **Add.** `click_link "Ajouter"`, `fill_in "Nom"`, `fill_in "Slug"`, `select "Usager", from: "Catégorie"`, `click_button "Enregistrer"`. Alert `« <nom> » enregistré.`, URL `/admin/vocabulaires/<id>` (read page: Slug, then `Catégorie` `Usager`), H1 `<nom>`, breadcrumb `Administration › Vocabulaires › <nom>` (items read with `visible: :all`, the list sits in a collapsed `fr-collapse` on narrow screens).
- **Read back.** `Vocabulaire.find_by!(nom:)` returns the row with `categorie == "usager"`.
- **Rename.** `click_link "Modifier"`, `fill_in "Nom"` with `<nom> modifié`, save: `« <nom> modifié » enregistré.`, back on the read page, H1 follows. Rename back the same way.
- **Delete.** `click_link "Vocabulaires"` (breadcrumb). No `Supprimer` button on the list. `ouvrir_depuis_la_liste` (search `<nom>`, click the name), `click_link "Modifier"`, then `accept_confirm("Supprimer « <nom> » ?") { click_button "Supprimer" }`. Alert `« <nom> » supprimé.`, row gone, `Vocabulaire.where(nom:).count == 0`.
- **Proof.** Screenshots after creation and deletion, both read-backs.

## Gotchas

- The delete goes through a Turbo confirm: `accept_confirm` works in both browsers.
- Deleting a solution or a démarche cascades to its recommendations: never drive delete on those tables with real rows.
