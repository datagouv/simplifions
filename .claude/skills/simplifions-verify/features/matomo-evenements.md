# Évènements Matomo

The site sends Matomo an event for each visitor gesture, filed by page zone. A logged-in admin is not measured at all, on the public site or in the administration.

## Sub-features

- pagination: changing page in a catalogue, the page number is the event name.
- filtres: choosing a filter, then applying it.
- defilement: nothing without a gesture from the visitor, the 100 % step after one.
- ouverture: an accordion counts when it opens, not when it closes.
- affichage: reopening the custom display after scrolling.
- endpoints: changing page and filtering the endpoints of a recommended API.
- sirene: the Sirene demo reports its result, never the SIRET typed.
- contact: choosing a solution to modify.
- admin: no Matomo once logged in, Matomo back after logging out, with no manual reload.

## How to get to it (user POV)

- Every public page, for anyone; the events are read in Matomo › Comportement › Évènements.
- In production the tag loads when `MATOMO_SITE_ID` is set; page views, searches and outlinks have their own feature, [`matomo.md`](matomo.md).

## Driving it with Capybara

Drive: `features/matomo-evenements.rb` (SKILL.md § Drive).

Preconditions: more than 20 visible démarches, and a démarche whose direct access lists more than 4 endpoints (both in the Grist import). The browser containers reach stats.data.gouv.fr. The drive sets `MATOMO_SITE_ID=999999`, a dummy site that stats.data.gouv.fr refuses, and reads the events from the `matomo.php` requests the browser sent (`performance.getEntriesByType('resource')`, parameters `e_c`, `e_a`, `e_n`).

- **Pagination.** On `/demarches`, click `Page 2`: the event `Changer de page` is named `2`, and the URL has `page=2`.
- **Filtres.** Choose a filter value: `Choisir un filtre` carries it. Click `Appliquer les filtres`: its event is sent.
- **Défilement.** On `/`, a script scroll sends no `Défilement` event; the `End` key sends `Atteindre 100 %`.
- **Ouverture.** On the démarche with endpoints, open `Par l'API directement`: `Ouvrir l'accès direct` is sent. Close it: nothing more.
- **Affichage.** On a fresh page scrolled down, click `Affichage personnalisé`: `Rouvrir l'affichage personnalisé` is sent.
- **Endpoints.** In the open accordion, click `Page 2`: `Changer de page d'endpoints`. Type a word and click `Filtrer`: `Filtrer les endpoints`, ending with the démarche's name.
- **Sirene.** On `/articles/qu-est-ce-qu-une-api`, submit an invalid SIRET: `Interroger l'API Sirene` is named `SIRET invalide` followed by the article's title, without the number.
- **Contact.** On `/contact/modifier-solution`, choose a solution: `Choisir la solution à modifier` carries its label.
- **Admin.** After the login form, `window._paq` does not exist, nor after following a link to the public site. After `Se déconnecter`, it exists again without any `visit`, and a click sends its event.
- **Proof.** Screenshots of the catalogue page 2 and of the logged-out page; read-back of the events sent at each step.

## Gotchas

- Never run with `MATOMO_SITE_ID=311`: the events would land in the real statistics.
- Wait for an event rather than reading the list once: the section and scroll events arrive after a delay.
- Between two steps the list is emptied by hand: a Turbo navigation keeps it, a `visit` restarts it.
- A step that closes the session must not use `visit` before its check: a reload would hide a script left running after the login or the logout.
