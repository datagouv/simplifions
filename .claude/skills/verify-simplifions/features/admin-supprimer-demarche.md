# Supprimer depuis la fiche, en voyant ce qui part avec

Deleting a démarche from the administration removes its recommandations with it in one `DELETE` (`dependent: :delete_all`); the recommended solution stays. The confirmation names the row and counts what goes or changes with it; for an organisation, it names the solutions that would become private (it was their only `Public` operator).

## How to get to it (user POV)

- Dashboard `/admin` → link `Démarches` → row → `Modifier` → `Supprimer` below the form, confirm `Supprimer « <nom> » ? 1 recommandation sera supprimée.`
- Same button on the six other edit pages; an organisation's says `Ces solutions deviendront privées : <noms>.`
- Admin only.

## Driving it with Capybara

Preconditions:

- Logged in (`Verify.login`).
- The drive creates its own démarche `Vérif verify-map <browser>` (not visible) and one recommandation towards the first non-private solution, through Active Record: never delete a real démarche.

- **Reach the table.** `click_link "Démarches"`. H1 `Démarches`, the row is listed.
- **Delete.** Within the row (`:xpath, "//tr[td[text()='<nom>']]"`), `click_link "Modifier"`, then `accept_confirm("Supprimer « <nom> » ? 1 recommandation sera supprimée.") { click_button "Supprimer" }`. Alert `« <nom> » supprimé.`, row gone.
- **Read back.** `Demarche.where(nom:).count == 0`, `Recommandation.where(demarche_id:).count == 0`, the solution still exists.
- **Organisation, cancelled.** First organisation with `solutions_rendues_privees`: its edit page, `dismiss_confirm { click_button "Supprimer" }` returns the message, which lists those solutions' names; the organisation is still in base. Never accept on a real organisation.
- **Proof.** Screenshots before and after deletion and after the cancelled organisation, read-backs of all three.

## Gotchas

- `bin/rails runner` runs the drive inside the executor, so the query cache is on: a read-back that repeats an earlier query returns the earlier answer. Read back after a mutation inside `ActiveRecord::Base.uncached`.
