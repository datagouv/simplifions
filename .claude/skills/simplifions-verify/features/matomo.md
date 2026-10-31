# Mesure d'audience Matomo

Every page a visitor sees sends one Matomo hit, on the first load and after each Turbo visit (link, form, back button), with its own url, title and the previous page as referrer. A search submitted in the catalogue, or a first load of a `?q=` link, sends one site-search hit (keyword, catalogue, result count) instead of the page view; the keyword last measured, one under 2 characters, or a page reached without submitting the form (back button, link) is a page view. A click on a link to another site sends one outlink hit, a click on a file link one download hit, on every page of the visit.

## Sub-features

- `matomo-page-vue` one hit per page shown, `url` (the path, without parameters) and `action_name` of that page.
- `matomo-recherche` a new keyword in `Rechercher` sends `search`, `search_cat` (`Cas d'usages` or `Solutions`) and `search_count`, and no page view.
- `matomo-meme-recherche` the keyword last measured (same search again, filter change), a keyword under 2 characters, or a search page reached by the back button is a page view.
- `matomo-lien-sortant` a click on a link to another site sends one hit with `link`, a click on a file link (pdf, csv, xlsx, docx, odt, ods, zip) one hit with `download` and no `link`, on the first page and after Turbo visits alike; a middle click or a right click (context menu) counts once too, as matomo.js does.

## How to get to it (user POV)

- Any public page, with the tag on: production sets `MATOMO_SITE_ID` (site 311); locally, run with `-e MATOMO_SITE_ID=999999`, a dummy site that stats.data.gouv.fr refuses.
- The search: `/demarches` or `/solutions`, field `Rechercher`.
- Browser devtools, Network tab filtered on `matomo.php`, shows each hit and its parameters.

## Driving it with Capybara

Drive: `features/matomo.rb` (SKILL.md § Drive).

Preconditions:

- Launch done and doctor green (SKILL.md § Launch, § Doctor); the browser containers reach stats.data.gouv.fr.
- One visible démarche matches « eaje ».

The drive sets `MATOMO_SITE_ID=999999` for its own server and counts the `matomo.php` requests the browser sent (`performance.getEntriesByType('resource')`), events aside: those carry `e_a` and have their own feature, [`matomo-evenements.md`](matomo-evenements.md).

- **Load.** `visit "/demarches"`. 1 hit, `action_name` `Cas d'usages | …`, no `search`.
- **Search.** `fill_in "Rechercher", with: "eaje"`, `click_button "Rechercher"`. 2 hits; the last has `search=eaje`, `search_cat=Cas d'usages`, `search_count` = `Demarche.catalogue({ "q" => "eaje" }).count`, and `url` the page's path without its parameters.
- **Open a result.** Click the first démarche link. 3 hits; the last has the page's url and title, `urlref` = the full search url (parameters included), no `search`.
- **Back.** `go_back`. 4 hits; the last is a page view of the search url, no `search`.
- **Same search again.** `fill_in "Rechercher", with: "eaje"`, `click_button "Rechercher"`. 5 hits; the last has no `search`.
- **Another search.** Same with « api ». 6 hits; the last has `search=api`.
- **Back to the older search.** `go_back`. 7 hits; the last is the « eaje » page, no `search`.
- **One character.** Same with « e ». 8 hits; the last has no `search`.
- **Outlink after navigation.** Cancel the next click (`addEventListener('click', e => e.preventDefault(), { once: true })`), click the footer link to `https://data.gouv.fr`. 9 hits; the last has `link=https://data.gouv.fr/`.
- **Download after navigation.** Insert a link to `/guide.pdf` into `main`, cancel the next click the same way, click it. 10 hits; the last has `download` ending in `/guide.pdf` and no `link`.
- **Outlink on the first page.** `visit "/demarches"` (full load, the count starts over): 1 hit; click the footer link the same way. Exactly 2 hits, the last with `link`: one hit per click, never two.
- **Middle click.** Cancel the next `auxclick`, middle-click the footer link (Selenium pointer action, `:middle`). Exactly 3 hits, the last with `link`.
- **Right click.** Cancel the next `contextmenu`, `right_click` the footer link. Exactly 4 hits, the last with `link`.
- **Proof.** `tmp/verify/matomo/`: one screenshot and one `read-back.txt` line per step with the last hit's parameters, in Chrome and Firefox.

## Gotchas

- Never run with `MATOMO_SITE_ID=311`: the hits would land in the real statistics.
- Without network to stats.data.gouv.fr, `matomo.js` never loads and no hit leaves: the drive times out on the first step.
- The tag measures link clicks itself; matomo.js's `enableLinkTracking` is off: its click listener binds once to the first `<body>`, which Turbo replaces.
- A hit is a `matomo.php` request; Matomo answers it even for the dummy site, so count requests, not responses.
