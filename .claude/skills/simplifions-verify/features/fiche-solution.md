# Lire une fiche solution

A solution page shows the operator badge (« Solution publique / privée | opérateur ») and, under « Solutions intégrant … », one tab per category of integrating solution with its count.

## How to get to it (user POV)

- From `/solutions`, click a card title; URL `/solutions/<slug>`, visible solutions only, anyone.

## Driving it with Capybara

Drive: `features/fiche-solution.rb` (SKILL.md § Drive).

Preconditions: a visible solution with integratrices in two categories or more (`bouquet-api-entreprise` in the Grist import).

- **Open.** Visit the solution with the most tabs (`Solution#integratrices_par_categorie`); the operator badge reads `Solution publique |` or `Solution privée |`.
- **Tabs.** `page.all('[role=tab]').map(&:text)` equals each category's label from `public.onglets_integratrices` with its count, in the model's order.
- **Switch.** Click the last tab; it becomes `aria-selected='true'`.
- **Card arrow.** In the open tab, a card's `.solution-integratrice-card__arrow` is `position: absolute` and its icon blue (`rgb(0, 0, 145)`): the stylesheet is shared with the cas d'usage cards.
- **Proof.** Screenshot after the switch, read-back of the slug, tab texts and model counts.
