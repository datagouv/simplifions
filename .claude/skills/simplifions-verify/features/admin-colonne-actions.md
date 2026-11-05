# Colonne d'état et d'actions

Every admin `new` and `edit` page (seven tables), except the edit page of a démarche, puts an `État et actions` column (`aside`) right of the fields, sticky while scrolling from 768 px up, under the H1 and before the fields below. It holds the state (`Publiée` / `Masquée`, démarches, solutions, recommandations), `Création` and `Dernière modification` (`cree_le` / `modifie_le`, else `created_at` / `updated_at`), `Identifiant Grist : …`, then `Enregistrer`, `Publier` or `Masquer`, `Annuler`, `Supprimer`, `Voir la page publique` for a visible démarche or solution with a slug, and `Prévisualiser` while a draft exists ([admin-previsualisation.md](admin-previsualisation.md)). `Enregistrer` is disabled until a named field changes (enabled from the start on a form re-rendered with errors, and always without JavaScript); `Publier` / `Masquer` are never disabled. `Enregistrer` never changes the state; `Publier` (`Masquer`) saves the fields with `visible` true (false). The edit page of a démarche has no column: its state bar, its blocks and its bottom buttons replace it ([admin-fiche-demarche.md](admin-fiche-demarche.md)). A donnée utile's page shows neither ([admin-brouillon.md](admin-brouillon.md)). On a published démarche or solution both `Publier` and `Masquer` show, and `Enregistrer` keeps a draft ([admin-brouillon.md](admin-brouillon.md)). The form keeps no button and no `Visible sur simplifions` box; the column buttons reach it through `form="formulaire-fiche"`.

## Sub-features

- `colonne-collante` the `État et actions` column stays in view while scrolling; above the form at 375 px.
- `colonne-etat` badge `Publiée` / `Masquée`.
- `colonne-dates-grist` `Création`, `Dernière modification`, `Identifiant Grist : …` (spec only).
- `colonne-enregistrer` `Enregistrer` disabled until a field changes, enabled on a refused form; Enter saves without changing the state.
- `colonne-publier-masquer` `Publier` / `Masquer` save the fields and set the state; `Voir la page publique` opens the public page.
- `colonne-supprimer` `Supprimer` from the column, after the confirm `Supprimer « … » ?`.

## How to get to it (user POV)

- Dashboard `/admin` → `Solutions` → a row name. The published solution with the most content has the tallest fiche: scroll, the column stays in view.
- Admin only.

## Driving it with Capybara

Drive: `features/admin-colonne-actions.rb` (SKILL.md § Drive).

Preconditions: logged in, catalogue imported (published solutions). The drive creates its own solution `Vérif verify-map <browser>` (slug `verif-verify-map-<browser>`, not visible) and deletes it; it saves nothing on the catalogue solution.

- **Sticky.** The published solution with the most content, scroll to the end of the form, just above the footer: `Enregistrer` inside the viewport and the topmost element at its centre.
- **Greyed.** Own solution opened: `Enregistrer` disabled, `Publier` enabled; type in `Nom`: `Enregistrer` enabled.
- **Enter.** Own solution, type in `Nom`, press Enter: `« … » enregistré.`, base `visible` still false, column `Masquée` (Enregistrer is the form's default button, before Publier in the DOM).
- **Errors.** Back on the saved fiche `Enregistrer` is disabled again; empty `Nom`, `Enregistrer`: `Nom doit être rempli` and `Enregistrer` enabled without typing.
- **Publish.** Scroll, `Publier`: `Publiée`, base `visible` true and the typed name saved. `Voir la page publique` opens `/solutions/<slug>` in a new window.
- **Hide.** `Masquer`: `Masquée`, base `visible` false.
- **Mobile.** Window 375 px: no horizontal scroll, the column above the form.
- **Delete.** `Supprimer` from the column, `Supprimer « … » ?`, `« … » supprimé.`
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-colonne-actions/`.

## Gotchas

- DSFR badges are uppercase by CSS: match `Publiée` / `Masquée` case-insensitively.
- The recommandation form also has an `aside` (the démarche callout): select `aside.admin-panneau` or `aside.fr-callout`.
- `position: sticky` needs no `overflow` on an ancestor; none in the admin layout today.
- Enter in an unchanged form submits nothing: the default button (`Enregistrer`) is disabled. Find it with `find_button("Enregistrer", disabled: true)` until a field is typed in.
