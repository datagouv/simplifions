# Prévenir avant de quitter un formulaire modifié

An admin form that was changed and not saved asks `Quitter sans enregistrer les modifications ?` before the page goes away: `Annuler`, any Turbo link, the browser back button, another form on the page (`Supprimer`, `Se déconnecter`), and the browser's own prompt on reload or close. Saving never asks. A form re-rendered with errors (422) counts as changed. Only fields with a `name` count (filter inputs do not).

## Sub-features

- `formulaire-modifie-sans-saisie` an unchanged form leaves without a question.
- `formulaire-modifie-question` a changed form asks `Quitter sans enregistrer les modifications ?` on `Annuler`, back, `Supprimer`; refusing keeps the typing.
- `formulaire-modifie-rechargement` the browser's own prompt on reload or close.
- `formulaire-modifie-quitter` accepting leaves without saving; forward shows the saved value.
- `formulaire-modifie-echec` a failed send or a refused form (422) still counts as changed.
- `formulaire-modifie-enregistrer` `Enregistrer`, and `Supprimer` on an unchanged form, never ask.
- `formulaire-modifie-filtres` typing in a filter field (no `name`) does not count (not driven).

## How to get to it (user POV)

- Dashboard `/admin` → any table → row name, or `Ajouter`; type in a field, then leave.
- Admin only; the seven admin forms carry `data-controller="formulaire-modifie"`.

## Driving it with Capybara

Drive: `features/admin-formulaire-modifie.rb` (SKILL.md § Drive).

Preconditions: logged in (`Verify.login`); the drive creates its own solution `Vérif verify-map <browser>` and deletes it. The démarche fiche edits each block in a modal whose `Annuler` puts the fields back ([admin-fiche-demarche.md](admin-fiche-demarche.md)), so the drive runs on a solution.

- **Unchanged.** Reach the fiche through Turbo links (Administration → Solutions → search → row name), `click_link "Annuler"`: no dialog, H1 `Solutions`.
- **Changed, stay.** Fill `Nom`, `dismiss_confirm { click_link "Annuler" }` then `dismiss_confirm { go_back }`, then `dismiss_confirm { click_button "Supprimer" }`: each returns the question (no delete dialog after the third), the field keeps the typed value, the solution is still in base.
- **beforeunload.** A synthetic cancelable `beforeunload` dispatched on `window` comes back `defaultPrevented`.
- **Delete refused after leaving.** Accept the question, dismiss `Supprimer « … » ?`: `Annuler` still asks.
- **Changed, leave.** Type again, `accept_confirm { go_back }`: list shown, the name in base unchanged.
- **Forward after leaving.** `go_forward`: the field shows the value in base, not the abandoned text (the form is reset on leave).
- **Network failure.** `window.fetch` rejected, type, `Enregistrer`: `Annuler` still asks (state restored on `turbo:submit-end` without success).
- **422.** Empty `Nom`, `Enregistrer`, then `Annuler` asks the question without typing.
- **Save.** Valid `Nom`, `Enregistrer`: no dialog, `« <nom> » enregistré.` on the same fiche, the name in base changed.
- **Delete, unchanged.** `accept_confirm("Supprimer « … » ?") { click_button "Supprimer" }`: only the delete dialog.
- **Proof.** Screenshots and `read-back.txt` in `tmp/verify/admin-formulaire-modifie/`.

## Gotchas

- Reach the fiche through Turbo links, not `visit`: back to a previous document is a cross-document traversal, where only `beforeunload` applies.
- WebDriver auto-accepts real `beforeunload` prompts (Chrome and Firefox): a reload never shows a modal to Capybara, hence the synthetic event.
- Back is caught by the Navigation API `navigate` event; Chrome makes a traversal cancelable only with a fresh user activation, so type in a field between two back presses.
