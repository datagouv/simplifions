# Choisir les éléments liés dans une liste filtrable

Every long list of linked rows in an admin form (intégrations, démarches, solutions, organisations, fournisseurs de services) shows only its checked boxes on load, with a `Filtrer les <liste>` field: entering it shows every box, typing shows the matching ones. Vocabulaires stay plain checkboxes, grouped under `Usager`, `Type de simplification`, `Catégorie de solution`, in Grist order.

## Sub-features

- `liste-filtrable` field `Filtrer les <legend in lowercase>`, hint `Sans filtre, seuls les éléments cochés sont affichés ; entrer dans le champ affiche tous les choix.`; once entered (click or Tab), the empty filter keeps every box shown until the page reloads; every word must match, accents and case ignored; a polite live line `2 cochés sur 474` (empty filter) or `1 résultat sur 474, 3 cochés`. The boxes stay native: Tab reaches the shown ones, Space checks.
- The filter field has no `name`: typing in it does not count as a change (no `Quitter sans enregistrer ?`) and Enter in it does not submit the form.
- `vocabulaires-groupes` nested fieldsets inside `Vocabulaires`, démarche and solution forms, no `Voir la fiche` under a checked vocabulaire.

## How to get to it (user POV)

- `/admin/demarches/<id>/edit` (Fournisseurs de services, Intégrations), solutions (Organisations, Fournisseurs de services), intégrations (Démarches), organisations (Solutions), fournisseurs de services and vocabulaires (Démarches, Solutions). Admin only.

## Driving it with Capybara

`drive.rb liste-filtrable`. Creates `Vérif verify-map <browser>` linked to the first two intégrations, removed at the end; no catalogue row is touched.

- **Groups.** Legends inside `Vocabulaires` are the three categories in order; no `Voir la fiche` link inside `Vocabulaires`.
- **Checked only.** Under `Intégrations`, 2 boxes shown, both checked; live line `2 cochés sur <Integration.count>`.
- **Enter shows all.** Focus the last vocabulaire box, Tab: focus lands in `Filtrer les intégrations`, every intégration box shown, live line unchanged.
- **Filter and keyboard.** Fill `Filtrer les intégrations` with the last intégration's libelle, transliterated and upcased; Enter does not save; Tab until its box has focus, Space; live line `1 résultat sur …, 3 cochés`.
- **Save.** Clear the filter: the new box is still shown, checked. `Enregistrer`: `integration_ids` in base has 3 ids, the target among them.
- **Leave.** Type in the filter, `Annuler`: no confirm, back on `Démarches`.
- **Proof.** `tmp/verify/admin-liste-filtrable/`.

## Gotchas

- DSFR checkboxes are opacity 0: read them with `visible: :all` under `[data-liste-filtrable-target=element]:not(.fr-hidden)`, find a shown one by its `label`.
- `I18n.transliterate` turns `→` into `?`: keep only the alphanumeric words when typing a libelle.
