# Identifiant data.gouv d'une API saisi dans l'administration

When an admin saves an API or a jeu de données with a new data.gouv identifier (creation, change, or « Publier » of a draft that changes it), its fiche shows the `Repris de data.gouv.fr` block filled right after the redirect. When data.gouv.fr does not know the identifier or does not answer, the API is saved anyway and the block says `Rien n’a été repris de data.gouv.fr pour cet identifiant … Nouvel essai chaque nuit.` An identifier already used by another fiche is refused at `Enregistrer` on the field, also when it would go into the draft of a published API, naming that fiche (`est déjà celui de « API Données du répertoire Sirene (API) »`); a fiche already sharing its identifier in the base stays editable while the identifier does not change. The rule is the administration's only: the Grist import keeps the fiches that share an identifier (a brique technique and its API, such as FranceConnect).

## Sub-features

- `creation` — a new API with a data.gouv identifier shows its title and organisation from data.gouv.fr.
- `inconnu` — an identifier data.gouv.fr does not know: saved, the block says nothing was taken.
- `doublon` — an identifier already used: refused, the message names the fiche that has it, nothing saved.

## How to get to it (user POV)

- Admin → `Solutions` → `Ajouter` (`/admin/solutions/new`) → `Catégorie de solution` `API`, field `Identifiant data.gouv` → `Enregistrer`.
- `/admin/solutions/<id>/edit` of an API → change `Identifiant data.gouv` → `Enregistrer` (masked API) or `Publier` (published API, the change waits in its draft until then).

## Driving it with Capybara

`drive.rb identifiant-datagouv`. Preconditions: logged in, catalogue imported (an API with identifier `672cf6aece89cb14e31f0fba`, none with `6661e09c7230a8fc3b1ec229`), network to www.data.gouv.fr (public API, live call).

- **Creation.** New API `Vérif verify-map <browser>` with `6661e09c7230a8fc3b1ec229` (API Melodi) → `« … (API) » enregistré.`, block `Titre : <datagouv_titre>` equal to the database, no `Rien n’a été repris`.
- **Inconnu.** Same fiche, identifier `verif-identifiant-inconnu` → `Enregistrer` → block shows `Rien n’a été repris de data.gouv.fr pour cet identifiant`; database `datagouv_titre` nil.
- **Doublon.** New API `Vérif verify-map <browser> doublon` with `672cf6aece89cb14e31f0fba` → stays on the form with `est déjà celui de « <libellé de la fiche existante> »`; database still has one fiche with that identifier.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-identifiant-datagouv/`; the drive deletes its `Vérif verify-map` rows in `ensure`.

## Gotchas

- The creation step needs data.gouv.fr up; when it is down the drive fails on `rien repris de data.gouv.fr`, which is the `inconnu` behaviour, not a regression.
- A leftover `Vérif verify-map <browser>` row from a crashed run keeps `6661e09c7230a8fc3b1ec229` taken: the drive raises `déjà en base`; delete the row.
