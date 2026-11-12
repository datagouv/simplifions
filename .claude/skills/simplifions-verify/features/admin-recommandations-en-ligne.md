# Gérer les solutions recommandées, leurs données utiles et leurs intégrations dans la fiche démarche

On a démarche's fiche, under `Contexte` and `Cadre juridique`, the block `Solutions recommandées (<n>)` shows each `niveau_2` recommandation as a card: `Position <n>` (or `Sans position`), the solution, a badge `Masquée` (not online) or `Ajoutée au brouillon` (goes online with the démarche's `Publier`), `Modifier <solution>` and `Retirer <solution>`; a last card `Ajouter une solution recommandée`. Positions, types and texts are read from the draft. A card whose solution provides APIs lists `Données utiles (<n>)`: the `niveau_1` recommandations of those APIs, with their position or `—`; each one sits in the first card, in order, whose solution provides it, the others under `Rattachées à aucune solution recommandée`. The card's `Ajouter une donnée utile à <solution>` opens its window: one line per donnée utile of the card (`Solution`, `Position`, `En quoi cette API ou ce jeu de données est utile`, `Enregistrer`, `Retirer`) plus a blank line `Ajouter une donnée utile` whose `Solution` lists only the APIs the solution provides and the démarche does not recommend yet. Every card lists `Intégrations (<n>)`, the checked intégrations of its APIs; `Ajouter une intégration à <solution>` opens the filterable list of those intégrations, saved with the fiche (a draft on a published démarche). Données utiles and intégrations attached to no card keep their own windows (`Modifier les données utiles`, `Modifier les intégrations`) under `Rattachées à aucune solution recommandée`. `Modifier <solution>` opens a window with `Solution`, `Type de recommandation`, `Position`, the three long texts and `URL de demande d’accès pour cette démarche`; `Enregistrer` closes it and updates the card in place (turbo-stream, message in `#message-recommandations`), a refused save reopens it with the error under its field. `Changer l’ordre` shows a handle on each card: dragging a card saves its new position among the cards (through the draft on a published démarche). `Retirer` asks `Supprimer la recommandation <solution> ?`, followed by `La suppression est immédiate, même pendant un brouillon : « Abandonner le brouillon » ne la remet pas.` when it deletes at once while a draft could be abandoned (a recommandation added in the draft of a published démarche, or a hidden démarche with a draft); on a published démarche an online recommandation is not deleted but waits for `Publier` (`admin-brouillon.md`, `retrait-en-brouillon`). Draft rules are the recommandation page's (`admin-recommandations-avec-la-demarche.md`).

## Sub-features

- `recos-cartes` cards with position, solution and badge; count in the heading; each donnée utile listed once, in its card or under `Rattachées à aucune solution recommandée`.
- `recos-fenetre-modifier` `Modifier <solution>` → window, `Enregistrer` → window closed, card updated, draft on a published démarche, focus back on `Modifier`.
- `recos-fenetre-erreur` a refused save reopens the window, `Choisissez une solution` under `Solution`.
- `recos-ajouter` `Ajouter une solution recommandée` → the same window, empty; the new card `Ajoutée au brouillon`.
- `recos-changer-l-ordre` `Changer l’ordre` shows the handles; a dragged card saves its position, the mode stays open; a refused neighbour stops the whole move (`Recommandation non déplacée : …`, request spec only).
- `recos-donnees-utiles` a card's `Ajouter une donnée utile à <solution>` → its window; a line saves alone, the window stays open, the card's list follows; the blank line offers only the APIs of that solution not yet recommended.
- `recos-integrations` a card's `Ajouter une intégration à <solution>` → that solution's intégrations only; `Enregistrer` → the card lists the new one, in the draft.
- `recos-retirer` `Retirer <solution>` on a card added in the draft: confirmation with the warning, card gone, focus on `supprimé`.
- `recos-etroit` no page-level horizontal scroll at 375 px.

## How to get to it (user POV)

`/admin/demarches/<id>/edit`, block `Solutions recommandées (<n>)`. Admin only.

## Driving it with Capybara

Drive: `features/admin-recommandations-en-ligne.rb` (SKILL.md § Drive).

Preconditions: logged in; the drive mutates then puts back every recommandation of the démarche as it found it (order and draft), the démarche's draft too, and deletes what it added. Démarche: among the visible ones with a slug, the one with the most cards that has a card to complete (not removed, with données utiles, an API it provides not yet recommended, an intégration not yet checked); card: its first one; solution to add: the first public API it does not recommend yet.

- **Cards.** `Solutions recommandées (<n>)` and the number of données utiles lines match the base read through the drafts; first card `Position <n>`.
- **Modify.** `Modifier <solution>` of the first card, `Position` 77, `Enregistrer` → no open window, card `Position 77`, `brouillon enregistré` in `#message-recommandations`, focus on `Modifier <solution>`, base ordre unchanged, 77 in the draft.
- **Error.** `Ajouter une solution recommandée`, `Enregistrer` with no solution → the window open again, `Choisissez une solution` under `Solution`.
- **Add.** Same window: the solution, `Enregistrer` → a new card `Ajoutée au brouillon`, count +1, base `visible` false.
- **Order.** The hint `Glissez une carte par sa poignée…` hidden; `Changer l’ordre` (`aria-expanded` true) shows it and the handles; drag the second card's handle onto the first card → `déplacée en position 1`, the card first in the grid and in base (draft order), the mode still open (handles shown) for the next drag.
- **Données utiles.** The card to complete: `Ajouter une donnée utile à <solution>` opens its own window; first line `Position` 55, its `Enregistrer` → message naming that line's solution in the window (and none behind it), window still open, focus on that line's form; the blank line's `Solution` offers exactly the APIs of the solution not yet recommended, the first one `Ajouter` → message naming it; `Fermer`: the card lists the line with `55` and the new one.
- **Intégrations.** Same card: `Ajouter une intégration à <solution>`, filter if the field is there, check its first unchecked intégration, `Enregistrer` → `brouillon enregistré`, the card's `Intégrations (<n>)` one more and lists it, the draft's `integration_ids` holds it.
- **Remove.** `Retirer <added solution>`: dismiss the confirmation (it reads `Supprimer la recommandation <solution> ? <avertissement>`, card stays), accept it → card gone, `supprimé` in `#message-recommandations`, which takes the focus.
- **Public page.** `/demarches/<slug>` cards unchanged.
- **Narrow.** At 375 px, no page-level horizontal scroll.
- **Proof.** `tmp/verify/admin-recommandations-en-ligne/`.

## Gotchas

- Firefox ignores Capybara's `drag_to` on SortableJS: `Verify.glisser` (harness.rb) falls back to Selenium actions (`click_and_hold`, `move_to`, `release`) for every drag of the map. Actions need both handles in the viewport: the drive drags the second card onto the first, scrolled to the centre.
- A modal button needs `data-fr-opened` for DSFR; a turbo-stream that replaces the button of an open window closes it. The windows of the cards close on `Enregistrer` (`aria-controls`) before the stream lands; a card's données utiles window stays open because a save there updates only its lines and the card's list, never the card itself, which holds the window's button.
- Each answer writes its message in the zone that acted (`#message-recommandations` for the cards, `#message-donnees-utiles-<card>` for a card's données utiles window) and empties the other: a check waits for the message naming its own solution, never for any message.
- `Intégrations` saves the whole fiche: on a démarche with many cards, Firefox takes more than Capybara's 5 s to reload it (Chrome less); that one check waits 15 s.
- Reordering writes the order of every card of the démarche (in its draft when it is published): the drive saves every recommandation's `ordre` and `brouillon` first and puts them back in its `ensure`.
