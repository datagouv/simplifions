# Chercher et lire les listes de l'admin

Each admin list has a DSFR search bar, 50 rows per page with the site's pagination, and the row's name as the link to its edit page (no `Modifier` button). Démarches, solutions and recommandations also show `Visible` (badge `Oui` / `Non`) and `Modifié le` (Paris date); solutions show `Intégrée par`, the integrating solutions linked to their own edit page.

## Sub-features

- `admin-recherche` field `Rechercher` + button `Rechercher` (GET `?q=`), accents and case ignored, every word must match. Démarches and solutions reuse the public catalogue search (name, short description, keywords for démarches); recommandations and intégrations match the names of the démarche and solutions they link; the other tables match the name.
- `admin-pagination` 50 rows, `Page 2` link keeps `q`.
- `admin-colonnes` headers `Id`, `Nom` (or `Ligne`), `Visible`, `Modifié le`, `Intégrée par` (solutions only).

## How to get to it (user POV)

- Dashboard `/admin` → any table link. Admin only.

## Driving it with Capybara

`drive.rb listes`, read-only. Preconditions: logged in, catalogue imported (230 solutions on 2026-10-05).

- **Columns and page 1.** `click_link "Solutions"`: headers as above, 50 rows.
- **Page 2.** `click_link "Page 2"`: first row is the 51st solution by id.
- **Search.** `rechercher(page, <nom of an integrated solution>)`: rows equal `Solution.recherche(q)` names.
- **Integrator link.** In that row, click an `Intégrée par` name: lands on `/admin/solutions/<integratrice id>/edit`.
- **Joined search.** Recommandations, search `<first word of the démarche> <last word of the solution>`: the recommandation's link is listed.
- **Proof.** `tmp/verify/admin-listes/`.

## Gotchas

- After `click_button "Rechercher"`, wait for `q=` in the URL before reading or clicking rows (`rechercher` in drive.rb): the old list is still on screen while Turbo fetches the new one, and a click on it is overridden by the search response.
- Drives open a row with `ouvrir_depuis_la_liste` (search then click the name), since a row created by a drive may sit past page 1.
