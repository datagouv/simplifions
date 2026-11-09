# Recommandations ajoutées dans le brouillon de leur démarche

A recommandation added to a démarche, hidden or published, waits for the démarche: it goes online with the démarche's `Publier`, shows in its `Prévisualiser`, and `Abandonner le brouillon` of the démarche deletes it when it was added since the last publication, and drops the draft of one already online. While a recommandation waits for the démarche's `Publier` (added, or an online one with a draft), the démarche's state bar shows `Brouillon non publié`, `Prévisualiser` and `Abandonner le brouillon`, even with no change of its own. The preview shows the recommandations as `Publier` will publish them: card or donnée utile, order and texts taken from their drafts.

## Sub-features

- `reco-demarche-masquee` a recommandation added to a hidden démarche goes online with the démarche's `Publier`, no other click.
- `reco-demarche-apercu` a démarche where only an added recommandation waits offers `Prévisualiser`; the preview shows its card, the public page does not.
- `reco-demarche-abandon` `Abandonner le brouillon` of the démarche deletes the recommandation added since its publication; the one already online stays.
- `reco-demarche-apercu-publie` an online recommandation with a draft (new `Position`) puts the démarche in `Brouillon non publié` with `Prévisualiser` and `Abandonner le brouillon`; the preview's cards are the public page's after `Publier`.

## How to get to it (user POV)

`/admin/demarches/<id>/edit`, block `Solutions recommandées (<n>)`, `Ajouter une solution recommandée`, then the state bar above the fiche. Admin only.

## Driving it with Capybara

Drive: `features/admin-recommandations-avec-la-demarche.rb` (SKILL.md § Drive).

Preconditions: logged in. Creates its own hidden démarche `Vérif reco-demarche <browser>` (slug `verif-reco-demarche-<browser>`) and deletes it with its recommandations; solutions: the first two public APIs.

- **Hidden démarche.** `Ajouter une solution recommandée`, window: `Solution` first API (type `Solution recommandée` already chosen), `Enregistrer` → state bar `Publier` → `/demarches/<slug>` shows one card, the first API's; in base the recommandation is visible, without draft.
- **Preview.** Same window with the second API → the state bar shows `Brouillon non publié` and `Prévisualiser`; the preview window shows two cards, the public page still one.
- **Abandon.** `Abandonner le brouillon`, accept the confirmation → the second API's card is gone, still one card on the public page, the first recommandation still in base.
- **Preview as published.** Add the second API again, state bar `Publier` (two cards, first API first); `Modifier <second API>`, window `Position` `0`, `Enregistrer` → state bar `Brouillon non publié`, `Prévisualiser`, `Abandonner le brouillon`; the preview's cards, second API first, differ from the public page's, then equal them after `Publier ce changement`, as the state bar's button reads once the démarche is published.
- **Proof.** `tmp/verify/admin-recommandations-avec-la-demarche/`.

## Gotchas

- `Publier` and `Abandonner le brouillon` live in the state bar; on a published démarche with a change, in its box `À la publication, …`, `Publier` reading `Publier ce changement` or `Publier ces N changements` (`click_button 'Publier'` finds both).
