# Prévisualiser une fiche avec son brouillon

On a démarche or solution that holds a draft, the column `État et actions` (on a démarche, its state bar) shows `Prévisualiser` (new window). It opens `/admin/<demarches|solutions>/:id/previsualisation`: the public page built from the draft in memory (nothing written), under a DSFR notice `Prévisualisation, non publiée.` (for a démarche: its recommandations show as they will be published with it and its intégrations as checked in the draft; for a solution: both in their published version), tab title prefixed `Prévisualisation - `, header `X-Robots-Tag: noindex`. Admin only; no link without a draft (a démarche also offers it while one of its recommandations waits for its `Publier`, `admin-recommandations-avec-la-demarche.md`).

## Sub-features

- `previsualisation-lien` `Prévisualiser` in `État et actions` only once a draft exists, opening a new window.
- `previsualisation-page` the public page built from the draft under `Prévisualisation, non publiée.`; the site and the base unchanged.
- `previsualisation-image` a solution's draft image shows in the preview, still not attached.
- `previsualisation-integrations` a démarche's intégrations come from its draft: one checked in the draft shows (card and `Solutions ayant intégré ces données`), the public page unchanged; one unchecked disappears (spec only).
- `previsualisation-entete` tab title prefixed `Prévisualisation - `, header `X-Robots-Tag: noindex`, admin only (spec only).

## How to get to it (user POV)

- Dashboard `/admin` → `Démarches` (or `Solutions`) → a published row → change a field → `Enregistrer` → `Prévisualiser`.

## Driving it with Capybara

Drive: `features/admin-previsualisation.rb` (SKILL.md § Drive).

Creates its own published démarche and solution `Vérif verify-map <browser>`, plus for the integrating solution an API, a bouquet (on a public organisation), a portail and their intégrations (recommandations of the démarche, API niveau 1, bouquet niveau 2), and deletes them. Preconditions: logged in.

- **Démarche.** No `Prévisualiser` before the draft; `Modifier l’en-tête`, `Nom` `<nom> brouillon`, `Enregistrer`, `Prévisualiser` in a new window: H1 the draft name, the notice; at 640 px wide (200 % zoom) no horizontal scroll.
- **Public page unchanged.** `/demarches/<slug>` H1 the published name, no notice; base `nom` unchanged.
- **Solution image.** Attach `app/assets/images/articles/api-franceconnectees-donnees-personnelles.png`, `Enregistrer`, `Prévisualiser`: the image shows, base image still not attached.
- **Integrating solution.** Intégration `consomme` `✅ en production` of the portail on the API, not yet linked to the démarche; `Choisir les intégrations` in the fiche (`/admin/demarches/:id/edit`), check it, `Enregistrer` (`brouillon enregistré, non publié.`), `Prévisualiser`: no error, the portail's name in the bouquet's `.reco-card` and in `#solutions-integratrices`; base `integration_ids` still empty; `/demarches/<slug>` shows it nowhere.
- **Proof.** `tmp/verify/admin-previsualisation/`.

## Gotchas

- The preview keeps the admin bar in the header (rendered by an admin controller).
