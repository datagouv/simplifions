# Erreurs de formulaire et champs obligatoires dans l'administration

A refused admin form shows a titled summary (`2 erreurs à corriger`) at its top that takes the focus, one link per error to its field, and each field in error in DSFR red with its message under it (`aria-invalid`, `aria-describedby`). Messages read as French sentences (`Choisissez une démarche`). Required fields say `(obligatoire)` in their label and carry `required`; the forms are `novalidate`, so the browser never blocks the send and the server summary always shows. Conditional rules (slug required when visible) sit in the hint.

## How to get to it (user POV)

- Dashboard `/admin` → `Démarches` → `Ajouter`; leave `Nom` empty, click `Publier` in the `État et actions` column (sends `visible=1`, so the slug is required too).
- `/admin/recommandations/new`, `Enregistrer` with nothing chosen.

## Driving it with Capybara

`drive.rb erreurs`. Saves nothing (every submit is refused). Preconditions: logged in.

- **Required.** `find_field 'Nom (obligatoire)'` has `required`.
- **Summary.** After `Enregistrer`: `.fr-alert--error` titled `2 erreurs à corriger` is `document.activeElement`; links `#demarche_nom`, `#demarche_slug`.
- **Keyboard.** `Tab` from the summary lands on the first link.
- **Link.** `click_link 'Nom doit être rempli'`: hash `#demarche_nom`, focus on the field (links carry `data-turbo="false"`, else Turbo fires `turbo:before-visit` and the leave warning asks).
- **Field.** `aria-invalid="true"`, `aria-describedby` points at the message `Nom doit être rempli`.
- **Still changed.** `Annuler` asks `Quitter sans enregistrer les modifications ?` (422 counts as changed).
- **Recommandation.** Messages `Choisissez une solution`, `Choisissez une démarche` under the selects.
- **Narrow.** 640 px wide: no horizontal scroll.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-erreurs-formulaire/`.

## Gotchas

- Leaving a refused form asks first: log out with `accept_confirm(question) { click_button 'Se déconnecter' }`.
- The link scrolls the input itself to the top: its label sits just above the viewport.
