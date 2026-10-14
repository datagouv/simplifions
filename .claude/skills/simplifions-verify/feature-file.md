# Feature file contract

Read before adding or fixing a file under `features/`, and at maintain step 3. One file per user-facing feature, an H1 and one paragraph on the user-visible behaviour, then exactly four H2 sections in this order.

1. `Sub-features` — short ids, one line each.
2. `How to get to it (user POV)` — every entry point: menu path, URL, keyboard shortcut, who can see it.
3. `Driving it with Capybara` — starts with `Preconditions:`; then labelled bullets, each pairing a user action with the exact step and the observable result, ending on a `**Proof.**` bullet. When `drive.rb` drives the feature, the section names its short name (`drive.rb vocabulaires`).
4. `Gotchas` — what wastes or invalidates a run.

`features/README.md` is the index: baseline preconditions, driving conventions, proof rules, then one line per feature file. A new file gets its line there in the same change.

Model to copy: [`features/catalogue-cas-usages.md`](features/catalogue-cas-usages.md) for a public page, [`features/admin-vocabulaires.md`](features/admin-vocabulaires.md) for an admin table with a mutation and its undo.

## Where the answers are in this repo

| To write | Look at |
| --- | --- |
| How to get to it | `config/routes.rb`, the header in `app/views/layouts/_header.html.erb`, the link texts in `app/views` and `app/components` |
| Accessible names for the steps | labels and button texts in `app/views` and `app/components`, `config/locales/fr.yml` for model attribute names |
| Selects that submit on change, keyboard shortcuts | `app/javascript/controllers` (`data-action`, `keydown`) |
| The read-back | the model scope the page uses (`Demarche.catalogue`, `Solution.recherche`), queried in Active Record from the drive |
| Accounts | `SKILL.md` § Enter: one dev-only admin created by the harness; visitors need none |
| What is already proven | `spec/requests/` and `spec/components/`: the drive proves what a spec cannot see (JavaScript, focus, layout, both browsers) |

Credentials, `.env` secrets and production accounts never appear in the map.
