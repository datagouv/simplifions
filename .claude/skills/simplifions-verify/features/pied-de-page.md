# Pied de page

Every page, admin included, ends on the same footer: five blocks of links to the catalogue filtered by target users and by service provider, three starter guides, the solutions by category and the two comparisons of integrating solutions, then the blocks « Simplifions.data.gouv.fr », « Aide » and « Contribution ». Under the brand, the site presents itself as a catalogue and links to the home section « Comment simplifions.data peut-il vous aider ? ».

## Sub-features

- `categories` — eight category titles in order, same on a public page and in `/admin`.
- `liens` — each link of the five new blocks opens a non-empty list, a guide or the integrating solutions of a bouquet.
- `en-quoi-aider` — the presentation link lands on the home section, top of the window.
- `mobile` — at 375 px the blocks stack in one column.

## How to get to it (user POV)

- Scroll to the bottom of any page: `/`, `/demarches`, `/solutions/<slug>`, `/articles/<slug>`, `/admin` once logged in.
- Anyone, no login for the public pages.

## Driving it with Capybara

Preconditions: baseline; `bouquet-api-entreprise` and `bouquet-api-particulier` visible with integrating solutions; the dev-only admin (`drive.rb` creates it). `drive.rb pied-de-page`.

- **Categories.** `/` at 1280 then 375 wide: the footer's `h3` read, in order, the five new titles then `Simplifions.data.gouv.fr`, `Aide`, `Contribution`.
- **Presentation link.** From `/demarches`, click `En quoi simplifions.data.gouv.fr peut-il vous aider ?`: path `/`, hash `#comment-vous-aider`, the section's top at 0.
- **Links.** For each link of the five new blocks, from `/`: click it by its `href`; a `/demarches?…` or `/solutions?…` page shows a count in `[role=status]` equal to `Demarche.catalogue(params)` / `Solution.catalogue(params)` and above zero; a guide shows its `h1`; a bouquet shows at least one card under `#solutions-integratices`.
- **Admin.** Logged in, `/admin`: same eight titles.
- **Proof.** `tmp/verify/pied-de-page/` : `<browser>-accueil-1280.png`, `-accueil-375.png`, `-en-quoi-aider.png`, `-liens-suivis.png`, `-admin.png`, and `read-back.txt` with the followed paths.

## Gotchas

- `Logiciel métier « clé en main »` holds non-breaking spaces: Capybara's text matching turns them into spaces, so links are found by `href`.
- The scroll to the anchor lands after the Turbo visit: wait for the hash and the section's position, do not read them right after the click.
- `request_uri` drops the `#solutions-integratices` fragment: rebuild it to find the link.
