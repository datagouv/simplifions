# Se connecter à l'administration

An admin signs in from the header, lands on the administration dashboard, and signs out back to the public site.

## Sub-features

- `connexion-formulaire` DSFR login form, wrong credentials stay on the form with an error alert.
- `connexion-tableau-de-bord` `/admin` lists the seven catalogue tables.
- `connexion-deconnexion` the header button ends the session.
- `connexion-garde` `/admin/*` without a session redirects to the login form.

## How to get to it (user POV)

- Header button `Se connecter` (visitors) → `/admin/connexion`.
- Header buttons `Administration` and `Se déconnecter` (admins).
- URL `/admin` when logged out shows `Vous devez vous connecter pour accéder à cette page.`

## Driving it with Capybara

Preconditions:

- App answers on `http://localhost:3101/up`.
- The dev-only admin exists (`Verify.ensure_admin`, SKILL.md § Enter).

- **Guard.** `visit "/admin"` → text `Vous devez vous connecter pour accéder à cette page.`
- **Log in.** `Verify.login(page)`: fill `Adresse e-mail`, `Mot de passe`, `click_button "Se connecter"`. Alert `Connecté.`, H1 `Administration`, header link `Administration`.
- **Log out.** `click_button "Se déconnecter"`. Header link `Se connecter` is back; `visit "/admin"` lands on `/admin/connexion`.
- **Proof.** Screenshot of the dashboard and of the guard after logout; read-back of `current_path` at both points.

## Gotchas

- `Verify.login` is a no-op when a session is open; a failed earlier feature leaves the browser logged in.
- Wrong password answers 422 and keeps the e-mail in the field.
