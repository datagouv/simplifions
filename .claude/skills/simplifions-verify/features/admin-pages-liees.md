# Relire les textes longs et rejoindre les pages liées

On an admin form, each text area is as tall as its content (rows computed server-side, no JS) and the fields rendered as Markdown on the site say `Markdown accepté`. A visible démarche or solution with a slug offers `Voir la page publique` in the `État et actions` column (new tab, announced in the `title`). Each checked box of a filterable list from the catalogue, the recommandation's solution and the intégration's two solutions offer `Voir la fiche`, named `Voir la fiche <libellé>`, outside the checkbox label. Every vocabulaire and every fournisseur de services (checked or not) offers instead a `?` icon (`fr-icon-question-line`) beside its label, its text `Fiche de <nom> (nouvel onglet)` read by screen readers only, opening its read page in a new tab; both lists sit on three columns from 992 px (two from 576 px, one below).

## How to get to it (user POV)

- `/admin/demarches/<id>/edit` of a visible démarche: `Contexte`, `Voir la page publique`, `Fournisseurs de services` checked boxes.
- `/admin/recommandations/<id>/edit`: link next to `Solution`. Admin only.

## Driving it with Capybara

`drive.rb pages-liees`, read-only. Precondition: catalogue imported (démarche 23 has a 2 947-character contexte on 2026-10-05).

- **Text area.** The longest visible contexte: `scrollHeight <= clientHeight`, hint `Markdown accepté`.
- **Public page.** `Voir la page publique` opens `/demarches/<slug>` in a new window.
- **Référentiel.** One `?` per checked fournisseur de services (list closed), named `Fiche de <nom> (nouvel onglet)`; at 1280 px 3 vocabulaires per row, each `?` right of its label (`trois_colonnes`). The first fournisseur's and the first vocabulaire's `?` open `/admin/types_acteurs/<id>` and `/admin/vocabulaires/<id>` (button `Modifier`) in a new window, the form stays open. At 375 px, one per row. Filtering on `fiche de` (the hidden link text) shows no box.
- **Recommandation.** `Voir la fiche <solution>` opens the solution's form.
- **Proof.** `tmp/verify/admin-pages-liees/`, including `referentiel-trois-colonnes`, `referentiel-375` and `etroit-320` (no horizontal scroll).

## Gotchas

- Rows are an estimate (80 characters per line): a text full of short words in a narrow window may still scroll a little.
