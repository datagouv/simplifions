# Saisies contrôlées dans l'administration

Four admin fields that used to break the public site in silence: a solution URL typed without `https://` is completed, an intégration's statut is a closed list, an organisation's « Public ou privé » is a radio group, a démarche or solution slug outside `a-z0-9-` is refused with a message.

## How to get to it (user POV)

- `/admin/solutions/<id>/edit` field `Site internet` (also `URL de demande d’accès`).
- `/admin/integrations/<id>/edit` select `Statut de l’intégration`.
- `/admin/organisations/<id>/edit` radios `Public ou privé`: `Non renseigné`, `Public`, `Privé`.
- `/admin/demarches/<id>/edit` and `/admin/solutions/<id>/edit` field `Slug`, hint `Minuscules sans accent, chiffres et tirets`.

## Driving it with Capybara

`drive.rb saisies`. Preconditions: logged in, a visible public solution with a slug, an intégration `✅ en production`, a visible démarche.

- **URL.** Fill `Site internet` with `www.exemple-verif.fr`, save: `« <nom> » enregistré.`, the public page's `Site de la solution` links to `https://www.exemple-verif.fr`. The drive restores the previous value.
- **Statut.** The `Statut de l’intégration` options are `""` + `Integration::STATUTS`; select the empty option then the current one (re-selecting it alone fires no change and leaves `Enregistrer` disabled), save, read back.
- **Public ou privé.** `Public` is checked for a public operator; retype `Nom` (Enregistrer stays disabled until a field changes), save; the public solution page still shows `Solution publique | <organisation>`.
- **Slug.** Fill `Slug` with `Vérif avec espaces/et accents`, save: the error `Slug ne doit contenir que des minuscules sans accent, des chiffres et des tirets`, the field keeps the typed value, the database keeps the old slug, `/demarches/<slug>` still answers with its H1.
- **Incohérences** (`drive.rb incoherences`). On the first intégration, select its intégratrice in `API ou jeu de données`, save: `Une solution ne peut pas s’intégrer elle-même`, the database keeps the old intégrée. A new vocabulaire with an empty `Slug`: `Slug doit être rempli`; with `Vérif Accents`: the format message; no row created.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-saisies-controlees/`.

## Gotchas

- The `Slug` label carries its hint inside the label: `fill_in 'Slug'` matches by substring.
- DSFR radios hide the native input: `assert_selector :radio_button, 'Public', checked: true, visible: :all`.
- Free text outside the lists cannot be typed through the UI; refusal of such values (Grist or crafted requests) is covered by the model specs.
