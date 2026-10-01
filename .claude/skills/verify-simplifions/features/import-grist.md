# Importer le catalogue depuis Grist

`bin/rails grist:import` copies the Grist document into the catalogue (démarches, solutions, intégrations, recommandations, solution images), then chains `datagouv:import`. Rows it cannot map go to quarantine instead of stopping the run. It runs at every deploy.

## How to get to it (user POV)

- Operator command, no UI: `bin/rails grist:import`. Needs network to the Grist document; a few minutes.

## Driving it

Preconditions:

- Never against `simplifions_development` nor through `db:schema:load` / `db:reset` without the override below: use a throwaway database.

  ```sh
  export DATABASE_URL=postgres:///simplifions_verify_import SKIP_TEST_DATABASE=1
  bin/rails runner 'puts ActiveRecord::Base.connection_db_config.database'   # must print simplifions_verify_import
  bin/rails db:create db:schema:load
  ```

- **Import.** `bin/rails grist:import > tmp/verify/import-grist/import.txt 2>&1`, exit 0. Last lines: `Import Grist terminé — N démarches, …` then `Import data.gouv terminé — …`.
- **Read back** (`bin/rails runner`, same `DATABASE_URL`): `Solution.joins(:image_attachment).count` equals the Grist Solutions rows that have an `Image`, every `image.filename.to_s.valid_encoding?`.
- **Proof.** `import.txt` and the read-back in `tmp/verify/import-grist/`.
- **Cleanup.** `bin/rails db:drop` with the same `DATABASE_URL`, then `unset DATABASE_URL`.

## Gotchas

- Active Storage uses the `db` service: image bytes live in the database and go with the drop.
- Grist sends some accented filenames in `Content-Disposition` as raw non-UTF-8 bytes (`\xFD` for `é`); the import stores them with `_` in place of the bad byte.
- `unknown OID 2278 … pg_advisory_xact_lock` on stderr is harmless.
