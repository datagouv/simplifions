# Choisir les éléments liés dans une liste filtrable

A list of 10 linked rows or fewer in an admin form shows every box on load, checked or not, with no filter field. Every longer list (intégrations, démarches, solutions, organisations, fournisseurs de services) shows only its checked boxes on load, with a filter field labelled with the list's name (`Intégrations`, `Organisations`…; the legend is read by screen readers only): a click in it or ArrowDown shows every box in a grey frame under the field, typing shows the matching ones (an intégration also by the name of its intégratrice's organisations, not shown), the `Effacer le filtre des <liste>` cross or leaving the list with an empty filter brings back the checked boxes only. Vocabulaires stay plain checkboxes, grouped by category (`Usager`, `Catégorie de solution`, `Type de simplification`).

## Sub-features

- `courte-liste` 10 choices or fewer: every box shown, a visible legend and no filter field, no live line; decided at page load from the number of choices.
- `liste-filtrable` filter field labelled with the legend, hint `Sans filtre, seuls les éléments cochés sont affichés ; cliquer dans le champ ou y appuyer sur flèche bas affiche tous les choix.`; Tab into the field opens nothing; once opened, every box stays shown until the cross or until focus leaves the fieldset with an empty filter (a click on blank page, on a label or on blank space inside the list keeps it open, also inside a tab of a fiche); every word must match, accents and case ignored; a polite live line `2 cochés sur 474` (empty filter) or `1 résultat sur 474, 3 cochés`. The boxes stay native: Tab reaches the shown ones, Space checks.
- The filter field has no `name`: typing in it does not count as a change (no `Quitter sans enregistrer les modifications ?`) and Enter in it does not submit the form.
- `vocabulaires-groupes` one fieldset per category in the démarche and solution forms (on a démarche, `Démarche à destination de :` beside `Démarche gérée par :`, then `Catégorie de solution` and `Type de simplification`), a `?` beside every vocabulaire (see `admin-pages-liees.md`).

## How to get to it (user POV)

- `/admin/demarches/<id>/edit` (the `Modifier les fournisseurs de services` window, and `Ajouter une intégration` on a solution recommandée's card), solutions (Organisations, Fournisseurs de services), intégrations (Démarches), organisations (Solutions), fournisseurs de services and vocabulaires (Démarches, Solutions). Admin only.

## Driving it with Capybara

Drive: `features/admin-liste-filtrable.rb` (SKILL.md § Drive).

Preconditions: logged in. The drive creates `Vérif verify-map <browser>`, recommending as a solution recommandée the API with the most intégrations and linked to the first two of them, removed at the end; no catalogue row is touched.

- **Short list.** The first intégration with 1 to 10 proposed démarches: under `Démarches`, every box shown, no filter field.
- **Groups.** On a démarche, the vocabulaires groups read `Démarche à destination de :`, `Catégorie de solution`, `Type de simplification`, in that order; one `?` per vocabulaire across them.
- **Checked only.** The card's `Ajouter une intégration à <API>`: 2 boxes shown, both checked; live line `2 cochés sur <that API's intégrations>`.
- **Tab passes through.** Focus the window's `Fermer`, Tab: focus lands in the `Intégrations` filter, still 2 boxes; 6 more Tab (cross, 2 boxes, 2 `Voir la fiche`) leave the list.
- **Click shows all, framed.** Click the field: every box shown, live line unchanged, `resultats` background no longer transparent.
- **Cross.** Type, click `Effacer le filtre des intégrations`: field empty, 2 boxes, no frame, focus back in the field.
- **ArrowDown, then leave.** ArrowDown shows all; Shift+Tab out of the fieldset: 2 boxes, no frame.
- **Editor or software.** Fill the `Intégrations` filter with the name of an organisation of an intégration's intégratrice, a name its libelle does not hold: that box shown, its label unchanged; then with the intégratrice's name: still shown. The cross clears the filter.
- **Filter and keyboard.** Fill the `Intégrations` filter with the last intégration's libelle, transliterated and upcased; Enter does not save; Tab until its box has focus, Space; live line `1 résultat sur …, 3 cochés`.
- **Save.** Clear the filter: the new box is still shown, checked. The window's `Enregistrer`: window closed, `integration_ids` in base has 3 ids, the target among them.
- **Leave.** Reopen the window, type in the filter: the fiche does not count as changed; `Annuler`, breadcrumb `Démarches`: no confirm, back on `Démarches`.
- **Click a label in a tab.** The first solution with organisations (a fiche with tabs): click the `Organisations` filter, then the label of the first unchecked organisation: every box still shown, that box checked, no focus ring around the list.
- **Click inside the list.** Click the live line: every box still shown, no focus ring; leave by the breadcrumb `Solutions`, accepting `Quitter sans enregistrer les modifications ?`.
- **Proof.** `tmp/verify/admin-liste-filtrable/`.

## Gotchas

- Find a list with `Verify.liste_filtrable(zone, legende)` (the fieldset whose legend is that name) and its field with `Verify.champ_de_filtre`.
- DSFR checkboxes are opacity 0: read them with `visible: :all` under `[data-liste-filtrable-target=element]:not(.fr-hidden)`, find a shown one by its `label`.
- `I18n.transliterate` turns `→` into `?`: keep only the alphanumeric words when typing a libelle.
