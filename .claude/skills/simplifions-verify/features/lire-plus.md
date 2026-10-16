# Lire plus sur Contexte et Cadre juridique

On a cas d'usage page, Contexte and Cadre juridique taller than 8 lines are folded, their bottom fading out, with a button « Lire plus » under the text, looking like a link with a down arrow, that unfolds it and becomes « Lire moins » with an up arrow. A shorter text shows whole with no button; without JavaScript every text shows whole.

## How to get to it (user POV)

- `/demarches/<slug>`, section « Contexte et cadre juridique », first block of the page under the header.
- Anyone, no login.

## Driving it with Capybara

Preconditions: the visible démarche with the longest `contexte` (folded), the one with the shortest non-blank `cadre_juridique` (whole).

- **Folded.** `#contexte-texte` has `lire-plus--replie`, `scrollHeight > clientHeight` (192 px = 8 × 24), computed `mask-image` not `none` (the fade), button `Lire plus : Contexte` (the section name is `fr-sr-only`), `fr-link` with `fr-icon-arrow-down-s-line`, `aria-expanded=false`, `aria-controls=contexte-texte`.
- **Toggle.** Click: class gone, whole height, no fade, `Lire moins : Contexte` with `fr-icon-arrow-up-s-line`, `aria-expanded=true`; click again (the button scrolled to the bottom of the window, the title « Contexte » out of view above): folded back, the title « Contexte » back in view below the header, the page does not jump down to the tabs.
- **Focus.** Focusing a link inside the folded text unfolds it.
- **Mobile.** 375 wide: still folded with its button (a `ResizeObserver` re-measures); unfold then fold from the bottom: title back in view.
- **Short.** `#cadre-juridique-texte` not cut, no fade, button hidden.
- **Threshold.** Every visible cas d'usage: the button shows if and only if unfolding reveals text (a text of exactly 8 lines has no button; the last paragraph's bottom margin is zeroed so it does not count as a 9th line).
- **No JS.** `Verify.session(javascript: false)`: no class, button hidden.

## Gotchas

- A blank field keeps « Aucun contenu actuellement » with no wrapper and no button.
- The browser container holds one session: the JS session is closed before the no-JS one opens, or it waits until `Net::ReadTimeout`.
- Read the state with `checkVisibility()` and `classList` in the browser; poll a few times, the `ResizeObserver` callback runs after the first paint.
