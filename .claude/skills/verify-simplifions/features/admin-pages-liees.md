# Relire les textes longs et rejoindre les pages liées

On an admin form, each text area is as tall as its content (rows computed server-side, no JS) and the fields rendered as Markdown on the site say `Markdown accepté`. A visible démarche or solution with a slug offers `Voir la page publique` (new tab, announced in the `title`). Each checked box of a filterable list or of the vocabulaires, the recommandation's solution and the intégration's two solutions offer `Voir la fiche`, named `Voir la fiche <libellé>`, outside the checkbox label.

## How to get to it (user POV)

- `/admin/demarches/<id>/edit` of a visible démarche: `Contexte`, `Voir la page publique`, `Fournisseurs de services` checked boxes.
- `/admin/recommandations/<id>/edit`: link next to `Solution`. Admin only.

## Driving it with Capybara

`drive.rb pages-liees`, read-only. Precondition: catalogue imported (démarche 23 has a 2 947-character contexte on 2026-10-05).

- **Text area.** The longest visible contexte: `scrollHeight <= clientHeight`, hint `Markdown accepté`.
- **Public page.** `Voir la page publique` opens `/demarches/<slug>` in a new window.
- **Linked items.** One `Voir la fiche <nom>` per checked fournisseur de services; filtering on `voir la fiche` shows no box; the link opens the fournisseur's read page (`/admin/types_acteurs/<id>`), the other tables' links open their form.
- **Recommandation.** `Voir la fiche <solution>` opens the solution's form.
- **Proof.** `tmp/verify/admin-pages-liees/`, including `etroit-320` (no horizontal scroll).

## Gotchas

- Rows are an estimate (80 characters per line): a text full of short words in a narrow window may still scroll a little.
