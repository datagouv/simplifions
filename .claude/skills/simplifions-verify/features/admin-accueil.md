# Reprendre son travail depuis l'accueil de l'admin

`/admin` greets with `Bonjour` and shows what waits: `À reprendre` lists every démarche and solution with a draft, the most recent first, each with its type, the draft date, its name linking to its fiche and a one-line summary of what changed (product labels, `Adresse de la page` for the slug, then for a démarche its solutions recommandées and données utiles added or changed). `Dernières modifications` lists the last change of the ten most recently changed fiches, all tables mixed: type, name (no link once deleted; a recommandation deleted with its démarche keeps the démarche's name), `Ajoutée` / `Modifiée` / `Supprimée`, date. On the right, `Catalogue` counts each table (with the published ones for démarches and solutions) and `Import depuis Grist et data.gouv` keeps the import button and its state under a warning box.

## Sub-features

- `accueil-a-reprendre` drafts, newest first, summary of the changed fields; `Aucun brouillon en cours.` without one.
- `accueil-dernieres-modifications` table of the last change of each fiche, ten rows.
- `accueil-catalogue` counts linking to each list.
- `accueil-import` warning box `L’import remplace les modifications faites ici par le contenu du Grist et supprime les fiches créées ici.` above the import button ([rafraichissement-admin.md](rafraichissement-admin.md)).

## How to get to it (user POV)

- After login, or header link `Administration` → `/admin`. Admin only.

## Driving it with Capybara

Drive: `features/admin-accueil.rb` (SKILL.md § Drive).

Preconditions: logged in. The drive creates a published démarche `Vérif verify-map <browser>`, saves a draft of it that changes `Contexte` and the slug, creates and deletes a vocabulaire of the same name, and deletes the démarche at the end.

- **Catalogue.** `/admin`: H1 `Bonjour`; the `Catalogue` box reads `Démarches <n> · <p> publiées` and the other counts, each equal to the database count.
- **À reprendre.** The first item of `À reprendre` is the drive's démarche: `Démarche · brouillon du <today>`, its name, `Contexte et adresse de la page modifiés`; its link opens `/admin/demarches/<id>/edit`.
- **Dernières modifications.** Back on `/admin`: first row `Vocabulaire`, the drive's name, `Supprimé`, no link; second row `Démarche`, the drive's name as a link, `Modifiée`.
- **Import.** The `Import depuis Grist et data.gouv` box shows the warning box and the `Rafraîchir depuis Grist et data.gouv` button.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-accueil/`.

## Gotchas

- The shared dev database holds other drafts and other changes: the drive's rows come first only because it writes them last; never hard-code another row.
- Counts move with every other drive: read them from the database at the moment of the check.
