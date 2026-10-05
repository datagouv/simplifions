# Dates de création et de modification tenues seules

The administration dates a démarche, a solution or a recommandation by itself: `cree_le` and `modifie_le` at creation, `modifie_le` at every save. The forms no longer offer the two fields. The Grist import and the data.gouv refresh keep the Grist dates (they do not go through the admin controllers).

## How to get to it (user POV)

- `/admin/demarches/new`, `/admin/solutions/new`, `/admin/recommandations/new` and their `edit`: no `Cree le` / `Modifie le` field.
- The dates show on the public pages (`Mis à jour le`) and in `sitemap.xml` (`lastmod`).

## Driving it with Capybara

`drive.rb dates`. Preconditions: logged in. The drive creates its own démarche `Vérif verify-map <browser>` (not visible) and deletes it.

- **Create.** `/admin/demarches/new`: no input named `demarche[cree_le]` or `demarche[modifie_le]`. Fill `Nom`, save: `Enregistré.`, read back `cree_le` within the last minute and `modifie_le` set.
- **Edit.** Rename to `<nom> modifiée`, save: `modifie_le` later than the creation, `cree_le` unchanged.
- **Delete.** From the list row, `Supprimer`, `Supprimé.`, read back 0 rows.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-dates/`.

## Gotchas

- Read back the created row inside `ActiveRecord::Base.uncached` (runner query cache).
- Solutions and recommandations follow the same code path; the request specs (`spec/requests/admin/crud_spec.rb`) cover all three.
