# La fiche démarche se modifie sur place

The edit page of a saved démarche puts the `État et actions` column on the left, like the other admin fiches ([admin-colonne-actions.md](admin-colonne-actions.md)): state (`Publiée` / `Masquée` with `Publier` or `Masquer`), `Voir la page publique` or the page address, the box `Modifications` (on a published démarche with a draft: draft badge, `Prévisualiser le brouillon`, the box `À la publication, N changements partiront`, `Publier le brouillon`, `Abandonner le brouillon`, [admin-brouillon.md](admin-brouillon.md)) with `Enregistrer`, the dates and `Historique`, then `Supprimer cette démarche`. On the right, the fields themselves, in one form: `Icône du titre` and `Nom` on one line, `Title SEO`, `Slug` (locked behind `Modifier le slug`), `Description courte`, `Démarche gérée par :` beside `Démarche à destination de :`, the vocabulaires `Catégorie de solution` and `Type de simplification`, `Contexte`, `Cadre juridique`, `Mots-clés`, then `Solutions recommandées` (one card per solution, with its `Données utiles (<n>)` and `Intégrations (<n>)`, [admin-recommandations-en-ligne.md](admin-recommandations-en-ligne.md)). The column's `Enregistrer` saves the fields (a draft on a published démarche); a refused field shows its message under the field and the fiche still counts as changed. No tabs. A card's `Ajouter une intégration à <solution>` opens the filterable list of that solution's intégrations ([admin-liste-filtrable.md](admin-liste-filtrable.md)) in a modal whose `Enregistrer` saves at once. A new démarche keeps the plain form.

## Sub-features

- `champ-enregistre` type in `Contexte` → the column's `Enregistrer`: notice, the field shows the new text, base holds it.
- `integrations-choisies` a card's `Ajouter une intégration à <solution>` → filter, check one → `Enregistrer`: still on the démarche, the card lists it, base holds it.
- `champ-refuse` empty `Nom` → `Enregistrer`: 422, `doit être rempli` under the field, leaving asks `Quitter sans enregistrer les modifications ?`.

## How to get to it (user POV)

- Dashboard `/admin` → `Démarches` → click a démarche → `/admin/demarches/:id/edit`.
- Admin only.

## Driving it with Capybara

Drive: `features/admin-fiche-demarche.rb` (SKILL.md § Drive).

Preconditions: the drive creates a hidden démarche `Vérif fiche <browser>` (hidden: saves write directly) recommending, as a solution recommandée, the API with the most intégrations, deleted at the end.

- **Reach the fiche.** Open it from the list: H1 is its name, the `État et actions` column, a `Contexte` field.
- **Save a field.** Fill `Contexte`, the column's `Enregistrer`: notice `« … » enregistré.`, `Contexte` holds the text, base `contexte` holds it.
- **Choose intégrations.** The API's card says `Intégrations (0)`; its `Ajouter une intégration à <API>`, filter on the API's last intégration, check it, `Enregistrer`: notice, no open modal, URL `/admin/demarches/<id>/edit`, the card says `Intégrations (1)` and lists it, base `integration_ids` is that one.
- **Refused field.** Empty `Nom`, `Enregistrer`: `doit être rempli` under the field, base `nom` unchanged; the breadcrumb `Démarches` asks `Quitter sans enregistrer les modifications ?`, accepted: back on `Démarches`.
- **Proof.** Screenshots `champ-enregistre`, `integrations-choisies`, `refuse`, read-backs.

## Gotchas

- The intégrations modal opens with a DSFR transition: wait for `dialog[open]` before filling.
- On a published démarche the save goes to a draft: the drive uses a hidden one to read the base directly.
