# Modifier les recommandations ligne à ligne dans la démarche

In a démarche's `Recommandations (<n>)` tab, each recommandation is a table row with three fields (`Solution`, `Type de recommandation`, `Ordre`), an `État` cell (`Publiée`/`Masquée`, then the modification date), a `Brouillon` badge when it has a draft, a button `Enregistrer la recommandation <solution>`, a link `Modifier la recommandation <solution>` (long texts stay on that page) and a trash button `Supprimer la recommandation <solution>` (confirmation `Supprimer la recommandation <solution> ?`, followed by `La suppression est immédiate, même pendant un brouillon : « Abandonner le brouillon » ne la remet pas.` when the démarche is published, or hidden with a draft to abandon; then `destroy!` as on the recommandation page, the row and its two hidden forms removed by turbo-stream). The table fits the page width from 1024 px up (no horizontal scroll in `.fr-table__content`). A last blank row adds one (`Ajouter la nouvelle recommandation`). A row saves alone, in place (turbo-stream): the message goes to `#message-recommandations` (role=status), an error stays on its row (`fr-error-text`, `aria-describedby` from the row's fields and button). Draft rules are the recommandation page's: in a published démarche, a change is a draft; a new one, in a hidden or published démarche, waits for the démarche's next `Publier` (`admin-recommandations-avec-la-demarche.md`).

## Sub-features

- `recos-ligne-enregistrer` a row saves alone with `Enregistrer la recommandation <solution>`: draft and badge `Brouillon` on a published démarche, focus kept.
- `recos-ligne-fiche` saving a row keeps the fiche's unsaved changes, no leave question.
- `recos-ligne-erreur` an error stays on its row (`Choisissez une solution`), described by the row's button.
- `recos-ligne-ajouter` the last blank row adds one (`Ajouter la nouvelle recommandation`), hidden until the démarche's `Publier`.
- `recos-ligne-supprimer` trash `Supprimer la recommandation <solution>`, confirmation, row gone, focus on `supprimé`.
- `recos-ligne-avertissement` the confirmation warns that deleting is immediate on a published démarche (row trash and `Supprimer` of the recommandation page), not on a masked one.
- `recos-ligne-largeur` the table fits the page at 1280 and 1024 px.

## How to get to it (user POV)

`/admin/demarches/<id>/edit`, tab `Recommandations (<n>)`. Admin only.

## Driving it with Capybara

Drive: `features/admin-recommandations-en-ligne.rb` (SKILL.md § Drive).

Preconditions: logged in; the drive mutates then undoes; a masked démarche `Vérif verify-map <browser>` with one recommandation is created for the Warning step and deleted at the end. Démarche: the visible one with a slug and the most recommandations; row: its first visible recommandation; solution: the first public API it does not recommend yet.

- **Row.** `Ordre de la recommandation <solution>` = 77 → fiche `Enregistrer` stays greyed; `Enregistrer la recommandation <solution>` → `brouillon enregistré`, badge `Brouillon`, focus stays on the button, ordre unchanged in base, 77 in the draft.
- **Fiche kept.** Tick or untick a box of the `Intégrations` tab (the fiche's blocks edit in modals), save a row → no confirmation, that tab's `Enregistrer` still active.
- **Error.** Blank row with only a type → `Choisissez une solution` on the row, button described by it, focus on it.
- **Add.** Blank row with the solution and ordre 99 → new row above, blank row again, count +1, `visible` false.
- **Public page.** Breadcrumb `Démarches` (accept the leave question) → `/demarches/<slug>` cards unchanged.
- **Width.** At 1280 and 1024 px, `.fr-table__content` `scrollWidth <= clientWidth`.
- **Undo.** `Modifier la recommandation <solution>` → `Abandonner le brouillon`; the added one → its trash button: dismiss the confirmation (it reads `Supprimer la recommandation <solution> ? <avertissement>`, the démarche being published; row stays, still in base), accept it (row gone, `supprimé` in `#message-recommandations`, which takes the focus through Turbo's stream `autofocus`, still on the démarche). Count and draft back.
- **Warning.** `Supprimer la recommandation <solution>` of the published démarche's row and `Supprimer` of its recommandation page (`/admin/recommandations/<id>/edit`): confirmation ends with the warning. Same two on the masked démarche's recommandation: confirmation without it. Dismissed each time, both recommandations still in base.
- **Proof.** `tmp/verify/admin-recommandations-en-ligne/`, including `etroit-375` (no page-level horizontal scroll; the table scrolls inside its container).

## Gotchas

- A row of a hidden recommandation saves directly (no draft): the drive only saves rows of visible ones, so its undo is the draft's abandon.
- Turbo disables a form's submitter during a submission by default, which drops focus to `<body>`: `application.js` sets `Turbo.config.forms.submitter = "aria-disabled"`, and rows are replaced with `method: :morph`, so focus stays on the row's button.
