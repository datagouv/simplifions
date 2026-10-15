#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<USAGE
Usage : $(basename "$0") [-p port] <nom> [branche]

Crée le worktree git worktrees/<nom> et son fichier .env : ses propres bases
(simplifions_development_<nom>, simplifions_test_<nom>), son propre port et
son propre projet docker compose (conteneurs et volume Postgres à part).

<nom> : un ticket Linear (OPI-123) ou un mot-clé (import-grist).

Port : 3NNNN, NNNN étant le numéro du ticket sur quatre chiffres
(OPI-123 -> 30123) ou, pour un mot-clé, quatre chiffres tirés du nom.
Avec -p, le port donné.

Branche, dans l'ordre :
  1. [branche] si elle est donnée
  2. la seule branche locale ou distante nommée <nom> ou <nom>-…,
     derrière un éventuel préfixe (feature/<nom>-titre)
  3. une nouvelle branche feature/<nom> depuis origin/main
Refuse une branche dont config/database.yml et compose.yaml ont des noms
de base et un port fixes (antérieure à ce script) : la rebaser d'abord.
USAGE
  exit 1
}

PORT=""
while getopts "p:h" opt; do
  case "$opt" in
    p) PORT="$OPTARG" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

if [ $# -lt 1 ] || [ $# -gt 2 ]; then usage; fi

NAME="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
BRANCH="${2:-}"
BRANCH="${BRANCH#origin/}"

if [[ ! "$NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Erreur : '$1' doit être un ticket (OPI-123) ou un mot-clé (import-grist)" >&2
  exit 1
fi

if [ -n "$PORT" ] && { [[ ! "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1024 ] || [ "$PORT" -gt 65535 ]; }; then
  echo "Erreur : port '$PORT' invalide (attendu entre 1024 et 65535)" >&2
  exit 1
fi

if [ -z "$PORT" ]; then
  if [[ "$NAME" =~ ^[a-z]+-([0-9]+)$ ]]; then
    PORT_SEED="$((10#${BASH_REMATCH[1]}))"
  else
    PORT_SEED="$(printf '%s' "$NAME" | cksum | cut -d' ' -f1)"
  fi
  PORT="$((30000 + PORT_SEED % 10000))"
fi

PRIMARY_ROOT="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
WORKTREE_PATH="$PRIMARY_ROOT/worktrees/$NAME"
SLUG="${NAME//-/_}"

if [ -e "$WORKTREE_PATH" ]; then
  echo "Erreur : $WORKTREE_PATH existe déjà" >&2
  exit 1
fi

if (echo > "/dev/tcp/127.0.0.1/$PORT") 2>/dev/null ||
  grep -qsx "PORT=$PORT" "$PRIMARY_ROOT"/worktrees/*/.env; then
  echo "Erreur : le port $PORT est déjà pris ou donné à un autre worktree, en choisir un autre avec -p" >&2
  exit 1
fi

git -C "$PRIMARY_ROOT" fetch --quiet origin

if [ -z "$BRANCH" ]; then
  MATCHES="$(git -C "$PRIMARY_ROOT" for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin \
    | grep -v '/HEAD$' | sed 's#^origin/##' | sort -u | grep -iE -- "(^|/)${NAME}(-|$)" || true)"
  if [ "$(grep -c . <<< "$MATCHES")" -gt 1 ]; then
    echo "Erreur : plusieurs branches correspondent à $NAME, en donner une :" >&2
    printf '%s\n' "$MATCHES" | sed 's/^/  /' >&2
    exit 1
  fi
  BRANCH="$MATCHES"
fi

if [ "$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]')" = main ]; then
  echo "Erreur : main reste dans le dépôt principal, donner une autre branche" >&2
  exit 1
fi

if [ -n "$BRANCH" ] && git -C "$PRIMARY_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "Branche locale $BRANCH"
  SOURCE="$BRANCH"
elif [ -n "$BRANCH" ] && git -C "$PRIMARY_ROOT" show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  echo "Branche distante origin/$BRANCH"
  SOURCE="origin/$BRANCH"
else
  BRANCH="${BRANCH:-feature/$NAME}"
  echo "Nouvelle branche $BRANCH depuis origin/main"
  SOURCE="origin/main"
fi

if ! git -C "$PRIMARY_ROOT" show "$SOURCE:config/database.yml" | grep -q DATABASE_NAME_DEVELOPMENT ||
  ! git -C "$PRIMARY_ROOT" show "$SOURCE:compose.yaml" | grep -q 'PORT:-'; then
  echo "Erreur : $SOURCE a des noms de base et un port fixes, son worktree" >&2
  echo "utiliserait ceux du dépôt principal. Rebaser $BRANCH sur origin/main, puis relancer." >&2
  exit 1
fi

case "$SOURCE" in
  "$BRANCH") git -C "$PRIMARY_ROOT" worktree add "$WORKTREE_PATH" "$BRANCH" ;;
  origin/main) git -C "$PRIMARY_ROOT" worktree add --no-track -b "$BRANCH" "$WORKTREE_PATH" origin/main ;;
  *) git -C "$PRIMARY_ROOT" worktree add --track -b "$BRANCH" "$WORKTREE_PATH" "$SOURCE" ;;
esac

if [ "$SOURCE" != "$BRANCH" ]; then
  git -C "$PRIMARY_ROOT" config "branch.$BRANCH.simplifions-worktree" "$NAME"
fi

cat > "$WORKTREE_PATH/.env" <<ENV
COMPOSE_PROJECT_NAME=simplifions_${SLUG}
PORT=${PORT}
DATABASE_NAME_DEVELOPMENT=simplifions_development_${SLUG}
DATABASE_NAME_TEST=simplifions_test_${SLUG}
ENV

echo
echo "Worktree prêt : $WORKTREE_PATH"
echo "Branche :       $BRANCH"
echo "Bases :         simplifions_development_${SLUG}, simplifions_test_${SLUG}"
echo "Démarrer :      cd $WORKTREE_PATH && make start"
echo "Sans Docker :   (set -a && . ./.env && bin/rails db:prepare && bin/rails server)"
echo "                chaque commande bin/rails entre ces parenthèses, sinon elle touche"
echo "                les bases du dépôt principal"
echo "Site :          http://localhost:${PORT}"
