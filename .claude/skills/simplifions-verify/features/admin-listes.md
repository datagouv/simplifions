# Chercher et lire les listes de l'admin

Démarches and solutions are not tables: the list stays on the left in a `Liste des démarches` (`Liste des solutions`) navigation, the open fiche or the prompt « Choisissez une démarche dans la liste » on the right (`admin-liste-et-fiche`). The other admin lists have a DSFR search bar, 50 rows per page with the site's pagination (organisations: every row on one page, so Ctrl+F finds one), and the row's name as the link to its edit page (no `Modifier` button); fournisseurs de services and vocabulaires link to their read page instead. Recommandations also show `Visible` (badge `Oui` / `Non`) and `Modifié le` (Paris date).

## Sub-features

- `admin-recherche` field `Rechercher` (`Rechercher une démarche` on the two left lists) + button `Rechercher` (GET `?q=`), accents and case ignored, every word must match. A search with no result shows « Aucune démarche ne contient « x ». » (« Aucun vocabulaire… », noun and gender of the list) instead of the count and the rows, then a link `Effacer la recherche` back to the full list; on démarches and solutions it sits in the left column. Démarches and solutions reuse the public catalogue search (name, short description, keywords for démarches); recommandations and intégrations match the names of the démarche and solutions they link; the other tables match the name.
- `admin-pagination` 50 rows, `Page 2` link keeps `q` (not on démarches and solutions: one scrolling list, every row).
- `admin-colonnes` headers `Id`, `Nom` (or `Ligne`), `Visible`, `Modifié le` (recommandations). Organisations: `Nom court`, `Nom long`. Intégrations: the form labels `Solution` (the link), `API ou jeu de données`, `Type d’intégration`, `Statut de l’intégration`.
- `admin-liste-et-fiche` démarches and solutions: `[role=status]` count `N démarches`, select `État` (`Toutes`, `Publiées`, `Masquées`, `En brouillon`) applied by `Filtrer` (`?etat=`), one link per row (name, with the icon `aria-hidden` for démarches; badges `Publiée` / `Masquée` and `Brouillon`), `Ajouter une démarche`. A row opens `/admin/<table>/<id>/edit?etat=…&q=…`: the list keeps its search and filter, the open row is `aria-current="page"`.

## How to get to it (user POV)

- Dashboard `/admin` → any table link under `Catalogue` ([admin-accueil.md](admin-accueil.md)), or the header rubriques. Admin only.

## Driving it with Capybara

Drive: `features/admin-listes.rb` (SKILL.md § Drive).

Read-only. Preconditions: logged in, catalogue imported (230 solutions on 2026-10-05).

- **Solutions list on the left.** `click_link "Solutions"`: navigation `Liste des solutions`, no `table` and no `.fr-pagination`, the prompt « Choisissez une solution dans la liste », as many rows as `Solution.count`, count `N solutions`.
- **Search.** `Verify.rechercher(page, <nom of an integrated solution>)`: row names equal `Solution.recherche(q)` names.
- **Démarches list and prompt.** `click_link "Démarches"`: navigation `Liste des démarches`, « Choisissez une démarche dans la liste », a row per démarche, no `table`.
- **Filtered row opens the fiche.** Select `Publiées` in `État`, `Filtrer`, open the first published démarche from the list: URL `/admin/demarches/<id>/edit?…etat=publiees`, H1 = its name, no prompt, one `aria-current="page"` row in the left list, `État` still `Publiées`.
- **Search without result on the left.** Démarches, search `zzz-introuvable`: inside `Liste des démarches`, the status « Aucune démarche ne contient « zzz-introuvable ». », a link `Effacer la recherche`, no row.
- **Joined search.** Recommandations, search `<first word of the démarche> <last word of the solution>`: the recommandation's link is listed.
- **Organisations.** `click_link "Organisations"`: no `.fr-pagination`, rows = `Organisation.count`; the first organisation with a `nom_long` shows both names in its row.
- **Intégrations.** `/admin/integrations` (out of the menu, still routed): headers `Id`, `Solution`, `API ou jeu de données`, `Type d’intégration`, `Statut de l’intégration`; first row equals the first integration by id read from the database.
- **Search without result.** Vocabulaires, search `zzz-introuvable`: status reads « Aucun vocabulaire ne contient « zzz-introuvable ». », no `table`; `click_link "Effacer la recherche"`: no `q` in the URL, rows = `[Vocabulaire.count, 50].min`.
- **Démarches.** Search the first démarche with an `icone`: its row name reads `<icone> <nom>`, the icon in an `aria-hidden` span.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-listes/`.

## Gotchas

- After `click_button "Rechercher"`, wait for `q=` in the URL before reading or clicking rows (`Verify.rechercher` in harness.rb): the old list is still on screen while Turbo fetches the new one, and a click on it is overridden by the search response.
- Drives open a row with `Verify.ouvrir_depuis_la_liste` (search then click the name, in the table or in the left list), since a row created by a drive may sit past page 1.
