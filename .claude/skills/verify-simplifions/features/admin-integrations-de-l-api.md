# Une intégration ne vaut que pour les démarches de son API

The démarches of an intégration are those that recommend its API or jeu de données (a recommandation of `integree`, visible or not). The intégration form only offers those démarches; the démarche form only offers the intégrations whose API it recommends. A link already out of the rule stays checked, labelled `(hors règle)`, so it can be unchecked. The server refuses an out-of-rule link with `La démarche « … » ne recommande pas l’API ou le jeu de données intégré` and saves nothing. A new intégration (no API yet) or a démarche recommending nothing shows a hint instead of the list. The Grist import drops such links with a note.

## How to get to it (user POV)

- `Démarches` → a démarche → `Intégrations` group; `Intégrations` → a fiche → `Démarches` group; `Intégrations` → `Ajouter`.

## Driving it with Capybara

`drive.rb integrations-de-l-api`, no lasting mutation (the forged save is refused).

- **Démarche 1.** Checkboxes in `Intégrations` = `integrations_proposees.count`, fewer than all intégrations (474 before); `(hors règle)` labels = checked links outside the rule.
- **Intégration.** First intégration with an out-of-rule démarche: checkboxes = `demarches_proposees.count`, at least one `(hors règle)`.
- **Refus serveur.** A hidden `integration[demarche_ids][]` for a démarche outside the list is injected, `Enregistrer`: error alert naming it, join table unchanged.
- **Nouvelle intégration.** `/admin/integrations/new`: no démarche checkbox, the hint `Démarches : à cocher une fois l’API ou le jeu de données enregistré…`.
- **Proof.** `tmp/verify/admin-integrations-de-l-api/`.
