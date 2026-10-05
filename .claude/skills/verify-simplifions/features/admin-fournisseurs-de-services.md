# Fournisseurs de services

The admin table `types_acteurs` is named « Fournisseurs de services » (Grist's word). A fournisseur is read before it is edited, and its « Regroupements » (the public `Démarches gérées par` filters) are ticked from the closed list `TypeActeur::FILTRES`.

## How to get to it (user POV)

- Dashboard `/admin` → link `Fournisseurs de services`; URL `/admin/types_acteurs` (unchanged).
- List columns `Id`, `Nom` (links to `/admin/types_acteurs/<id>`, the read page), `Regroupements` (filter labels).
- Read page: `dt`/`dd` Regroupements, Ce que cela inclut, Codes juridiques, Démarches, Solutions, Identifiant Grist; button `Modifier`.
- Form: fieldset `Regroupements` of checkboxes; `Ce que cela inclut` and `Codes juridiques` hinted `Mémo interne, non affiché sur le site`. Saving returns to the read page.

## Driving it with Capybara

`drive.rb fournisseurs`, logged in, no row named `Vérif verify-map <browser>`:

- **Read a real row.** First fournisseur with slugs, opened from the list: read page URL, `Regroupements` = `regroupements` in base.
- **Edit form.** `Modifier`: checked boxes = its slugs; both memo hints.
- **Create.** `/admin/types_acteurs/new`, name, tick `Régions` and `Tous les acteurs publics`, save: lands on the read page, slugs read back.
- **Untick.** `Modifier`, untick `Régions`, save: base slugs `tout-acteurs-publics`, list column says `Tous les acteurs publics`.
- **Delete** from the edit page, `reste_en_base=0`.

## Gotchas

- Never tick or untick on a real row: the slugs drive the public filters.
