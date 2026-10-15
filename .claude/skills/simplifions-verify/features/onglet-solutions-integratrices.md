# Onglet des solutions ayant intégré les données

A cas d'usage page has two tabs: « Données disponibles et utiles (N) » and « Solutions ayant intégré ces données (N) ». The second groups, by category (logiciel métier, brique, site), the solutions that integrated at least one useful published datum, with the same card and window as the first tab, the counter at the cas d'usage total.

## How to get to it (user POV)

- `/demarches/<slug>`, click the tab « Solutions ayant intégré ces données ».
- Anyone, no login.

## Driving it with Capybara

Preconditions: a visible démarche with `Demarche#integratrices_par_categorie` not empty.

- **Open.** Click `[role=tab][aria-controls=solutions-integratrices]`; `#solutions-integratrices.fr-tabs__panel--selected` appears, `#donnees-disponibles` goes hidden.
- **Proof.** Tab label count and card names, in order, against `integratrices_par_categorie` (flattened); category titles in order (`h3 > .section-depliable__bouton`), the panel's computed background blue and as wide as the window.
- **Category.** Click the first category title (`.section-depliable__bouton`, arrow on its left, not the DSFR accordion): its cards hide (`aria-expanded=false`, arrow turned right); Enter on the focused title: they show, focus stays on the title.
- **Eye.** Click the first card's eye: `dialog#<aria-controls>[open]`, its « Sur l'ensemble du cas d'usage » count equals the card's total. Escape closes it.
- **No JS.** Quit the JS session (one session per browser container), then `Verify.session(javascript: false)`: `#solutions-integratrices` starts where `#donnees-disponibles` ends, its cards visible.

## Gotchas

- The tab label carries the count: match the whole text, not a Regexp (Capybara rejects a Regexp locator for buttons).
- Panels slide for 0.3 s after a tab click: wait on `.fr-tabs__panel--selected` before a screenshot.
