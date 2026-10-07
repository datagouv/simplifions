# Prévisualiser une fiche avec son brouillon

On a démarche or solution that holds a draft, the column `État et actions` shows `Prévisualiser` (new window). It opens `/admin/<demarches|solutions>/:id/previsualisation`: the public page built from the draft in memory (nothing written), under a DSFR notice `Prévisualisation, non publiée.` that says recommandations and intégrations show in their published version, tab title prefixed `Prévisualisation - `, header `X-Robots-Tag: noindex`. Admin only; no link without a draft.

## How to get to it (user POV)

- Dashboard `/admin` → `Démarches` (or `Solutions`) → a published row → change a field → `Enregistrer` → `Prévisualiser`.

## Driving it with Capybara

`drive.rb previsualisation`. Creates its own published démarche and solution `Vérif verify-map <browser>` and deletes them.

- **Démarche.** No `Prévisualiser` before the draft; `Nom` `<nom> brouillon`, `Enregistrer`, `Prévisualiser` in a new window: H1 the draft name, the notice; at 640 px wide (200 % zoom) no horizontal scroll.
- **Public page unchanged.** `/demarches/<slug>` H1 the published name, no notice; base `nom` unchanged.
- **Solution image.** Attach `app/assets/images/solutions/data-subvention.png`, `Enregistrer`, `Prévisualiser`: the image shows, base image still not attached.
- **Proof.** `tmp/verify/admin-previsualisation/`.

## Gotchas

- The preview keeps the admin bar in the header (rendered by an admin controller).
