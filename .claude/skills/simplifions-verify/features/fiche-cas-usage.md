# Lire une fiche cas d'usage

A cas d'usage page describes a démarche, its public, its legal frame, and the data sources recommended to simplify it, each unfolding in an accordion.

## Sub-features

- `fiche-entete` title, lead, public visé.
- `fiche-contexte` section `Contexte et cadre juridique`.
- `fiche-donnees` first tab `Données disponibles et utiles (N)`, panel `#donnees-disponibles`: one block per level-2 recommendation, accordions for direct API access and integrating solutions.
- `fiche-sans-solution` a moyen d'accès with no solution (« Aucun site », « Aucun logiciel », « Aucune brique ») is a plain line, no arrow, not clickable; its title is in the grey of that mention, readable on the card (≥ 4,5:1).

## How to get to it (user POV)

- From `/demarches`, click a card title.
- URL `/demarches/<slug>`; only visible démarches answer, others 404.
- Anyone, no login.

## Driving it with Capybara

Drive: `features/fiche-cas-usage.rb` (SKILL.md § Drive).

Preconditions:

- Launch done and doctor green (SKILL.md § Launch, § Doctor).
- The first card on `/demarches` has at least one level-2 recommendation with an accordion.
- The démarche `tarification-daccueil-du-jeune-enfant-par-un-eaje-beneficiant-de-la-psu` (Grist catalogue) is visible and has at least one moyen d'accès with no solution; if Grist renames it, pick another such démarche for `Sans solution`.

- **Open a fiche.** On `/demarches`, `titre = page.first("h3 a").text` then `click_link titre`. H1 equals `titre`.
- **Find the data.** `page.find("#donnees-disponibles")`, the tab panel selected on arrival.
- **Unfold.** In that section, click the first `button[aria-expanded='false']`. It becomes `aria-expanded='true'` and its panel shows.
- **Proof.** Screenshot after unfolding, read-back of the démarche slug and `recommandations.visibles.niveau_2.count`.
- **Sans solution.** Open `/demarches/tarification-daccueil-du-jeune-enfant-par-un-eaje-beneficiant-de-la-psu`. Each line whose screen-reader text says `(Aucune solution référencée)` is measured by script in light at 1280 and 375 px wide, then dark (`data-fr-theme`): title colour equal to its « Aucun … » badge, contrast of that colour on the first opaque background behind it ≥ 4,5, no button or link around it, no `::after` arrow. Proof: screenshot and read-back per condition.

## Gotchas

- The panel's H2 is `fr-sr-only`: assert the tab (`[role=tab]`), not the heading.
- Firefox will not shrink its window under about 500 px: the 375 px measure is Chrome's.
- Titles carry an emoji prefix (`💼 Marchés publics | …`); match the whole text.
