# Affichage personnalisé d'un cas d'usage

On a cas d'usage page, a blue banner under the breadcrumb offers three tags: « API et jeux de données », « Logiciels métiers « clé en main » », « Sites de consultation des données ». A pressed tag unfolds its sections and folds the others in both tabs (accordions of « Données disponibles et utiles », categories of « Solutions ayant intégré ces données »); nothing is hidden. « API et jeux de données » covers direct access and briques. Several tags add up, a second press removes one; with none, tab 1 is all folded and tab 2 all unfolded. On desktop and tablet the breadcrumb stays at the top while scrolling; once scrolled, the banner folds for good and a button « Affichage personnalisé » (« (2) » with two tags) brings the tags back under the breadcrumb. On phone nothing sticks and the button never shows.

## Sub-features

- `tags` — press, add, remove a tag; sections unfold and fold in both tabs.
- `aucun-tag` — the default folding of each tab.
- `defilement` — sticky breadcrumb, banner folding, the button and its count (desktop and tablet).
- `ancres` — a sommaire link or an `#ancre` lands below the sticky header, banner open or folded (desktop and tablet).
- `mobile` — no sticky breadcrumb, no button.
- `sans-js` — no tag, no button, every section readable.

## How to get to it (user POV)

- `/demarches/<slug>`, the banner is open on arrival; after scrolling on a screen at least 768 px wide, the button at the right of the breadcrumb.
- Anyone, no login.

## Driving it with Capybara

Drive: `features/affichage-personnalise.rb` (SKILL.md § Drive).

Preconditions: a visible démarche with at least two categories in `Demarche#integratrices_par_categorie` (the first by id).

- **Arrival.** Three `button.fr-tag`, role `button`, `aria-pressed=false`; no `Affichage personnalisé` button; tab 1 no `[data-filtre] > .fr-collapse--expanded`, tab 2 every category content (`[data-section-depliable-target=contenu]`, the custom disclosure, not a DSFR collapse) not `hidden`.
- **Keyboard.** Each tag is pressed with `send_keys(:space)` on the button; `aria-pressed` flips, focus stays on it.
- **Tags.** « Logiciels métiers « clé en main » »: only `[data-filtre=logiciels]` sections expanded in both tabs, no `[data-filtre]` with `display: none`; add « Sites de consultation des données »: both; press « Logiciels » again: sites only; release all: back to Arrival. « API et jeux de données »: direct access and brique of tab 1, brique category of tab 2.
- **Scroll.** At 1280 and 800 wide, `window.scrollTo(0, 1500)`: header top at 0, tags folded, button shown; click it: tags between the breadcrumb bottom and the header bottom; two tags pressed: `Affichage personnalisé (2)`.
- **Anchors.** At 1280 and 800 wide, each sommaire link, then the page loaded with that `#ancre`, then `location.hash` with the tags reopened by the button: the target's top is below the header's bottom (the sticky header sets the page's `scroll-padding-top` to its height).
- **Slow scroll.** At 1280 and 375 wide, 15 × `scrollBy(0, 40)`: `scrollY` keeps growing past 300. Folding the banner shortens the page and the browser's scroll anchoring pulls `scrollY` back once; the banner never reopens by itself, or the page would bounce back to the top.
- **Turbo.** From `/demarches`, `Turbo.visit` to the page: a tag unfolds its sections, the button counts it.
- **Mobile.** Window 375 wide, scrolled: header above the viewport, no button, page does not overflow.
- **No JS.** `Verify.session(javascript: false)`: no tag, no button, every `[data-filtre]` content (DSFR collapse in tab 1, category content in tab 2) visible.
- **Proof.** `tmp/verify/affichage-personnalise/read-back.txt`: expanded sections per tag and tab against the totals read in the page, header position and button text per width.

## Gotchas

- Clicking a tab scrolls past the top, so the banner folds: reopen it with the button before pressing a tag (`basculer_au_clavier` does).
- Wait for `.fr-collapsing` to go before counting expanded sections.
- The recommandation accordions are `data-fr-group="false"`: in a DSFR group, opening the brique accordion closed the direct-access one.
- Headless Firefox will not go under about 480 px wide: still a phone width.
