# Retrouver les brouillons en cours depuis les listes

The démarches and solutions lists mark with a `Brouillon` badge every row whose changes wait for a « Publier »: its own draft, or for a démarche a recommandation that waits for the démarche's publication ([admin-brouillon.md](admin-brouillon.md), [admin-recommandations-en-ligne.md](admin-recommandations-en-ligne.md)). The select `État` of the left list, set to `En brouillon`, keeps only those rows, and the search keeps the filter. The admin home page lists them under `À reprendre` ([admin-accueil.md](admin-accueil.md)).

## Sub-features

- `admin-badge-brouillon` badge `Brouillon` beside `Publiée` / `Masquée` in each row of the démarches and solutions lists.
- `admin-filtre-brouillons` select `État` = `En brouillon` + `Filtrer` (GET `?etat=brouillons`); `q` keeps the filter.

## How to get to it (user POV)

- `/admin/demarches` or `/admin/solutions` → `État` `En brouillon` → `Filtrer`. Admin only.

## Driving it with Capybara

Drive: `features/admin-brouillons-en-cours.rb` (SKILL.md § Drive).

Preconditions: logged in. The drive creates a published démarche `Vérif verify-map <browser>` with a draft and a solution of the same name with a draft, and deletes both at the end.

- **Filtered démarches.** `Démarches` rubrique, `État` `En brouillon`, `Filtrer`: the URL holds `etat=brouillons`; `État` reads `En brouillon`, the `[role=status]` count of `Liste des démarches` equals the database count, every row shows `Brouillon`, the drive's démarche is listed, no `Voir toutes les lignes` link.
- **Search keeps the filter.** `Verify.rechercher(page, "Vérif verify-map")`: the URL keeps `etat=brouillons`, only the drive's démarche is listed, with `Brouillon`.
- **Filtered solutions.** `Solutions` rubrique, `État` `En brouillon`, `Filtrer`: as many rows as the database count, all with `Brouillon`, the drive's solution among them.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-brouillons-en-cours/`.

## Gotchas

- The counts move with every other draft in the shared dev database: read them from the database at the moment of the check, never hard-code them.
- Rows are created straight in the database (a draft is a JSON column): no form to fill, but the drive's `ensure` must destroy them.
- The DSFR badge shows `BROUILLON` in capitals through CSS, and Selenium reads the rendered text: compare in lower case.
