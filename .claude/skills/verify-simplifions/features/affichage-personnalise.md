# Affichage personnalisé d'un cas d'usage

On a cas d'usage page, a blue banner under the breadcrumb offers three tags: « API et jeux de données », « Logiciels métiers », « Sites de consultation ». A pressed tag keeps only its blocks in both tabs (accordions of « Données disponibles », categories of « Solutions ayant intégré ces données », cards and tables); several tags = union, none = everything. « API et jeux de données » also opens the direct-access and brique accordions. The breadcrumb stays at the top while scrolling; once scrolled, the banner folds and a button « Affichage personnalisé » brings the tags back under the breadcrumb.

## How to get to it (user POV)

- `/demarches/<slug>`, the banner is open on arrival; after scrolling, the button at the right of the breadcrumb.
- Anyone, no login.

## Driving it with Capybara

Preconditions: a visible démarche with at least two categories in `Demarche#integratrices_par_categorie` (the first by id has 12 recommandations and the three categories).

- **Arrival.** Three `button.fr-tag`, role `button`, `aria-pressed=false`; no `Affichage personnalisé` button at the top of the page.
- **Keyboard.** Each tag is pressed with `send_keys(:space)` on the button; `aria-pressed` flips, focus stays on it.
- **Proof.** Visible `[data-filtre=<api|logiciels|sites>]` per panel (`checkVisibility()`), against `recommandations_affichees.size` (tab 1: 2 api, 1 logiciels, 1 sites per recommandation) and the categories of `integratrices_par_categorie` (tab 2, brique counted as api). Tab 2 in « Tableau »: only the pressed category's table shows.
- **API.** With « API et jeux de données » pressed, every `[data-filtre=api] > .fr-collapse` of tab 1 is `fr-collapse--expanded`.
- **Scroll.** `window.scrollTo(0, 1500)`: header top at 0, tags hidden, button shown; click it: tags between the breadcrumb bottom and the header bottom; back to the top: button gone, the pressed tag kept.
- **Turbo.** From `/demarches`, `Turbo.visit` to the page: scroll, button, a tag filters.
- **Mobile.** Window 375 wide: header sticks at 0, page does not overflow.
- **No JS.** `Verify.session(javascript: false)`: no tag, no button, every block shown.

## Gotchas

- Clicking a tab scrolls past the top, so the banner folds: reopen it with the button before pressing a tag.
- `page.all(..).size` with visibility checks on hundreds of nodes takes seconds; count with `checkVisibility()` in the browser.
- The recommandation accordions are `data-fr-group="false"`: in a DSFR group, opening the brique accordion closed the direct-access one.
