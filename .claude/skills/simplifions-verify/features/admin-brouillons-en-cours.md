# Retrouver les brouillons en cours depuis les listes

The démarches and solutions lists mark with a `Brouillon` badge, in the `Visible` column, every row whose changes wait for a « Publier »: its own draft, or for a démarche a recommandation that waits for the démarche's publication ([admin-brouillon.md](admin-brouillon.md), [admin-recommandations-en-ligne.md](admin-recommandations-en-ligne.md)). Above both lists, `Brouillons en cours (N)` keeps only those rows; the filtered list offers `Voir toutes les lignes`, and the search and the pages keep the filter. The admin home page lists them under `À reprendre` ([admin-accueil.md](admin-accueil.md)).

## Sub-features

- `admin-badge-brouillon` badge `Brouillon` beside `Oui` / `Non` in the `Visible` cell of the démarches and solutions lists.
- `admin-filtre-brouillons` link `Brouillons en cours (N)` (GET `?brouillons=1`), back link `Voir toutes les lignes`; `q` and `Page 2` keep the filter.

## How to get to it (user POV)

- `/admin/demarches` or `/admin/solutions` → `Brouillons en cours (N)`. Admin only.

## Driving it with Capybara

Drive: `features/admin-brouillons-en-cours.rb` (SKILL.md § Drive).

Preconditions: logged in. The drive creates a published démarche `Vérif verify-map <browser>` with a draft and a solution of the same name with a draft, and deletes both at the end.

- **Filtered démarches.** `Démarches` rubrique, `Brouillons en cours (N)`: lands on `/admin/demarches?brouillons=1`; the `[role=status]` count equals the database count, every row shows `Brouillon`, the drive's démarche is listed; `Voir toutes les lignes` goes back to `/admin/demarches`.
- **Search keeps the filter.** `Brouillons en cours (N)`, then `Verify.rechercher(page, "Vérif verify-map")`: the URL keeps `brouillons=1`, only the drive's démarche is listed, with `Brouillon`.
- **Filtered solutions.** `Solutions` rubrique, `Brouillons en cours (N)` with N the database count: the drive's solution is listed with `Brouillon`.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-brouillons-en-cours/`.

## Gotchas

- The counts move with every other draft in the shared dev database: read them from the database at the moment of the check, never hard-code them.
- Rows are created straight in the database (a draft is a JSON column): no form to fill, but the drive's `ensure` must destroy them.
- The DSFR badge shows `BROUILLON` in capitals through CSS, and Selenium reads the rendered text: compare in lower case. The solutions list has `Privée` before `Visible`, so its badge is in another column than the démarches'.
