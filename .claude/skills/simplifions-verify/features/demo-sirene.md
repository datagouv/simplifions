# Démo Sirene

In the article « Qu'est-ce qu'une API ? », the « Démonstrateur avec l'API Sirene » block queries the API from the visitor's browser: while it waits, an icon turns next to « Interrogation de l'API en cours… ». When the visitor's device asks to reduce animations, the icon stays, still, and the text does not change.

## Sub-features

- `chargement` — the turning icon and its text while the API answers.
- `animations-reduites` — the same icon, still, under « réduire les animations ».

## How to get to it (user POV)

- `/articles/qu-est-ce-qu-une-api`, block « Démonstrateur avec l'API Sirene », field « Numéro de SIRET d'un établissement : », button « Interroger l'API ».
- Anyone, no login.

## Driving it with Capybara

Drive: `features/demo-sirene.rb` (SKILL.md § Drive).

Preconditions: none in the base; `window.fetch` is replaced by a promise that never settles, so the wait lasts and no request leaves the browser.

- **Turning.** Type `35600000000048`, click `Interroger l'API`: « Interrogation de l'API en cours… » shows, the icon beside it is visible and its computed `animation-name` is `sirene-spin`.
- **Still.** A second session whose browser asks to reduce animations (Chrome `--force-prefers-reduced-motion`, Firefox pref `ui.prefersReducedMotion` = 1), same steps: `matchMedia('(prefers-reduced-motion: reduce)')` matches, the same text shows, the icon is visible and its `animation-name` is `none`.
- **Proof.** Screenshot and read-back after each step: `reduce=<matches> animation=<name> icone=<visible>`.

## Gotchas

- Without the `fetch` stub the real API answers in a few hundred milliseconds and the icon is gone before it is read.
- The browser container holds one session: the first one is closed before the reduced-motion one opens.
