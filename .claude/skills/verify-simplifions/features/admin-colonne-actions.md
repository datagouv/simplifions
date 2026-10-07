# Colonne d'état et d'actions

Every admin `new` and `edit` page (seven tables) puts an `État et actions` column (`aside`) right of the fields, sticky while scrolling from 768 px up, under the H1 and before the fields below. It holds the state (`Publiée` / `Masquée`, démarches, solutions, recommandations), `Création` and `Dernière modification` (`cree_le` / `modifie_le`, else `created_at` / `updated_at`), `Identifiant Grist : …`, then `Enregistrer`, `Publier` or `Masquer`, `Annuler`, `Supprimer`, and `Voir la page publique` for a visible démarche or solution with a slug. `Enregistrer` never changes the state; `Publier` (`Masquer`) saves the fields with `visible` true (false). The form keeps no button and no `Visible sur simplifions` box; the column buttons reach it through `form="formulaire-fiche"`.

## How to get to it (user POV)

- Dashboard `/admin` → `Démarches` → a row name. Démarche 1 (`Marchés publics | Dépôt…`) is about 21 000 px tall: scroll, the column stays in view.
- Admin only.

## Driving it with Capybara

`drive.rb colonne`. Preconditions: logged in, catalogue imported (démarche 1 published). The drive creates its own démarche `Vérif verify-map <browser>` (slug `verif-verify-map-<browser>`, not visible) and deletes it; it saves nothing on démarche 1.

- **Sticky.** Démarche 1, scroll to y = 14 000: `Enregistrer` inside the viewport and the topmost element at its centre.
- **Enter.** Own démarche, type in `Nom`, press Enter: `« … » enregistré.`, base `visible` still false, column `Masquée` (Enregistrer is the form's default button, before Publier in the DOM).
- **Publish.** Scroll, `Publier`: `Publiée`, base `visible` true and the typed name saved. `Voir la page publique` opens `/demarches/<slug>` in a new window.
- **Hide.** `Masquer`: `Masquée`, base `visible` false.
- **Mobile.** Window 375 px: no horizontal scroll, the column above the form.
- **Delete.** `Supprimer` from the column, `Supprimer « … » ?`, `« … » supprimé.`
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-colonne-actions/`.

## Gotchas

- DSFR badges are uppercase by CSS: match `Publiée` / `Masquée` case-insensitively.
- The recommandation form also has an `aside` (the démarche callout): select `aside.admin-panneau` or `aside.fr-callout`.
- `position: sticky` needs no `overflow` on an ancestor; none in the admin layout today.
