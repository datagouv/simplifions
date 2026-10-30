# Parcourir au clavier et avec un lecteur d'écran

The first Tab of any page lands on a « Contenu » skip link that jumps to the main content; the catalogue filters and tri change nothing until « Appliquer les filtres »; a number that changes without reload (solution counter, endpoints filter, Sirene demo result) sits in a `role="status"` region a screen reader announces.

## Sub-features

- `clavier-contenu` first Tab focuses « Contenu », Enter moves the next Tab inside `#content`, no reload.
- `clavier-filtres` arrows in a catalogue select keep the page; « Appliquer les filtres » submits facettes and tri together.
- `annonce-compteur` « N solutions disponibles » on a solution page is a status region updated by its filters.
- `annonce-endpoints` the endpoints filter of a recommandation writes « N endpoint(s) » into a hidden status region, empty on load.
- `annonce-sirene` the Sirene demo writes its error or « Résultat : <nom> » into a hidden status region.
- `emoji-muets` a démarche's title icon, ✒️ and 💡 stay on screen but are hidden from screen readers; the tab title carries the name alone.

## How to get to it (user POV)

- Any page, Tab from the address bar; admin pages too (same layout).
- `/demarches` or `/solutions`, left column, button under the last filter.
- `/solutions/<slug>` of a solution integrated by several solutions, filters above the tabs.
- `/demarches/<slug>`, a recommendation with several endpoints, field `Filtrer les endpoints`.
- `/articles/qu-est-ce-qu-une-api`, field `Numéro de SIRET d'un établissement :`.
- `/demarches/<slug>` of a démarche with a title icon and a site de consultation; its card on `/demarches?q=<nom>`.
- Anyone, no login.

## Driving it with Capybara

Drive: `features/clavier-lecteur-ecran.rb` (SKILL.md § Drive).

Preconditions: catalogue imported; a visible solution with several integrating solutions; a visible démarche whose recommandation lists two endpoints or more; a visible démarche with a title icon and a site de consultation.

- **Contenu.** Visit `/`, `send_keys(:tab)` on `body`: the focused element reads `Contenu`; Enter, then Tab: the focused element is inside `#content`, `performance.timeOrigin` unchanged.
- **Flèches.** On `/demarches`, `send_keys(:down, :down, :down)` on `Démarches à destination des :`: the select holds a value, path still `/demarches`, same `timeOrigin`. `click_button 'Appliquer les filtres'`: URL gains `target-users=<valeur>` (the count against the base is `catalogue-cas-usages.rb`).
- **Compteur.** On the solution page, `send_keys(:down)` on `Cas d'usage :`: the `[role=status]` text « N solutions disponibles » changes.
- **Endpoints.** Unfold the recommandation, `set('zzzz')` in its endpoints field: its `[role=status]` (hidden, read with `visible: :all`) goes from empty to `0 endpoint`.
- **Sirene.** SIRET `123` then `Interroger l'API`: the status holds « …14 chiffres. »; replace `window.fetch` with a stub answering `nom_complet: 'Vérif Sirene'`, SIRET `35600000000048`: the status holds `Résultat : Vérif Sirene`.
- **Emoji muets.** On the démarche page: the tab title has no icon; the H1, the breadcrumb's current item and « Proposer une modification du contenu » read, without their `aria-hidden` part, the name or the heading alone, and that part holds the icon or ✒️; the « Pour vraiment simplifier » box shows 💡 only inside `aria-hidden`. The catalogue card link reads the same.
- **Proof.** `tmp/verify/clavier-lecteur-ecran/` screenshots per step and `read-back.txt`: focus text, hash, `dans_main=true`, value chosen with `meme_page=true`, URL after the button, counter before → after, both announcements, the read and seen texts of the icons.

## Gotchas

- The skip link carries `data-turbo="false"`: Turbo turns every `#ancre` link into a visit that reloads the page (see `onglet-solutions-integratrices.md`).
- The endpoints and Sirene regions are `fr-sr-only`: Capybara sees them only with `visible: :all` and `text(:all)`.
- The Sirene demo calls `recherche-entreprises.api.gouv.fr` from the browser; stub `fetch` instead of depending on the network.
