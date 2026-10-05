# Prévenir avant de quitter un formulaire modifié

An admin form that was changed and not saved asks `Quitter sans enregistrer les modifications ?` before the page goes away: `Annuler`, any Turbo link, the browser back button, another form on the page (`Supprimer`, `Se déconnecter`), and the browser's own prompt on reload or close. Saving never asks. A form re-rendered with errors (422) counts as changed. Only fields with a `name` count (filter inputs do not).

## How to get to it (user POV)

- Dashboard `/admin` → any table → row → `Modifier`, or `Ajouter`; type in a field, then leave.
- Admin only; the seven admin forms carry `data-controller="formulaire-modifie"`.

## Driving it with Capybara

Preconditions: logged in (`Verify.login`); the drive creates its own démarche `Vérif verify-map <browser>` and deletes it.

- **Unchanged.** Reach the fiche through Turbo links (Administration → Démarches → row → `Modifier`), `click_link "Annuler"`: no dialog, H1 `Démarches`.
- **Changed, stay.** Fill `Nom`, `dismiss_confirm { click_link "Annuler" }` then `dismiss_confirm { go_back }`, then `dismiss_confirm { click_button "Supprimer" }`: each returns the question (no delete dialog after the third), the field keeps the typed value, the démarche is still in base.
- **beforeunload.** A synthetic cancelable `beforeunload` dispatched on `window` comes back `defaultPrevented`.
- **Delete refused after leaving.** Accept the question, dismiss `Supprimer « … » ?`: `Annuler` still asks.
- **Changed, leave.** Type again, `accept_confirm { go_back }`: list shown, the name in base unchanged.
- **Forward after leaving.** `go_forward`: the field shows the value in base, not the abandoned text (the form is reset on leave).
- **Network failure.** `window.fetch` rejected, type, `Enregistrer`: `Annuler` still asks (state restored on `turbo:submit-end` without success).
- **422.** Empty `Nom`, `Enregistrer`, then `Annuler` asks the question without typing.
- **Save.** Valid `Nom`, `Enregistrer`: no dialog, `Enregistré.`, the name in base changed.
- **Delete, unchanged.** `accept_confirm("Supprimer « … » ?") { click_button "Supprimer" }`: only the delete dialog.

## Gotchas

- Reach the fiche through Turbo links, not `visit`: back to a previous document is a cross-document traversal, where only `beforeunload` applies.
- WebDriver auto-accepts real `beforeunload` prompts (Chrome and Firefox): a reload never shows a modal to Capybara, hence the synthetic event.
- Back is caught by the Navigation API `navigate` event; Chrome makes a traversal cancelable only with a fresh user activation, so type in a field between two back presses.
