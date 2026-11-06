# Brouillon d'une fiche publiée

On a published démarche or solution, `Enregistrer` keeps the form in a draft (`brouillon` jsonb) and leaves the public page as it was: notice `« <nom publié> » : brouillon enregistré, non publié.`, column badges `Publiée` and `Brouillon non publié`, then `Brouillon du jj/mm/aaaa à hh:mm` while `Dernière modification` keeps the published date. The form reopens on the draft (fields, checked boxes, image). `Publier` puts draft + form online (validations run here: an incomplete draft saves, its publication is refused with the error); `Masquer` hides the fiche and keeps the rest of the form as draft; `Abandonner le brouillon` (confirm `Abandonner le brouillon de « … » ? Les modifications non publiées seront perdues.`) returns to the published version. A hidden fiche saves directly.

Recommandations follow their démarche: `Enregistrer` on a published one keeps a draft (badge `Brouillon — sera publiée avec la démarche`); a new one added to a published démarche is created `Masquée` with that badge (notice `« <démarche> → <solution> » : brouillon enregistré, non publié.`). The démarche column counts them (`N recommandations en brouillon`), and the démarche's `Publier` puts them online together, or nothing if one is refused (error names it). A hidden recommandation without draft still saves directly. Données utiles (type `Donnée utile`) arrive `Publiée` from the import and follow the same rule; one added to a démarche, published or hidden, or a hidden recommandation switched to `Donnée utile` (even one keeping a draft), waits for the démarche's `Publier` (request spec only). As soon as `Donnée utile` is chosen in `Type de recommandation`, saved or not (`Nouvelle ligne` included), the page has neither `Publier` nor `Masquer`: it goes online with its démarche; back to `Solution recommandée`, they return. When an import Grist changed the fiche after the draft started (`commence_le`, kept across saves), the column shows a warning `Le Grist a modifié cette fiche le … : publier remplacera ces changements.` with `Voir l’historique` (request spec only, the drive does not run an import).

Fiches without a draft (intégration, organisation, fournisseur de services, vocabulaire) say so in their `État et actions` panel: `Pas de brouillon : « Enregistrer » met en ligne tout de suite.` On a solution the sentence sits above the lines of each of its tabs `API fournies`, `API intégrées` and `Solutions qui l’intègrent`; the panels of a démarche, a solution and a recommandation do not carry it.

## Sub-features

- `brouillon-enregistrer` `Enregistrer` on a published fiche keeps a draft: notice, badge `Brouillon non publié`, draft date, public page unchanged.
- `brouillon-publier` the form reopens on the draft; `Publier` puts it online.
- `brouillon-publication-refusee` an incomplete draft saves, its `Publier` is refused with the error (spec only).
- `brouillon-masquer` `Masquer` hides the fiche and keeps the draft; a hidden fiche saves directly (spec only).
- `brouillon-abandonner` `Abandonner le brouillon`, after a confirm, returns to the published version.
- `ce-qui-partira` on a published démarche with a draft, a box at the top of the fiche lists what `Publier` will put online, each line a link to its block, and carries the draft's actions; moving solutions recommandées, however many cards shift, gives one line `Ordre des solutions recommandées modifié`.
- `brouillon-image` a new image waits in the draft until `Publier`.
- `brouillon-recommandations` recommandations of a published démarche wait as drafts, counted in its column, published by its `Publier`.
- `brouillon-donnees-utiles` a `Donnée utile` waits for the démarche's `Publier`; choosing that type removes `Publier` and `Masquer`.
- `brouillon-alerte-grist` warning `Le Grist a modifié cette fiche le …` with `Voir l’historique` (spec only).
- `brouillon-fiches-sans-brouillon` the sentence on the fiches that save directly, and not on the fiches that keep a draft.

## How to get to it (user POV)

- Dashboard `/admin` → `Démarches` (or `Solutions`) → a published row → change a field → `Enregistrer`.
- Admin only.

## Driving it with Capybara

Drive: `features/admin-brouillon.rb` (SKILL.md § Drive).

The drive creates its own published démarche and solution `Vérif verify-map <browser>` (slug `verif-verify-map-<browser>`) and deletes them; it saves nothing on imported rows.

