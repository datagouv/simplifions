# Survol à la souris

Three site elements take a hover colour under the mouse: a cas d'usage card in the catalogue, the « Type » choice of the catalogue (`Cas d'usages` / `Solutions`) and the floating « Proposer une modification » button of a cas d'usage page. On a touch screen they keep their normal colour, even where a touch leaves the browser's hover state behind (back from the next page, back on the tab the button opened).

## Sub-features

- `souris` — the three elements change colour when the pointer is over them, on a device with a mouse.
- `tactile` — the same three elements keep their colour on a touch device.

## How to get to it (user POV)

- Card and « Type » choice: `/demarches`, header menu `Cas d'usages`.
- Floating button: bottom right of every cas d'usage page `/demarches/<slug>` (and solution page), text `Proposer une modification` (`Une modification ?` on a narrow screen).
- Anyone, no login.

## Driving it with Capybara

Drive: `features/survol-souris.rb` (SKILL.md § Drive).

Preconditions: at least one visible démarche. The default headless browsers report no hover at all, so each step opens its own session with the device it needs: a mouse (Chrome `--blink-settings=primaryPointerType=4,primaryHoverType=2`, Firefox pref `ui.primaryPointerCapabilities` = 6), then a phone (Chrome `--blink-settings=primaryPointerType=2,primaryHoverType=1`, Firefox `ui.primaryPointerCapabilities` = 1). Each session first checks `matchMedia('(hover: hover) and (pointer: fine)')`.

- **Mouse.** On `/demarches`, put the pointer on the first card's title link, then on the link `Solutions <count>`; on the first démarche page (by `nom`), on the floating link `Proposer une modification`. Each time the background colour of the link or one of its three parents differs from the one read with the pointer on the H1.
- **Touch.** Same steps in the phone session: no background colour changes.
- **Proof.** Screenshots `souris` and `tactile`; read-back `appareil=<souris|tactile> carte=<change|inchange> type=… bouton=…`.

## Gotchas

- The browser container holds one session: each emulated session is closed before the next opens.
- Chrome's mobile emulation with touch never sets `:hover` from WebDriver's pointer, so the touch step would pass on the unguarded CSS too; the pointer and hover types are set with `--blink-settings` instead. Both emulated sessions keep the desktop window size.
- WebDriver's pointer still sets `:hover` in the phone session, as a touch does; what the step proves is that the hover colour is kept for mouse devices.
