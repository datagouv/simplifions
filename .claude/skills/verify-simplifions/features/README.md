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
