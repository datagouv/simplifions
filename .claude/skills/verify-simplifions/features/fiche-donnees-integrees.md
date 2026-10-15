# Voir les données intégrées par une solution

On a cas d'usage page, each integrating solution card in « Données disponibles » has an eye button that opens one modal per solution: the useful published data of the cas d'usage, grouped by recommended data, each checked or crossed.

## How to get to it (user POV)

- `/demarches/<slug>`, unfold a « Via … » accordion, click the eye on a card.
- Anyone, no login.

## Driving it with Capybara

Preconditions: a visible démarche with useful data and integrating solutions (`Demarche#integratrices` not empty).

- **Open.** Unfold the accordion holding the first eye button (`aria-controls` of the `.fr-collapse` around it), click the eye. `dialog#<aria-controls>[open]` appears.
- **Proof.** Read-back of the total in the modal against `Demarche#donnees_utiles.size`, of the dialog count against `integratrices.size` (one modal per solution), and one eye per card.
- **Close.** Escape: the dialog loses `open`, focus is back on the eye (`document.activeElement` has the same `aria-controls`).

## Gotchas

- Modals sit at the end of the section, outside the accordions: find them with `visible: :all` until opened.
- Headless Firefox does not go below 500 px wide; check 375 px in Chrome.
