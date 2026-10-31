# Couleurs et ombres du DSFR

The colours and shadows that once were the site's own now come from DSFR tokens: the title band of the catalogue cards, the « 1/1 » counters (green, yellow, orange or red by share of integrated data), the grey icon of « Périmètre de simplification non couvert », the grey background of a solution's « Solutions intégrant … » part, and the shadows of the home box, the article screenshots and the floating « Proposer une modification » button.

## Sub-features

- `couleurs` — each of those elements has the computed colour or shadow of its DSFR token.
- `captures` — one capture per touched screen, desktop (1280 px) and phone (375 px), light mode: the before/after the PO validates.

## How to get to it (user POV)

- Home `/`: the box of the banner.
- Catalogue `/demarches`: the cas d'usage cards.
- A cas d'usage page, tab `Solutions ayant intégré ces données`: the counters on the cards and the floating button.
- A solution page `/solutions/<slug>`: the icon of « Périmètre de simplification non couvert », the part « Solutions intégrant … » and its counters.
- Article `/articles/qu-est-ce-qu-une-api`: the screenshots.
- Anyone, no login.

## Driving it with Capybara

Drive: `features/couleurs-dsfr.rb` (SKILL.md § Drive).

Preconditions: a visible démarche with integrating solutions (the drive takes the one whose counters show the most colours), a visible solution with a « non couvert » text (the one with the most integrating solutions).

- **Each screen.** Visit it, then for each rule read the computed style of every visible matching element and compare it with a probe `div` given the token (`var(--…)`), so the browser resolves both the same way. A rule with no visible element fails the screen (counters excepted: not every colour shows on every page). Then capture at 1280 and 375 px, the element scrolled to the centre.
- **Proof.** Check `Couleurs DSFR` lists every mismatch, after all captures are taken: run on the old CSS it fails and still leaves the « before » captures.

## Gotchas

- The hover colour of a card's band is not driven: the default headless browsers report no hover (see `survol-souris.md`).
- Firefox will not shrink below about 450 px: its `-mobile` captures are wider than Chrome's.
