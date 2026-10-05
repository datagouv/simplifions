# Éditer une table du catalogue (vocabulaires)

Admins add, edit and delete rows of every catalogue table from plain DSFR forms; vocabulaires is the smallest table and the drive for all seven.

## Sub-features

- `admin-liste` table `Id`, `Nom` (the name links to the edit page, no `Supprimer`), an `Ajouter` button; search and pagination in `admin-listes.md`.
- `admin-creer` form `Nom`, `Slug`, `Catégorie`, `Grist`, checkboxes for linked démarches and solutions.
- `admin-modifier` same form on `/admin/vocabulaires/<id>/edit`, H1 = the row's name, breadcrumb `Administration › Vocabulaires › <nom>`, tab title `<nom> — Modifier — Vocabulaire | Simplifions.data.gouv.fr`, prefixed with the notice right after a save (`« <nom> » enregistré. — <nom> — …`) so a screen reader announces it.
- `admin-enregistrer` create and update stay on the row's edit page with `« <nom> » enregistré.` (every table, name or `libelle` for recommandations and intégrations).
- `admin-supprimer` on the edit page, below the form: confirm dialog `Supprimer « <nom> » ?` followed by what goes or is detached with it (`2 démarches en seront détachées.`), then `« <nom> » supprimé.`

## How to get to it (user POV)

- Dashboard `/admin` → link `Vocabulaires` (also Démarches, Solutions, Recommandations, Intégrations, Organisations, Fournisseurs de services).
- URL `/admin/vocabulaires`, `/admin/vocabulaires/new`.
- Admin only.

## Driving it with Capybara

Preconditions:

- Logged in (`Verify.login`).
- No row named `Vérif verify-map <browser>` exists.

- **Reach the table.** `click_link "Vocabulaires"`. H1 `Vocabulaires`.
- **Add.** `click_link "Ajouter"`, `fill_in "Nom"`, `fill_in "Slug"`, `select "Usager", from: "Catégorie"`, `click_button "Enregistrer"`. Alert `« <nom> » enregistré.`, URL `/admin/vocabulaires/<id>/edit`, H1 `<nom>`, breadcrumb `Administration › Vocabulaires › <nom>` (items read with `visible: :all`, the list sits in a collapsed `fr-collapse` on narrow screens).
- **Read back.** `Vocabulaire.find_by!(nom:)` returns the row with `categorie == "usager"`.
- **Rename.** On the same page, `fill_in "Nom"` with `<nom> modifié`, save: `« <nom> modifié » enregistré.`, still on the edit page, H1 follows. Rename back.
- **Delete.** `click_link "Vocabulaires"` (breadcrumb). No `Supprimer` button on the list. `ouvrir_depuis_la_liste` (search `<nom>`, click the name), then `accept_confirm("Supprimer « <nom> » ?") { click_button "Supprimer" }`. Alert `« <nom> » supprimé.`, row gone, `Vocabulaire.where(nom:).count == 0`.
- **Proof.** Screenshots after creation and deletion, both read-backs.

## Gotchas

- The delete goes through a Turbo confirm: `accept_confirm` works in both browsers.
- Deleting a solution or a démarche cascades to its recommendations: never drive delete on those tables with real rows.
