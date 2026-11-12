# Une intégration ne vaut que pour les démarches de son API

The démarches of an intégration are those that recommend its API or jeu de données (a recommandation of `integree`, visible or not). The intégration form only offers those démarches; the démarche form only offers the intégrations whose API it recommends. A link already out of the rule stays checked, labelled `(hors règle)`, so it can be unchecked. The server refuses an out-of-rule link with `La démarche « … » ne recommande pas l’API ou le jeu de données intégré` and saves nothing. A new intégration (no API yet) or a démarche recommending nothing shows a hint instead of the list. The Grist import drops such links with a note.

## Sub-features

- `integrations-api-demarche` a démarche's intégrations windows (`Ajouter une intégration` on each card, `Modifier les intégrations` for those attached to no card) offer only intégrations of APIs it recommends, each one in a single window.
- `integrations-api-integration` an intégration offers only démarches recommending its API.
- `integrations-api-hors-regle` an out-of-rule link stays checked, labelled `(hors règle)`.
- `integrations-api-refus` the server refuses an out-of-rule link, names the démarche, saves nothing.
- `integrations-api-aide` a new intégration shows a hint instead of the list.
- `integrations-api-demarche-vide` a démarche recommending nothing shows a hint (spec only).
- `integrations-api-import` the Grist import drops out-of-rule links with a note (spec only).

## How to get to it (user POV)

- `Démarches` → a démarche → a card's `Ajouter une intégration`; `/admin/integrations` (typed: out of the admin menu) or a solution's row link `Modifier l’intégration <libellé>` → `Démarches` group; `/admin/integrations/new`.

## Driving it with Capybara

Drive: `features/admin-integrations-de-l-api.rb` (SKILL.md § Drive).

Preconditions: logged in, catalogue imported. The drive makes its own out-of-rule link: a throwaway démarche `Vérif verify-map <browser>` recommends the API of the first intégration, is linked to it, then loses the recommandation; the démarche and its link are deleted at the end. The forged save is refused, so nothing else changes.

- **Démarche 1.** Checkboxes of the intégrations windows, all cards together = `integrations_proposees.count`, fewer than all intégrations (474 before); `(hors règle)` labels = checked links outside the rule.
- **Intégration.** The first intégration, now linked to the throwaway démarche out of the rule: checkboxes = `demarches_proposees.count`, at least one `(hors règle)`.
- **Refus serveur.** A hidden `integration[demarche_ids][]` for a démarche outside the list is injected, `Enregistrer`: error alert naming it, join table unchanged.
- **Nouvelle intégration.** `/admin/integrations/new`: no démarche checkbox, the hint `Démarches : à cocher une fois l’API ou le jeu de données enregistré…`.
- **Proof.** `tmp/verify/admin-integrations-de-l-api/`.

## Gotchas

- `Intégrations` is in neither the admin menu nor the dashboard: reach its list and its fiches by URL ([admin-navigation.md](admin-navigation.md)).
