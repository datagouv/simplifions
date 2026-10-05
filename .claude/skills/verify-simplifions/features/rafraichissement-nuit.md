# Rafraîchir le catalogue chaque nuit

`RafraichirCatalogueJob` replays the Grist import then the data.gouv copy. Solid Queue runs it every night at 3:00 Europe/Paris (`config/recurring.yml`) on the servers, where Puma starts the supervisor (`plugin :solid_queue`, very_ansible), only on the frontal host: `FRONTAL=false` (written by very_ansible) skips the recurring tasks (`config/initializers/solid_queue_frontal.rb`). A failed Grist import raises, keeps the previous catalogue and reaches Sentry; Sentry is off locally.

## How to get to it (user POV)

- No UI. In staging, sandbox and production the catalogue changes overnight. Locally nothing runs it unless a supervisor is started by hand.

## Driving it

Preconditions: a throwaway database, never `simplifions_development`.

```sh
export DATABASE_URL=postgres:///simplifions_verify_nuit SKIP_TEST_DATABASE=1
bin/rails runner 'puts ActiveRecord::Base.connection_db_config.database'   # must print simplifions_verify_nuit
bin/rails db:create && SCHEMA=tmp/schema_rejoue.rb bin/rails db:migrate   # replays every migration, Solid Queue tables included
bin/rails grist:import
```

- **Job.** In a `bin/rails runner` script: blank `datagouv_titre` on `Solution.sur_datagouv` and rename one démarche, run `RafraichirCatalogueJob.perform_now`, read back: the démarche has its Grist name again, titles are back except the solutions data.gouv answers 404 for; quarantines and notes are in the Rails log.
- **Schedule.** `timeout -s INT 25 bin/rails solid_queue:start`, then `SolidQueue::RecurringTask` lists `rafraichir_catalogue` with `0 3 * * * Europe/Paris`, next run at 03:00 +01:00/+02:00, and `clear_solid_queue_finished_jobs`. With `FRONTAL=false`, while it runs `SolidQueue::Process` has no `Scheduler` and no task is registered.
- **Proof.** Output and read-backs in `tmp/verify/rafraichissement-nuit/`.
- **Cleanup.** `bin/rails db:drop` with the same `DATABASE_URL` (add `DISABLE_DATABASE_ENVIRONMENT_CHECK=1` after a `SCHEMA=` replay), `rm -f tmp/schema_rejoue.rb`, `unset DATABASE_URL`.

## Gotchas

- On an empty database `db:migrate` loads `db/schema.rb` instead of replaying the migrations; `SCHEMA=` pointing at an absent file forces the replay.
- `config/queue.yml` and `config/recurring.yml` have no environment keys: the same settings apply to sandbox, staging and production. Do not boot those environments locally to check, it decrypts their credentials.
