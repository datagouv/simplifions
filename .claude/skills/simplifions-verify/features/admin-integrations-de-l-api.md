# Une intégration ne vaut que pour les démarches de son API

The démarches of an intégration are those that recommend its API or jeu de données (a recommandation of `integree`, visible or not). The intégration form only offers those démarches; the démarche form only offers the intégrations whose API it recommends. A link already out of the rule stays checked, labelled `(hors règle)`, so it can be unchecked. The server refuses an out-of-rule link with `La démarche « … » ne recommande pas l’API ou le jeu de données intégré` and saves nothing. A new intégration (no API yet) or a démarche recommending nothing shows a hint instead of the list. The Grist import drops such links with a note.

## How to get to it (user POV)

- `Démarches` → a démarche → `Intégrations (<n>)` tab; `Intégrations` → a fiche → `Démarches` group; `Intégrations` → `Ajouter`.

## Driving it with Capybara

Drive: `features/admin-integrations-de-l-api.rb` (SKILL.md § Drive).

Preconditions: logged in, catalogue imported. The drive makes its own out-of-rule link: a throwaway démarche `Vérif verify-map <browser>` recommends the API of the first intégration, is linked to it, then loses the recommandation; the démarche and its link are deleted at the end. The forged save is refused, so nothing else changes.

- **Démarche 1.** Checkboxes in `Intégrations` = `integrations_proposees.count`, fewer than all intégrations (474 before); `(hors règle)` labels = checked links outside the rule.
- **Intégration.** The first intégration, now linked to the throwaway démarche out of the rule: checkboxes = `demarches_proposees.count`, at least one `(hors règle)`.
- **Refus serveur.** A hidden `integration[demarche_ids][]` for a démarche outside the list is injected, `Enregistrer`: error alert naming it, join table unchanged.
- **Nouvelle intégration.** `/admin/integrations/new`: no démarche checkbox, the hint `Démarches : à cocher une fois l’API ou le jeu de données enregistré…`.
- **Proof.** `tmp/verify/admin-integrations-de-l-api/`.
