# Formulaire solution adapté à sa catégorie

A new solution starts with its catégorie alone (radios, `Continuer`); its form then shows only the fields of that catégorie: for `API` or `Jeu de données` the empty fiche fields (Slug, Titre SEO, Site internet, URL de demande d’accès, Image principale, Légende de l’image, Description courte, Cette solution permet / ne permet pas) are hidden (`fr-hidden`) and disabled. The catégorie reads as text (`Catégorie de solution : …`); `Changer de catégorie` opens a modal where each catégorie says what it erases (`Efface : …` or `Rien n’est effacé.`) and `Changer et enregistrer` saves the form with the new catégorie, keeping the common fields. A published solution cannot become `API` or `Jeu de données`: those radios are disabled, the hint says to mask it first. The current image is shown (alt = légende) with a `Retirer l’image` box and the hint `Formats acceptés : png, jpg, webp`. A private solution carries a `Privée` badge under its H1.

## Sub-features

- `formulaire-solution-premiere-etape` the catégorie alone first, then the form of that catégorie; the left list's search and `État` filter carried through `Continuer` and the save.
- `formulaire-solution-categorie` `Changer de catégorie` modal: what each catégorie erases, `Changer et enregistrer`, refused for a published solution.
- `formulaire-solution-image` current image (alt = légende), `Retirer l’image`, hint `Formats acceptés : png, jpg, webp`.
- `formulaire-solution-privee` `Privée` badge under the H1.

## How to get to it (user POV)

- `/admin/solutions/new` (`Ajouter une solution`), `/admin/solutions/<id>/edit` and `/admin/solutions`. Admin only.

## Driving it with Capybara

Drive: `features/admin-formulaire-solution.rb` (SKILL.md § Drive).

Preconditions: logged in; the drive works on a solution it creates (`Vérif verify-map <browser>`, Brique technique, image + légende, no organisation) and the one it adds (`… ajoutée`), and deletes both.

- **Privée.** Open the solution from the left list: badge under the H1.
- **Image.** Preview alt = légende, hint lists the formats.
- **Première étape.** `/admin/solutions/new`: no form fields, the catégorie radios; `Continuer` with none chosen → `Choisissez une catégorie.`; `API` then `Continuer` → `Catégorie de solution : API`, Description courte hidden and disabled; without typing anything, `Changer de catégorie`, `Logiciel métier`, `Changer et enregistrer` → the form comes back with `Catégorie de solution : Logiciel métier` and `Nom doit être rempli`, nothing created.
- **Filtres gardés.** From `/admin/solutions?q=verify-map&etat=masquees`, `Ajouter une solution`, `Brique technique`, `Continuer` → URL and left list keep `q` and `etat`; type a Nom, `Enregistrer` → the redirect keeps them too, the row exists in the database.
- **Catégorie.** On the solution: `Changer de catégorie` → the modal says `Efface : …` under `API`, `Rien n’est effacé.` under `Logiciel métier`; `Annuler` closes it, nothing changes.
- **Publiée.** The same solution published (row set visible by the drive): `API` and `Jeu de données` disabled, hint `Masquez d’abord la solution…`.
- **One save.** Back to masked, `Changer de catégorie`, `API`, `Changer et enregistrer` → database: catégorie api, name kept, no légende, no image; page `Catégorie de solution : API`.
- **Proof.** `tmp/verify/admin-formulaire-solution/`, including `etroit-320`.

## Gotchas

- Read-backs after a mutation go through `ActiveRecord::Base.uncached`.
- A failed run leaves the `Vérif verify-map` solution: the drive deletes it in `ensure`.
