# Modifier les recommandations ligne à ligne dans la démarche

In a démarche's `Recommandations (<n>)` tab, each recommandation is a table row with three fields (`Solution`, `Type de recommandation`, `Ordre`), an `État` cell (`Publiée`/`Masquée`, then the modification date), a `Brouillon` badge when it has a draft, a button `Enregistrer la recommandation <solution>`, a link `Modifier la recommandation <solution>` (long texts stay on that page) and a trash button `Supprimer la recommandation <solution>` (confirmation `Supprimer la recommandation <solution> ?`, then `destroy!` as on the recommandation page, the row and its two hidden forms removed by turbo-stream). The table fits the page width from 1024 px up (no horizontal scroll in `.fr-table__content`). A last blank row adds one (`Ajouter la nouvelle recommandation`). A row saves alone, in place (turbo-stream): the message goes to `#message-recommandations` (role=status), an error stays on its row (`fr-error-text`, `aria-describedby` from the row's fields and button). Draft rules are the recommandation page's: in a published démarche, a change is a draft and a new one waits for the démarche's next `Publier`.

## How to get to it (user POV)

`/admin/demarches/<id>/edit`, tab `Recommandations (<n>)`. Admin only.

## Driving it with Capybara

`drive.rb recommandations-en-ligne`, mutating then undone. Démarche: the visible one with a slug and the most recommandations; row: its first visible recommandation; solution: the first public API it does not recommend yet.

- **Row.** `Ordre de la recommandation <solution>` = 77 → fiche `Enregistrer` stays greyed; `Enregistrer la recommandation <solution>` → `brouillon enregistré`, badge `Brouillon`, focus stays on the button, ordre unchanged in base, 77 in the draft.
- **Fiche kept.** Change `Description courte`, save a row → no confirmation, fiche `Enregistrer` still active.
- **Error.** Blank row with only a type → `Choisissez une solution` on the row, button described by it, focus on it.
- **Add.** Blank row with the solution and ordre 99 → new row above, blank row again, count +1, `visible` false.
- **Public page.** `Annuler` (accept the leave question) → `/demarches/<slug>` cards unchanged.
- **Width.** At 1280 and 1024 px, `.fr-table__content` `scrollWidth <= clientWidth`.
- **Undo.** `Modifier la recommandation <solution>` → `Abandonner le brouillon`; the added one → its trash button: dismiss the confirmation (row stays, still in base), accept it (row gone, `supprimé` in `#message-recommandations`, which takes the focus through Turbo's stream `autofocus`, still on the démarche). Count and draft back.
- **Proof.** `tmp/verify/admin-recommandations-en-ligne/`, including `etroit-375` (no page-level horizontal scroll; the table scrolls inside its container).

## Gotchas

- A row of a hidden recommandation saves directly (no draft): the drive only saves rows of visible ones, so its undo is the draft's abandon.
- Turbo disables a form's submitter during a submission by default, which drops focus to `<body>`: `application.js` sets `Turbo.config.forms.submitter = "aria-disabled"`, and rows are replaced with `method: :morph`, so focus stays on the row's button.
