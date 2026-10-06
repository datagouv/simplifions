# Nous contacter

`/contact` orients a visitor in steps (`/contact/<besoin>`), then gives the team address, a subject and a message template, with a prefilled e-mail link and « Copier » buttons. From a cas d'usage or solution page, the step cites that page.

## How to get to it (user POV)

- From a cas d'usage page, the « Proposer une modification du contenu » block links to `/contact/modifier-cas-usage?demarche=<slug>`; a solution page to `/contact/modifier-solution?solution=<slug>`.
- Home and about link to `/contact/contenu`; the sitemap lists `/contact`.
- Anyone, no login. Unknown step → 404.

## Driving it with Capybara

- **From a fiche.** Visit the first visible démarche, `click_link "proposer une modification du contenu de ce cas d'usage"`. Path `/contact/modifier-cas-usage?demarche=<slug>`.
- **Fiche cited.** `find_field('Objet du message', readonly: true).value` ends with ` : <nom>`; the decoded `href` of the link `Écrire à l'équipe` holds `Fiche concernée : <nom>`.
- **Copy.** Chrome needs `page.driver.browser.add_permission('clipboard-write', 'granted')`. Click `Copier l'objet du message`; the sr-only `[data-copier-target=statut]` reads `Objet du message copié.` (`visible: :all`).
- **Journey.** `Retour` → `/contact/contenu` (group headings h3), `Retour` → `/contact`, click `J'ai une question sur ma propre démarche administrative`: the answer shows, no `Écrire à l'équipe` link.
- **Proof.** `drive.rb contact`, screenshots `fiche-citee` and `reponse-sans-adresse`.

## Gotchas

- The « Copier » buttons carry `fr-hidden` until the Stimulus controller connects (and only when `navigator.clipboard` exists): `hidden` does not hide a `.fr-btn`.
