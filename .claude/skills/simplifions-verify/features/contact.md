# Nous contacter

`/contact` orients a visitor in steps (`/contact/<besoin>`), then gives a prefilled e-mail link and three blocks to copy: the team address, the subject and the message template. On the « modifier » steps a select picks the démarche or solution; from a cas d'usage or solution page, it comes preselected and the subject and message cite that page.

## How to get to it (user POV)

- From a cas d'usage page, the « Proposer une modification du contenu » block opens `/contact/modifier-cas-usage?demarche=<slug>` in a new tab; a solution page opens `/contact/modifier-solution?solution=<slug>`.
- Home and about link to `/contact/contenu`; the sitemap lists `/contact`.
- Anyone, no login. Unknown step → 404.

## Driving it with Capybara

Preconditions:

- Launch done and doctor green (SKILL.md § Launch, § Doctor).
- At least two visible démarches.

- **From a fiche.** Visit the first visible démarche by `nom`; the link `proposer une modification du contenu de ce cas d'usage` has `target=_blank`: visit its `href`. Path `/contact/modifier-cas-usage?demarche=<slug>`.
- **Fiche cited.** The select `Démarche concernée` shows the démarche's `titre` (emoji prefix included); the text of `#objet-message` ends with ` : <titre>`; the decoded `href` of the link `Ouvrir un e-mail déjà pré-rempli` holds `Fiche concernée : <titre>`.
- **Copy.** Buttons `Copier l'e-mail`, `Copier l'objet`, `Copier le modèle`. Chrome needs `page.driver.browser.add_permission('clipboard-write', 'granted')`. Click `Copier l'objet`; the sr-only `[data-copier-target=statut]` reads `Objet du mail copié` (`visible: :all`).
- **Another démarche, no reload.** Set a `window` marker, `select <titre>, from: "Démarche concernée"`: the form submits on change into a Turbo frame, the URL becomes `?demarche=<slug>`, the subject follows, the marker is still there.
- **Chosen without a fiche.** `Retour` → `/contact/contenu` (group heading h3 `Démarches`), click `Proposer une modification d'une démarche existante`: subject without ` : `; select a démarche → URL and subject follow. `Retour` → `/contact/contenu`.
- **No-contact answer.** `Retour` → `/contact`, click `J'ai une question sur ma propre démarche administrative`: the answer shows, no `mailto:` link in it.
- **Proof.** `drive.rb contact`, screenshots `fiche-citee`, `demarche-changee`, `demarche-choisie` and `reponse-sans-adresse`.

## Gotchas

- The « Copier » buttons carry `fr-hidden` until the Stimulus controller connects, and only when `navigator.clipboard` exists, i.e. in a secure context: the harness marks the drive's `http://<container ip>:3101` origin as secure in both browsers.
- Without JavaScript a `Préremplir le message` button inside `<noscript>` submits the select.
