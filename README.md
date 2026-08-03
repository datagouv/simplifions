# Simplifions

Nouvelle version de [simplifions.data.gouv.fr](https://simplifions.data.gouv.fr) : le catalogue des données accessibles aux acteurs publics pour simplifier les démarches de leurs usagers.

Application Ruby on Rails 8 + PostgreSQL, DSFR auto-hébergé.

| Environnement | URL | Déploiement |
|---|---|---|
| Sandbox | https://sandbox.simplifions.data.gouv.fr | manuel (branche au choix) |
| Staging | https://staging.simplifions.data.gouv.fr | continu au merge sur `main` |
| Production | https://production.simplifions.data.gouv.fr | manuel |

## Démarrer avec Docker (recommandé)

Seul prérequis : [Docker Desktop](https://docs.docker.com/get-docker/) installé et lancé.

```bash
make install   # une seule fois : construit l'image et prépare la base
make start     # démarre le site sur http://localhost:3000
make stop      # arrête le site
```

`make` tout seul liste les autres commandes (logs, console, restart). Chaque commande vérifie d'abord que Docker est prêt et explique quoi faire sinon.

Les fichiers modifiés localement sont pris en compte immédiatement (le code est monté dans le conteneur) — il suffit de recharger la page.

## Démarrer sans Docker

Prérequis : Ruby 3.4.5 (voir `.ruby-version`) et PostgreSQL.

```bash
bin/setup      # installe les gems, crée la base, démarre le serveur
```

## Tests et lint

```bash
bundle exec rspec     # tests (via docker : docker compose exec web bundle exec rspec)
bundle exec rubocop   # lint
```

La CI GitHub rejoue tests, lint et scans de sécurité (brakeman, bundler-audit, importmap audit) à chaque push.
