# Relire les textes longs et rejoindre les pages liées

On an admin form, each text area is as tall as its content (rows computed server-side, no JS) and the fields rendered as Markdown on the site say `Markdown accepté`. A visible solution with a slug offers `Voir la page publique` in the `État et actions` column; so does a visible démarche, `Voir la page publique de <nom> - nouvelle fenêtre` in its `title`; both open a new tab. Each checked box of a filterable list from the catalogue, the recommandation's solution and the intégration's two solutions offer `Voir la fiche`, named `Voir la fiche <libellé>`, outside the checkbox label. Every vocabulaire and every fournisseur de services (checked or not) offers instead a `?` icon (`fr-icon-question-line`) beside its label, its text `Fiche de <nom> (nouvel onglet)` read by screen readers only, opening its read page in a new tab; the `Catégorie de solution` and `Type de simplification` vocabulaires sit on three columns from 992 px (two from 576 px, one below); on a démarche `Démarche gérée par :` (fournisseurs) and `Démarche à destination de :` (usagers) share a row, one column each.

## Sub-features

- `pages-liees-texte` each text area as tall as its content; Markdown fields say `Markdown accepté`.
- `pages-liees-publique` `Voir la page publique` in the column opens the public page in a new tab.
- `pages-liees-referentiel` a `?` beside each vocabulaire and fournisseur opens its read page in a new tab; three columns from 992 px.
- `pages-liees-recommandation` `Voir la fiche <solution>` on a recommandation opens the solution's form.
- `pages-liees-cases` `Voir la fiche <libellé>` beside each checked catalogue box and the intégration's two solutions (spec only).

## How to get to it (user POV)

- `/admin/demarches/<id>/edit` of a visible démarche: `Voir la page publique` in the column, then the `Contexte`, `Démarche gérée par :` and vocabulaires fields of the fiche.
- `/admin/recommandations/<id>/edit`: link next to `Solution`. Admin only.

## Driving it with Capybara

Drive: `features/admin-pages-liees.rb` (SKILL.md § Drive).

Read-only. Preconditions: catalogue imported (démarche 23 has a 2 947-character contexte on 2026-10-05).

- **Text area.** The longest visible contexte, its `Contexte` field: `scrollHeight <= clientHeight`, hint `Markdown accepté`.
- **Public page.** `Voir la page publique` opens `/demarches/<slug>` in a new window.
- **Référentiel.** `Démarche gérée par :`: one `?` per checked fournisseur de services (list closed), named `Fiche de <nom> (nouvel onglet)`; `Catégorie de solution` and `Type de simplification`: at 1280 px 3 vocabulaires per row, each `?` right of its label (`trois_colonnes`). The first fournisseur's and the first non-usager vocabulaire's `?` open `/admin/types_acteurs/<id>` and `/admin/vocabulaires/<id>` (button `Modifier`) in a new window, the form stays open. At 375 px, one per row. Filtering on `fiche de` (the hidden link text) shows no box.
- **Recommandation.** `Voir la fiche <solution>` opens the solution's form.
- **Proof.** `tmp/verify/admin-pages-liees/`, including `referentiel-trois-colonnes`, `referentiel-375` and `etroit-320` (no horizontal scroll).

## Gotchas

- Rows are an estimate (60 characters per line, the fiche column holds about 65 at 1280 px): a text full of short words in a narrow window may still scroll a little.
