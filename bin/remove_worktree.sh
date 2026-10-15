#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<USAGE
Usage : $(basename "$0") <nom>

Arrête le site de worktrees/<nom>, supprime ses conteneurs et son volume
Postgres docker, ses bases dans le Postgres local s'il y en a, le worktree,
puis sa branche locale si setup_worktree.sh l'a créée et qu'elle est mergée
(la branche distante reste).
<nom> : celui donné à setup_worktree.sh.
USAGE
  exit 1
}

[ $# -eq 1 ] || usage

NAME="$(echo "$1" | tr '[:upper:]' '[:lower:]')"

if [[ ! "$NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Erreur : '$1' doit être un ticket (OPI-123) ou un mot-clé (import-grist)" >&2
  exit 1
fi

PRIMARY_ROOT="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
WORKTREE_PATH="$PRIMARY_ROOT/worktrees/$NAME"
SLUG="${NAME//-/_}"

if [ "$(pwd -P)" = "$WORKTREE_PATH" ] || [[ "$(pwd -P)" == "$WORKTREE_PATH/"* ]]; then
  echo "Erreur : lancer ce script hors de $WORKTREE_PATH" >&2
  exit 1
fi

if [ -d "$WORKTREE_PATH" ]; then
  if [ -n "$(git -C "$WORKTREE_PATH" status --porcelain)" ]; then
    echo "Erreur : $WORKTREE_PATH a des changements non commités, rien n'est supprimé" >&2
    exit 1
  fi
  PROJECT_LABEL="label=com.docker.compose.project=simplifions_${SLUG}"
  if command -v docker >/dev/null 2>&1 &&
    [ -n "$(docker ps -aq --filter "$PROJECT_LABEL"; docker volume ls -q --filter "$PROJECT_LABEL")" ]; then
    (
      cd "$WORKTREE_PATH" &&
        docker compose run --rm --no-deps -T web chown -R "$(id -u):$(id -g)" /rails &&
        docker compose down --volumes --rmi local
    )
  fi
  PORT="$(sed -n 's/^PORT=//p' "$WORKTREE_PATH/.env" 2>/dev/null || true)"
  PIDS="$( [ -n "$PORT" ] && lsof -nP -iTCP:"$PORT" -sTCP:LISTEN -t 2>/dev/null || true)"
  if [ -n "$PIDS" ]; then
    echo "$PIDS" | xargs kill
    echo "Serveur local arrêté sur le port $PORT"
  fi
  BRANCH="$(git -C "$WORKTREE_PATH" rev-parse --abbrev-ref HEAD)"
  CREATED_FOR="$(git -C "$PRIMARY_ROOT" config --get "branch.$BRANCH.simplifions-worktree" || true)"
  DEFAULT_BRANCH="$(git -C "$PRIMARY_ROOT" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)"
  git -C "$PRIMARY_ROOT" worktree remove "$WORKTREE_PATH"
  echo "Worktree supprimé : $WORKTREE_PATH"
  if [ "$BRANCH" = HEAD ]; then
    echo "Aucune branche supprimée : le worktree n'était sur aucune branche"
  elif [ "$CREATED_FOR" != "$NAME" ] || [ "$BRANCH" = main ] || [ "$BRANCH" = "${DEFAULT_BRANCH#origin/}" ]; then
    echo "Branche locale $BRANCH gardée : setup_worktree.sh ne l'a pas créée"
  elif git -C "$PRIMARY_ROOT" branch -d "$BRANCH" 2>/dev/null; then
    echo "Branche locale $BRANCH supprimée"
  else
    echo "Branche locale $BRANCH gardée (pas mergée) : git branch -D $BRANCH pour la supprimer" >&2
  fi
else
  echo "Attention : $WORKTREE_PATH introuvable, seules les bases locales sont supprimées" >&2
fi

if command -v psql >/dev/null 2>&1; then
  for db in "simplifions_development_${SLUG}" "simplifions_test_${SLUG}"; do
    if psql -X -Atc "SELECT 1 FROM pg_database WHERE datname = '$db'" postgres 2>/dev/null | grep -q 1; then
      dropdb --force "$db"
      echo "Base $db supprimée"
    fi
  done
fi
