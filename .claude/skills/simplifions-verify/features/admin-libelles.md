# Libellés en français dans l'administration

The seven admin forms name their fields with the Grist words (`Identifiant data.gouv`, `Mots-clés`, `Type d’intégration`), show list values in French (`Donnée utile (API ou jeu de données)`, `Brique technique`, `Intégrée`), explain ambiguous fields with a hint inside the label, and follow the order of the Grist record cards.

## How to get to it (user POV)

- `/admin/recommandations/<id>/edit`: select `Type de recommandation` with its hint.
- `/admin/solutions/<id>/edit`: field `Identifiant data.gouv`, select `Catégorie de solution`.
- `/admin/integrations/<id>/edit`: `API ou jeu de données`, then `Solution`, then `Type d’intégration`.
- `/admin/demarches/<id>/edit`: `Icône du titre`, `Nom`… (the state is no longer a field: see admin-colonne-actions.md).

## Driving it with Capybara

`drive.rb libelles`. Read-only: it opens existing catalogue rows and saves nothing. Preconditions: logged in, catalogue imported (a `niveau_1` recommandation, a solution with a data.gouv UID and a category, a `consomme` intégration).

- **Values.** The selects show the stored key's French label: `Type de recommandation` = `Donnée utile (API ou jeu de données)`, `Catégorie de solution` = `Solution.human_attribute_name("categorie.<key>")`, `Type d’intégration` = `Intégrée`.
- **Order.** The read-back lists each form's labels and legends in page order (own text, hint left out).
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-libelles/`. Saving a French option stores the key: `drive.rb vocabulaires` selects `Usager` and reads back `categorie == "usager"`.

## Gotchas

- Labels carry their hint inside: `find_field 'Type de recommandation'` matches by substring, `label.text` includes the hint.
