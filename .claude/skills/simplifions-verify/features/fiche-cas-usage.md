# Lire une fiche cas d'usage

A cas d'usage page describes a démarche, its public, its legal frame, and the data sources recommended to simplify it, each unfolding in an accordion.

## Sub-features

- `fiche-entete` title, lead, public visé.
- `fiche-contexte` section `Contexte et cadre juridique`.
- `fiche-donnees` section `Données disponibles`: one block per level-2 recommendation, accordions for direct API access and integrating solutions.

## How to get to it (user POV)

- From `/demarches`, click a card title.
- URL `/demarches/<slug>`; only visible démarches answer, others 404.
- Anyone, no login.

## Driving it with Capybara

Preconditions:

- App answers on `http://localhost:3101/up`.
- The first card on `/demarches` has at least one level-2 recommendation with an accordion.

- **Open a fiche.** On `/demarches`, `titre = page.first("h3 a").text` then `click_link titre`. H1 equals `titre`.
- **Find the data.** `page.find("section", text: "Données disponibles", match: :first)`.
- **Unfold.** In that section, click the first `button[aria-expanded='false']`. It becomes `aria-expanded='true'` and its panel shows.
- **Proof.** Screenshot after unfolding, read-back of the démarche slug and `recommandations.visibles.niveau_2.count`.

## Gotchas

- The section ids (`donnees-disponibles`) sit on the H2, not on the section: scope by section text.
- Titles carry an emoji prefix (`💼 Marchés publics | …`); match the whole text.
