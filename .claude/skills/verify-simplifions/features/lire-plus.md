# Lire plus sur Contexte et Cadre juridique

On a cas d'usage page, Contexte and Cadre juridique taller than 8 lines are folded, with a button « Lire plus » under the text that unfolds it and becomes « Lire moins ». A shorter text shows whole with no button; without JavaScript every text shows whole.

## How to get to it (user POV)

- `/demarches/<slug>`, section « Contexte et cadre juridique », first block of the page under the header.
- Anyone, no login.

## Driving it with Capybara

Preconditions: the visible démarche with the longest `contexte` (folded), the one with the shortest non-blank `cadre_juridique` (whole).

- **Folded.** `#contexte-texte` has `lire-plus--replie`, `scrollHeight > clientHeight` (192 px = 8 × 24), button `Lire plus : Contexte` (the section name is `fr-sr-only`), `aria-expanded=false`, `aria-controls=contexte-texte`.
- **Toggle.** Click: class gone, whole height, `Lire moins : Contexte`, `aria-expanded=true`; click again: folded back.
- **Focus.** Focusing a link inside the folded text unfolds it.
- **Mobile.** 375 wide: still folded with its button (a `ResizeObserver` re-measures).
- **Short.** `#cadre-juridique-texte` not cut, button hidden.
- **Threshold.** Every visible cas d'usage: the button shows if and only if unfolding reveals text (a text of exactly 8 lines has no button; the last paragraph's bottom margin is zeroed so it does not count as a 9th line).
- **No JS.** `Verify.session(javascript: false)`: no class, button hidden.

## Gotchas

- A blank field keeps « Aucun contenu actuellement » with no wrapper and no button.
- Read the state with `checkVisibility()` and `classList` in the browser; poll a few times, the `ResizeObserver` callback runs after the first paint.
