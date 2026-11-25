#!/usr/bin/env bash
# Hook PreToolUse (Bash) : refuse db:schema:load, db:drop et db:reset, sauf sur une base jetable
# simplifions_verify_* gardée par `test "$DATABASE_URL" = postgres:///simplifions_verify_…`
# (forme des fiches de la carte de vérif). Lit le JSON du hook sur l'entrée standard.
commande=$(jq -r '.tool_input.command // ""')

grep -Eq 'db:(schema:load|drop|reset)' <<<"$commande" || exit 0

if grep -Fq 'DATABASE_URL=postgres:///simplifions_verify_' <<<"$commande" &&
   grep -Fq 'test "$DATABASE_URL" = postgres:///simplifions_verify_' <<<"$commande" &&
   ! grep -Fq 'simplifions_development' <<<"$commande"; then
  exit 0
fi

jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny",
  permissionDecisionReason: "db:schema:load, db:drop et db:reset ne visent qu’une base jetable simplifions_verify_*, gardée par test \"$DATABASE_URL\" = postgres:///simplifions_verify_… (voir features/import-grist.md)."}}'
