# Brouillon d'une fiche publiée

On a published démarche or solution, `Enregistrer` keeps the form in a draft (`brouillon` jsonb) and leaves the public page as it was: notice `« <nom publié> » : brouillon enregistré, non publié.`, column badges `Publiée` and `Brouillon non publié`, then `Brouillon du jj/mm/aaaa à hh:mm` while `Dernière modification` keeps the published date. The form reopens on the draft (fields, checked boxes, image). `Publier` puts draft + form online (validations run here: an incomplete draft saves, its publication is refused with the error); `Masquer` hides the fiche and keeps the rest of the form as draft; `Abandonner le brouillon` (confirm `Abandonner le brouillon de « … » ? Les modifications non publiées seront perdues.`) returns to the published version. A hidden fiche saves directly.

Recommandations follow their démarche: `Enregistrer` on a published one keeps a draft (badge `Brouillon — sera publiée avec la démarche`); a new one added to a published démarche is created `Masquée` with that badge (notice `« <démarche> → <solution> » : brouillon enregistré, non publié.`). The démarche column counts them (`N recommandations en brouillon`), and the démarche's `Publier` puts them online together, or nothing if one is refused (error names it). A hidden recommandation without draft still saves directly. Données utiles (type `Donnée utile`) arrive `Publiée` from the import and follow the same rule; one added to a démarche, published or hidden, or a hidden recommandation switched to `Donnée utile` (even one keeping a draft), waits for the démarche's `Publier` (request spec only). As soon as `Donnée utile` is chosen in `Type de recommandation`, saved or not (`Nouvelle ligne` included), the page has neither `Publier` nor `Masquer`: it goes online with its démarche; back to `Solution recommandée`, they return. When an import Grist changed the fiche after the draft started (`commence_le`, kept across saves), the column shows a warning `Le Grist a modifié cette fiche le … : publier remplacera ces changements.` with `Voir l’historique` (request spec only, the drive does not run an import).

## How to get to it (user POV)

- Dashboard `/admin` → `Démarches` (or `Solutions`) → a published row → change a field → `Enregistrer`.
- Admin only.

## Driving it with Capybara

`drive.rb brouillon`. The drive creates its own published démarche and solution `Vérif verify-map <browser>` (slug `verif-verify-map-<browser>`) and deletes them; it saves nothing on imported rows.

- **Draft.** Type `<nom> brouillon` in `Nom`, `Enregistrer`: the notice, both badges, the draft date; base `nom` unchanged, `visible` true.
- **Public page unchanged.** `/demarches/<slug>` H1 still the published name.
- **Reopen and publish.** Row from the list (still under the published name): `Nom` holds the draft; `Publier`: `« … brouillon » enregistré.`, no draft badge, public H1 the new name, base `brouillon` nil.
- **Abandon.** New draft, `Abandonner le brouillon`, accept the confirm: `Brouillon de « … » abandonné.`, `Nom` back to the published value, base `brouillon` nil.
- **Recommandations.** Two own API solutions `<nom> a` / `<nom> b` (no slug), a published `niveau_2` recommandation on `a` with `Données utiles` `Avant`. Change it to `Après`, `Enregistrer`: draft badge, base unchanged. `/admin/recommandations/new?demarche_id=…`, pick `b`, `Solution recommandée`, `Enregistrer`: notice, `Masquée` + draft badge, base `visible` false, draft `visible: "1"`. Public page: one `.reco-card`, with `Avant`. Démarche fiche: `2 recommandations en brouillon`; `Publier`: two cards, `Après` shown, no draft left in base.
- **Données utiles.** Own bouquet `<nom> bouquet` (a public organisation from the base) exposing an API `<nom> c`, recommended on the démarche, and a published donnée utile on `c` described `Utile avant`. Its row in the `Recommandations` tab: `Publiée`. `Modifier la recommandation <nom> c (API)`: no `Publier` nor `Masquer` in the column; `En quoi cette API ou ce jeu de données est utile` = `Utile après`, `Enregistrer`: notice, base description unchanged; public `Endpoints utiles` row still `Utile avant`. Démarche fiche: `1 recommandation en brouillon`; `Publier`: public row `Utile après`, the line `Publiée` without `Brouillon`.
- **Type chosen.** Own API `<nom> d`, a hidden `niveau_2` recommandation on it. On `/admin/recommandations/new?demarche_id=…` then on its `Modifier` page: select `Donnée utile (API ou jeu de données)` → no `Publier` nor `Masquer` in the column; select `Solution recommandée` → `Publier` is back. Nothing is saved.
- **Image.** Own published solution `Vérif verify-map <browser>`: attach `app/assets/images/articles/api-franceconnectees-donnees-personnelles.png`, `Enregistrer`: draft badge, the form shows the new image, base image not attached; `Publier`: base image `api-franceconnectees-donnees-personnelles.png`, draft nil.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-brouillon/`.

## Gotchas

- The list and the H1 show the published name; only the form shows the draft: open the row by its published name, then match `Nom` on the draft value.
- The public page has no admin bar: go back to `/admin` before `rubrique`.
