# Features

Index for `verify-simplifions`. One file per user-facing feature; each holds the entry points, the exact drive and what proves it.

## Baseline preconditions

- App answers on `http://localhost:3101/up` (SKILL.md § Launch); nothing else listens on 3101.
- Catalogue present: at least one visible démarche and one visible solution in `simplifions_development`.
- Admin drives: the dev-only admin exists (`Verify.ensure_admin`), removed at cleanup.
- Data reset: none needed for public features; admin drives delete what they create.

## Driving conventions

- Capybara through `harness.rb`, `Verify.session`, one session per browser, run twice (`VERIFY_BROWSER=chrome`, then `firefox`).
- Accessible names and route paths only; `[role=status]` for the result count, `aria-expanded` for accordions.
- Selects auto-submit; wait on the URL (`assert_current_path(/q=…/, url: false)`) before reading a count.

## Proof rules

- Evidence = screenshot + `read-back.txt` line with the page state and the database state, in `tmp/verify/<feature>/`.
- A count on the page is compared with the same query in Active Record.
- A mutation is read back after creation and after deletion.

## Features

- [catalogue-cas-usages.md](catalogue-cas-usages.md) — search and filter the cas d'usages list; the count matches the database.
- [fiche-cas-usage.md](fiche-cas-usage.md) — open a cas d'usage from the list and unfold a recommended data source.
- [connexion-admin.md](connexion-admin.md) — log in as admin, reach the dashboard, log out.
- [admin-vocabulaires.md](admin-vocabulaires.md) — add a vocabulaire row in the administration, then delete it.
- [admin-supprimer-demarche.md](admin-supprimer-demarche.md) — delete from the edit page: the confirmation names the row and what goes with it (démarche drive created, organisation cancelled).
- [admin-saisies-controlees.md](admin-saisies-controlees.md) — the four admin fields that broke the public site: URL completed, statut and public/privé closed, slug format refused.
- [import-grist.md](import-grist.md) — import the catalogue from Grist into a throwaway database; every solution image attached, data.gouv chained.
- [contenu-html-grist.md](contenu-html-grist.md) — the HTML typed in Grist markdown fields (DSFR callout, `<hr>`) shows on the public pages, never `raw HTML omitted`.
- [rafraichissement-nuit.md](rafraichissement-nuit.md) — run the nightly refresh job on a throwaway database and see the 3:00 Paris recurring task registered.
- [rafraichissement-admin.md](rafraichissement-admin.md) — click the admin button that refreshes the catalogue on a throwaway database; the button stays disabled during the run, the dashboard ends on `terminé`.
- [admin-dates.md](admin-dates.md) — create then edit a démarche in the administration: `cree_le` and `modifie_le` set by themselves, no date field in the form.
- [admin-lecture-seule.md](admin-lecture-seule.md) — the Grist identifier and a solution's data.gouv fields show as text in the administration, never as fields.
- [admin-formulaire-modifie.md](admin-formulaire-modifie.md) — leaving a changed admin form (Annuler, link, back) asks first; saving does not; a 422 form counts as changed.
- [admin-libelles.md](admin-libelles.md) — admin forms in the Grist words: French labels and list values, hints inside labels, fields in the Grist record-card order.
- [admin-erreurs-formulaire.md](admin-erreurs-formulaire.md) — a refused admin form: titled summary with focus and links to the fields, DSFR error under each field, French messages, required fields marked.
- [admin-previsualisation.md](admin-previsualisation.md) — preview a démarche or solution draft as its public page, under a « Prévisualisation » notice; the public page stays as published.
- [admin-listes.md](admin-listes.md) — admin lists: search, 50 rows per page, name links to the edit page, Visible / Modifié le / Intégrée par columns.
- [admin-liste-filtrable.md](admin-liste-filtrable.md) — long lists of linked rows in admin forms show only checked boxes and filter as you type; vocabulaires grouped by category.
- [admin-recommandations-demarche.md](admin-recommandations-demarche.md) — list and add a démarche's recommandations from its form; a recommandation keeps its démarche in view.
- [admin-recommandations-en-ligne.md](admin-recommandations-en-ligne.md) — edit, add and see errors on a démarche's recommandations row by row in its tab, drafts kept off the public page.
- [admin-formulaire-solution.md](admin-formulaire-solution.md) — a solution form shows only the fields of its catégorie, its image (removable) and whether it is private.
- [admin-fournisseurs-de-services.md](admin-fournisseurs-de-services.md) — fournisseurs de services (types d'acteurs): read page first, regroupements ticked from the public filters, memo hints.
- [admin-saisie-solution.md](admin-saisie-solution.md) — a solution's types as checkboxes on a fixed list, one-line légende, image removal announced, linked démarches and intégrations shown with links.
- [admin-colonne-actions.md](admin-colonne-actions.md) — the sticky `État et actions` column of admin forms: save from anywhere, publish or hide, Enter keeps the state, mobile layout.
- [admin-historique.md](admin-historique.md) — who changed a fiche last and its history page: author (admin, Import Grist, data.gouv), each changed field before → after.
- [admin-navigation.md](admin-navigation.md) — under `/admin` the header bar lists the seven admin rubriques, the current one marked; the public bar elsewhere.
- [admin-integrations-de-l-api.md](admin-integrations-de-l-api.md) — an intégration only offers the démarches that recommend its API, and the reverse; an out-of-rule link is marked, refused by the server, dropped by the import.
- [admin-brouillon.md](admin-brouillon.md) — on a published démarche or solution, Enregistrer keeps a draft off the public site; Publier puts it online, Abandonner le brouillon drops it.
- [admin-image-refusee.md](admin-image-refusee.md) — a solution image whose content is not png, jpg or webp is refused, on a hidden and on a published solution, with no file or draft kept.
- [admin-onglets.md](admin-onglets.md) — démarche and solution edit pages in tabs inside one form; a save reopens its tab, an error opens the tab of the first error.
- [contact.md](contact.md) — reach /contact/<besoin> from a cas d'usage page: the page is cited in the subject and the e-mail, copy works, the answer-only steps give no address.
