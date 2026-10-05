# Éditer une table du catalogue (vocabulaires)

Admins add, edit and delete rows of every catalogue table from plain DSFR forms; vocabulaires is the smallest table and the drive for all seven.

## Sub-features

- `admin-liste` table `Id`, `Nom`, `Actions` (a `Modifier` button per row, no `Supprimer`) and an `Ajouter` button.
- `admin-creer` form `Nom`, `Slug`, `Categorie`, `Grist`, checkboxes for linked démarches and solutions.
- `admin-modifier` same form on `/admin/vocabulaires/<id>/edit`.
- `admin-supprimer` on the edit page, below the form: confirm dialog `Supprimer « <nom> » ?` followed by what goes or is detached with it (`2 démarches en seront détachées.`), then `« <nom> » supprimé.`

## How to get to it (user POV)

- Dashboard `/admin` → link `Vocabulaires` (also Démarches, Solutions, Recommandations, Intégrations, Organisations, Types d'acteurs).
- URL `/admin/vocabulaires`, `/admin/vocabulaires/new`.
- Admin only.

## Driving it with Capybara

Preconditions:

- Logged in (`Verify.login`).
- No row named `Vérif verify-map <browser>` exists.

- **Reach the table.** `click_link "Vocabulaires"`. H1 `Vocabulaires`.
- **Add.** `click_link "Ajouter"`, `fill_in "Nom"`, `fill_in "Slug"`, `select "usager", from: "Categorie"`, `click_button "Enregistrer"`. Alert `Enregistré.`, the row appears in the table.
- **Read back.** `Vocabulaire.find_by!(nom:)` returns the row with `categorie == "usager"`.
- **Delete.** No `Supprimer` button on the list. Within the row (`:xpath, "//tr[td[text()='<nom>']]"`), `click_link "Modifier"`, then `accept_confirm("Supprimer « <nom> » ?") { click_button "Supprimer" }`. Alert `« <nom> » supprimé.`, row gone, `Vocabulaire.where(nom:).count == 0`.
- **Proof.** Screenshots after creation and deletion, both read-backs.

## Gotchas

- `Categorie` label has no accent (it is the raw attribute name); `select` by that spelling.
- The delete goes through a Turbo confirm: `accept_confirm` works in both browsers.
- Deleting a solution or a démarche cascades to its recommendations: never drive delete on those tables with real rows.
