.DEFAULT_GOAL := help
.PHONY: help install start stop restart logs console check

COMPOSE = docker compose

help: ## Affiche cette aide
	@echo ""
	@echo "Commandes disponibles :"
	@echo ""
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-10s %s\n", $$1, $$2}'
	@echo ""

install: check ## Prépare tout (images docker + base de données)
	@echo "→ Construction de l'image de l'application (quelques minutes la première fois)..."
	@$(COMPOSE) build
	@echo "→ Installation des dépendances..."
	@$(COMPOSE) run --rm web bundle install
	@echo "→ Préparation de la base de données..."
	@$(COMPOSE) run --rm web bin/rails db:prepare
	@echo ""
	@echo "✓ Installation terminée. Lancez « make start » pour démarrer le site."

start: check ## Démarre le site sur http://localhost:3000
	@$(COMPOSE) up --detach
	@echo "→ Démarrage du site..."
	@for i in $$(seq 1 60); do \
		if curl -s -o /dev/null http://localhost:3000/up; then \
			echo ""; \
			echo "✓ Le site tourne : http://localhost:3000"; \
			echo "  Pour l'arrêter : make stop"; \
			exit 0; \
		fi; \
		sleep 2; \
	done; \
	echo ""; \
	echo "❌ Le site n'a pas démarré après 2 minutes."; \
	echo "   Regardez ce qui se passe avec : make logs"; \
	exit 1

stop: check ## Arrête le site
	@$(COMPOSE) down
	@echo "✓ Site arrêté."

restart: stop start ## Redémarre le site

logs: check ## Affiche les logs de l'application (Ctrl+C pour quitter)
	@$(COMPOSE) logs --follow web

console: check ## Ouvre une console Rails dans le conteneur
	@$(COMPOSE) exec web bin/rails console

check:
	@command -v docker >/dev/null 2>&1 || { \
		echo "❌ Docker n'est pas installé."; \
		echo "   Installez Docker Desktop : https://docs.docker.com/get-docker/"; \
		exit 1; }
	@docker info >/dev/null 2>&1 || { \
		echo "❌ Docker est installé mais ne tourne pas."; \
		echo "   Lancez Docker Desktop puis réessayez."; \
		exit 1; }
	@docker compose version >/dev/null 2>&1 || { \
		echo "❌ Docker Compose n'est pas disponible."; \
		echo "   Mettez à jour Docker Desktop (Compose v2 est inclus)."; \
		exit 1; }
