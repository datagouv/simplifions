# Identifiant data.gouv d'une API saisi dans l'administration

The `Catégorie de solution` is chosen first, alone (`Continuer`); the form then starts with the `Identifiant data.gouv`, then `Nom`. As soon as an identifier is entered for an API or a jeu de données (on `change`), `Recherche de cet identifiant sur data.gouv.fr…` shows (and is announced to screen readers) until data.gouv.fr answers, then the `Repris de data.gouv.fr` block shows what data.gouv.fr gives, before any save (when data.gouv.fr does not know the identifier or does not answer: `data.gouv.fr ne connaît pas cet identifiant ou n’a pas répondu.`), and an empty `Nom` (or one still holding an earlier preview's title) takes the data.gouv title; a name the admin typed is never replaced. Nothing is saved by the preview. When an admin saves an API or a jeu de données with a new data.gouv identifier (creation, change, or « Publier » of a draft that changes it), its fiche shows the `Repris de data.gouv.fr` block filled right after the redirect. When data.gouv.fr does not know the identifier or does not answer, the API is saved anyway and the block says `Rien n’a été repris de data.gouv.fr pour cet identifiant … Nouvel essai chaque nuit.` An identifier already used by another fiche is refused at `Enregistrer` on the field, also when it would go into the draft of a published API, naming that fiche (`est déjà celui de « API Données du répertoire Sirene (API) »`); a fiche already sharing its identifier in the base stays editable while the identifier does not change. The rule is the administration's only: the Grist import keeps the fiches that share an identifier (a brique technique and its API, such as FranceConnect).

## Sub-features

- `apercu` — the identifier shows the block before saving and fills an empty `Nom`, never a typed one.
- `creation` — a new API with a data.gouv identifier shows its title and organisation from data.gouv.fr.
- `inconnu` — an identifier data.gouv.fr does not know: saved, the block says nothing was taken.
- `doublon` — an identifier already used: refused, the message names the fiche that has it, nothing saved.

## How to get to it (user POV)

- Admin → `Solutions` → `Ajouter une solution` (`/admin/solutions/new`) → `API`, `Continuer` → `Identifiant data.gouv` (first field) → the block appears on leaving the field → `Enregistrer`.
- `/admin/solutions/<id>/edit` of an API → change `Identifiant data.gouv` → `Enregistrer` (masked API) or `Publier` (published API, the change waits in its draft until then).

## Driving it with Capybara

Drive: `features/admin-identifiant-datagouv.rb` (SKILL.md § Drive).

Preconditions: logged in, catalogue imported (an API with identifier `672cf6aece89cb14e31f0fba`, none with `6661e09c7230a8fc3b1ec229`), network to www.data.gouv.fr (public API, live call).

- **Aperçu.** New form (`API`, `Continuer`), identifier `6661e09c7230a8fc3b1ec229` → the status region said `Recherche de cet identifiant sur data.gouv.fr…` during the wait (the drive records every text of the page's status regions, the wait can be too short to see), then is empty; block `Titre : <title>` and `Nom` = that title; identifier `672cf6aece89cb14e31f0fba` → `Nom` follows the new title; `Nom` typed, identifier back to Melodi → block back to Melodi, typed `Nom` kept; database: no fiche with Melodi's identifier; the breadcrumb `Solutions` (« Quitter sans enregistrer »).
- **Creation.** New API `Vérif verify-map <browser>` with `6661e09c7230a8fc3b1ec229` (API Melodi) → `« … (API) » enregistré.`, block `Titre : <datagouv_titre>` equal to the database, no `Rien n’a été repris`.
- **Inconnu.** Same fiche, identifier `verif-identifiant-inconnu` → `Enregistrer` → wait for the new page (the drive marks the old `body` before the click and waits until Turbo replaces it: the old page already shows the Creation step's notice, and its `Enregistrer` is disabled during the request) → block shows `Rien n’a été repris de data.gouv.fr pour cet identifiant`; database `datagouv_titre` nil.
- **Doublon.** New API `Vérif verify-map <browser> doublon` with `672cf6aece89cb14e31f0fba` → stays on the form with `est déjà celui de « <libellé de la fiche existante> »`; database still has one fiche with that identifier.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-identifiant-datagouv/`; the drive deletes its `Vérif verify-map` rows in `ensure`.

## Gotchas

- A preview takes up to 35 s when data.gouv.fr is slow (5 s to connect, 30 s to read): the drive waits 40 s on the block. A block with an empty `Titre :` means data.gouv.fr did not answer.

- The creation step needs data.gouv.fr up; when it is down the drive fails on `rien repris de data.gouv.fr`, which is the `inconnu` behaviour, not a regression.
- A leftover `Vérif verify-map <browser>` row from a crashed run keeps `6661e09c7230a8fc3b1ec229` taken: the drive raises `déjà en base`; delete the row.
