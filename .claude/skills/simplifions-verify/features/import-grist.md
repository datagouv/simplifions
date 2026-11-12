# Importer le catalogue depuis Grist

`bin/rails grist:import` copies the Grist document into the catalogue (démarches, solutions, intégrations, recommandations, solution images), then chains `datagouv:import`. Rows it cannot map go to quarantine instead of stopping the run. It runs on a developer machine only (`make install`, `make import`): elsewhere than development and test it stops before any Grist request, since it would delete the fiches created in the admin. The server start no longer runs it, nor any other refresh.

## Sub-features

- `import-grist-catalogue` `bin/rails grist:import` copies démarches, solutions, intégrations, recommandations, then chains `datagouv:import`.
- `import-grist-images` every Grist solution image is attached, its filename valid UTF-8.
- `import-grist-poste-seulement` outside development and test it fails with `Import Grist refusé hors d'un poste de développement : il effacerait les fiches créées dans l'admin`, nothing read nor written (spec only).
- `import-grist-quarantaine` rows it cannot map go to quarantine with a report instead of stopping the run (spec only).

## How to get to it (user POV)

- Operator command, no UI: `bin/rails grist:import`. Needs network to the Grist document; a few minutes.

## Driving it

Preconditions:

- Never against `simplifions_development` nor through `db:schema:load` / `db:reset` without the override below: use a throwaway database.

  Every command of this file runs as `docker compose run --rm -e DATABASE_URL=postgres:///simplifions_verify_import -e SKIP_TEST_DATABASE=1 web bash -c 'test "$DATABASE_URL" = postgres:///simplifions_verify_import && <command>'`: the `test` stops a command whose `-e` was forgotten before it touches `simplifions_development`.

  ```sh
  docker compose run --rm -e DATABASE_URL=postgres:///simplifions_verify_import -e SKIP_TEST_DATABASE=1 web bash -c 'test "$DATABASE_URL" = postgres:///simplifions_verify_import && bin/rails db:create db:schema:load'
  ```

- **Import.** `bin/rails grist:import > tmp/verify/import-grist/import.txt 2>&1`, exit 0. Last lines: `Import Grist terminé — N démarches, …` then `Import data.gouv terminé — …`.
- **Read back** (`bin/rails runner`, same `DATABASE_URL`): `Solution.joins(:image_attachment).count` equals the Grist Solutions rows that have an `Image`, every `image.filename.to_s.valid_encoding?`.
- **Proof.** `import.txt` and the read-back in `tmp/verify/import-grist/`.
- **Cleanup.** `docker compose run --rm -e DATABASE_URL=postgres:///simplifions_verify_import -e SKIP_TEST_DATABASE=1 web bash -c 'test "$DATABASE_URL" = postgres:///simplifions_verify_import && bin/rails db:drop'`.

## Gotchas

- Active Storage uses the `db` service: image bytes live in the database and go with the drop.
- Grist sends some accented filenames in `Content-Disposition` as raw non-UTF-8 bytes (`\xFD` for `é`); the import stores them with `_` in place of the bad byte.
- `unknown OID 2278 … pg_advisory_xact_lock` on stderr is harmless.
