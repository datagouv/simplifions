---
name: simplifions-verify
description: Launch Simplifions (Rails 8 catalogue site with a Devise admin) in Docker and drive it with Capybara in headless Chrome and Firefox containers — the public catalogue of cas d'usages, a cas d'usage page, the admin login, the admin tables — then capture evidence; holds the procedure to keep the map up to date. Read before starting the app, logging in as admin, clicking through the site, or maintaining the feature map.
---

# simplifions-verify

Simplifions is a public catalogue (cas d'usages, solutions, articles) read by anyone, plus an administration behind a Devise login where an admin edits the catalogue tables. The dev database holds the catalogue imported from Grist; it has no admin account and `db/seeds.rb` is empty, so the map creates one dev-only admin for the run and removes it at cleanup.

## Use the map

1. Read this file and the `features/README.md` index; never improvise a launch or a login.
2. Follow Launch and Doctor literally, then run the feature's drive, `features/<feature>.rb`. Done when it printed its result lines and its evidence path.
3. **Read the result lines, not the evidence.** A `PASS` is proof as it stands: the screenshots are for the human reading the PR. Open a screenshot or `read-back.txt` only behind a `FAIL`, to say what went wrong.
4. A step the map describes that the app no longer does is either drift (fix the map in the same PR) or a regression (report it, do not paper over it).
5. A change that adds or changes a user journey updates its feature file and its drive in the same PR; a new journey gets its file in the shape of [`feature-file.md`](feature-file.md).
6. Keeping the whole map honest against the code: [`maintain.md`](maintain.md).

## Launch

Everything runs in Docker: Docker Desktop on a Mac (Apple silicon or Intel), Docker Engine on Linux. No Ruby, browser or driver is installed on the machine. Commands run from the root of the checkout being verified.

1. Once per machine: `make install` (image, gems, database, Grist catalogue).
2. Browsers, one container each, started on demand by the `verify` profile:

   ```sh
   docker compose --profile verify up -d --wait chrome firefox
   ```

   It returns once both browsers accept sessions. `selenium/standalone-chromium` and `selenium/standalone-firefox` are published for arm64 and amd64: `uname -m` may print `arm64` or `x86_64`, the same command works. The first pull downloads about 2 GB.
3. Database schema up to date: `docker compose run --rm web bin/rails db:prepare`.
4. A drive runs in a one-off `web` container: `bin/rails runner` loads the app, Capybara starts its own server inside that container on port 3101 (this checkout's code, the dev database), and the browser container opens it at the container's address. No server to start or stop, port 3000 and `make start` are left alone.

   ```sh
   docker compose run --rm -e VERIFY_BROWSER=chrome web bin/rails runner .claude/skills/simplifions-verify/features/catalogue-cas-usages.rb
   ```

From a git worktree, add `-p <folder name of the main checkout>` (`-p simplifions`) right after `docker compose` in every command: the worktree's code is the one mounted, the database, gems and browsers are the main checkout's. Without it Compose builds a separate stack for the worktree, with an empty database.

No `.env` and no `config/master.key` are needed in development (the only credential read is the Sentry DSN, optional).

## Doctor

- `make check` is silent: Docker is installed and running (otherwise it says what to do, in French).
- `docker compose --profile verify ps chrome firefox` shows both `healthy`; otherwise Launch step 2.
- `docker compose run --rm web bin/rails runner 'puts ActiveRecord::Base.connection.current_database, Demarche.visibles.count'` → `simplifions_development`, then a number above zero; zero → `make import` (needs network, a few minutes).
- `docker compose run --rm -e VERIFY_BROWSER=chrome web bin/rails runner .claude/skills/simplifions-verify/features/catalogue-cas-usages.rb` prints only `PASS` lines, then `evidence tmp/verify/catalogue-cas-usages/`: the harness and the browser work.

## Enter

One role: admin. Visitors need no account.

| Role | Account | Where it comes from |
| --- | --- | --- |
| Visitor | none | every public page |
| Admin | `verif@simplifions.local` / `verif-simplifions-2026` | created by `Verify.ensure_admin` (harness.rb) at the start of a drive, removed at cleanup; dev-only, never exists in staging or production |

Login path: header button `Se connecter` → `/admin/connexion`, fields `Adresse e-mail` and `Mot de passe`, button `Se connecter`. Landing: `/admin`, an info alert `Connecté.`, an H1 `Administration` with one link per catalogue table. The header then shows `Administration` and `Se déconnecter` instead of `Se connecter`. In a drive `Verify.login(page)` does this and is a no-op when already logged in; end with `Verify.logout(page)`, which waits for `Se connecter`: a bare click lets the next `Verify.login` see the dying session and skip the form.

## Drive

- Harness: `harness.rb` next to this file registers two Capybara drivers (`:verify_chrome`, `:verify_firefox`) on the browser containers (`http://chrome:4444`, `http://firefox:4444`), starts the app server inside the drive's container and provides `Verify.session` (`javascript: false` for a no-JS page: `--blink-settings=scriptEnabled=false` in Chrome, `javascript.enabled` pref in Firefox; one session per browser container, so quit the other first), `Verify.drive`, `Verify.check`, `Verify.login`, `Verify.logout`, `Verify.ensure_admin`, `Verify.remove_admin`, `Verify.evidence`, and the steps several features share (`Verify::Etapes`: `rubrique`, `rechercher`, `ouvrir_fiche`, `onglet`…).
- One drive per feature: `features/<feature>.rb` beside `features/<feature>.md`, same basename, wrapped in `Verify.drive(__FILE__) do |page| … ensure <cleanup> end`. Each labelled bullet of the feature file's driving section is one `Verify.check('<label>') { … }`: it prints `PASS <label>`, or `FAIL <label>: <what it saw>` and stops the drive (a screenshot `<browser>-echec.png` is taken, the drive's `ensure` cleans up). The drive ends on `evidence tmp/verify/<feature>/`. A helper used by one feature stays in its file; one used by several lives in `harness.rb`.

  ```sh
  docker compose run --rm -e VERIFY_BROWSER=chrome  web bin/rails runner .claude/skills/simplifions-verify/features/admin-vocabulaires.rb
  docker compose run --rm -e VERIFY_BROWSER=firefox web bin/rails runner .claude/skills/simplifions-verify/features/admin-vocabulaires.rb
  ```

- The whole map, one feature after another in one container (`/verify maintain`), Chrome then Firefox, never both at once: drives in the two browsers pick the same catalogue rows and break each other's counts.

  ```sh
  docker compose run --rm -e VERIFY_BROWSER=chrome web sh -c 'for f in .claude/skills/simplifions-verify/features/*.rb; do bin/rails runner "$f"; done'
  ```

- A new or one-off drive: a scratch script under `tmp/verify/` that starts with `require Rails.root.join('.claude/skills/simplifions-verify/harness.rb')` and `page = Verify.session`, run with `docker compose run --rm -e VERIFY_BROWSER=chrome web bin/rails runner tmp/verify/<file>.rb`, so read-backs use Active Record directly.
- A `bin/rails …` command in a feature file runs the same way, `docker compose run --rm web bin/rails …`. The features on a throwaway database spell out each command in full, guarded by `test "$DATABASE_URL" = …`; copy them as they are, never drop the `-e` or the guard.
- Steps follow the feature files: accessible names only (`click_link "Vocabulaires"`, `fill_in "Rechercher"`, `select "Entreprises", from: "Démarches à destination des :"`). The catalogue selects wait for the `Appliquer les filtres` button; the search field needs the `Rechercher` button.
- Both browsers, every time: the users browse with Firefox, CI and Capybara defaults lean on Chrome.

## Evidence

`tmp/verify/<feature>/` in the checkout (the container writes into it): `<browser>-<step>.png` screenshots and one `read-back.txt` line per step, `timestamp browser step: <state read from the page and from the database>`. A mutation is proven by the read-back after it, then by the read-back after its undo. `tmp/` is gitignored, so evidence stays on the machine and survives branch switches and cleanup.

Nobody else can open that folder. For the PR reader, attach to the Linear issue the screenshots that show the change and the `read-back.txt` (the tracker's attach-a-file call: prepare the upload, PUT the bytes within 60 s, then create the attachment); the PR body names the evidence folders and says the files are on the issue.

## Cleanup

```sh
docker compose run --rm web bin/rails runner 'require "./.claude/skills/simplifions-verify/harness"; Verify.remove_admin'
docker compose --profile verify stop chrome firefox
```

Leave `tmp/verify/*/` in place. Each drive deletes what it creates, in its `ensure`; a drive killed midway can leave a `Vérif verify-map <browser>` row: remove it with `docker compose run --rm web bin/rails runner 'Vocabulaire.where("nom LIKE ?", "Vérif verify-map%").destroy_all'` (same for `Demarche` and `Solution`).

## Rules

- Stable handles only: accessible names, labels, route paths, `data-*` attributes; never CSS position or generated classes.
- Drive only an instance this run started, on its own port; a shared dev server is not verified through. The server Capybara starts inside the drive's container is that instance.
- Evidence is the action and the resulting state, plus a read-back of any mutation; a final screenshot alone proves nothing.
- The map is the user's point of view; class names and code paths stay out of the feature files, an agent finds them at run time.

## Gotchas

- The dev database is shared with the site on port 3000 and with `make import`; never `db:reset`, never edit catalogue rows outside the rows a drive creates.
- `Vérif` appears in the row name on purpose: it sorts last and is greppable.
- One browser session per container, held for the whole drive: a second drive started meanwhile waits 5 minutes, then fails on `session not created`. Run drives one after another.
- `bin/rails runner` keeps the query cache on: a read-back after a mutation made by the browser goes inside `ActiveRecord::Base.uncached { … }`.
- On Linux the container writes `tmp/` and `log/` as root; before removing a worktree, `docker compose run --rm web chown -R "$(id -u):$(id -g)" tmp log`. Docker Desktop on a Mac keeps the user as owner.
