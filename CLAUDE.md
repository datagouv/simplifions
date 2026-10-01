# Simplifions

Rails 8 + PostgreSQL, DSFR. Langue du dépôt : français (commits, PR, code métier).

Le dépôt reçoit des contributions de personnes qui ne sont pas développeuses, assistées par IA : l'assistant explique ses choix en mots simples, annonce en une phrase sa lecture du ticket avant d'écrire du code, et s'arrête pour demander quand deux lectures sont possibles.

## Commandes (Docker, sans Ruby installé)
- `make start` : site sur http://localhost:3000 ; `make` liste les autres commandes.
- Tests : `docker compose exec web bundle exec rspec` (un fichier : ajouter son chemin).
- Lint : `docker compose exec web bin/rubocop -a`.
- Après chaque étape : lint, puis les specs du fichier touché.

## Simplicité
S'arrêter au premier échelon qui suffit :
1. Faut-il vraiment le faire ? Rien hors du ticket.
2. Rails ou le DSFR le font-ils déjà (`validates`, `normalizes`, scopes, composants `fr-*`) ?
3. Un composant, un helper, un partial du dépôt le fait-il déjà ?
4. Une ligne suffit-elle ?
5. Sinon : le minimum qui marche.

Supprimer plutôt qu'ajouter, simple plutôt que malin, le moins de fichiers possible. Un nouveau fichier dans `app/models/`, une gem, une table, un job, un moteur générique (YAML + classe) : en parler d'abord dans le ticket. Minimal veut dire moins de code, pas moins correct : validation des entrées, accessibilité et sécurité ne se négocient pas.

## Où mettre le code (Rails standard)
- Contrôleur : lit les paramètres, charge, rend. Aucune règle métier.
- Modèle : règles métier, validations, scopes.
- Vue : affiche seulement. Morceau d'interface répété → composant dans `app/components/` (ex. `SolutionCardComponent`) ; mise en forme → helper.
- Import Grist et data.gouv : les interactors et organizers existants (`app/interactors/`, `app/organizers/`).
- Pas de nouvelle couche (service, form object, presenter) pour un seul usage : on extrait à la troisième répétition.

## Interface
- DSFR d'abord : composants et utilitaires `fr-*` (plugin `dsfr-skill`). Une classe dans `application.css` seulement si aucun utilitaire ne convient.
- `hidden` ne masque pas un élément DSFR (`.fr-btn`, `.fr-grid-row`…) : utiliser la classe `fr-hidden`.
- Nouvelle page publique : route, spec de requête, et une entrée dans les deux plans du site (`sitemap.html.erb` et `sitemap.xml.erb`).
- Chaque vue créée ou modifiée passe `/accessibility:audit <fichier>` (plugin `accessibility`) avant la PR.

## Tests et style
- Chaque changement de comportement arrive avec son spec, écrit d'abord quand c'est possible ; une page = `spec/requests/`.
- Tester le comportement visible, pas les associations ActiveRecord ni des fragments HTML exacts.
- RuboCop fait foi (`.rubocop.yml`) : guillemets simples hors interpolation, méthodes courtes.
- Pas de commentaire dans le code : un nom clair le remplace.
- Aucun document de travail dans le dépôt (PDF, maquette, export).

## Commits
- Partir d'une branche à jour : `git fetch && git rebase origin/main`.
- Chaque commit est une étape finie qui se lit seule dans `git log`. Un fichier ajouté puis retiré dans la même branche, un « fix suite review », un « WIP » ne doivent pas apparaître.
- Une correction d'un commit pas encore mergé va dans ce commit : `git commit --fixup <sha>`, puis `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash origin/main`, puis `git push --force-with-lease`.
- Sujet : moins de 60 caractères, ce qui change pour le lecteur du site, en mots du domaine. Pas de préfixe `feat:` / `fix:`. Exemples du dépôt :
  - `Réserver un espace /admin aux administrateurs connectés`
  - `Signaler à l'admin pourquoi une ligne est refusée`
  - `Page de connexion en DSFR, messages Devise en français`
- Corps : vide par défaut ; une ou deux lignes seulement pour un pourquoi que le sujet ne dit pas. Jamais la liste des fichiers ni les étapes suivies. Aucun trailer.

## Pull requests
- Une PR = une fonctionnalité, utilisable seule une fois mergée.
- Titre : comme un sujet de commit. Corps : 1 à 3 lignes (ce que le relecteur obtient, la contrainte à connaître), puis `Closes <lien Linear>`. Pas de titres, pas de plan de test.
- Avant le premier push : relire tout le diff (`git diff origin/main...`) contre cette page, tests et lint verts, page vérifiée dans Firefox et Chrome.
