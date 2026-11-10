# Identifiant Grist et champs data.gouv en lecture seule

The administration shows a row's Grist identifier as text (`Identifiant Grist : Cas_d_usages:1`), never as a field: changing it made the next Grist import delete the row. A solution's six data.gouv fields show in a `Repris de data.gouv.fr` block, read-only: the data.gouv refresh rewrites them.

## Sub-features

- `lecture-seule-grist` `Identifiant Grist : <id>` as text, no field: in the `État de la démarche` bar for a démarche, in `État et actions` for the other tables.
- `lecture-seule-datagouv` a solution's data.gouv fields in the read-only block `Repris de data.gouv.fr`.
- `lecture-seule-requete` a value sent anyway by a crafted request is ignored (spec only).

## How to get to it (user POV)

- Any admin `edit` page: `Identifiant Grist : …` in the `État et actions` column, on a démarche in the `État de la démarche` bar above the H1, after the dates; absent on `new` and on rows created in the admin.
- `/admin/solutions/<id>/edit` of a solution with a data.gouv UID: the `Repris de data.gouv.fr` list (titre, organisation, logo URL, accès, accès des acteurs publics, badges).

## Driving it with Capybara

Drive: `features/admin-lecture-seule.rb` (SKILL.md § Drive).

Read-only: it opens existing catalogue rows and saves nothing. Preconditions: logged in, catalogue imported (a démarche with a `grist_id`, a solution with a `datagouv_titre`).

- **Grist.** First démarche with a `grist_id`: text `Identifiant Grist : <grist_id>`, no input named `demarche[grist_id]`.
- **data.gouv.** First solution with a `datagouv_titre`: block `Repris de data.gouv.fr` with `Titre : <datagouv_titre>`, no input named `solution[datagouv_*]`.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-lecture-seule/`.

## Gotchas

- A value sent anyway by a crafted request is ignored (strong params); the request specs (`spec/requests/admin/crud_spec.rb`) cover it, the browser cannot send it.
