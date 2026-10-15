# Onglet des solutions ayant intégré les données

A cas d'usage page has two tabs: « Données disponibles et utiles (N) » and « Solutions ayant intégré ces données (N) ». The second ranks, by category (logiciel métier, brique, site), the solutions that integrated at least one useful published datum, with the same card and modal as the first tab.

## How to get to it (user POV)

- `/demarches/<slug>`, click the tab « Solutions ayant intégré ces données ».
- Anyone, no login.

## Driving it with Capybara

Preconditions: a visible démarche with `Demarche#integratrices_par_categorie` not empty.

- **Open.** Click `[role=tab][aria-controls=solutions-integratrices]`; `#solutions-integratrices.fr-tabs__panel--selected` appears, `#donnees-disponibles` goes hidden.
- **Proof.** Tab label count and card names, in order, against `integratrices_par_categorie` (flattened); category accordion titles in order.
- **Eye.** Click the first card's eye: `dialog#<aria-controls>[open]`, its total equals the card's x/y. Escape closes it.
- **No JS.** `Verify.session(javascript: false)`: `#solutions-integratrices` starts where `#donnees-disponibles` ends, its cards visible.

## Gotchas

- The tab label carries the count: match the whole text, not a Regexp (Capybara rejects a Regexp locator for buttons).
- Panels slide for 0.3 s after a tab click: wait on `.fr-tabs__panel--selected` before a screenshot.
