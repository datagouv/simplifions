# Lire le HTML saisi dans le Grist

Les blocs markdown du Grist portent parfois du HTML (encadrés DSFR, `<details>`, `<hr>`). Le site l'affiche, nettoyé des scripts, attributs `on*` et liens `javascript:`/`data:`.

## How to get to it (user POV)

- `/demarches/actes-detat-civil` : encadré « Utilisez Comedec… » dans la recommandation COMEDEC (Recommandations:212).
- `/solutions/passe-marche` : un `<hr>` saisi avant « Conditions d'accès » (Solutions:10).
- Toute fiche démarche ou solution visible dont un champ markdown contient `<`.
- Anyone, no login.

## Driving it with Capybara

Preconditions: app on `http://localhost:3101/up`; catalogue Grist importé dans `simplifions_development`. Lecture seule.

- **Encadré.** Visit `/demarches/actes-detat-civil`, `find(".fr-callout", text: "Utilisez Comedec")`.
- **Séparateur.** Visit `/solutions/passe-marche`, `find("hr:not([class])")` (les `hr` du gabarit portent `fr-hr`).
- **Aucun HTML jeté.** Chaque page démarche/solution dont `contexte`, `cadre_juridique`, `donnees_utiles`, `parametres_a_saisir`, `description` (API utiles), `permet` ou `ne_permet_pas` contient `<` : `page.html` sans `raw HTML omitted`.
- **Proof.** `drive.rb contenu-html` : captures + read-back du nombre de pages contrôlées et omises.

## Gotchas

- Avant SIM-190, Commonmarker rendait en `unsafe: false` : le HTML devenait `<!-- raw HTML omitted -->`, invisible à l'écran.
- La liste blanche Rails retire `style`, `target` et `id` : un encadré stylé en ligne perd son fond.
