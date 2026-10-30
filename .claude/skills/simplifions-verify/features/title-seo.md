# Title SEO d'une fiche

A démarche or solution can carry a « Title SEO », typed in its admin form under `Nom`. Once published, it is the whole browser tab title and `og:title` (what Google and a shared link show), without ` | Simplifions.data.gouv.fr`, instead of `Cas d'usage - <titre> | Simplifions.data.gouv.fr` or `Solution - <nom> | …`. The H1 and the description stay as they were. Left empty, the title is the usual one. An API or a jeu de données has no page: the field is hidden like the other page fields. The Grist import does not touch it.

## Sub-features

- `title-seo-demarche` the field on a démarche, its public tab title, emptied back to the default.
- `title-seo-solution` the same on a solution.
- `title-seo-api` no field on an API.

## How to get to it (user POV)

- Admin: `/admin` → `Démarches` (or `Solutions`) → a row → `Title SEO` → `Publier` (on a published fiche `Enregistrer` keeps it in the draft, see admin-brouillon.md).
- Visitor: the tab title and the shared-link title of `/demarches/<slug>` and `/solutions/<slug>`.

## Driving it with Capybara

Drive: `features/title-seo.rb` (SKILL.md § Drive).

The drive creates its own published démarche and solution `Vérif verify-map <browser>` (slug `verif-verify-map-<browser>`) and an API `Vérif verify-map <browser> api`, and deletes them.

Preconditions:

- Launch done and doctor green (SKILL.md § Launch, § Doctor).

- **Default.** `/demarches/<slug>`: tab `Cas d'usage - <nom> | Simplifions.data.gouv.fr`.
- **Démarche.** Admin fiche, `Title SEO` = `Vérif title SEO <browser>`, `Publier`: public tab and `og:title` read exactly `Vérif title SEO <browser>`, H1 still `<nom>`.
- **Emptied.** Same field emptied, `Publier`: the default tab title is back.
- **Solution.** Same on `/admin/solutions/<id>/edit`, read on `/solutions/<slug>`.
- **API.** The API's form has no visible `Title SEO` field.
- **Proof.** Screenshots and `read-back.txt` (tab, H1, `og:title`, base values) in `tmp/verify/title-seo/`.

## Gotchas

- `og:title` sits in `<head>`: find it with `visible: false`.
- The label holds its hint: `fill_in 'Title SEO'` matches it by its start.
