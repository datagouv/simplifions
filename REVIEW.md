# Revue de code

Ce qui s'ajoute à la liste générale du relecteur. Les règles d'écriture du dépôt (DSFR et `fr-hidden`, plans du site, audit d'accessibilité, Firefox et Chrome, commits, PR) sont dans [`CLAUDE.md`](CLAUDE.md) : les vérifier, sans les recopier ici.

## À quoi ressemble l'échec ici

- Un brouillon se voit sur le site public avant « Publier ».
- Une saisie de l'admin disparaît la nuit suivante, réécrite ou supprimée par l'import Grist.
- Un même chiffre ou une même liste, écrit à deux endroits, qui ne disent plus la même chose.
- Une page publique qui ne se lit plus sans JavaScript ou au clavier.

## Contrôles propres au dépôt

1. **Brouillon et publication.** Le site public lit les colonnes publiées, jamais `brouillon`. Une recommandation ajoutée à une démarche publiée attend la publication de la démarche : le public la lit par `Demarche#recommandations_publiees` ou le scope `Recommandation.parues`, jamais par `recommandations` seul. Suivre chaque nouvel endroit public : fiche, carte, compteur, fenêtre (SIM-232 : trois fuites en deux rondes).
2. **Import Grist.** Chaque nuit, `Grist::ImportStep#synchronise` réécrit toutes les colonnes importées, et `Grist::PruneDisparus` supprime toute ligne absente du passage, y compris celles mises en quarantaine. D'où :
   - une validation ajoutée à un modèle importé fait supprimer les lignes Grist qui ne la passent pas, sauf si l'import vide la valeur avec une note (`vide_hors_liste`) (SIM-189, SIM-202) ;
   - un champ ouvert à la saisie dans l'admin, que l'import ou le rafraîchissement data.gouv écrit aussi, est écrasé au passage suivant (SIM-200, SIM-201).
3. **Un chiffre, une source.** Compteur d'onglet, « x/y » d'une carte, total d'une fenêtre : une seule méthode du modèle, sur le même périmètre (SIM-257, SIM-258). Une liste de valeurs du domaine (catégories de solution, rubriques de l'admin) existe une fois (SIM-229, SIM-258, SIM-260).
4. **Sans JavaScript, au clavier.** Une page publique reste lisible sans JavaScript : onglets, « Lire plus », titres qui ne sont pas des boutons inertes (SIM-258, SIM-261). Dans l'admin, une réponse `turbo_stream` a son chemin HTML (SIM-241) et le focus a une cible après une suppression (SIM-240).
5. **Texte venu du Grist ou de l'admin** : affiché par le helper `markdown` (liste de balises fermée), jamais `raw` ni `html_safe` (SIM-190).
6. **Admin** : un nouveau contrôleur hérite d'`Admin::BaseController` (connexion obligatoire, auteur dans l'historique).
7. **Preuve du JavaScript.** Le dépôt n'a pas d'outil de test JavaScript : un comportement JS se prouve par un parcours de la carte `.claude/skills/simplifions-verify/`, mise à jour dans la même PR. Le constat porte sur un parcours absent ou une carte pas à jour, pas sur le spec JS manquant (SIM-204, SIM-211, SIM-226).

## Déjà connu, ne pas relever

- Compteurs d'onglet de l'admin figés après une action sur une ligne : https://linear.app/pole-api/issue/SIM-237/us-la-demarche-suit-lajout-dune-recommandation-sans-recharger-la-page

## Chemins à ignorer

- `app/assets/images/`, `app/assets/fonts/`, `config/credentials*.yml.enc`, `Gemfile.lock` (bundler-audit en CI).
- `db/schema.rb` : la CI rejoue les migrations et lance active_record_doctor ; lire la migration.
- `db/grist/topics_snapshot.json` : données figées (slug et date de création par identifiant Grist), lues seulement quand ils manquent.
