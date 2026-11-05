# La fiche démarche se lit comme la page publique

The edit page of a saved démarche shows it as the public page does: a state bar (`Publiée` / `Masquée`, draft badge, dates, `Prévisualiser`, `Abandonner le brouillon`, `Publier`), the en-tête (page address, icon, name, short description, publics) above the tabs, then in the `Fiche` tab the blocks `Contexte`, `Cadre juridique` and, under `Hors de la page publique`, `Title SEO`, `Mots-clés`, `Fournisseurs de services`, `Vocabulaires`. Each block has a `Modifier …` button that opens a DSFR modal with that block's fields only. `Enregistrer` saves (a draft on a published démarche), closes the modal and shows the block updated on the same page; a refused field keeps the modal open with the message under the field; `Annuler` or Escape closes it and puts the fields back. `Masquer la démarche` (published only) and `Supprimer la démarche` sit at the bottom. The `Intégrations` tab keeps its boxes and its own `Enregistrer`. A new démarche keeps the plain form.

## Sub-features

- `bloc-enregistre` `Modifier le contexte` → type → `Enregistrer`: modal closed, block shows the new text, base holds it.
- `bloc-annule` `Modifier l’en-tête` → type → Escape: modal closed, nothing saved, reopening shows the saved value.
- `bloc-refuse` `Modifier l’en-tête` → empty `Nom` → `Enregistrer`: 422, modal open again, `doit être rempli` under the field.

## How to get to it (user POV)

- Dashboard `/admin` → `Démarches` → click a démarche → `/admin/demarches/:id/edit`, tab `Fiche`.
- Admin only.

## Driving it with Capybara

Drive: `features/admin-fiche-demarche.rb` (SKILL.md § Drive).

Preconditions: the drive creates a hidden démarche `Vérif fiche <browser>` (hidden: saves write directly), deleted at the end.

- **Reach the fiche.** Open it from the list: H1 is its name, no `État et actions` column, a `Modifier le contexte` button.
- **Save a block.** `Modifier le contexte`, fill `Contexte`, `Enregistrer`: notice `« … » enregistré.`, no open modal, the `Contexte` block shows the text, base `contexte` holds it.
- **Cancel with Escape.** `Modifier l’en-tête`, fill `Nom`, Escape: modal closed, base `nom` unchanged; reopen: `Nom` holds the saved name.
- **Refused field.** `Modifier l’en-tête`, empty `Nom`, `Enregistrer`: the modal is open again with `doit être rempli`; `Annuler`, then the breadcrumb `Démarches` asks `Quitter sans enregistrer les modifications ?` (the refused entry is still in the form), accept.
- **Proof.** Screenshots `bloc-enregistre`, `refuse`, read-backs.

## Gotchas

- The modal opens with a DSFR transition: wait for `dialog[open]` before filling.
- On a published démarche the save goes to a draft: the drive uses a hidden one to read the base directly.
