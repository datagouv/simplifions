# Lire le site sur un téléphone

Below 48em (phones), the public pages drop their desktop insets: the home blocks keep 16 px on each side, the catalogue folds its four facets under a `Filtres` button that counts the chosen ones, a cas d'usage card is shorter, the data text of a cas d'usage uses the card's width, and closing an access-means accordion leaves its title where it was. Desktop is unchanged; without JavaScript the facets stay unfolded.

## Sub-features

- `mobile-accueil` the two-column home blocks (« Ne demandez plus aux usagers… », the blue block, « Proposer une modification », « Règles de référencement ») have 16 px sides, 80 px on desktop; no sideways scroll.
- `mobile-filtres` on `/demarches` and `/solutions` a `Filtres` button folds the four facets and `Appliquer les filtres`; the page comes back folded with `Filtres (N)`; search, `Type` and results stay visible; desktop shows the column and its `Filtres` title, no button; without JavaScript the facets show, no button.
- `mobile-cartes` cas d'usage cards: title 18 px (20 px on desktop), inner padding 12 px (16 px).
- `mobile-fiche` a cas d'usage's « Données disponibles » and « Informations à saisir » blocks and their quotes start at most 40 px from the card edge.
- `mobile-accordeon` closing « Via un logiciel métier » keeps the scroll position, the title in place and the focus on it.

## How to get to it (user POV)

- A phone, or a desktop window narrowed under 768 px.
- `/`, `/demarches` (`/solutions` same list), `/demarches/<slug>`.
- Anyone, no login.

## Driving it with Capybara

Drive: `features/mobile.rb` (SKILL.md § Drive).

Preconditions:

- Launch done and doctor green (SKILL.md § Launch, § Doctor).
- One visible démarche whose recommandation's « Informations à saisir » holds a markdown quote (`> …`) and a « Via un logiciel métier » accordion.

- **Home.** `page.visit('/')`, read the left padding of the block holding « Ne demandez plus aux usagers » at 1280 px, then `resize_to(320, 812)`. `80px` then `16px`; `document.documentElement.scrollWidth <= innerWidth`.
- **Folded facets.** `page.visit('/demarches')`. Button `Filtres` `aria-expanded=false`, select `Démarches à destination des :` not visible, `Rechercher` and link `Cas d'usages` visible.
- **Open and apply.** `click` `Filtres`, `select 'Entreprises', from: 'Démarches à destination des :'`, `click_button 'Appliquer les filtres'`. URL gains `target-users=entreprises`, button `Filtres (1)` folded, the count equals `Demarche.catalogue({ 'target-users' => 'entreprises' }).count`; two more clicks open then fold it.
- **Cards.** First `#list h3`: font size `18px`, its parent's padding `12px`.
- **Fiche.** On the démarche of the preconditions, the first `#donnees-disponibles blockquote` text starts at most 40 px inside the card; no sideways scroll.
- **Accordion.** Scroll « Via un logiciel métier » to the middle, open it, close it. `scrollY`, the button's top and the focus are the same before and after closing.
- **Desktop.** `resize_to(1280, 1024)`, `/demarches`: no `Filtres` button, the facets and a `Filtres` paragraph show, card title `20px`, padding `16px`.
- **Without JavaScript.** `Verify.session(javascript: false)`, 320 px, `/demarches`: facets visible, no `Filtres` button.
- **Proof.** Screenshots `1-accueil` to `9-filtres-sans-js` in `tmp/verify/mobile/`, one read-back line per step (paddings, button text, page count against the base, quote offset, scroll before and after closing).

## Gotchas

- Firefox headless will not go under about 500 px wide: its run checks the phone layout at 500 px, still under 48em; Chrome runs at 320 px, the width of the reporter's iPhone.
- The accordion jump was reported on an iPhone (WebKit), probably because DSFR gives the focus back to the last focused element on closing, and a tapped button gets no focus in Safari. Chrome and Firefox focus the clicked button, so this drive cannot see a Safari-only jump.
