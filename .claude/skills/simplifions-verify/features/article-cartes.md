# Cartes citées dans un article

An article cites solutions and cas d'usages as cards, in its spotlights and in the « Sont mentionnés dans cet article » carousel. Each card shows the catalogue record in the database: its name, its operator badge, its link.

## How to get to it (user POV)

- From `/articles`, click an article; URL `/articles/<slug>`.
- Anyone, no login.

## Driving it with Capybara

Drive: `features/article-cartes.rb` (SKILL.md § Drive).

Preconditions:

- App answers on `http://localhost:3101/up`.
- Visible solution `data-subvention` with an operator, visible démarche `tarification-cantine-scolaire-a-1eur`.

- **Cards from the base.** Visit `/articles/guide-base-petites-collectivites`. The spotlight holding `Data.Subvention` links to `/solutions/data-subvention` with the record's `nom`, and its badge bolds `organisations.first.nom`. A link to `/demarches/tarification-cantine-scolaire-a-1eur` carries the démarche's `titre`.
- **Hidden record.** `update_columns(visible: false)` on `data-subvention`, reload: the H1 is there, no card links to `/solutions/data-subvention` (`.fr-card a[href=…]`; the article prose keeps its own link). Restore `visible: true` in `ensure`.
- **Proof.** Screenshot and read-back after each step: badge text against the base, then `visible=false carte=absente`.

## Gotchas

- A spotlight whose every card is skipped disappears with its comment.
- The drive restores visibility even on failure; a crash before `ensure` leaves `data-subvention` hidden: `Solution.find_by(slug: 'data-subvention').update_columns(visible: true)`.
