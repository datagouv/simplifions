# Supprimer une démarche et ses recommandations

Deleting a démarche from the administration removes its recommandations with it in one `DELETE` (`dependent: :delete_all`); the recommended solution stays.

## How to get to it (user POV)

- Dashboard `/admin` → link `Démarches` → row → `Supprimer`, confirm `Supprimer la ligne <id> ? Ses recommandations partent avec elle.`
- Admin only.

## Driving it with Capybara

Preconditions:

- Logged in (`Verify.login`).
- The drive creates its own démarche `Vérif verify-map <browser>` (not visible) and one recommandation towards the first non-private solution, through Active Record: never delete a real démarche.

- **Reach the table.** `click_link "Démarches"`. H1 `Démarches`, the row is listed.
- **Delete.** Within the row (`:xpath, "//tr[td[text()='<nom>']]"`), `accept_confirm { click_button "Supprimer" }`. Alert `Supprimé.`, row gone.
- **Read back.** `Demarche.where(nom:).count == 0`, `Recommandation.where(demarche_id:).count == 0`, the solution still exists.
- **Proof.** Screenshots before and after deletion, read-backs of both.

## Gotchas

- `bin/rails runner` runs the drive inside the executor, so the query cache is on: a read-back that repeats an earlier query returns the earlier answer. Read back after a mutation inside `ActiveRecord::Base.uncached`.
