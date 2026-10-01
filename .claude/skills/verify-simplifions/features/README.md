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
- [admin-supprimer-demarche.md](admin-supprimer-demarche.md) — delete a démarche the drive created; its recommandations go with it.
- [admin-saisies-controlees.md](admin-saisies-controlees.md) — the four admin fields that broke the public site: URL completed, statut and public/privé closed, slug format refused.
- [import-grist.md](import-grist.md) — import the catalogue from Grist into a throwaway database; every solution image attached, data.gouv chained.
