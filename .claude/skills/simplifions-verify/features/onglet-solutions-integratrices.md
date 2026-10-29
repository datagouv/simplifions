# Onglet des solutions ayant intégré les données

A cas d'usage page has two tabs: « Données disponibles et utiles (N) » and « Solutions ayant intégré ces données (N) ». The second groups, by category (logiciel métier, brique, site), the solutions that integrated at least one useful published datum, with the same card and window as the first tab, the counter at the cas d'usage total.

## How to get to it (user POV)

- `/demarches/<slug>`, click the tab « Solutions ayant intégré ces données », its sommaire entry, or any link to `/demarches/<slug>#solutions-integratrices`.
- Anyone, no login.

## Driving it with Capybara

Preconditions: a visible démarche with `Demarche#integratrices_par_categorie` not empty.

- **Open.** Click `[role=tab][aria-controls=solutions-integratrices]`; `#solutions-integratrices.fr-tabs__panel--selected` appears, `#donnees-disponibles` goes hidden.
- **Proof.** Tab label count and card names, in order, against `integratrices_par_categorie` (flattened); category titles in order (`h3 > .section-depliable__bouton`), the panel's computed background blue and as wide as the window.
- **Titles.** Each category title is plural (« Logiciels métier « clé en main » », « Briques logicielles à intégrer », « Sites de consultation »), followed by a blue badge with its number of solutions (« 12 logiciels ») and, except for briques, « Sans développement »; a one-line description opens its content. At 1280 and 375 px the title line stays inside the window, badges wrapping under the title.
- **Category.** Click the first category title (`.section-depliable__bouton`, arrow on its left, not the DSFR accordion): its description and cards hide (`aria-expanded=false`, arrow turned right); Enter on the focused title: they show, focus stays on the title.
- **Eye.** Click the first card's eye: `dialog#<aria-controls>[open]`, its « Sur l'ensemble du cas d'usage » count equals the card's total. Escape closes it.
- **Anchor.** Visit `/demarches/<slug>#solutions-integratrices` (link from another site, full load), then from `/demarches` run `Turbo.visit` to the same URL (link inside the site): the solutions panel is selected on arrival both ways. Then, from the page without hash, click the sommaire link `Solutions ayant intégré ces données`: same, in the same document (a `window` flag set before the click survives, no reload). Read back the panel's top in the viewport.
- **No JS.** Quit the JS session (one session per browser container), then `Verify.session(javascript: false)`: `#solutions-integratrices` starts where `#donnees-disponibles` ends, its cards visible.

## Gotchas

- Firefox headless does not shrink its window below about 450 px: its « 375 » screenshot is wider than Chrome's.
- DSFR badges are uppercased by CSS: read their text with `text(:all)`.
- The tab label carries the count: match the whole text, not a Regexp (Capybara rejects a Regexp locator for buttons).
- Turbo 8.0.23 turns every `#ancre` link into a visit that reloads the page (its same-page test reads `link.href`, always absolute): the sommaire opts out with `data-turbo="false"` and jumps natively. A Turbo visit from another page re-renders without `hashchange`; `application.js` fires one on `turbo:render` so the DSFR reads the new anchor. Without it the tab looked selected at 0.1 s and fell back to tab 1 at 0.5 s: assert the selected panel again after the wait.
- A Turbo visit to this page re-renders a heavy body: about 1.5 s in Chrome, past 5 s on a loaded machine (seen with CPU throttled x6, also in a headed Chrome), while Firefox stays faster. The anchor steps wait up to 20 s for the solutions panel, not Capybara's default 5 s; the page itself always ends on the right tab.
- Panels slide for 0.3 s after a tab click: wait on `.fr-tabs__panel--selected` before a screenshot.