- **Draft.** `Modifier l’en-tête`, type `<nom> brouillon` in `Nom`, `Enregistrer` in the modal: the notice, both badges and the draft date in the state bar; base `nom` unchanged, `visible` true.
- **Public page unchanged.** `/demarches/<slug>` H1 still the published name.
- **Reopen and publish.** Row from the list (still under the published name): the H1 shows the draft; `Publier`: `« … brouillon » enregistré.`, no draft badge, public H1 the new name, base `brouillon` nil.
- **Abandon.** New draft, `Abandonner le brouillon`, accept the confirm: `Brouillon de « … » abandonné.`, the H1 back to the published value, base `brouillon` nil.
- **What will go out.** On the fiche with no draft: no box. `Modifier le contexte`, `Enregistrer`: a box `À la publication, 1 changement partira` with the link `Contexte modifié`. Add an own API `<nom> g` with `Ajouter une solution recommandée`: the box, without reload, says `À la publication, 2 changements partiront` and adds `Solution recommandée ajoutée : <nom> g (API)`. The link `Contexte modifié` jumps to `#bloc-contexte`. `Publier ces 2 changements`: notice, no box, base `contexte` the new text, `brouillon` nil, the recommandation `visible`.
- **Image.** Own published solution `Vérif verify-map <browser>`: attach `app/assets/images/articles/api-franceconnectees-donnees-personnelles.png`, `Enregistrer`: draft badge, the form shows the new image, base image not attached; `Publier`: base image `api-franceconnectees-donnees-personnelles.png`, draft nil.
- **Recommandations.** Two own API solutions `<nom> a` / `<nom> b` (no slug), a published `niveau_2` recommandation on `a` with `Données utiles` `Avant`. Change it to `Après`, `Enregistrer`: draft badge, base unchanged. `/admin/recommandations/new?demarche_id=…`, pick `b`, `Solution recommandée`, `Enregistrer`: notice, `Masquée` + draft badge, base `visible` false, draft `visible: "1"`. Public page: one `.reco-card`, with `Avant`. Démarche fiche: `2 recommandations en brouillon`; `Publier`: two cards, `Après` shown, no draft left in base.
- **Données utiles.** Own bouquet `<nom> bouquet` (a public organisation from the base) exposing an API `<nom> c`, recommended on the démarche, and a published donnée utile on `c` described `Utile avant`. Its line in the démarche's `Modifier les données utiles` window: no badge (neither `Masquée` nor `Ajoutée au brouillon`), no draft in base. Its page `/admin/recommandations/<id>/edit`: no `Publier` nor `Masquer` in the column; `En quoi cette API ou ce jeu de données est utile` = `Utile après`, `Enregistrer`: notice, base description unchanged; public `Endpoints utiles` row still `Utile avant`. Démarche fiche: `1 recommandation en brouillon`; `Publier`: public row `Utile après`, the line without badge and no draft in base.
- **Type chosen.** Own API `<nom> d`, a hidden `niveau_2` recommandation on it. On `/admin/recommandations/new?demarche_id=…` then on its `Modifier` page: select `Donnée utile (API ou jeu de données)` → no `Publier` nor `Masquer` in the column; select `Solution recommandée` → `Publier` is back. Nothing is saved.
- **No draft.** Own solutions `<nom> e` / `<nom> f` with an intégration, an organisation `<nom> org`, a fournisseur de services `<nom> fournisseur`, a vocabulaire `<nom> voc`, and a recommandation of the démarche on `f`. Each of the four edit pages: the panel `État et actions` holds the paragraph `Pas de brouillon : « Enregistrer » met en ligne tout de suite.` Solution `e`, tabs `API fournies`, `API intégrées`, `Solutions qui l’intègrent`: each starts with that sentence, then its own heading. Edit pages of the démarche (its state bar), solution `e` and the recommandation: no such paragraph in the panel.
- **One order line.** Three own published `niveau_2` cards `<nom> h` / `i` / `j` (positions 1 to 3). `Changer l’ordre`, drag `j` onto `h`: every card that shifted keeps a draft (at least 3 in base), and the box says `À la publication, 1 changement partira` with the single link `Ordre des solutions recommandées modifié`, which jumps to `#bloc-solutions-recommandees`.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-brouillon/`.

## Gotchas

- The list and the H1 show the published name; only the fiche shows the draft: open the row by its published name, then match the fiche's H1 on the draft value.
- The public page has no admin bar: go back to `/admin` before `rubrique`.
