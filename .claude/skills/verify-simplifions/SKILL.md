---
name: verify-simplifions
description: Launch Simplifions (Rails 8 catalogue site with a Devise admin) on port 3101 and drive it with Capybara in headless Chrome and Firefox — the public catalogue of cas d'usages, a cas d'usage page, the admin login, the admin tables — then capture evidence. Read before starting the app, logging in as admin, or clicking through the site.
---

# verify-simplifions

Simplifions is a public catalogue (cas d'usages, solutions, articles) read by anyone, plus an administration behind a Devise login where an admin edits the catalogue tables. The dev database holds the catalogue imported from Grist; it has no admin account and `db/seeds.rb` is empty, so the map creates one dev-only admin for the run and removes it at cleanup.

## Launch

1. From the repo root or a worktree. No `.env` and no `config/master.key` needed in development (the only credential read is the Sentry DSN, optional).
2. Database: `bin/rails db:prepare`. Catalogue present when `bin/rails runner 'puts Demarche.visibles.count'` is above zero; otherwise `bin/rails grist:import` (needs network, a few minutes).
3. Web on the dedicated verify port:

   ```sh
   mkdir -p tmp/verify
   nohup bin/rails server -p 3101 -P tmp/verify/server.pid > tmp/verify/server.log 2>&1 &
   ```

   Ready when `curl -s localhost:3101/up` answers 200 (under 10 s).
4. Browsers, once per machine:
   - Chrome: selenium-manager downloads its own Chrome and chromedriver into `~/.cache/selenium` on first run. Never point at the snap Chromium, it refuses to start under Selenium.
   - Firefox: the snap Firefox and snap geckodriver are unusable. Download the Mozilla build once:

     ```sh
     mkdir -p ~/.cache/simplifions-verify && cd ~/.cache/simplifions-verify
     curl -sL -o firefox.tar.xz 'https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=fr'
     tar xf firefox.tar.xz && rm firefox.tar.xz
     ```

     geckodriver comes from `~/.cache/selenium/geckodriver/linux64/<version>/` (selenium-manager fetches it on a first Firefox run; if the directory is empty, run the Chrome drive first, then `VERIFY_BROWSER=firefox`). Override paths with `VERIFY_FIREFOX`.

## Doctor

- `curl -s -o /dev/null -w '%{http_code}' localhost:3101/up` → `200`.
- `ss -ltnp | grep ':3101'` shows the pid in `tmp/verify/server.pid`; another pid means a foreign server owns the port: stop, do not verify through it. Thomas's own dev server lives on 3050, never target it.
- `bin/rails runner 'puts ActiveRecord::Base.connection.current_database'` → `simplifions_development`.
- `bin/rails runner 'puts Demarche.visibles.count'` above zero.
- `VERIFY_BROWSER=chrome bin/rails runner .claude/skills/verify-simplifions/drive.rb catalogue` prints `ok catalogue`: the harness and the browser work.

## Enter

One role: admin. Visitors need no account.

| Role | Account | Where it comes from |
| --- | --- | --- |
| Visitor | none | every public page |
| Admin | `verif@simplifions.local` / `verif-simplifions-2026` | created by `Verify.ensure_admin` (harness.rb) at the start of a drive, removed at cleanup; dev-only, never exists in staging or production |

Login path: header button `Se connecter` → `/admin/connexion`, fields `Adresse e-mail` and `Mot de passe`, button `Se connecter`. Landing: `/admin`, an info alert `Connecté.`, an H1 `Administration` with one link per catalogue table. The header then shows `Administration` and `Se déconnecter` instead of `Se connecter`. In a drive `Verify.login(page)` does this and is a no-op when already logged in.

## Drive

- Harness: `harness.rb` next to this file registers two Capybara drivers (`:verify_chrome`, `:verify_firefox`) with the flags that work on this machine, targets `http://localhost:3101` with `run_server = false`, and provides `Verify.session`, `Verify.login`, `Verify.ensure_admin`, `Verify.remove_admin`, `Verify.evidence`.
- Ready-made drive: `drive.rb` runs every feature file in order, or one by its short name:

  ```sh
  VERIFY_BROWSER=chrome  bin/rails runner .claude/skills/verify-simplifions/drive.rb
  VERIFY_BROWSER=firefox bin/rails runner .claude/skills/verify-simplifions/drive.rb vocabulaires
  ```

  It prints `ok <feature>` or `ECHEC <feature>: <error>` and never aborts the other features.
- A new or one-off drive: a scratch script under `tmp/verify/` that starts with `require Rails.root.join(".claude/skills/verify-simplifions/harness.rb")`, run with `bin/rails runner tmp/verify/<file>.rb`, so read-backs use Active Record directly.
- Steps follow the feature files: accessible names only (`click_link "Vocabulaires"`, `fill_in "Recherche"`, `select "Entreprises", from: "Démarches à destination des :"`). The filter selects auto-submit on change (Stimulus); the search field needs the `Recherche` button.
- Both browsers, every time: the user browses with Firefox, CI and Capybara defaults lean on Chrome.

## Evidence

`tmp/verify/<feature>/`: `<browser>-<step>.png` screenshots and one `read-back.txt` line per step, `timestamp browser step: <state read from the page and from the database>`. A mutation is proven by the read-back after it, then by the read-back after its undo. `tmp/` is gitignored, so evidence stays on the machine and survives branch switches and cleanup.

## Cleanup

```sh
kill "$(cat tmp/verify/server.pid)" && rm -f tmp/verify/server.pid
bin/rails runner 'require "./.claude/skills/verify-simplifions/harness"; Verify.remove_admin'
```

Leave `tmp/verify/*/` in place. `drive.rb` deletes what it creates (the vocabulaire row); a drive that failed midway leaves a `Vérif verify-map <browser>` row in `vocabulaires`: remove it with `bin/rails runner 'Vocabulaire.where("nom LIKE ?", "Vérif verify-map%").destroy_all'`. Chrome profiles go to a `mktmpdir` and vanish with the process.

## Gotchas

- The dev database is shared with the developer's server on 3050 and with `bin/rails grist:import`; never `db:reset`, never edit catalogue rows outside the vocabulaire the drive creates.
- `Vérif` appears in the row name on purpose: it sorts last and is greppable.
- `allow_browser versions: :modern` rejects old user agents; the headless browsers here are recent enough.
- Random `EACCES … tmp/storage` in specs is a root-owned folder left by Docker, not a regression.
