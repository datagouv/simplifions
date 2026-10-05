# Rafraîchir le catalogue depuis l'administration

A button on the admin dashboard enqueues `RafraichirCatalogueJob` (Grist import then data.gouv), the same job as the nightly run. One run at a time: Solid Queue discards a request that arrives while a run holds the `rafraichir_catalogue` lock (one hour). The dashboard reads the last `SolidQueue::Job` of that class: none, `en cours`, `terminé le JJ/MM/AAAA à HH:MM` (Paris), `échoué (message)`. While the last run is `en cours` the button is disabled and reads `Rafraîchissement en cours…`, as of page load (no live update). Finished jobs are cleared after a day, then it says `Aucun rafraîchissement récent.`

## How to get to it (user POV)

- Log in as admin → `/admin` → section `Rafraîchir le catalogue` → button `Rafraîchir depuis Grist et data.gouv` → native confirm (« Le contenu du Grist remplacera les modifications faites dans l’administration. ») → back on `/admin` with `Rafraîchissement lancé.`, `Dernier rafraîchissement : en cours.` and the disabled `Rafraîchissement en cours…` button.

## Driving it

Preconditions: a throwaway database, never `simplifions_development` (the job rewrites the catalogue).

```sh
export DATABASE_URL=postgres:///simplifions_verify_rafraichir SKIP_TEST_DATABASE=1
bin/rails runner 'puts ActiveRecord::Base.connection.current_database'   # must print simplifions_verify_rafraichir
bin/rails db:create db:schema:load && bin/rails grist:import
```

Web on 3101 with the same `DATABASE_URL` (SKILL.md § Launch).

- **Click.** Scratch drive: `Verify.login`, `page.accept_confirm { click_button 'Rafraîchir depuis Grist et data.gouv' }` returns the confirm text; assert `Rafraîchissement lancé.`, `en cours` and `page.find_button('Rafraîchissement en cours…', disabled: true)`. Read-back inside `ActiveRecord::Base.uncached`: one `SolidQueue::Job` of class `RafraichirCatalogueJob`.
- **Run.** `timeout -s INT 400 bin/rails solid_queue:start` in the background (no `bin/jobs` in the repo). The worker polls every 60 s; the job is claimed, then finishes in about a minute.
- **During the run** (`claimed?`): reload `/admin`, the button is still disabled; the server-side discard of a second request is covered by `spec/jobs/rafraichir_catalogue_job_spec.rb`.
- **Finished.** Reload `/admin`: `terminé le … à HH:MM`, Paris time of `finished_at`, button enabled again.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/rafraichissement-admin/`, Chrome then Firefox.
- **Cleanup.** Stop the server and the supervisor, `bin/rails db:drop` with the same `DATABASE_URL`, `unset DATABASE_URL`.

## Gotchas

- A request that reaches the server during a run (stale page, nightly run) still gets `Rafraîchissement lancé.`: ActiveJob marks every enqueue as successful; the status line tells the truth.
- Read-backs from a runner script go inside `ActiveRecord::Base.uncached`, or the query cache hides the job the server just created.
- `en cours` also covers a job waiting for the worker to poll.
