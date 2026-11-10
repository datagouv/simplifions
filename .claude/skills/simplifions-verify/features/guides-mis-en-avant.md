# Guides mis en avant

The site puts its guides (articles) where a visitor looks for help. The home page has a section `Nos guides pour simplifier vos démarches` with three article cards (the commune guide, « Anticiper le parcours usager », « Prérequis et étapes d'intégration ») and a `Voir tous les articles` button. In the catalogue of cas d'usages or of solutions, filtered on `Communes et groupements de communes`, the first page shows after its third result (after the last one when there are fewer) the sentence `Vous êtes une mairie ou une petite collectivité ? Nous vous recommandons cet article :` and a horizontal card of the commune guide; another filter or another page shows none. A shared article carries its image (`og:image`) and, for search engines, a schema.org `Article` with its publication and update dates.

## Sub-features

- `guides-accueil` the home section: three cards, each opening its article, then `Voir tous les articles`.
- `guides-catalogue-communes` the commune guide card after the third result of the catalogue filtered on communes, cas d'usages and solutions; absent with another filter.
- `guides-partage` an article page gives `og:image` (its image) and a JSON-LD `Article` with `headline`, `datePublished`, `dateModified`.

## How to get to it (user POV)

- `/`, section `Nos guides pour simplifier vos démarches`, below the home blocks.
- `/demarches` or `/solutions` → `Démarches gérées par :` `Communes et groupements de communes` → `Appliquer les filtres`; or the footer link `Communes et groupements de communes` ([pied-de-page.md](pied-de-page.md)).
- Any `/articles/<slug>`: the shared-link image and the search-engine data sit in `<head>`.
- Anyone, no login.

## Driving it with Capybara

Drive: `features/guides-mis-en-avant.rb` (SKILL.md § Drive).

Preconditions:

- Catalogue imported: at least one visible démarche and one visible solution whose fournisseurs include communes.
- Read-only.

- **Home.** Visit `/`: the H2 `Nos guides pour simplifier vos démarches`, three card links in the order of the home guides, each to `/articles/<slug>` with the article's `h1`; `Voir tous les articles` opens `/articles`.
- **Communes, cas d'usages.** `/demarches`, select `Communes et groupements de communes` from `Démarches gérées par :`, `Appliquer les filtres`: the URL holds `fournisseurs-de-service=communes`, the sentence `Vous êtes une mairie ou une petite collectivité ?` shows, its list item follows as many result cards as `min(3, results on the page)`, its card links to `/articles/guide-base-petites-collectivites`.
- **Communes, solutions.** Same on `/solutions`.
- **Other filter.** Same select with `Départements`: no `Vous êtes une mairie` sentence.
- **Sharing.** `/articles/guide-base-petites-collectivites`: `meta[property="og:image"]` ends with the article's image file name; the `application/ld+json` script parses to `@type` `Article`, `headline` = the article's `h1`, `datePublished` and `dateModified` = its YAML `published_on` and `updated_on`.
- **Proof.** Screenshots and `read-back.txt` (card titles, guide position against the result count, og:image, JSON-LD dates) in `tmp/verify/guides-mis-en-avant/`.

## Gotchas

- The home guides and the commune guide are fixed slugs in the controllers: a renamed article fails `Home` first, the drive reads titles from `Article.find`, never hard-coded.
- The image URL is fingerprinted by the asset pipeline (`-<digest>.jpg`): compare the file name stem, not the whole URL.
- `og:image` and the JSON-LD script are in `<head>`: find them with `visible: false`.
