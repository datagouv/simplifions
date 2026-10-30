# Plan du site

The `Plan du site` page lists the site's eight entries, each a level-2 heading link; under `Cas d'usages`, `Solutions` and `Articles`, one link per visible cas d'usage, per visible solution fiche and per article, in alphabetical order; under `À propos`, the two doctrine pages and the `Guide pour la simplification`. A fiche whose description is cut for search engines and link previews keeps its apostrophes readable in `meta description` and `og:description`.

## Sub-features

- `feuilles` — one link per visible cas d'usage, solution fiche and article, alphabetical.
- `a-propos` — doctrine pages and guide under `À propos`.
- `mobile` — no horizontal scroll at 375 px.
- `description-fiche` — a truncated fiche description shows `'`, never `&#39;`.

## How to get to it (user POV)

- Footer link `Plan du site` on every page → `/sitemap`.
- The description: source of `/demarches/<slug>` or `/solutions/<slug>` (`meta name=description`, `meta property=og:description`), what a search engine or a shared link shows.
- Anyone, no login.

## Driving it with Capybara

Drive: `features/plan-du-site.rb` (SKILL.md § Drive).

Preconditions: baseline catalogue; one visible démarche whose escaped chapo is longer than 155 characters and keeps an apostrophe once cut.

- **Open.** Home, footer `Plan du site` → `/sitemap`.
- **Feuilles.** The links of the list right under `Cas d'usages`, `Solutions`, `Articles` equal `Demarche.visibles.order(:nom)`, `Solution.visibles.fiches.order(:nom)` (names squished: the browser collapses spaces), the article titles sorted.
- **À propos.** Its list reads the two doctrine pages then `Guide pour la simplification`.
- **Mobile.** 375 wide: `scrollWidth` not above `innerWidth`.
- **Description.** That démarche's page: `meta description` content contains `'` and no `&#39;`, `og:description` the same.
- **Proof.** `tmp/verify/plan-du-site/<browser>-{bureau,mobile,description-fiche}.png` and `read-back.txt`: counts per entry against the base, widths, the description read.

## Gotchas

- `ul a` scoped to an `li` also matches its heading link (the outer list is an ancestor): use `:scope > ul a`.
- Dev names carry trailing or double spaces (`Gestion RH secteur public `, `Loisiciel  (ILE)`): compare squished.
- Firefox does not go below about 500 px wide; the mobile step reads 488/500 there.
