# La fiche démarche se lit comme la page publique

The edit page of a saved démarche shows it as the public page does: a state bar (`Publiée` / `Masquée`, draft badge, dates, `Prévisualiser`, `Abandonner le brouillon`, `Publier`; on a published démarche with a draft, these actions move into the box `À la publication, N changements partiront`, [admin-brouillon.md](admin-brouillon.md)), the en-tête (page address, icon, name, short description, publics), then the blocks `Contexte`, `Cadre juridique`, `Solutions recommandées` (one card per solution, with its `Données utiles (<n>)` and `Intégrations (<n>)`, [admin-recommandations-en-ligne.md](admin-recommandations-en-ligne.md)) and, under `Hors de la page publique`, `Title SEO`, `Mots-clés`, `Fournisseurs de services`, `Vocabulaires`. Each block has a `Modifier …` button that opens a DSFR modal with that block's fields only. `Enregistrer` saves (a draft on a published démarche), closes the modal and shows the block updated on the same page; a refused field keeps the modal open with the message under the field; `Annuler` or Escape closes it and puts the fields back (after a refusal, the fiche reloads with the saved values). `Historique de la démarche` (when a version exists), `Masquer la démarche` (published only) and `Supprimer la démarche` sit at the bottom. No tabs. A card's `Ajouter une intégration à <solution>` opens the filterable list of that solution's intégrations ([admin-liste-filtrable.md](admin-liste-filtrable.md)) in a modal like the others. A new démarche keeps the plain form.

## Sub-features

- `bloc-enregistre` `Modifier le contexte` → type → `Enregistrer`: modal closed, block shows the new text, base holds it.
- `bloc-annule` `Modifier l’en-tête` → type → Escape: modal closed, nothing saved, reopening shows the saved value.
- `integrations-choisies` a card's `Ajouter une intégration à <solution>` → filter, check one → `Enregistrer`: still on the démarche, the card lists it, base holds it.
- `bloc-refuse` `Modifier l’en-tête` → empty `Nom` → `Enregistrer`: 422, modal open again, `doit être rempli` under the field.

## How to get to it (user POV)

- Dashboard `/admin` → `Démarches` → click a démarche → `/admin/demarches/:id/edit`.
- Admin only.

## Driving it with Capybara

Drive: `features/admin-fiche-demarche.rb` (SKILL.md § Drive).

Preconditions: the drive creates a hidden démarche `Vérif fiche <browser>` (hidden: saves write directly) recommending, as a solution recommandée, the API with the most intégrations, deleted at the end.

- **Reach the fiche.** Open it from the list: H1 is its name, no `État et actions` column, a `Modifier le contexte` button.
- **Save a block.** `Modifier le contexte`, fill `Contexte`, `Enregistrer`: notice `« … » enregistré.`, no open modal, the `Contexte` block shows the text, base `contexte` holds it.
- **Cancel with Escape.** `Modifier l’en-tête`, fill `Nom`, Escape: modal closed, the fiche no longer counts as changed, base `nom` unchanged; reopen: `Nom` holds the saved name.
- **Choose intégrations.** The API's card says `Intégrations (0)`; its `Ajouter une intégration à <API>`, filter on the API's last intégration, check it, `Enregistrer`: notice, no open modal, URL `/admin/demarches/<id>/edit`, the card says `Intégrations (1)` and lists it, base `integration_ids` is that one.
- **Refused field.** `Modifier l’en-tête`, empty `Nom`, `Enregistrer`: the modal is open again with `doit être rempli`; `Annuler`: the fiche reloads with the saved values (`Nom` holds the saved name), and the breadcrumb `Démarches` leaves without a question.
- **Proof.** Screenshots `bloc-enregistre`, `integrations-choisies`, `refuse`, read-backs.

## Gotchas

- The modal opens with a DSFR transition: wait for `dialog[open]` before filling.
- On a published démarche the save goes to a draft: the drive uses a hidden one to read the base directly.
