# Lire une fiche cas d'usage

A cas d'usage page describes a démarche, its public, its legal frame, and the data sources recommended to simplify it, each unfolding in an accordion.

## Sub-features

- `fiche-entete` title, lead, public visé.
- `fiche-contexte` section `Contexte et cadre juridique`.
- `fiche-donnees` first tab `Données disponibles et utiles (N)`, panel `#donnees-disponibles`: one block per level-2 recommendation, accordions for direct API access and integrating solutions.

## How to get to it (user POV)

- From `/demarches`, click a card title.
- URL `/demarches/<slug>`; only visible démarches answer, others 404.
- Anyone, no login.

## Driving it with Capybara

Drive: `features/fiche-cas-usage.rb` (SKILL.md § Drive).

Preconditions:

- Launch done and doctor green (SKILL.md § Launch, § Doctor).
- The first card on `/demarches` has at least one level-2 recommendation with an accordion.

- **Open a fiche.** On `/demarches`, `titre = page.first("h3 a").text` then `click_link titre`. H1 equals `titre`.
- **Find the data.** `page.find("#donnees-disponibles")`, the tab panel selected on arrival.
- **Unfold.** In that section, click the first `button[aria-expanded='false']`. It becomes `aria-expanded='true'` and its panel shows.
- **Proof.** Screenshot after unfolding, read-back of the démarche slug and `recommandations.visibles.niveau_2.count`.

## Gotchas

- The panel's H2 is `fr-sr-only`: assert the tab (`[role=tab]`), not the heading.
- Titles carry an emoji prefix (`💼 Marchés publics | …`); match the whole text.
