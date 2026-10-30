# Bouton « Proposer une modification »

Every cas d'usage and solution page keeps a floating « Proposer une modification » button at the bottom right, over the text. The element a keyboard user reaches with Tab is never hidden under it: the page scrolls until that element shows above the button. On a phone the button is as tall as on a computer (40 px).

## Sub-features

- `focus-visible` — no element reached with Tab sits under the button, at phone, narrow and computer widths.
- `hauteur` — the button is at least 40 px tall at every width.

## How to get to it (user POV)

- Bottom right of every cas d'usage page `/demarches/<slug>` and solution page `/solutions/<slug>`, text `Proposer une modification` (`Une modification ?` on a narrow screen).
- The long list of the tab « Solutions ayant intégré ces données » is where Tab brings links down to the bottom of the window.
- Anyone, no login.

## Driving it with Capybara

Drive: `features/bouton-proposer-modification.rb` (SKILL.md § Drive).

Preconditions: visible démarche `tarification-daccueil-du-jeune-enfant-par-un-eaje-beneficiant-de-la-psu` with integrating solutions (about 50 Tab stops in its solutions tab).

- **Phone.** Window 390×844, `/demarches/<slug>#solutions-integratrices`, focus on the tab, then Tab through every stop of the panel: none overlaps the button's box, and the button is at least 40 px tall.
- **Narrow.** Same at 500×844.
- **Computer.** Same at 1280×800.
- **Proof.** Screenshots `<largeur>-depart` and `<largeur>-dernier-arret`; read-back `fenetre=… arrets=… chevauchent=0 bouton=<hauteur>px`.

## Gotchas

- Firefox headless does not shrink its window below about 450 px: its « 390 » run is wider than Chrome's.
- Tab is sent with WebDriver's key actions, so the browser does its own scroll to the focused element, as for a user; `element.focus()` from a script would not exercise it the same way.
- The tab panel itself takes the focus (DSFR `tabindex=0`) and is taller than the window: it is not a stop the drive measures.
